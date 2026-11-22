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

        // Action 1: Save & Continue
        AppButton(
          variant: AppButtonVariant.primary,
          size: AppButtonSize.md,
          text: strings.unsavedChangesSaveAndContinue,
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.saveAndContinue),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Action 2: Discard & Leave
        AppButton(
          variant: AppButtonVariant.destructive,
          size: AppButtonSize.md,
          text: strings.unsavedChangesDiscardAndLeave,
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.discardAndLeave),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Action 3: Stay / Cancel
        AppButton(
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.md,
          text: strings.unsavedChangesStay,
          onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.stay),
        ),
      ],
    );
  }
}
