import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../domain/atelier_models.dart';

class CreationDetailSheet extends StatefulWidget {
  const CreationDetailSheet({
    super.key,
    required this.creation,
    required this.onRetry,
    required this.onTogglePrivate,
    required this.onDelete,
  });

  final AtelierCreation creation;
  final VoidCallback onRetry;
  final VoidCallback onTogglePrivate;
  final VoidCallback onDelete;

  @override
  State<CreationDetailSheet> createState() => _CreationDetailSheetState();
}

class _CreationDetailSheetState extends State<CreationDetailSheet> {
  int _rating = 0; // -1, 0, 1

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final c = widget.creation;
    final localizedTitle = strings.tr(c.templateTitle);

    return AppBottomSheetShell(
      title: localizedTitle,
      maxHeightFactor: 0.90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Artwork display with permanent watermark badge
          AppCard(
            height: 240,
            variant: AppCardVariant.subtle,
            padding: EdgeInsetsDirectional.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      c.type == 'v'
                          ? Icons.play_circle_filled_rounded
                          : Icons.auto_awesome_rounded,
                      size: 64,
                      color: colors.pr,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      localizedTitle,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                    Text(
                      '${strings.tr('آماده‌شده در تاریخ')} ${strings.tr(c.date)}',
                      style: AppTypography.caption(color: colors.mu),
                    ),
                  ],
                ),
                // Mandatory Watermark Badge
                PositionedDirectional(
                  bottom: 10,
                  start: 10,
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
                          c.watermarkText ?? strings.aiWatermarkBadge,
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
                if (c.anatomicalScore != null)
                  PositionedDirectional(
                    bottom: 10,
                    end: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.ok.withValues(alpha: 0.9),
                        borderRadius: AppRadius.rSm,
                      ),
                      child: Text(
                        strings.formatPercent(
                            (c.anatomicalScore! * 100).round()),
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Grid
          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  icon: Icon(Icons.download_rounded,
                      size: 15, color: colors.prt),
                  text: strings.atelDownload,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          strings.tr(
                              'فایل خروجی با بالاترین کیفیت در گالری ذخیره شد.'),
                          style: const TextStyle(fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  icon: Icon(Icons.replay_rounded, size: 15, color: colors.tx),
                  text: c.isFreeRetryUsed
                      ? strings.atelRebuild
                      : strings.atelFreeRebuild,
                  onPressed: () {
                    widget.onRetry();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  icon: Icon(
                    c.isPrivate
                        ? Icons.lock_outline_rounded
                        : Icons.link_rounded,
                    size: 15,
                    color: colors.tx,
                  ),
                  text: c.isPrivate
                      ? strings.atelPrivateLink
                      : strings.atelPublicLink,
                  onPressed: widget.onTogglePrivate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 15, color: colors.orColor),
                  text: strings.atelDeleteWork,
                  onPressed: () {
                    widget.onDelete();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Feedback row
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.atelRateQuality,
                  style: AppTypography.caption(color: colors.tx),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _rating == 1
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        size: 18,
                        color: _rating == 1 ? colors.ok : colors.mu,
                      ),
                      onPressed: () => setState(() => _rating = 1),
                    ),
                    IconButton(
                      icon: Icon(
                        _rating == -1
                            ? Icons.thumb_down_rounded
                            : Icons.thumb_down_outlined,
                        size: 18,
                        color: _rating == -1 ? colors.orColor : colors.mu,
                      ),
                      onPressed: () => setState(() => _rating = -1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
