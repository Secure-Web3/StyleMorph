import 'package:flutter/material.dart';

@immutable
class WellnessScore {
  final int total;
  final String status;
  final Map<String, int> subScores;

  const WellnessScore({
    required this.total,
    required this.status,
    required this.subScores,
  });
}

@immutable
class WellnessTask {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final bool isDone;

  const WellnessTask({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.isDone = false,
  });

  WellnessTask copyWith({bool? isDone}) {
    return WellnessTask(
      id: id,
      title: title,
      icon: icon,
      color: color,
      isDone: isDone ?? this.isDone,
    );
  }
}

@immutable
class DailyCheckIn {
  final int mood; // 1 to 5
  final String energy; // 'کم', 'متوسط', 'زیاد'
  final String sleepOption;
  final double? weight;
  final DateTime date;

  const DailyCheckIn({
    required this.mood,
    required this.energy,
    required this.sleepOption,
    this.weight,
    required this.date,
  });
}
