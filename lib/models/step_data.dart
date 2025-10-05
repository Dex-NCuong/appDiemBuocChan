class StepData {
  final int steps;
  final double distance; // km
  final double calories; // kcal
  final int activeTime; // minutes
  final DateTime date;

  StepData({
    required this.steps,
    required this.distance,
    required this.calories,
    required this.activeTime,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'activeTime': activeTime,
      'date': date.toIso8601String(),
    };
  }

  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      steps: json['steps'] ?? 0,
      distance: (json['distance'] ?? 0.0).toDouble(),
      calories: (json['calories'] ?? 0.0).toDouble(),
      activeTime: json['activeTime'] ?? 0,
      date: DateTime.parse(json['date']),
    );
  }

  StepData copyWith({
    int? steps,
    double? distance,
    double? calories,
    int? activeTime,
    DateTime? date,
  }) {
    return StepData(
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      activeTime: activeTime ?? this.activeTime,
      date: date ?? this.date,
    );
  }
}
