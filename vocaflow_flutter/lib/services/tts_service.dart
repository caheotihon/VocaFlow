// TTS Service - Singleton to control text-to-speech
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  late final FlutterTts _flutterTts;
  bool _isInitialized = false;

  TtsService._internal() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45); // slightly slower rate for learners
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      print('❌ [TtsService init error]: $e');
    }
  }

  /// Speaks the given text in English
  Future<void> speak(String text) async {
    if (!_isInitialized) await _initTts();
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ [TtsService speak error]: $e');
    }
  }

  /// Stops current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('❌ [TtsService stop error]: $e');
    }
  }

  /// Changes dialect/language (e.g. 'en-US' or 'en-GB')
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      print('❌ [TtsService setLanguage error]: $e');
    }
  }

  /// Adjusts speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('❌ [TtsService setSpeechRate error]: $e');
    }
  }
}
