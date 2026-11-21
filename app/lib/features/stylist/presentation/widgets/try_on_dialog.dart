import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/email_verification_gate.dart';
import '../../domain/stylist_models.dart';
import '../stylist_provider.dart';

class TryOnDialog extends ConsumerStatefulWidget {
  const TryOnDialog({super.key, required this.outfit});

  final StylistOutfit outfit;

  @override
  ConsumerState<TryOnDialog> createState() => _TryOnDialogState();
}

class _TryOnDialogState extends ConsumerState<TryOnDialog> {
  bool _confirmedTerms = false;
  bool _inProgress = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ref.read(stylistProvider.notifier).resetTryOnStatus();
  }

  Future<void> _executeTryOn() async {
    if (!checkEmailVerificationGate(context, ref)) return;
    setState(() {
      _inProgress = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(stylistProvider.notifier)
          .runTryOnSimulation(widget.outfit);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _inProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final stylistState = ref.watch(stylistProvider);
    final appCoins = ref.watch(appStateProvider).coins;
    final selectedTier = stylistState.selectedTier;
    final status = stylistState.tryOnStatus;

    return AppBottomSheetShell(
      title: strings.styTryOnDialogTitle,
      maxHeightFactor: 0.90,
      bottomBar: status == TryOnStatus.completed
          ? AppButton(
              isFullWidth: true,
              text: strings.stySaveInAlbum,
              onPressed: () => Navigator.pop(context),
            )
          : AppButton(
              isFullWidth: true,
              text:
                  '${strings.tr('تأیید و اجرای پرو مجازی')} (${strings.coinsText(selectedTier.coinCost)})',
              onPressed: (_confirmedTerms && !_inProgress)
                  ? _executeTryOn
                  : null,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Outfit mini preview
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.pr.withValues(alpha: 0.12),
                    borderRadius: AppRadius.rLg,
                  ),
                  child: Icon(
                    Icons.checkroom_rounded,
                    color: colors.pr,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tr(widget.outfit.title),
                        style: AppTypography.cardTitle(color: colors.tx),
                      ),
                      Text(
                        '${strings.formatNumber(widget.outfit.items.length)} ${strings.tr('آیتم انتخابی از کمد')}',
                        style: AppTypography.caption(color: colors.mu),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (status == TryOnStatus.completed) ...[
            // Completed result with watermark badge
            AppCard(
              height: 220,
              variant: AppCardVariant.subtle,
              borderColor: colors.ok,
              padding: EdgeInsetsDirectional.zero,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: colors.pr.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.tr('پیش‌نمایش پرو روی آناتومی شما'),
                        style: AppTypography.cardTitle(color: colors.tx),
                      ),
                      Text(
                        strings.tr('تطابق بافت پارچه و چین‌خوردگی تأیید شد'),
                        style: AppTypography.caption(color: colors.ok),
                      ),
                      if (stylistState.lastTryOnResult != null) ...[
                        const SizedBox(height: 6),
                        AppBadge(
                          variant: AppBadgeVariant.success,
                          size: AppBadgeSize.sm,
                          child: Text(
                            '${strings.formatPercent(stylistState.lastTryOnResult!.anatomicalScorePercent)} · ${stylistState.lastTryOnResult!.watermarkText}',
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Mandatory AI Watermark Badge
                  PositionedDirectional(
                    bottom: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: AppRadius.rSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            strings.aiWatermarkBadge,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_inProgress) ...[
            // Step-by-step anatomical progress
            AppCard(
              variant: AppCardVariant.subtle,
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    status == TryOnStatus.holdingCoins
                        ? strings.tr('در حال نگه‌داشت امن سکه...')
                        : status == TryOnStatus.analyzingAnatomy
                        ? strings.tr('بررسی تطابق آناتومیک و اصلاح اسکلت...')
                        : strings.tr('پردازش بافت و مدل‌سازی سه‌بعدی لباس...'),
                    style: AppTypography.cardTitle(color: colors.tx),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.tr('سیستم خودترمیمی آناتومی فعال است'),
                    style: AppTypography.caption(color: colors.mu),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Tier Selector
            Text(
              strings.styQualityTierTitle,
              style: AppTypography.inputLabel(color: colors.tx),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...TryOnTier.values.map((tier) {
              final isSelected = selectedTier == tier;
              return AppCard(
                onTap: () =>
                    ref.read(stylistProvider.notifier).setSelectedTier(tier),
                margin: const EdgeInsetsDirectional.only(bottom: 6),
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                backgroundColor: isSelected
                    ? colors.pr.withValues(alpha: 0.08)
                    : colors.bg,
                borderColor: isSelected ? colors.pr : colors.bd,
                borderWidth: isSelected ? 1.5 : 1.0,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 16,
                      color: isSelected ? colors.pr : colors.mu,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.tr(tier.label),
                            style: AppTypography.cardTitle(color: colors.tx),
                          ),
                          Text(
                            strings.tr(tier.description),
                            style: AppTypography.caption(color: colors.mu),
                          ),
                        ],
                      ),
                    ),
                    AppBadge(
                      size: AppBadgeSize.sm,
                      child: Text(strings.coinsText(tier.coinCost)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),

            // Cost summary row
            AppCard(
              variant: AppCardVariant.subtle,
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.balanceText(appCoins),
                    style: AppTypography.caption(color: colors.mu),
                  ),
                  Text(
                    '${strings.tr('هزینه کسر')}: ${strings.coinsText(selectedTier.coinCost)}',
                    style: AppTypography.cardTitle(color: colors.tx),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Confirmation Checkbox
            AppCheckboxTile(
              label: strings.styTryOnTerms,
              value: _confirmedTerms,
              onChanged: (val) => setState(() => _confirmedTerms = val),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings.tr(_errorMessage!),
              style: AppTypography.bodySmall(color: colors.orColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
