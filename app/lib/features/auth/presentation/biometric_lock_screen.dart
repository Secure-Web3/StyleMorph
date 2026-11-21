import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_top_bar.dart';

/// Overlay screen displayed on app launch/resume for signed-in mobile users
/// when biometric app lock is enabled.
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptBiometric();
    });
  }

  Future<void> _promptBiometric() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      final service = ref.read(biometricServiceProvider);
      final strings = context.strings;
      final success = await service.authenticate(
        localizedReason: strings.setBiometricAuthReason,
      );
      if (success && mounted) {
        ref.read(biometricUnlockedProvider.notifier).state = true;
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
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

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AuthTopBar(isTransparent: false),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo
                        const Center(child: AppLogo(size: 64)),
                        const SizedBox(height: AppSpacing.xl),

                        // Fingerprint Icon Container
                        Center(
                          child: InkWell(
                            onTap: _promptBiometric,
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: colors.sf,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.pr.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.fingerprint_rounded,
                                size: 52,
                                color: colors.pr,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Title
                        Text(
                          strings.setBiometricLockedTitle,
                          style: AppTypography.headlineMedium(color: colors.tx),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Description
                        Text(
                          strings.setBiometricLockedDesc,
                          style: AppTypography.bodySmall(color: colors.mu),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Unlock Button
                        AppButton(
                          isFullWidth: true,
                          text: _isAuthenticating
                              ? null
                              : strings.setBiometricUnlockBtn,
                          icon: _isAuthenticating
                              ? null
                              : const Icon(Icons.lock_open_rounded, size: 16),
                          onPressed: _isAuthenticating
                              ? null
                              : _promptBiometric,
                          child: _isAuthenticating
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
                        const SizedBox(height: AppSpacing.md),

                        // Sign Out fallback
                        Center(
                          child: TextButton.icon(
                            onPressed: _signOut,
                            icon: Icon(
                              Icons.logout_rounded,
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
            const AuthFooter(isTransparent: false),
          ],
        ),
      ),
    );
  }
}
