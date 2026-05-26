// TTS Service - Singleton: audioUrl (real recording) first, TTS fallback
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  late final FlutterTts _flutterTts;
  late final AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  TtsService._internal() {
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      print('❌ [TtsService init error]: $e');
    }
  }

  /// PRIMARY: Play real audio recording from URL.
  /// FALLBACK: If URL is empty or fails, use TTS to synthesize speech.
  Future<void> playWord(String word, {String audioUrl = ''}) async {
    if (audioUrl.isNotEmpty) {
      try {
        await _flutterTts.stop();
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(audioUrl));
        return;
      } catch (_) {
        // Fall through to TTS if network audio fails
      }
    }
    await speak(word);
  }

  /// Speaks the given text in English using device TTS
  Future<void> speak(String text) async {
    if (!_isInitialized) await _initTts();
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ [TtsService speak error]: $e');
    }
  }

  /// Stops all audio (both URL-based and TTS)
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop();
    } catch (e) {
      print('❌ [TtsService stop error]: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      print('❌ [TtsService setLanguage error]: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('❌ [TtsService setSpeechRate error]: $e');
    }
  }
}
