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

  Map<String, dynamic>? _todayStats;
  List<WordModel> _todayCorrectWords = [];
  List<WordModel> _todayWrongWords = [];

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

  Map<String, dynamic>? get todayStats => _todayStats;
  List<WordModel> get todayCorrectWords => _todayCorrectWords;
  List<WordModel> get todayWrongWords => _todayWrongWords;

  Future<bool> fetchTodayHistory() async {
    _setLoading(true);
    try {
      final res = await _api.getTodayHistory();
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _todayStats = data['stats'];
        _todayCorrectWords = (data['correctWords'] as List)
            .map((w) => WordModel.fromJson(w))
            .toList();
        _todayWrongWords = (data['wrongWords'] as List)
            .map((w) => WordModel.fromJson(w))
            .toList();
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

  Future<bool> resumeSession() async {
    _setLoading(true);
    try {
      final res = await _api.getLastActiveSession();
      if (res.data['success'] == true && res.data['data']['session'] != null) {
        final sessionData = res.data['data']['session'];
        final words = (sessionData['words_studied'] as List)
            .map((w) => WordModel.fromJson(w))
            .toList();
        
        selectedSource = sessionData['source'];
        selectedLevel = sessionData['level'];
        selectedTopic = sessionData['topic'];
        selectedMode = sessionData['mode'];

        final currentIndex = (sessionData['correct_answers'] ?? 0) + (sessionData['wrong_answers'] ?? 0);

        _session = SessionModel(
          id: sessionData['_id'] ?? sessionData['session_id'] ?? '',
          source: selectedSource!,
          level: selectedLevel,
          topic: selectedTopic,
          mode: selectedMode!,
          words: words,
          currentIndex: currentIndex,
          correctAnswers: sessionData['correct_answers'] ?? 0,
          wrongAnswers: sessionData['wrong_answers'] ?? 0,
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
