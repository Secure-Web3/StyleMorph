import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_modal.dart';

enum UnsavedChangesAction { saveAndContinue, discardAndLeave, stay }

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key});

  static Future<UnsavedChangesAction?> show(BuildContext context) {
    return AppModal.showAppDialog<UnsavedChangesAction>(
      context: context,
      barrierDismissible: true,
      child: const UnsavedChangesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon + Title Header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.wn.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 16,
                color: colors.wn,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                strings.unsavedChangesTitle,
                style: AppTypography.titleMedium(color: colors.tx),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Message
        Text(
          strings.unsavedChangesMessage,
          style: AppTypography.bodyMedium(
            color: colors.mu,
          ).copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Single Horizontal 3-Button Row ──────────────────────────────
        Row(
          children: [
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                height: 38,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    strings.unsavedChangesSaveAndContinue,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pop(UnsavedChangesAction.saveAndContinue),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.sm,
                height: 38,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    strings.unsavedChangesDiscardAndLeave,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pop(UnsavedChangesAction.discardAndLeave),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                height: 38,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    strings.unsavedChangesStay,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                onPressed: () =>
                    Navigator.of(context).pop(UnsavedChangesAction.stay),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
