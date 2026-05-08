// Word model matching backend schema
class WordModel {
  final String id;
  final String word;
  final String meaningVn;
  final String definitionVn;
  final String definitionEn;
  final String example;
  final String exampleVn;
  final String pronunciation;
  final String audioUrl;
  final String imageUrl;
  final String level;
  final String source;
  final String topic;
  final int difficulty;
  final int frequencyRank;
  final List<String> tags;
  final String partOfSpeech;
  final List<String> synonyms;
  final List<String> antonyms;

  WordModel({
    required this.id,
    required this.word,
    required this.meaningVn,
    this.definitionVn = '',
    this.definitionEn = '',
    this.example = '',
    this.exampleVn = '',
    this.pronunciation = '',
    this.audioUrl = '',
    this.imageUrl = '',
    required this.level,
    required this.source,
    required this.topic,
    this.difficulty = 1,
    this.frequencyRank = 9999,
    this.tags = const [],
    this.partOfSpeech = 'noun',
    this.synonyms = const [],
    this.antonyms = const [],
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id:            json['_id'] ?? '',
      word:          json['word'] ?? '',
      meaningVn:     json['meaning_vn'] ?? '',
      definitionVn:  json['definition_vn'] ?? '',
      definitionEn:  json['definition_en'] ?? '',
      example:       json['example'] ?? '',
      exampleVn:     json['example_vn'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      audioUrl:      json['audio_url'] ?? '',
      imageUrl:      json['image_url'] ?? '',
      level:         json['level'] ?? 'A1',
      source:        json['source'] ?? '',
      topic:         json['topic'] ?? '',
      difficulty:    json['difficulty'] ?? 1,
      frequencyRank: json['frequency_rank'] ?? 9999,
      tags:          List<String>.from(json['tags'] ?? []),
      partOfSpeech:  json['partOfSpeech'] ?? 'noun',
      synonyms:      List<String>.from(json['synonyms'] ?? []),
      antonyms:      List<String>.from(json['antonyms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':            id,
    'word':           word,
    'meaning_vn':     meaningVn,
    'definition_vn':  definitionVn,
    'definition_en':  definitionEn,
    'example':        example,
    'level':          level,
    'source':         source,
    'topic':          topic,
    'difficulty':     difficulty,
    'frequency_rank': frequencyRank,
    'tags':           tags,
    'partOfSpeech':   partOfSpeech,
  };
}
