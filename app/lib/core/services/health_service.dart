import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported wearable hardware & health platforms
enum WearableDeviceType {
  appleHealth('apple_health', 'Apple HealthKit', 'Apple Watch'),
  healthConnect('health_connect', 'Google Health Connect', 'Pixel / Android Health'),
  galaxyWatch('galaxy_watch', 'Samsung Health', 'Galaxy Watch 6 / 7'),
  miBand('mi_band', 'Xiaomi Fitness', 'Mi Smart Band 8 / 9');

  final String wireValue;
  final String displayName;
  final String hardwareModel;

  const WearableDeviceType(
    this.wireValue,
    this.displayName,
    this.hardwareModel,
  );
}

/// Granular privacy permission scopes that user can consent to individually
enum HealthPermissionScope {
  steps('steps', 'گام‌ها و مسافت پیاده‌روی'),
  sleep('sleep', 'مدت زمان و کیفیت خواب عمیق'),
  heartRate('heartRate', 'ضربان قلب استراحت و فعالیت'),
  weight('weight', 'وزن هوشمند و ترکیب بدنی'),
  calories('calories', 'کالری فعال سوزانده‌شده');

  final String wireValue;
  final String labelFa;

  const HealthPermissionScope(this.wireValue, this.labelFa);
}

@immutable
class HealthDnaSnapshot {
  final String? recordId;
  final WearableDeviceType sourceDevice;
  final Set<HealthPermissionScope> consentedScopes;
  final bool isConnected;
  final int? steps;
  final double? sleepHours;
  final double? deepSleepHours;
  final int? heartRateBpm;
  final double? weightKg;
  final int? activeCalories;
  final int energyReadinessScore;
  final String stylistBiometricHint;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final String? errorMessage;

  const HealthDnaSnapshot({
    this.recordId,
    this.sourceDevice = WearableDeviceType.galaxyWatch,
    this.consentedScopes = const {
      HealthPermissionScope.steps,
      HealthPermissionScope.sleep,
      HealthPermissionScope.heartRate,
      HealthPermissionScope.weight,
      HealthPermissionScope.calories,
    },
    this.isConnected = true,
    this.steps = 8450,
    this.sleepHours = 5.2,
    this.deepSleepHours = 1.1,
    this.heartRateBpm = 68,
    this.weightKg = 58.5,
    this.activeCalories = 380,
    this.energyReadinessScore = 68,
    this.stylistBiometricHint = 'low_sleep_comfort_mode',
    this.lastSyncedAt,
    this.isSyncing = false,
    this.errorMessage,
  });

  HealthDnaSnapshot copyWith({
    String? recordId,
    WearableDeviceType? sourceDevice,
    Set<HealthPermissionScope>? consentedScopes,
    bool? isConnected,
    int? steps,
    double? sleepHours,
    double? deepSleepHours,
    int? heartRateBpm,
    double? weightKg,
    int? activeCalories,
    int? energyReadinessScore,
    String? stylistBiometricHint,
    DateTime? lastSyncedAt,
    bool? isSyncing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HealthDnaSnapshot(
      recordId: recordId ?? this.recordId,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      consentedScopes: consentedScopes ?? this.consentedScopes,
      isConnected: isConnected ?? this.isConnected,
      steps: steps ?? this.steps,
      sleepHours: sleepHours ?? this.sleepHours,
      deepSleepHours: deepSleepHours ?? this.deepSleepHours,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      weightKg: weightKg ?? this.weightKg,
      activeCalories: activeCalories ?? this.activeCalories,
      energyReadinessScore: energyReadinessScore ?? this.energyReadinessScore,
      stylistBiometricHint: stylistBiometricHint ?? this.stylistBiometricHint,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Converts filtered snapshot into JSON context for AI Gateway requests
  Map<String, dynamic> toGatewayContext() {
    return <String, dynamic>{
      'sourceDevice': sourceDevice.wireValue,
      if (consentedScopes.contains(HealthPermissionScope.steps) && steps != null)
        'steps': steps,
      if (consentedScopes.contains(HealthPermissionScope.sleep) && sleepHours != null)
        'sleepHours': sleepHours,
      if (consentedScopes.contains(HealthPermissionScope.sleep) && deepSleepHours != null)
        'deepSleepHours': deepSleepHours,
      if (consentedScopes.contains(HealthPermissionScope.heartRate) && heartRateBpm != null)
        'heartRateBpm': heartRateBpm,
      if (consentedScopes.contains(HealthPermissionScope.weight) && weightKg != null)
        'weightTrendKg': weightKg,
      if (consentedScopes.contains(HealthPermissionScope.calories) && activeCalories != null)
        'activeCalories': activeCalories,
      'energyReadinessScore': energyReadinessScore,
      'stylistBiometricHint': stylistBiometricHint,
    };
  }
}

class HealthService extends StateNotifier<HealthDnaSnapshot> {
  static const MethodChannel _platformChannel =
      MethodChannel('com.stylemorph.app/health_bridge');

  HealthService()
      : super(HealthDnaSnapshot(
          lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 18)),
        ));

  /// Switches active wearable device source
  void setSourceDevice(WearableDeviceType device) {
    state = state.copyWith(sourceDevice: device);
    syncNow();
  }

  /// Toggles individual privacy consent scope (e.g. user denies weight or sleep)
  void toggleScopeConsent(HealthPermissionScope scope) {
    final updated = Set<HealthPermissionScope>.from(state.consentedScopes);
    if (updated.contains(scope)) {
      updated.remove(scope);
    } else {
      updated.add(scope);
    }
    state = state.copyWith(consentedScopes: updated);
    _recalculateReadiness();
  }

  void setScopeConsent(HealthPermissionScope scope, bool isGranted) {
    final updated = Set<HealthPermissionScope>.from(state.consentedScopes);
    if (isGranted) {
      updated.add(scope);
    } else {
      updated.remove(scope);
    }
    state = state.copyWith(consentedScopes: updated);
    _recalculateReadiness();
  }

  void toggleConnection(bool connected) {
    state = state.copyWith(isConnected: connected);
    if (connected) {
      syncNow();
    }
  }

  /// Performs live wearable sync with platform channel or simulated wearable device
  Future<void> syncNow({
    int? overrideSteps,
    double? overrideSleep,
    int? overrideHeartRate,
    double? overrideWeight,
  }) async {
    if (!state.isConnected) return;

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        // Attempt native platform channel if available on physical device
        try {
          final result = await _platformChannel.invokeMapMethod<String, dynamic>(
            'fetchLatestMetrics',
            <String, dynamic>{
              'sourceDevice': state.sourceDevice.wireValue,
              'consentedScopes':
                  state.consentedScopes.map((s) => s.wireValue).toList(),
            },
          );

          if (result != null) {
            _applySyncedData(
              steps: result['steps'] as int?,
              sleepHours: (result['sleepHours'] as num?)?.toDouble(),
              deepSleepHours: (result['deepSleepHours'] as num?)?.toDouble(),
              heartRateBpm: result['heartRateBpm'] as int?,
              weightKg: (result['weightKg'] as num?)?.toDouble(),
              activeCalories: result['activeCalories'] as int?,
            );
            return;
          }
        } catch (_) {
          // Fall through to realistic simulated engine if native channel is unhandled
        }
      }

      // Realistic Wearable Simulator for Windows / Web / Desktop / Test
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final baseSteps = overrideSteps ??
          switch (state.sourceDevice) {
            WearableDeviceType.appleHealth => 9200,
            WearableDeviceType.healthConnect => 8150,
            WearableDeviceType.galaxyWatch => 10600,
            WearableDeviceType.miBand => 7800,
          };

      final baseSleep = overrideSleep ??
          switch (state.sourceDevice) {
            WearableDeviceType.appleHealth => 5.1,
            WearableDeviceType.healthConnect => 7.2,
            WearableDeviceType.galaxyWatch => 4.9,
            WearableDeviceType.miBand => 6.5,
          };

      final baseHeartRate = overrideHeartRate ??
          switch (state.sourceDevice) {
            WearableDeviceType.appleHealth => 66,
            WearableDeviceType.healthConnect => 72,
            WearableDeviceType.galaxyWatch => 69,
            WearableDeviceType.miBand => 74,
          };

      final baseWeight = overrideWeight ?? 58.2;

      _applySyncedData(
        steps: baseSteps,
        sleepHours: baseSleep,
        deepSleepHours: (baseSleep * 0.22).clamp(0.5, 2.5),
        heartRateBpm: baseHeartRate,
        weightKg: baseWeight,
        activeCalories: (baseSteps * 0.042).round(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'خطا در همگام‌سازی اطلاعات گجت هوشمند.',
      );
    }
  }

  void _applySyncedData({
    int? steps,
    double? sleepHours,
    double? deepSleepHours,
    int? heartRateBpm,
    double? weightKg,
    int? activeCalories,
  }) {
    final scopes = state.consentedScopes;

    final effectiveSteps = scopes.contains(HealthPermissionScope.steps) ? steps : null;
    final effectiveSleep = scopes.contains(HealthPermissionScope.sleep) ? sleepHours : null;
    final effectiveDeepSleep = scopes.contains(HealthPermissionScope.sleep) ? deepSleepHours : null;
    final effectiveHeartRate = scopes.contains(HealthPermissionScope.heartRate) ? heartRateBpm : null;
    final effectiveWeight = scopes.contains(HealthPermissionScope.weight) ? weightKg : null;
    final effectiveCalories = scopes.contains(HealthPermissionScope.calories) ? activeCalories : null;

    final readiness = _computeReadiness(
      sleepHours: effectiveSleep,
      deepSleepHours: effectiveDeepSleep,
      steps: effectiveSteps,
      heartRateBpm: effectiveHeartRate,
    );

    final hint = _deriveHint(
      sleepHours: effectiveSleep,
      steps: effectiveSteps,
      readiness: readiness,
    );

    state = state.copyWith(
      steps: effectiveSteps,
      sleepHours: effectiveSleep,
      deepSleepHours: effectiveDeepSleep,
      heartRateBpm: effectiveHeartRate,
      weightKg: effectiveWeight,
      activeCalories: effectiveCalories,
      energyReadinessScore: readiness,
      stylistBiometricHint: hint,
      lastSyncedAt: DateTime.now(),
      isSyncing: false,
    );
  }

  void _recalculateReadiness() {
    _applySyncedData(
      steps: state.steps,
      sleepHours: state.sleepHours,
      deepSleepHours: state.deepSleepHours,
      heartRateBpm: state.heartRateBpm,
      weightKg: state.weightKg,
      activeCalories: state.activeCalories,
    );
  }

  int _computeReadiness({
    double? sleepHours,
    double? deepSleepHours,
    int? steps,
    int? heartRateBpm,
  }) {
    var weightedSum = 0.0;
    var totalWeight = 0.0;

    if (sleepHours != null) {
      totalWeight += 45;
      var s = 0.0;
      if (sleepHours >= 7 && sleepHours <= 9) {
        s = 40;
      } else if (sleepHours < 7) {
        s = (sleepHours / 7.0) * 40;
      } else {
        s = 40 - (sleepHours - 9) * 4;
      }
      if (deepSleepHours != null && deepSleepHours >= 1.5) {
        s += 5;
      }
      weightedSum += s.clamp(0, 45);
    }

    if (steps != null) {
      totalWeight += 35;
      var a = 0.0;
      if (steps >= 7000 && steps <= 12000) {
        a = 35;
      } else if (steps < 7000) {
        a = (steps / 7000.0) * 35;
      } else {
        a = 35 - ((steps - 12000) / 10000.0) * 7;
      }
      weightedSum += a.clamp(0, 35);
    }

    if (heartRateBpm != null) {
      totalWeight += 20;
      var h = 0.0;
      if (heartRateBpm >= 55 && heartRateBpm <= 75) {
        h = 20;
      } else if (heartRateBpm > 75 && heartRateBpm <= 90) {
        h = 15;
      } else if (heartRateBpm > 90) {
        h = 20 - (heartRateBpm - 75) * 0.4;
      } else {
        h = 16;
      }
      weightedSum += h.clamp(5, 20);
    }

    if (totalWeight == 0) return 70;
    return ((weightedSum / totalWeight) * 100).round().clamp(0, 100);
  }

  String _deriveHint({
    double? sleepHours,
    int? steps,
    required int readiness,
  }) {
    if (sleepHours != null && sleepHours < 5.5) {
      return 'low_sleep_comfort_mode';
    }
    if (steps != null && steps >= 10000) {
      return 'high_activity_breathable_mode';
    }
    if (readiness < 50) {
      return 'low_energy_relaxed_mode';
    }
    if (readiness >= 80 && (steps ?? 0) >= 7000) {
      return 'high_vitality_active_mode';
    }
    return 'balanced_lifestyle_mode';
  }
}

final healthServiceProvider =
    StateNotifierProvider<HealthService, HealthDnaSnapshot>((ref) {
  return HealthService();
});
