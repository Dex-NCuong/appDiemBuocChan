class UserSettings {
  final double height; // cm
  final double weight; // kg
  final int dailyGoal; // steps per day
  final double stepLength; // meters per step

  UserSettings({
    required this.height,
    required this.weight,
    required this.dailyGoal,
    required this.stepLength,
  });

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'weight': weight,
      'dailyGoal': dailyGoal,
      'stepLength': stepLength,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      height: (json['height'] ?? 170.0).toDouble(),
      weight: (json['weight'] ?? 70.0).toDouble(),
      dailyGoal: json['dailyGoal'] ?? 10000,
      stepLength: (json['stepLength'] ?? 0.75).toDouble(),
    );
  }

  UserSettings copyWith({
    double? height,
    double? weight,
    int? dailyGoal,
    double? stepLength,
  }) {
    return UserSettings(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      stepLength: stepLength ?? this.stepLength,
    );
  }

  // Calculate step length based on height (approximate)
  static double calculateStepLength(double height) {
    return height * 0.43 / 100; // Convert cm to meters and apply factor
  }
}
