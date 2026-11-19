import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../localization/app_strings.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_feedback.dart';
import 'app_modal.dart';
import '../../features/auth/presentation/email_verification_provider.dart';

/// Checks if the current user's email is verified.
/// If verified, returns `true`.
/// If not verified, shows a localized soft-gate prompt dialog and returns `false`.
bool checkEmailVerificationGate(BuildContext context, WidgetRef ref) {
  final isVerified = ref.read(emailVerificationProvider).isVerified;
  if (isVerified) {
    return true;
  }

  showEmailVerificationSoftGate(context, ref);
  return false;
}

/// Displays a soft-gate modal prompt guiding the user to verify their email.
Future<bool?> showEmailVerificationSoftGate(
  BuildContext context,
  WidgetRef ref,
) {
  final colors = context.colors;
  final strings = context.strings;

  return AppModal.showAppDialog<bool>(
    context: context,
    barrierDismissible: true,
    child: Consumer(
      builder: (context, ref, _) {
        final verificationState = ref.watch(emailVerificationProvider);
        final notifier = ref.read(emailVerificationProvider.notifier);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Shield Icon
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.wn.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  FontAwesomeIcons.shieldHalved,
                  size: 24,
                  color: colors.wn,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              strings.emailVerificationSoftGateTitle,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium(color: colors.tx),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              strings.emailVerificationSoftGateDesc,
              textAlign: TextAlign.center,
              style:
                  AppTypography.bodyMedium(color: colors.mu).copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action 1: Go to Profile & Identity
            AppButton(
              isFullWidth: true,
              variant: AppButtonVariant.primary,
              text: strings.emailVerificationGoToProfile,
              onPressed: () {
                Navigator.pop(context, false);
                ref
                    .read(appStateProvider.notifier)
                    .switchProfileTab('p-identity');
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Action 2: Check Verification Right Now
            AppButton(
              isFullWidth: true,
              variant: AppButtonVariant.outline,
              text: verificationState.isChecking
                  ? null
                  : strings.authEmailCheckBtn,
              onPressed: verificationState.isChecking
                  ? null
                  : () async {
                      final verified =
                          await notifier.reloadAndCheckVerification();
                      if (!context.mounted) return;
                      if (verified) {
                        Navigator.pop(context, true);
                        AppFeedback.showSuccess(
                          context,
                          strings.emailVerificationSuccessToast,
                        );
                      } else {
                        AppFeedback.showError(
                          context,
                          strings.authEmailNotVerifiedYet,
                        );
                      }
                    },
              child: verificationState.isChecking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Action 3: Close / Later
            AppButton(
              isFullWidth: true,
              variant: AppButtonVariant.ghost,
              text: strings.wellClose,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    ),
  );
}
