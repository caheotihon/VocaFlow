// Word Provider — manages vocabulary data state
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/api_service.dart';

class WordProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<WordModel> _words = [];
  List<WordModel> _searchResults = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _topics = [];
  bool _isLoading = false;
  String? _error;

  List<WordModel> get words => _words;
  List<WordModel> get searchResults => _searchResults;
  List<Map<String, dynamic>> get sources => _sources;
  List<Map<String, dynamic>> get topics => _topics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSources({String? level}) async {
    _setLoading(true);
    try {
      final res = await _api.getSources(level: level);
      if (res.data['success'] == true) {
        _sources = List<Map<String, dynamic>>.from(res.data['data']['sources']);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTopics({String? source, String? level}) async {
    _setLoading(true);
    try {
      final res = await _api.getTopics(source: source, level: level);
      if (res.data['success'] == true) {
        _topics = List<Map<String, dynamic>>.from(res.data['data']['topics']);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<WordModel>> loadWordsBySource(String source,
      {String? level, String? topic}) async {
    _setLoading(true);
    try {
      final res = await _api.getWordsBySource(source, level: level, topic: topic);
      if (res.data['success'] == true) {
        _words = (res.data['data']['words'] as List)
            .map((w) => WordModel.fromJson(w))
            .toList();
        return _words;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    return [];
  }

  Future<void> searchWords(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      final res = await _api.searchWords(query);
      if (res.data['success'] == true) {
        _searchResults = (res.data['data']['words'] as List)
            .map((w) => WordModel.fromJson(w))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
