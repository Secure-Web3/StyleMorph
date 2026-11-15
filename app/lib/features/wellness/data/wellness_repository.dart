import 'package:flutter/material.dart';
import '../domain/wellness_models.dart';

class WellnessRepository {
  static const WellnessScore _beautyScore = WellnessScore(
    total: 80,
    status: 'خوب',
    subScores: {
      'مراقبت منظم': 75,
      'وضعیت پوست': 82,
      'وضعیت مو': 84,
    },
  );

  static const WellnessScore _healthScore = WellnessScore(
    total: 85,
    status: 'خوب',
    subScores: {
      'کیفیت خواب': 88,
      'تغذیه سالم': 80,
      'فعالیت بدنی': 82,
    },
  );

  static const WellnessScore _mindScore = WellnessScore(
    total: 70,
    status: 'متوسط',
    subScores: {
      'خلق‌وخو': 72,
      'کنترل استرس': 65,
      'کیفیت استراحت': 74,
    },
  );

  static final List<WellnessTask> _initialTasks = [
    const WellnessTask(
      id: 'task_1',
      title: 'تمرین کوتاه ۱۰ دقیقه‌ای کششی',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF4F7A5A),
      isDone: false,
    ),
    const WellnessTask(
      id: 'task_2',
      title: 'استفاده از مرطوب‌کننده صبح و شب',
      icon: Icons.water_drop_rounded,
      color: Color(0xFFC2547A),
      isDone: false,
    ),
    const WellnessTask(
      id: 'task_3',
      title: '۳ دقیقه تمرین تنفس آرام ذهن‌آگاهی',
      icon: Icons.air_rounded,
      color: Color(0xFF6B5FB5),
      isDone: false,
    ),
  ];

  WellnessScore getBeautyScore() => _beautyScore;
  WellnessScore getHealthScore() => _healthScore;
  WellnessScore getMindScore() => _mindScore;
  List<WellnessTask> getTasks() => List.unmodifiable(_initialTasks);
}
