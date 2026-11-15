import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/health_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import 'wellness_provider.dart';
import 'widgets/wearable_consent_sheet.dart';
import 'widgets/wellness_modals.dart';

class WellnessTab extends ConsumerWidget {
  const WellnessTab({super.key});

  void _openModal(BuildContext context, Widget modal) {
    AppModal.showSheet(
      context: context,
      child: modal,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final state = ref.watch(wellnessProvider);
    final notifier = ref.read(wellnessProvider.notifier);
    final isPriv = state.isPrivateMode;

    return Column(
      children: [
        // --- Top Bar ---
        AppModuleHeader(
          icon: Icons.favorite_rounded,
          title: strings.wellnessTitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: isPriv
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                isActive: isPriv,
                tooltip: strings.wellPrivacyTooltip,
                onTap: () => notifier.togglePrivateMode(),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: Icons.tune_rounded,
                onTap: () => _openModal(context, const HealthDetailSheet()),
              ),
            ],
          ),
        ),

        // --- Main Scrollable Dashboard ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3 Score Ring Buttons
                Row(
                  children: [
                    Expanded(
                      child: _ScoreCardButton(
                        score: state.beautyScore.total,
                        label: strings.wellBeauty,
                        status: strings.tr(state.beautyScore.status),
                        ringColor: const Color(0xFFC2547A),
                        isPrivate: isPriv,
                        colors: colors,
                        onTap: () =>
                            _openModal(context, const BeautyDetailSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ScoreCardButton(
                        score: state.healthScore.total,
                        label: strings.wellHealth,
                        status: strings.tr(state.healthScore.status),
                        ringColor: const Color(0xFF4F7A5A),
                        isPrivate: isPriv,
                        colors: colors,
                        onTap: () =>
                            _openModal(context, const HealthDetailSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ScoreCardButton(
                        score: state.mindScore.total,
                        label: strings.wellMind,
                        status: strings.tr(state.mindScore.status),
                        ringColor: const Color(0xFF6B5FB5),
                        isPrivate: isPriv,
                        colors: colors,
                        onTap: () =>
                            _openModal(context, const MindDetailSheet()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Wearable & Health App Sync Banner / Card
                _WearableSyncCard(
                  colors: colors,
                  strings: strings,
                  health: ref.watch(healthServiceProvider),
                  onSync: () async {
                    await ref.read(healthServiceProvider.notifier).syncNow();
                    final updated = ref.read(healthServiceProvider);
                    notifier.applyWearableHealthSync(updated);
                  },
                  onManage: () =>
                      _openModal(context, const HealthConsentSheet()),
                ),
                const SizedBox(height: 12),

                // Today's Insight Card
                AppCard(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16,
                            color: Color(0xFFC2547A),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              strings.wellInsightTitle,
                              style: AppTypography.cardTitle(color: colors.tx),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.wellInsightBody,
                        style: AppTypography.bodySmall(color: colors.tx),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () =>
                            _openModal(context, const BeautyDetailSheet()),
                        child: Text(
                          strings.wellViewSkinRoutine,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.pr,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Today's Checklist Tasks
                AppCard(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              strings.wellTodayActions,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle(color: colors.tx),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.tasksProgress(
                              state.completedTasksCount,
                              state.tasks.length,
                            ),
                            style: AppTypography.caption(color: colors.mu),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...state.tasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () => notifier.toggleTask(task.id),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Icon(
                                  task.icon,
                                  size: 18,
                                  color: task.color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strings.tr(task.title),
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 11,
                                      decoration: task.isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color:
                                          task.isDone ? colors.mu : colors.tx,
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: task.isDone,
                                  activeColor: colors.pr,
                                  onChanged: (_) =>
                                      notifier.toggleTask(task.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 7-Day Trend Chart Box
                AppCard(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              strings.wellTrend7Days,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle(color: colors.tx),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.wellAutoUpdate,
                            style: AppTypography.caption(color: colors.mu),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Mock Sparkline Painter
                      SizedBox(
                        height: 70,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _WellnessChartPainter(
                            color: colors.pr,
                            isPrivate: isPriv,
                            hiddenLabel: strings.wellChartHiddenPrivacy,
                            textDirection: Directionality.of(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Metric segmented switcher
                      AppSegmentedControl<String>(
                        expand: true,
                        height: 34,
                        value: state.activeMetric,
                        onChanged: notifier.setActiveMetric,
                        items: [
                          AppSegmentItem(
                              value: 'w', label: strings.wellMetricWeight),
                          AppSegmentItem(
                              value: 's', label: strings.wellMetricSleep),
                          AppSegmentItem(
                              value: 'a', label: strings.wellMetricActivity),
                          AppSegmentItem(
                              value: 'm', label: strings.wellMetricMood),
                          AppSegmentItem(
                              value: 'h', label: strings.wellMetricHeart),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Button: Daily checkin
                AppButton(
                  isFullWidth: true,
                  icon: Icon(Icons.edit_calendar_rounded,
                      size: 16, color: colors.prt),
                  text: strings.wellDailyCheckinBtn,
                  onPressed: () =>
                      _openModal(context, const DailyCheckInSheet()),
                ),
                const SizedBox(height: AppSpacing.md),

                // Bottom 4 Quick Modules
                Row(
                  children: [
                    Expanded(
                      child: _BottomWellnessTile(
                        icon: Icons.spa_rounded,
                        label: strings.wellBeauty,
                        color: const Color(0xFFC2547A),
                        colors: colors,
                        onTap: () =>
                            _openModal(context, const BeautyDetailSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BottomWellnessTile(
                        icon: Icons.favorite_rounded,
                        label: strings.wellHealth,
                        color: const Color(0xFF4F7A5A),
                        colors: colors,
                        onTap: () =>
                            _openModal(context, const HealthDetailSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BottomWellnessTile(
                        icon: Icons.psychology_rounded,
                        label: strings.wellMind,
                        color: const Color(0xFF6B5FB5),
                        colors: colors,
                        onTap: () =>
                            _openModal(context, const MindDetailSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BottomWellnessTile(
                        icon: Icons.auto_awesome_rounded,
                        label: strings.wellFutureYou,
                        color: const Color(0xFFB7791F),
                        colors: colors,
                        onTap: () => _openModal(context, const FutureSelfSheet()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreCardButton extends StatelessWidget {
  const _ScoreCardButton({
    required this.score,
    required this.label,
    required this.status,
    required this.ringColor,
    required this.isPrivate,
    required this.colors,
    required this.onTap,
  });

  final int score;
  final String label;
  final String status;
  final Color ringColor;
  final bool isPrivate;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 3.5,
                  backgroundColor: colors.bd,
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
                if (isPrivate)
                  Icon(Icons.lock_rounded, size: 14, color: colors.mu)
                else
                  Text(
                    context.strings.formatNumber(score),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.tx,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.cardTitle(color: colors.tx),
          ),
          Text(
            status,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 9,
              color: ringColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomWellnessTile extends StatelessWidget {
  const _BottomWellnessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      height: 62,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessChartPainter extends CustomPainter {
  const _WellnessChartPainter({
    required this.color,
    required this.isPrivate,
    required this.hiddenLabel,
    required this.textDirection,
  });

  final Color color;
  final bool isPrivate;
  final String hiddenLabel;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (isPrivate) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: hiddenLabel,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.grey),
        ),
        textDirection: textDirection,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.55),
      Offset(size.width * 0.4, size.height * 0.60),
      Offset(size.width * 0.6, size.height * 0.40),
      Offset(size.width * 0.8, size.height * 0.35),
      Offset(size.width, size.height * 0.25),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WellnessChartPainter old) =>
      old.color != color ||
      old.isPrivate != isPrivate ||
      old.hiddenLabel != hiddenLabel ||
      old.textDirection != textDirection;
}

class _WearableSyncCard extends StatelessWidget {
  const _WearableSyncCard({
    required this.colors,
    required this.strings,
    required this.health,
    required this.onSync,
    required this.onManage,
  });

  final AppColors colors;
  final AppStrings strings;
  final HealthDnaSnapshot health;
  final VoidCallback onSync;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final isConnected = health.isConnected;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Device Name, Icon, and Connection Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF4F7A5A).withAlpha(30)
                      : colors.bd,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  switch (health.sourceDevice) {
                    WearableDeviceType.appleHealth => Icons.watch_rounded,
                    WearableDeviceType.healthConnect =>
                      Icons.health_and_safety_rounded,
                    WearableDeviceType.galaxyWatch => Icons.watch_outlined,
                    WearableDeviceType.miBand => Icons.fitness_center_rounded,
                  },
                  size: 18,
                  color: isConnected ? const Color(0xFF4F7A5A) : colors.mu,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            health.sourceDevice.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle(color: colors.tx),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppBadge(
                          size: AppBadgeSize.sm,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? const Color(0xFF22C55E)
                                      : colors.mu,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isConnected
                                    ? strings.wearableStatusConnected
                                    : strings.wearableStatusDisconnected,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isConnected
                                      ? const Color(0xFF15803D)
                                      : colors.mu,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${strings.wearableLastSynced} ${health.lastSyncedAt != null ? strings.formatNumber('${health.lastSyncedAt!.hour.toString().padLeft(2, '0')}:${health.lastSyncedAt!.minute.toString().padLeft(2, '0')}') : '---'}',
                      style: AppTypography.caption(color: colors.mu),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 3 Compact Telemetry Pills (Steps, Sleep, Readiness)
          Row(
            children: [
              Expanded(
                child: _TelemetryPill(
                  icon: Icons.directions_walk_rounded,
                  label: strings.wearablePermSteps,
                  value: health.steps != null
                      ? strings.formatNumber(health.steps!)
                      : '---',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TelemetryPill(
                  icon: Icons.bedtime_rounded,
                  label: strings.wearablePermSleep,
                  value: health.sleepHours != null
                      ? '${strings.formatNumber(health.sleepHours!)}h'
                      : '---',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TelemetryPill(
                  icon: Icons.bolt_rounded,
                  label: strings.wellHealth,
                  value: '${strings.formatNumber(health.energyReadinessScore)}%',
                  colors: colors,
                  valueColor: const Color(0xFFD99A06),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Buttons: Quick Sync & Manage
          AppButton(
            isFullWidth: true,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            text: strings.wearableSyncNow,
            icon: health.isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, size: 14),
            onPressed: health.isSyncing ? null : onSync,
          ),
          const SizedBox(height: 6),
          AppButton(
            isFullWidth: true,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
            text: strings.wearableManagePermissions,
            icon: const Icon(Icons.tune_rounded, size: 14),
            onPressed: onManage,
          ),
        ],
      ),
    );
  }
}

class _TelemetryPill extends StatelessWidget {
  const _TelemetryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpacing.xs,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: colors.bd, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: colors.mu),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 9,
                    color: colors.mu,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}
