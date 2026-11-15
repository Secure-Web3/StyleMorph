import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/ai_gateway_client.dart';
import '../../../core/services/health_service.dart';
import '../../../core/state/app_state.dart';
import '../data/wellness_repository.dart';
import '../domain/wellness_models.dart';

class WellnessState {
  final WellnessScore beautyScore;
  final WellnessScore healthScore;
  final WellnessScore mindScore;
  final List<WellnessTask> tasks;
  final bool isPrivateMode;
  final String activeMetric; // 'w', 's', 'a', 'm', 'h'
  final DailyCheckIn? lastCheckIn;
  final AiGenerationResult? lastFutureSelfResult;
  final bool isSimulatingFutureSelf;

  const WellnessState({
    required this.beautyScore,
    required this.healthScore,
    required this.mindScore,
    required this.tasks,
    this.isPrivateMode = false,
    this.activeMetric = 'w',
    this.lastCheckIn,
    this.lastFutureSelfResult,
    this.isSimulatingFutureSelf = false,
  });

  WellnessState copyWith({
    WellnessScore? beautyScore,
    WellnessScore? healthScore,
    WellnessScore? mindScore,
    List<WellnessTask>? tasks,
    bool? isPrivateMode,
    String? activeMetric,
    DailyCheckIn? lastCheckIn,
    AiGenerationResult? lastFutureSelfResult,
    bool? isSimulatingFutureSelf,
  }) {
    return WellnessState(
      beautyScore: beautyScore ?? this.beautyScore,
      healthScore: healthScore ?? this.healthScore,
      mindScore: mindScore ?? this.mindScore,
      tasks: tasks ?? this.tasks,
      isPrivateMode: isPrivateMode ?? this.isPrivateMode,
      activeMetric: activeMetric ?? this.activeMetric,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      lastFutureSelfResult: lastFutureSelfResult ?? this.lastFutureSelfResult,
      isSimulatingFutureSelf:
          isSimulatingFutureSelf ?? this.isSimulatingFutureSelf,
    );
  }

  int get completedTasksCount => tasks.where((t) => t.isDone).length;
}

class WellnessNotifier extends StateNotifier<WellnessState> {
  final Ref _ref;

  WellnessNotifier(WellnessRepository repo, this._ref)
      : super(
          WellnessState(
            beautyScore: repo.getBeautyScore(),
            healthScore: repo.getHealthScore(),
            mindScore: repo.getMindScore(),
            tasks: repo.getTasks(),
          ),
        );

  void togglePrivateMode() {
    state = state.copyWith(isPrivateMode: !state.isPrivateMode);
  }

  void toggleTask(String id) {
    final updated = state.tasks.map((t) {
      if (t.id == id) {
        return t.copyWith(isDone: !t.isDone);
      }
      return t;
    }).toList();
    state = state.copyWith(tasks: updated);
  }

  void setActiveMetric(String metric) {
    state = state.copyWith(activeMetric: metric);
  }

  void submitDailyCheckIn(DailyCheckIn checkIn) {
    state = state.copyWith(lastCheckIn: checkIn);
  }

  void applyWearableHealthSync(HealthDnaSnapshot snapshot) {
    if (!snapshot.isConnected) return;

    final currentSub = Map<String, int>.from(state.healthScore.subScores);
    if (snapshot.steps != null) {
      currentSub['فعالیت فیزیکی'] = (snapshot.steps! / 110).clamp(30, 100).round();
    }
    if (snapshot.sleepHours != null) {
      currentSub['کیفیت خواب'] = (snapshot.sleepHours! * 12.0).clamp(25, 100).round();
    }
    if (snapshot.heartRateBpm != null) {
      currentSub['شاخص قلب'] =
          (100 - (snapshot.heartRateBpm! - 65).abs() * 1.5).clamp(40, 100).round();
    }

    final newTotal = snapshot.energyReadinessScore;
    final status = newTotal >= 80 ? 'عالی' : (newTotal >= 60 ? 'خوب' : 'متوسط');

    state = state.copyWith(
      healthScore: WellnessScore(
        total: newTotal,
        status: status,
        subScores: currentSub,
      ),
    );
  }

  Future<AiGenerationResult?> runFutureSelfSimulation({
    String timeframe = '۶ ماه',
    bool simulateFailure = false,
  }) async {
    const cost = 10;
    final coins = _ref.read(appStateProvider).coins;
    if (coins < cost) {
      throw Exception('موجودی سکه برای شبیه‌ساز خودِ آینده کافی نیست.');
    }

    // Hold 10 coins synchronously before awaiting gateway response
    _ref.read(appStateProvider.notifier).addCoins(-cost);
    state = state.copyWith(isSimulatingFutureSelf: true);

    final gateway = _ref.read(aiGatewayClientProvider);
    final localeCode = _ref.read(localeProvider).code;
    final idempotencyKey = gateway.generateIdempotencyKey('future_self');

    final healthSnapshot = _ref.read(healthServiceProvider);
    final healthContext = healthSnapshot.isConnected
        ? healthSnapshot.toGatewayContext()
        : null;

    try {
      final result = await gateway.generate(
        userId: 'user_local_demo',
        serviceType: AiServiceType.wellnessAnalysis,
        qualityTier: AiQualityTier.standard,
        prompt: 'Physiological Future Self simulation ($timeframe)',
        locale: localeCode,
        idempotencyKey: idempotencyKey,
        healthContext: healthContext,
        simulateFailure: simulateFailure,
      );
      if (!mounted) return null;

      state = state.copyWith(
        lastFutureSelfResult: result,
        isSimulatingFutureSelf: false,
      );
      return result;
    } catch (e) {
      if (mounted) {
        _ref.read(appStateProvider.notifier).addCoins(cost);
        state = state.copyWith(isSimulatingFutureSelf: false);
      }
      rethrow;
    }
  }
}

final wellnessRepositoryProvider = Provider<WellnessRepository>(
  (_) => WellnessRepository(),
);

final wellnessProvider = StateNotifierProvider<WellnessNotifier, WellnessState>(
  (ref) => WellnessNotifier(ref.read(wellnessRepositoryProvider), ref),
);
