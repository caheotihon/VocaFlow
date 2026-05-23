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
  final Map<String, bool> _answeredCorrectByWordId = {};

  Map<String, dynamic>? _todayStats;
  List<WordModel> _todayCorrectWords = [];
  List<WordModel> _todayWrongWords = [];

  // AI Story state
  bool _isLoadingStory = false;
  String? _aiStoryEn;
  String? _aiStoryVi;

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

  bool get isLoadingStory => _isLoadingStory;
  String? get aiStoryEn => _aiStoryEn;
  String? get aiStoryVi => _aiStoryVi;

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

  Future<void> submitAnswer(
    bool isCorrect, {
    int timeTakenMs = 0,
    String? userAnswer,
    String? correctAnswer,
    String? prompt,
    List<String>? options,
    String? mode,
    bool advance = true,
  }) async {
    if (_session == null || _session!.currentWord == null) return;
    final word = _session!.currentWord!;

    final prev = _answeredCorrectByWordId[word.id];
    if (prev != null) {
      if (prev) {
        _session!.correctAnswers = (_session!.correctAnswers - 1) < 0 ? 0 : (_session!.correctAnswers - 1);
      } else {
        _session!.wrongAnswers = (_session!.wrongAnswers - 1) < 0 ? 0 : (_session!.wrongAnswers - 1);
      }
    }
    _answeredCorrectByWordId[word.id] = isCorrect;

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
        userAnswer: userAnswer,
        correctAnswer: correctAnswer,
        prompt: prompt,
        options: options,
        mode: mode,
      );
    } catch (_) { /* Fire and forget */ }

    if (advance) _session!.nextWord();
    notifyListeners();
  }

  void goToPreviousWord() {
    if (_session == null) return;
    _session!.prevWord();
    notifyListeners();
  }

  void goToNextWord() {
    if (_session == null) return;
    _session!.nextWord();
    notifyListeners();
  }

  void nextWord() {
    if (_session != null) {
      _session!.nextWord();
      notifyListeners();
    }
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

  Future<bool> generateAiStory(List<String> wordIds) async {
    _isLoadingStory = true;
    _aiStoryEn = null;
    _aiStoryVi = null;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.generateAiStory(wordIds);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _aiStoryEn = data['storyEn'];
        _aiStoryVi = data['storyVi'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingStory = false;
      notifyListeners();
    }
    return false;
  }

  void resetSession() {
    _session = null;
    _sessionResult = null;
    _aiStoryEn = null;
    _aiStoryVi = null;
    _answeredCorrectByWordId.clear();
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    if (val) _error = null;
    notifyListeners();
  }
}
