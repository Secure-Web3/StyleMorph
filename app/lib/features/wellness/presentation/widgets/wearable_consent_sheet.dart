import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/health_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_switch.dart';
import '../wellness_provider.dart';

class HealthConsentSheet extends ConsumerWidget {
  const HealthConsentSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final healthState = ref.watch(healthServiceProvider);
    final healthNotifier = ref.read(healthServiceProvider.notifier);
    final wellnessNotifier = ref.read(wellnessProvider.notifier);

    return AppBottomSheetShell(
      title: strings.wearableConsentTitle,
      bottomBar: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: AppButton(
          isFullWidth: true,
          text: strings.wearableSyncNow,
          icon: healthState.isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded, size: 16),
          onPressed: healthState.isSyncing
              ? null
              : () async {
                  await healthNotifier.syncNow();
                  final updated = ref.read(healthServiceProvider);
                  wellnessNotifier.applyWearableHealthSync(updated);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Device Selection Header
          Text(
            strings.wearableSourceDevice,
            style: AppTypography.cardTitle(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.wearablePermissionsSubtitle,
            style: AppTypography.caption(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.md),

          // Device Cards Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WearableDeviceType.values.map((device) {
              final isSelected = healthState.sourceDevice == device;
              return InkWell(
                onTap: () {
                  healthNotifier.setSourceDevice(device);
                  final updated = ref.read(healthServiceProvider);
                  wellnessNotifier.applyWearableHealthSync(updated);
                },
                borderRadius: AppRadius.rCard,
                child: Container(
                  width: (MediaQuery.sizeOf(context).width - 48) / 2,
                  padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.pr.withAlpha(20) : colors.sf,
                    borderRadius: AppRadius.rCard,
                    border: Border.all(
                      color: isSelected ? colors.pr : colors.bd,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        switch (device) {
                          WearableDeviceType.appleHealth => Icons.watch_rounded,
                          WearableDeviceType.healthConnect =>
                            Icons.health_and_safety_rounded,
                          WearableDeviceType.galaxyWatch =>
                            Icons.watch_outlined,
                          WearableDeviceType.miBand =>
                            Icons.fitness_center_rounded,
                        },
                        size: 20,
                        color: isSelected ? colors.pr : colors.mu,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? colors.pr : colors.tx,
                              ),
                            ),
                            Text(
                              device.hardwareModel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(color: colors.mu),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: colors.pr,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Master Connection Toggle
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            child: AppSwitchTile(
              label: strings.wearableCardTitle,
              subtitle: healthState.isConnected
                  ? strings.wearableStatusConnected
                  : strings.wearableStatusDisconnected,
              value: healthState.isConnected,
              onChanged: (val) {
                healthNotifier.toggleConnection(val);
                final updated = ref.read(healthServiceProvider);
                wellnessNotifier.applyWearableHealthSync(updated);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Granular Permission Toggles
          Text(
            'مجوزهای اشتراک‌گذاری داده‌ها',
            style: AppTypography.cardTitle(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),

          AppCard(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                AppSwitchTile(
                  label: strings.wearablePermSteps,
                  subtitle: healthState.steps != null
                      ? '${strings.formatNumber(healthState.steps!)} گام'
                      : 'غیرفعال',
                  value: healthState.consentedScopes.contains(
                    HealthPermissionScope.steps,
                  ),
                  onChanged: (val) => healthNotifier.setScopeConsent(
                    HealthPermissionScope.steps,
                    val,
                  ),
                ),
                Divider(height: 1, color: colors.bd),
                AppSwitchTile(
                  label: strings.wearablePermSleep,
                  subtitle: healthState.sleepHours != null
                      ? '${strings.formatNumber(healthState.sleepHours!)} ساعت'
                      : 'غیرفعال',
                  value: healthState.consentedScopes.contains(
                    HealthPermissionScope.sleep,
                  ),
                  onChanged: (val) => healthNotifier.setScopeConsent(
                    HealthPermissionScope.sleep,
                    val,
                  ),
                ),
                Divider(height: 1, color: colors.bd),
                AppSwitchTile(
                  label: strings.wearablePermHeart,
                  subtitle: healthState.heartRateBpm != null
                      ? '${strings.formatNumber(healthState.heartRateBpm!)} BPM'
                      : 'غیرفعال',
                  value: healthState.consentedScopes.contains(
                    HealthPermissionScope.heartRate,
                  ),
                  onChanged: (val) => healthNotifier.setScopeConsent(
                    HealthPermissionScope.heartRate,
                    val,
                  ),
                ),
                Divider(height: 1, color: colors.bd),
                AppSwitchTile(
                  label: strings.wearablePermWeight,
                  subtitle: healthState.weightKg != null
                      ? '${strings.formatNumber(healthState.weightKg!)} kg'
                      : 'غیرفعال',
                  value: healthState.consentedScopes.contains(
                    HealthPermissionScope.weight,
                  ),
                  onChanged: (val) => healthNotifier.setScopeConsent(
                    HealthPermissionScope.weight,
                    val,
                  ),
                ),
                Divider(height: 1, color: colors.bd),
                AppSwitchTile(
                  label: strings.wearablePermCalories,
                  subtitle: healthState.activeCalories != null
                      ? '${strings.formatNumber(healthState.activeCalories!)} kcal'
                      : 'غیرفعال',
                  value: healthState.consentedScopes.contains(
                    HealthPermissionScope.calories,
                  ),
                  onChanged: (val) => healthNotifier.setScopeConsent(
                    HealthPermissionScope.calories,
                    val,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Live Readiness Preview Badge
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.sf,
              borderRadius: AppRadius.rCard,
              border: Border.all(color: colors.bd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 20,
                      color: Color(0xFFD99A06),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      strings.wearableReadinessLabel,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                  ],
                ),
                AppBadge(
                  size: AppBadgeSize.md,
                  child: Text(
                    '${strings.formatNumber(healthState.energyReadinessScore)} / ۱۰۰',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
