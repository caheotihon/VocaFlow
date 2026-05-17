// User model matching backend User schema
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String bio;
  final int streakDays;
  final int bestStreak;
  final int totalXP;
  final int dailyXP;
  final int dailyGoal;
  final int goalAccuracy;
  final List<String> badges;
  final List<int> streakMilestonesClaimed;
  final String authProvider;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.bio = '',
    this.streakDays = 0,
    this.bestStreak = 0,
    this.totalXP = 0,
    this.dailyXP = 0,
    this.dailyGoal = 20,
    this.goalAccuracy = 80,
    this.badges = const [],
    this.streakMilestonesClaimed = const [],
    this.authProvider = 'local',
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:                       json['_id'] ?? '',
      name:                     json['name'] ?? '',
      email:                    json['email'] ?? '',
      avatar:                   json['avatar'],
      bio:                      json['bio'] ?? '',
      streakDays:               json['streakDays'] ?? 0,
      bestStreak:               json['bestStreak'] ?? 0,
      totalXP:                  json['totalXP'] ?? 0,
      dailyXP:                  json['dailyXP'] ?? 0,
      dailyGoal:                json['dailyGoal'] ?? 20,
      goalAccuracy:             json['goalAccuracy'] ?? 80,
      badges:                   List<String>.from(json['badges'] ?? []),
      streakMilestonesClaimed:  List<int>.from(json['streakMilestonesClaimed'] ?? []),
      authProvider:             json['authProvider'] ?? 'local',
      createdAt:                json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':                    id,
    'name':                   name,
    'email':                  email,
    'avatar':                 avatar,
    'bio':                    bio,
    'streakDays':             streakDays,
    'bestStreak':             bestStreak,
    'totalXP':                totalXP,
    'dailyXP':                dailyXP,
    'dailyGoal':              dailyGoal,
    'goalAccuracy':           goalAccuracy,
    'badges':                 badges,
    'streakMilestonesClaimed': streakMilestonesClaimed,
    'authProvider':           authProvider,
  };

  UserModel copyWith({
    String? name,
    String? avatar,
    String? bio,
    int? dailyGoal,
    int? goalAccuracy,
    int? streakDays,
    int? bestStreak,
    int? totalXP,
    int? dailyXP,
    List<String>? badges,
    List<int>? streakMilestonesClaimed,
  }) {
    return UserModel(
      id: id,
      email: email,
      authProvider: authProvider,
      createdAt: createdAt,
      name:                    name ?? this.name,
      avatar:                  avatar ?? this.avatar,
      bio:                     bio ?? this.bio,
      streakDays:              streakDays ?? this.streakDays,
      bestStreak:              bestStreak ?? this.bestStreak,
      totalXP:                 totalXP ?? this.totalXP,
      dailyXP:                 dailyXP ?? this.dailyXP,
      dailyGoal:               dailyGoal ?? this.dailyGoal,
      goalAccuracy:            goalAccuracy ?? this.goalAccuracy,
      badges:                  badges ?? this.badges,
      streakMilestonesClaimed: streakMilestonesClaimed ?? this.streakMilestonesClaimed,
    );
  }
}
