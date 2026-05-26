import 'word_model.dart';

class StoryQuizModel {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  StoryQuizModel({
    required this.question,
    required this.options,
    required this.answerIndex,
    this.explanation = '',
  });

  factory StoryQuizModel.fromJson(Map<String, dynamic> json) {
    return StoryQuizModel(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answerIndex: json['answerIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'answerIndex': answerIndex,
    'explanation': explanation,
  };
}

class StoryModel {
  final String id;
  final String user;
  final String title;
  final String content;
  final String translation;
  final List<WordModel> words;
  final List<StoryQuizModel> quiz;
  final bool isCompleted;
  final int xpEarned;
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.user,
    required this.title,
    required this.content,
    required this.translation,
    required this.words,
    required this.quiz,
    required this.isCompleted,
    required this.xpEarned,
    required this.createdAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    var wordsJson = json['words'] as List? ?? [];
    List<WordModel> wordsList = wordsJson
        .map((w) => w is Map<String, dynamic> ? WordModel.fromJson(w) : WordModel(id: w.toString(), word: '', meaningVn: '', level: 'A1', source: '', topic: ''))
        .toList();

    var quizJson = json['quiz'] as List? ?? [];
    List<StoryQuizModel> quizList = quizJson
        .map((q) => StoryQuizModel.fromJson(q))
        .toList();

    return StoryModel(
      id: json['_id'] ?? '',
      user: json['user'] ?? '',
      title: json['title'] ?? 'AI English Story',
      content: json['content'] ?? '',
      translation: json['translation'] ?? '',
      words: wordsList,
      quiz: quizList,
      isCompleted: json['isCompleted'] ?? false,
      xpEarned: json['xpEarned'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user': user,
    'title': title,
    'content': content,
    'translation': translation,
    'words': words.map((w) => w.toJson()).toList(),
    'quiz': quiz.map((q) => q.toJson()).toList(),
    'isCompleted': isCompleted,
    'xpEarned': xpEarned,
    'createdAt': createdAt.toIso8601String(),
  };
}
