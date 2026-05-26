// Favorites Provider
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/api_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<WordModel> _favorites = [];
  Set<String> _favoriteIds = {};
  List<Map<String, dynamic>> _learnedWords = [];
  bool _isLoading = false;

  List<WordModel> get favorites => _favorites;
  List<Map<String, dynamic>> get learnedWords => _learnedWords;
  bool get isLoading => _isLoading;
  bool isFavorite(String wordId) => _favoriteIds.contains(wordId);

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.getFavorites();
      if (res.data['success'] == true) {
        final favs = res.data['data']['favorites'] as List;
        _favorites = favs
            .map((f) => WordModel.fromJson(f['word']))
            .toList();
        _favoriteIds = _favorites.map((w) => w.id).toSet();
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLearnedWords() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.getProgress();
      if (res.data['success'] == true) {
        final List progs = res.data['data']['progresses'] ?? [];
        _learnedWords = progs.map((p) {
          final wordJson = p['word'];
          return {
            'word': WordModel.fromJson(wordJson),
            'status': p['status'] ?? 'learning',
            'mastery': p['mastery'] ?? 0,
          };
        }).toList();
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(WordModel word) async {
    if (_favoriteIds.contains(word.id)) {
      _favoriteIds.remove(word.id);
      _favorites.removeWhere((w) => w.id == word.id);
      notifyListeners();
      await _api.removeFavorite(word.id);
    } else {
      _favoriteIds.add(word.id);
      _favorites.insert(0, word);
      notifyListeners();
      await _api.addFavorite(word.id);
    }
  }
}
