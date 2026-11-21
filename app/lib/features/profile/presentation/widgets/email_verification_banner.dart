import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/email_verification_provider.dart';

/// A prominent, non-blocking email verification status banner displayed in the
/// user Profile / Identity area whenever the current user's email is not yet verified.
class EmailVerificationBanner extends ConsumerWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationState = ref.watch(emailVerificationProvider);

    // If verified, hide completely
    if (verificationState.isVerified) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final strings = context.strings;
    final notifier = ref.read(emailVerificationProvider.notifier);

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: AppCard(
        variant: AppCardVariant.surface,
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: colors.wn, width: 3),
            ),
          ),
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.wn.withValues(alpha: 0.12),
                      borderRadius: AppRadius.rSm,
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(
                      FontAwesomeIcons.envelopeOpenText,
                      size: 15,
                      color: colors.wn,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      strings.emailVerificationBannerTitle,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.emailVerificationBannerDesc,
                style: AppTypography.caption(
                  color: colors.mu,
                ).copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Resend Verification Link Button
                  AppButton(
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.outline,
                    height: 36,
                    text: verificationState.isResending
                        ? null
                        : (verificationState.cooldownSeconds > 0
                              ? strings.authEmailResendCooldown(
                                  verificationState.cooldownSeconds,
                                )
                              : strings.authEmailResendBtn),
                    onPressed:
                        (verificationState.cooldownSeconds > 0 ||
                            verificationState.isResending ||
                            verificationState.isChecking)
                        ? null
                        : () async {
                            final success = await notifier
                                .resendVerificationEmail();
                            if (!context.mounted) return;
                            if (success) {
                              AppFeedback.showSuccess(
                                context,
                                strings.authVerificationEmailSent,
                              );
                            } else {
                              AppFeedback.showError(
                                context,
                                strings.authErrGeneric,
                              );
                            }
                          },
                    child: verificationState.isResending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          )
                        : null,
                  ),

                  // Check Verification Status Button
                  AppButton(
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.primary,
                    height: 36,
                    text: verificationState.isChecking
                        ? null
                        : strings.authEmailCheckBtn,
                    onPressed:
                        (verificationState.isChecking ||
                            verificationState.isResending)
                        ? null
                        : () async {
                            final verified = await notifier
                                .reloadAndCheckVerification();
                            if (!context.mounted) return;
                            if (verified) {
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
