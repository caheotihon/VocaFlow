// LingoPro — API Service using Dio
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Use 'http://10.0.2.2:3000/api' for Android Emulator
  // Use 'http://localhost:3000/api' for iOS Simulator or Web
  // Use your machine's IP for physical device: 'http://192.168.1.x:3000/api'
  static const String _baseUrl = 'http://localhost:3000/api';

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  /// Test constructor — accepts a pre-configured [Dio] instance for unit testing.
  @visibleForTesting
  ApiService.withDio(Dio dio) : _dio = dio;

  // ── Auth ───────────────────────────────────────────────────────────
  Future<Response> register(String name, String email, String password) =>
      _dio.post('/auth/register', data: {'name': name, 'email': email, 'password': password});

  Future<Response> login(String email, String password) =>
      _dio.post('/auth/login', data: {'email': email, 'password': password});

  /// Google login — pass profile data directly (no idToken needed for google_sign_in)
  Future<Response> googleLogin({
    String? idToken,
    String? email,
    String? name,
    String? avatar,
    String? googleId,
  }) =>
      _dio.post('/auth/google', data: {
        if (idToken != null) 'idToken': idToken,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (googleId != null) 'googleId': googleId,
      });

  Future<Response> getMe() => _dio.get('/auth/me');

  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/auth/profile', data: data);

  // ── Words ──────────────────────────────────────────────────────────
  Future<Response> getWords({int page = 1, int limit = 20}) =>
      _dio.get('/words', queryParameters: {'page': page, 'limit': limit});

  Future<Response> getWordById(String id) => _dio.get('/words/$id');

  Future<Response> searchWords(String q) =>
      _dio.get('/words/search', queryParameters: {'q': q});

  Future<Response> getRandomWord() => _dio.get('/words/random');

  Future<Response> getWordsBySource(String source, {String? level, String? topic, int page = 1}) =>
      _dio.get('/words/source/${Uri.encodeComponent(source)}',
          queryParameters: {'level': level, 'topic': topic, 'page': page});

  Future<Response> getWordsByTopic(String topic, {String? level, String? source}) =>
      _dio.get('/words/topic/${Uri.encodeComponent(topic)}',
          queryParameters: {'level': level, 'source': source});

  Future<Response> getWordsByLevel(String level) =>
      _dio.get('/words/level/$level');

  Future<Response> getSources({String? level}) =>
      _dio.get('/words/sources/list', queryParameters: level != null ? {'level': level} : null);

  Future<Response> getTopics({String? source, String? level}) =>
      _dio.get('/words/topics/list', queryParameters: {'source': source, 'level': level});

  Future<Response> generateAIDeck(String topic, {String? level}) =>
      _dio.post('/words/ai-generate', data: {'topic': topic, 'level': level});

  // ── Learn ──────────────────────────────────────────────────────────
  Future<Response> startSession(String source, String mode,
          {String? level, String? topic, int count = 10}) =>
      _dio.post('/learn/start', data: {
        'source': source, 'mode': mode, 'level': level, 'topic': topic, 'count': count,
      });

  Future<Response> submitResult(
    String sessionId,
    String wordId, {
    required bool isCorrect,
    int timeTakenMs = 0,
    String? userAnswer,
    String? correctAnswer,
    String? prompt,
    List<String>? options,
    String? mode,
  }) =>
      _dio.post('/learn/result', data: {
        'session_id': sessionId,
        'word_id': wordId,
        'is_correct': isCorrect,
        'time_taken_ms': timeTakenMs,
        if (userAnswer != null) 'user_answer': userAnswer,
        if (correctAnswer != null) 'correct_answer': correctAnswer,
        if (prompt != null) 'prompt': prompt,
        if (options != null) 'options': options,
        if (mode != null) 'mode': mode,
      });

  Future<Response> completeSession(String sessionId, {int durationSeconds = 0}) =>
      _dio.post('/learn/complete',
          data: {'session_id': sessionId, 'duration_seconds': durationSeconds});

  Future<Response> getProgress({String? source, String? level, String? topic}) =>
      _dio.get('/learn/progress',
          queryParameters: {'source': source, 'level': level, 'topic': topic});

  Future<Response> getReviewToday() => _dio.get('/learn/review-today');
  Future<Response> getTodayHistory() => _dio.get('/learn/today-history');
  Future<Response> getLastActiveSession() => _dio.get('/learn/last-active');
  Future<Response> generateAiStory(List<String> wordIds) =>
      _dio.post('/learn/ai-story', data: {'word_ids': wordIds});

  // ── Favorites ─────────────────────────────────────────────────────
  Future<Response> getFavorites() => _dio.get('/favorite');
  Future<Response> addFavorite(String wordId) => _dio.post('/favorite/$wordId');
  Future<Response> removeFavorite(String wordId) => _dio.delete('/favorite/$wordId');
  Future<Response> checkFavorite(String wordId) => _dio.get('/favorite/check/$wordId');

  // ── Stats ─────────────────────────────────────────────────────────
  Future<Response> getDashboard() => _dio.get('/stats/dashboard');
  Future<Response> getLeaderboard({String type = 'streak'}) =>
      _dio.get('/stats/leaderboard', queryParameters: {'type': type});

  // ── Stories (AI Story Generator) ──────────────────────────────────
  Future<Response> generateStory(List<String> wordIds) =>
      _dio.post('/stories/generate', data: {'wordIds': wordIds});

  Future<Response> getStories() => _dio.get('/stories');

  Future<Response> getStoryById(String id) => _dio.get('/stories/$id');

  Future<Response> completeStoryQuiz(String id) => _dio.post('/stories/$id/complete');

  Future<Response> deleteStory(String id) => _dio.delete('/stories/$id');
}
