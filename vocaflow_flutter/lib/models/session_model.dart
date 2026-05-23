// Session model for active learning session state
import 'word_model.dart';

class SessionModel {
  final String id;
  final String source;
  final String? level;
  final String? topic;
  final String mode;
  final List<WordModel> words;
  int currentIndex;
  int correctAnswers;
  int wrongAnswers;
  final DateTime startTime;

  SessionModel({
    required this.id,
    required this.source,
    this.level,
    this.topic,
    required this.mode,
    required this.words,
    this.currentIndex = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  WordModel? get currentWord =>
      currentIndex < words.length ? words[currentIndex] : null;

  bool get isComplete => currentIndex >= words.length;

  double get accuracy =>
      (correctAnswers + wrongAnswers) > 0
          ? (correctAnswers / (correctAnswers + wrongAnswers)) * 100
          : 0;

  int get durationSeconds =>
      DateTime.now().difference(startTime).inSeconds;

  void nextWord() => currentIndex++;
  void prevWord() {
    if (currentIndex > 0) currentIndex--;
  }
}

// Learning result for a single word answer
class WordResult {
  final WordModel word;
  final bool isCorrect;
  final int timeTakenMs;

  WordResult({
    required this.word,
    required this.isCorrect,
    required this.timeTakenMs,
  });
}
