import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/brand_wordmark.dart';
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - AppSpacing.xl * 2)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // App Logo & Brand Wordmark
                              const Center(child: AppLogo(size: 64)),
                              const SizedBox(height: AppSpacing.sm),
                              Center(
                                child: BrandWordmark(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: colors.tx,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Title & Subtitle
                              Text(
                                strings.setBiometricLockedTitle,
                                style: AppTypography.headlineMedium(
                                  color: colors.tx,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                strings.setBiometricLockedDesc,
                                style: AppTypography.bodySmall(
                                  color: colors.mu,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Sole Interactive Circular Fingerprint Trigger
                              Center(
                                child: Material(
                                  color: colors.pr.withValues(alpha: 0.08),
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    key: const Key('biometric_fingerprint_btn'),
                                    onTap: _isAuthenticating
                                        ? null
                                        : _promptBiometric,
                                    customBorder: const CircleBorder(),
                                    splashColor: colors.pr.withValues(
                                      alpha: 0.16,
                                    ),
                                    highlightColor: colors.pr.withValues(
                                      alpha: 0.08,
                                    ),
                                    child: Container(
                                      width: 92,
                                      height: 92,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.pr.withValues(
                                            alpha: 0.45,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _isAuthenticating
                                          ? SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: colors.pr,
                                              ),
                                            )
                                          : Icon(
                                              Icons.fingerprint_rounded,
                                              size: 52,
                                              color: colors.pr,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                strings.setBiometricTapToUnlock,
                                style: AppTypography.bodySmall(
                                  color: colors.mu,
                                ).copyWith(fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xl),

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
                  );
                },
              ),
            ),
            const AuthFooter(isTransparent: false),
          ],
        ),
      ),
    );
  }
}
