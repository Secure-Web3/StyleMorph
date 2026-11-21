import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import 'auth_provider.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_top_bar.dart';

/// Session override flag when user clicks "I've Verified My Email"
final emailVerifiedOverrideProvider = StateProvider<bool>((ref) => false);

/// Screen displayed when an email/password account is not yet verified.
/// Strictly gates access to the main app until user clicks the verification link.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final User user;

  const EmailVerificationScreen({super.key, required this.user});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      await widget.user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null) {
        try {
          await refreshedUser.getIdToken(true);
        } catch (_) {}
      }
      if (!mounted) return;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // 1. Immediately unlock AuthGate
        ref.read(emailVerifiedOverrideProvider.notifier).state = true;
        // 2. Guarantee session document is created and marked primary
        await ref.read(sessionServiceProvider).upsertSession();
        // 3. Load profile from Firestore
        await ref.read(appStateProvider.notifier).loadProfileFromFirestore();
        // 4. Force authStateChangesProvider refresh
        ref.invalidate(authStateChangesProvider);
      } else {
        AppFeedback.showError(context, context.strings.authEmailNotVerifiedYet);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, context.strings.authErrGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    if (_cooldownSeconds > 0) return;
    setState(() => _isResending = true);
    try {
      await widget.user.sendEmailVerification();
      if (!mounted) return;
      _startCooldown();
      AppFeedback.showSuccess(
        context,
        context.strings.authVerificationEmailSent,
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, context.strings.authErrGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(appStateProvider.notifier).logout();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final email = widget.user.email ?? '';

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AuthTopBar(isTransparent: false),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: AppCard(
                      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon & Brand Header
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colors.inb,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.mark_email_unread_outlined,
                                size: 32,
                                color: colors.inColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Title
                          Text(
                            strings.authEmailVerifyTitle,
                            style: AppTypography.headlineMedium(
                              color: colors.tx,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Description
                          Text(
                            strings.authEmailVerifyDesc,
                            style: AppTypography.bodySmall(color: colors.mu),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Email badge container
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.bd),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: colors.mu,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    email,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.tx,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Button 1: Check verification
                          AppButton(
                            isFullWidth: true,
                            text: _isChecking
                                ? null
                                : strings.authEmailCheckBtn,
                            onPressed: _isChecking ? null : _checkVerification,
                            child: _isChecking
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.prt,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Button 2: Resend email (with cooldown)
                          AppButton(
                            isFullWidth: true,
                            variant: AppButtonVariant.outline,
                            text: _cooldownSeconds > 0
                                ? strings.authEmailResendCooldown(
                                    _cooldownSeconds,
                                  )
                                : strings.authEmailResendBtn,
                            onPressed: (_isResending || _cooldownSeconds > 0)
                                ? null
                                : _resendVerification,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Button 3: Back / Sign Out
                          Center(
                            child: TextButton.icon(
                              onPressed: _signOut,
                              icon: Icon(
                                Icons.arrow_back,
                                size: 14,
                                color: colors.mu,
                              ),
                              label: Text(
                                strings.authBackOrSignOut,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  color: colors.mu,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const AuthFooter(isTransparent: false),
          ],
        ),
      ),
    );
  }
}
