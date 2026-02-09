class UserSettings {
  final String userId;
  final List<String> signs;
  final String pushTime; // "HH:MM"
  final bool isActive;

  UserSettings({
    required this.userId,
    required this.signs,
    required this.pushTime,
    required this.isActive,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      signs: (json['signs'] as List<dynamic>).cast<String>(),
      pushTime: json['push_time'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'signs': signs,
      'push_time': pushTime,
      'is_active': isActive,
    };
  }
}
