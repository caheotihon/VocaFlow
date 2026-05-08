// Learn Provider — manages active learning session state
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';

class LearnProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  SessionModel? _session;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _sessionResult;

  // Selected learn flow state
  String? selectedSource;
  String? selectedLevel;
  String? selectedTopic;
  String? selectedMode;

  SessionModel? get session => _session;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get sessionResult => _sessionResult;
  WordModel? get currentWord => _session?.currentWord;
  bool get isSessionComplete => _session?.isComplete ?? false;

  void selectSource(String source) {
    selectedSource = source;
    notifyListeners();
  }

  void selectLevel(String level) {
    selectedLevel = level;
    notifyListeners();
  }

  void selectTopic(String topic) {
    selectedTopic = topic;
    notifyListeners();
  }

  void selectMode(String mode) {
    selectedMode = mode;
    notifyListeners();
  }

  Future<bool> startSession() async {
    if (selectedSource == null || selectedMode == null) return false;
    _setLoading(true);
    try {
      final res = await _api.startSession(
        selectedSource!,
        selectedMode!,
        level: selectedLevel,
        topic: selectedTopic,
        count: 10,
      );
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final words = (data['words'] as List)
            .map((w) => WordModel.fromJson(w))
            .toList();
        _session = SessionModel(
          id: data['session_id'],
          source: selectedSource!,
          level: selectedLevel,
          topic: selectedTopic,
          mode: selectedMode!,
          words: words,
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> submitAnswer(bool isCorrect, {int timeTakenMs = 0}) async {
    if (_session == null || _session!.currentWord == null) return;
    final word = _session!.currentWord!;

    if (isCorrect) {
      _session!.correctAnswers++;
    } else {
      _session!.wrongAnswers++;
    }

    try {
      await _api.submitResult(
        _session!.id,
        word.id,
        isCorrect: isCorrect,
        timeTakenMs: timeTakenMs,
      );
    } catch (_) { /* Fire and forget */ }

    _session!.nextWord();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> completeSession() async {
    if (_session == null) return null;
    try {
      final res = await _api.completeSession(
        _session!.id,
        durationSeconds: _session!.durationSeconds,
      );
      if (res.data['success'] == true) {
        _sessionResult = res.data['data'];
        notifyListeners();
        return _sessionResult;
      }
    } catch (e) {
      _error = e.toString();
    }
    return null;
  }

  void resetSession() {
    _session = null;
    _sessionResult = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    if (val) _error = null;
    notifyListeners();
  }
}
