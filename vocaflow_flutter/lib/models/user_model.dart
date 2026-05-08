// User model matching backend User schema
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final int streakDays;
  final int totalXP;
  final int dailyXP;
  final int dailyGoal;
  final int goalAccuracy;
  final List<String> badges;
  final String authProvider;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.streakDays = 0,
    this.totalXP = 0,
    this.dailyXP = 0,
    this.dailyGoal = 20,
    this.goalAccuracy = 80,
    this.badges = const [],
    this.authProvider = 'local',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:           json['_id'] ?? '',
      name:         json['name'] ?? '',
      email:        json['email'] ?? '',
      avatar:       json['avatar'],
      streakDays:   json['streakDays'] ?? 0,
      totalXP:      json['totalXP'] ?? 0,
      dailyXP:      json['dailyXP'] ?? 0,
      dailyGoal:    json['dailyGoal'] ?? 20,
      goalAccuracy: json['goalAccuracy'] ?? 80,
      badges:       List<String>.from(json['badges'] ?? []),
      authProvider: json['authProvider'] ?? 'local',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':          id,
    'name':         name,
    'email':        email,
    'avatar':       avatar,
    'streakDays':   streakDays,
    'totalXP':      totalXP,
    'dailyXP':      dailyXP,
    'dailyGoal':    dailyGoal,
    'goalAccuracy': goalAccuracy,
    'badges':       badges,
    'authProvider': authProvider,
  };

  UserModel copyWith({
    String? name, String? avatar, int? dailyGoal, int? goalAccuracy,
  }) {
    return UserModel(
      id: id, email: email, streakDays: streakDays,
      totalXP: totalXP, dailyXP: dailyXP, badges: badges, authProvider: authProvider,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      goalAccuracy: goalAccuracy ?? this.goalAccuracy,
    );
  }
}
