import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/referral_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'auth_provider.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_top_bar.dart';
import 'widgets/fallback_security_challenge.dart';
import 'widgets/turnstile_widget.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _forgotEmailController;
  late final TextEditingController _referralCodeController;

  final TurnstileController _turnstileController = TurnstileController();
  final FallbackChallengeController _fallbackController =
      FallbackChallengeController();
  String? _turnstileToken;
  bool _useSecurityFallback = false;

  int _consecutiveLoginFailures = 0;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(authFormProvider);
    _emailController = TextEditingController(text: initialState.email);
    _passwordController = TextEditingController(text: initialState.password);
    _confirmPasswordController = TextEditingController(
      text: initialState.confirmPassword,
    );
    _forgotEmailController = TextEditingController(
      text: initialState.forgotEmail,
    );
    _referralCodeController = TextEditingController(
      text: initialState.referralCode,
    );
    if (_referralCodeController.text.isEmpty) {
      ReferralService()
          .getPendingReferralCode()
          .then((code) {
            if (code != null && code.isNotEmpty && mounted) {
              _referralCodeController.text = code;
              ref.read(authFormProvider.notifier).setReferralCode(code);
            }
          })
          .catchError((_) {});
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    _referralCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onVerificationTabChanged(bool useFallback) {
    if (_useSecurityFallback == useFallback) return;
    _turnstileController.reset();
    _fallbackController.reset();
    setState(() {
      _turnstileToken = null;
      _useSecurityFallback = useFallback;
    });
  }

  void _switchMode(AuthMode mode) {
    _turnstileController.reset();
    _fallbackController.reset();
    _turnstileToken = null;
    _useSecurityFallback = false;
    ref.read(authFormProvider.notifier).setMode(mode);
    _animController
      ..reset()
      ..forward();
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSeconds = 30;
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_lockoutSeconds > 1) {
          _lockoutSeconds--;
        } else {
          _lockoutSeconds = 0;
          _consecutiveLoginFailures = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    if (_lockoutSeconds > 0) {
      AppFeedback.showError(
        context,
        context.strings.authLockoutCooldown(_lockoutSeconds),
      );
      return;
    }

    if (kIsWeb && (_turnstileToken == null || _turnstileToken!.isEmpty)) {
      AppFeedback.showError(context, context.strings.authTurnstileRequired);
      return;
    }

    final success = await ref.read(authFormProvider.notifier).login();
    if (!mounted) return;
    if (success) {
      _consecutiveLoginFailures = 0;
      _lockoutTimer?.cancel();
      _lockoutSeconds = 0;
      ref.read(appStateProvider.notifier).login();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _turnstileController.reset();
      _fallbackController.reset();
      setState(() {
        _turnstileToken = null;
        _consecutiveLoginFailures++;
      });

      if (_consecutiveLoginFailures >= 3) {
        _startLockoutTimer();
        AppFeedback.showError(
          context,
          context.strings.authLockoutCooldown(_lockoutSeconds),
        );
      } else {
        final code = ref.read(authFormProvider).errorCode;
        if (code != null) {
          AppFeedback.showError(
            context,
            context.strings.authErrorMessage(code),
          );
        }
      }
    }
  }

  Future<void> _handleSignup() async {
    if (kIsWeb && (_turnstileToken == null || _turnstileToken!.isEmpty)) {
      AppFeedback.showError(context, context.strings.authTurnstileRequired);
      return;
    }

    final success = await ref.read(authFormProvider.notifier).signup();
    if (!mounted) return;
    if (success) {
      ref.read(appStateProvider.notifier).login();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _turnstileController.reset();
      _fallbackController.reset();
      setState(() => _turnstileToken = null);
      final code = ref.read(authFormProvider).errorCode;
      if (code != null) {
        AppFeedback.showError(context, context.strings.authErrorMessage(code));
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref
        .read(authFormProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    if (success) {
      ref.read(appStateProvider.notifier).login();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final code = ref.read(authFormProvider).errorCode;
      if (code != null && code != 'google-cancelled') {
        AppFeedback.showError(context, context.strings.authErrorMessage(code));
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    final success = await ref.read(authFormProvider.notifier).signInWithApple();
    if (!mounted) return;
    if (success) {
      ref.read(appStateProvider.notifier).login();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final code = ref.read(authFormProvider).errorCode;
      if (code != null && code != 'apple-cancelled') {
        AppFeedback.showError(context, context.strings.authErrorMessage(code));
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final success = await ref
        .read(authFormProvider.notifier)
        .sendPasswordResetEmail();
    if (!mounted) return;
    if (success) {
      AppFeedback.showSuccess(context, context.strings.authResetEmailSent);
      _switchMode(AuthMode.login);
    } else {
      final code = ref.read(authFormProvider).errorCode;
      if (code != null) {
        AppFeedback.showError(context, context.strings.authErrorMessage(code));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    ref.watch(localeProvider);
    final colors = context.colors;
    final strings = context.strings;
    final formState = ref.watch(authFormProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Universal Top Header (Pinned at top) ─────────────
            const AuthTopBar(isTransparent: false),

            // ── 2. Scrollable Body ───────────────────────────────────
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Branding Header (Logo + App Title)
                        _BrandingHeader(colors: colors, strings: strings),

                        const SizedBox(height: AppSpacing.xl),

                        // Animated Form Switch
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildForm(formState, colors, strings),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 3. Universal Footer (Pinned at bottom) ───────────────
            const AuthFooter(isTransparent: false),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthFormState state, AppColors colors, AppStrings strings) {
    switch (state.mode) {
      case AuthMode.login:
        return _LoginForm(
          emailController: _emailController,
          passwordController: _passwordController,
          isPasswordVisible: state.isPasswordVisible,
          isSubmitting: state.isSubmitting,
          rememberMe: state.rememberMe,
          onRememberMeChanged: (val) =>
              ref.read(authFormProvider.notifier).setRememberMe(val),
          turnstileController: _turnstileController,
          fallbackController: _fallbackController,
          useSecurityFallback: _useSecurityFallback,
          onVerificationTabChanged: _onVerificationTabChanged,
          isTurnstileVerified:
              !kIsWeb ||
              (_turnstileToken != null && _turnstileToken!.isNotEmpty),
          lockoutSeconds: _lockoutSeconds,
          onTurnstileVerified: (token) {
            setState(() => _turnstileToken = token);
          },
          onTurnstileExpired: () => setState(() => _turnstileToken = null),
          onTurnstileError: () {
            setState(() {
              _turnstileToken = null;
              _useSecurityFallback = true;
            });
          },
          onEmailChanged: (val) =>
              ref.read(authFormProvider.notifier).setEmail(val),
          onPasswordChanged: (val) =>
              ref.read(authFormProvider.notifier).setPassword(val),
          onTogglePasswordVisibility: () =>
              ref.read(authFormProvider.notifier).togglePasswordVisibility(),
          onLogin: _handleLogin,
          onGoogleLogin: _handleGoogleSignIn,
          onAppleLogin: _handleAppleSignIn,
          onSwitchToSignup: () => _switchMode(AuthMode.signup),
          onForgotPassword: () => _switchMode(AuthMode.forgotPassword),
        );
      case AuthMode.signup:
        return _SignupForm(
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          referralCodeController: _referralCodeController,
          isPasswordVisible: state.isPasswordVisible,
          isConfirmPasswordVisible: state.isConfirmPasswordVisible,
          validationState: state.passwordValidation,
          passwordsMatch: state.passwordsMatch,
          isSubmitting: state.isSubmitting,
          turnstileController: _turnstileController,
          fallbackController: _fallbackController,
          useSecurityFallback: _useSecurityFallback,
          onVerificationTabChanged: _onVerificationTabChanged,
          isTurnstileVerified:
              !kIsWeb ||
              (_turnstileToken != null && _turnstileToken!.isNotEmpty),
          onTurnstileVerified: (token) {
            setState(() => _turnstileToken = token);
          },
          onTurnstileExpired: () => setState(() => _turnstileToken = null),
          onTurnstileError: () {
            setState(() {
              _turnstileToken = null;
              _useSecurityFallback = true;
            });
          },
          onEmailChanged: (val) =>
              ref.read(authFormProvider.notifier).setEmail(val),
          onPasswordChanged: (val) =>
              ref.read(authFormProvider.notifier).setPassword(val),
          onConfirmPasswordChanged: (val) =>
              ref.read(authFormProvider.notifier).setConfirmPassword(val),
          onReferralCodeChanged: (val) =>
              ref.read(authFormProvider.notifier).setReferralCode(val),
          onTogglePasswordVisibility: () =>
              ref.read(authFormProvider.notifier).togglePasswordVisibility(),
          onToggleConfirmPasswordVisibility: () => ref
              .read(authFormProvider.notifier)
              .toggleConfirmPasswordVisibility(),
          onSignup: _handleSignup,
          onGoogleSignup: _handleGoogleSignIn,
          onAppleSignup: _handleAppleSignIn,
          onSwitchToLogin: () => _switchMode(AuthMode.login),
        );
      case AuthMode.forgotPassword:
        return _ForgotPasswordForm(
          emailController: _forgotEmailController,
          isSubmitting: state.isSubmitting,
          onEmailChanged: (val) =>
              ref.read(authFormProvider.notifier).setForgotEmail(val),
          onResetPassword: _handleResetPassword,
          onBackToLogin: () => _switchMode(AuthMode.login),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding Header (Logo + Title)
// ─────────────────────────────────────────────────────────────────────────────

class _BrandingHeader extends StatelessWidget {
  final AppColors colors;
  final AppStrings strings;

  const _BrandingHeader({required this.colors, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: 52),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.appName,
          style: AppTypography.headlineMedium(color: colors.tx),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          strings.sub,
          style: AppTypography.bodySmall(color: colors.mu),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divider with label
// ─────────────────────────────────────────────────────────────────────────────

class _LabelDivider extends StatelessWidget {
  final String label;

  const _LabelDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: colors.bd, height: 1)),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          child: Text(label, style: AppTypography.caption(color: colors.mu)),
        ),
        Expanded(child: Divider(color: colors.bd, height: 1)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verification Method Selector Tab
// ─────────────────────────────────────────────────────────────────────────────

class _VerificationTabSelector extends StatelessWidget {
  final bool useSecurityFallback;
  final ValueChanged<bool> onTabSelected;

  const _VerificationTabSelector({
    required this.useSecurityFallback,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rFull,
        border: Border.all(color: colors.bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(
            title: strings.authVerificationCloudflare,
            isSelected: !useSecurityFallback,
            onTap: () => onTabSelected(false),
            colors: colors,
          ),
          _buildTab(
            title: strings.authVerificationMath,
            isSelected: useSecurityFallback,
            onTap: () => onTabSelected(true),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.pr : Colors.transparent,
          borderRadius: AppRadius.rFull,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colors.prt : colors.mu,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. LOGIN FORM
// ─────────────────────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isSubmitting;
  final bool isTurnstileVerified;
  final bool useSecurityFallback;
  final ValueChanged<bool>? onVerificationTabChanged;
  final int lockoutSeconds;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final TurnstileController? turnstileController;
  final FallbackChallengeController? fallbackController;
  final ValueChanged<String>? onTurnstileVerified;
  final VoidCallback? onTurnstileExpired;
  final VoidCallback? onTurnstileError;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onAppleLogin;
  final VoidCallback onSwitchToSignup;
  final VoidCallback onForgotPassword;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isSubmitting,
    this.isTurnstileVerified = true,
    this.useSecurityFallback = false,
    this.onVerificationTabChanged,
    this.lockoutSeconds = 0,
    this.rememberMe = true,
    required this.onRememberMeChanged,
    this.turnstileController,
    this.fallbackController,
    this.onTurnstileVerified,
    this.onTurnstileExpired,
    this.onTurnstileError,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onTogglePasswordVisibility,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onAppleLogin,
    required this.onSwitchToSignup,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final bool isLocked = lockoutSeconds > 0;
    final bool isButtonDisabled =
        isSubmitting || isLocked || !isTurnstileVerified;
    final String? buttonText = isSubmitting
        ? null
        : isLocked
        ? strings.authLockoutBtn(lockoutSeconds)
        : strings.authLoginBtn;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            strings.authLoginTitle,
            style: AppTypography.titleMedium(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.authLoginSubtitle,
            style: AppTypography.bodySmall(color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Email Field
          AppTextField(
            label: strings.authEmailLabel,
            placeholder: strings.authEmailHint,
            controller: emailController,
            onChanged: onEmailChanged,
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined, size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.md),

          // Password Field
          AppTextField(
            label: strings.authPasswordLabel,
            placeholder: strings.authPasswordHint,
            controller: passwordController,
            onChanged: onPasswordChanged,
            obscureText: !isPasswordVisible,
            prefix: Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: colors.mu,
            ),
            suffix: GestureDetector(
              onTap: onTogglePasswordVisibility,
              child: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: colors.mu,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Remember Me Checkbox (Luxury Editorial styled)
          AppCheckboxTile(
            label: strings.authRememberMe,
            value: rememberMe,
            onChanged: onRememberMeChanged,
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpacing.xxs,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Cloudflare Turnstile anti-bot verification or Smart Fallback (Web only)
          if (kIsWeb) ...[
            if (onVerificationTabChanged != null) ...[
              Center(
                child: _VerificationTabSelector(
                  useSecurityFallback: useSecurityFallback,
                  onTabSelected: onVerificationTabChanged!,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Center(
              child: useSecurityFallback
                  ? FallbackSecurityChallenge(
                      controller: fallbackController,
                      onVerified: onTurnstileVerified ?? (_) {},
                    )
                  : TurnstileWidget(
                      controller: turnstileController,
                      onVerified: onTurnstileVerified ?? (_) {},
                      onExpired: onTurnstileExpired,
                      onError: onTurnstileError,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Primary Login Button (With loading spinner and lockout countdown)
          AppButton(
            isFullWidth: true,
            text: buttonText,
            onPressed: isButtonDisabled ? null : onLogin,
            child: isSubmitting
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

          const SizedBox(height: AppSpacing.xl),

          // Social divider
          _LabelDivider(label: strings.authOrWith),

          const SizedBox(height: AppSpacing.md),

          // Social login buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  icon: FaIcon(
                    FontAwesomeIcons.google,
                    size: 14,
                    color: colors.tx,
                  ),
                  text: 'Google',
                  onPressed: isSubmitting ? null : onGoogleLogin,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Opacity(
                  opacity: 0.45,
                  child: AppButton(
                    variant: AppButtonVariant.secondary,
                    icon: FaIcon(
                      FontAwesomeIcons.apple,
                      size: 16,
                      color: colors.mu,
                    ),
                    text: 'Apple',
                    onPressed: null,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Secondary actions: Sign Up & Forgot Password
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            children: [
              AppTextButton(
                text: strings.authSwitchToSignup,
                onPressed: isSubmitting ? null : onSwitchToSignup,
                isPrimary: true,
              ),
              AppTextButton(
                text: strings.authForgotPassword,
                onPressed: isSubmitting ? null : onForgotPassword,
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SIGNUP FORM
// ─────────────────────────────────────────────────────────────────────────────

class _SignupForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController? referralCodeController;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final PasswordValidationState validationState;
  final bool passwordsMatch;
  final bool isSubmitting;
  final bool isTurnstileVerified;
  final bool useSecurityFallback;
  final ValueChanged<bool>? onVerificationTabChanged;
  final TurnstileController? turnstileController;
  final FallbackChallengeController? fallbackController;
  final ValueChanged<String>? onTurnstileVerified;
  final VoidCallback? onTurnstileExpired;
  final VoidCallback? onTurnstileError;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final ValueChanged<String>? onReferralCodeChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final VoidCallback onSignup;
  final VoidCallback onGoogleSignup;
  final VoidCallback onAppleSignup;
  final VoidCallback onSwitchToLogin;

  const _SignupForm({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    this.referralCodeController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.validationState,
    required this.passwordsMatch,
    required this.isSubmitting,
    this.isTurnstileVerified = true,
    this.useSecurityFallback = false,
    this.onVerificationTabChanged,
    this.turnstileController,
    this.fallbackController,
    this.onTurnstileVerified,
    this.onTurnstileExpired,
    this.onTurnstileError,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    this.onReferralCodeChanged,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.onSignup,
    required this.onGoogleSignup,
    required this.onAppleSignup,
    required this.onSwitchToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final isPasswordEmpty = passwordController.text.isEmpty;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            strings.authSignupTitle,
            style: AppTypography.titleMedium(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.authSignupSubtitle,
            style: AppTypography.bodySmall(color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 1. Email Field
          AppTextField(
            label: strings.authEmailLabel,
            placeholder: strings.authEmailHint,
            controller: emailController,
            onChanged: onEmailChanged,
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined, size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.md),

          // 2. Password Field
          AppTextField(
            label: strings.authPasswordLabel,
            placeholder: strings.authPasswordHint,
            controller: passwordController,
            onChanged: onPasswordChanged,
            obscureText: !isPasswordVisible,
            prefix: Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: colors.mu,
            ),
            suffix: GestureDetector(
              onTap: onTogglePasswordVisibility,
              child: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: colors.mu,
              ),
            ),
          ),

          // Real-Time Visual Password Strength Indicator
          if (!isPasswordEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _PasswordStrengthIndicator(
              state: validationState,
              strings: strings,
              colors: colors,
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // 3. Confirm Password Field
          AppTextField(
            label: strings.authConfirmPasswordLabel,
            placeholder: strings.authConfirmPasswordHint,
            controller: confirmPasswordController,
            onChanged: onConfirmPasswordChanged,
            obscureText: !isConfirmPasswordVisible,
            prefix: Icon(Icons.lock_reset_rounded, size: 16, color: colors.mu),
            suffix: GestureDetector(
              onTap: onToggleConfirmPasswordVisibility,
              child: Icon(
                isConfirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: colors.mu,
              ),
            ),
          ),

          // Password mismatch warning
          if (!passwordsMatch && confirmPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: colors.orColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    strings.authPwMismatch,
                    style: AppTypography.caption(color: colors.orColor),
                  ),
                ),
              ],
            ),
          ],

          // 4. Optional Referral Code Field
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: strings.authReferralCodeLabel,
            placeholder: strings.authReferralCodeHint,
            controller: referralCodeController,
            onChanged: onReferralCodeChanged,
            prefix: Icon(
              Icons.card_giftcard_rounded,
              size: 16,
              color: colors.mu,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Cloudflare Turnstile anti-bot verification or Smart Fallback (Web only)
          if (kIsWeb) ...[
            if (onVerificationTabChanged != null) ...[
              Center(
                child: _VerificationTabSelector(
                  useSecurityFallback: useSecurityFallback,
                  onTabSelected: onVerificationTabChanged!,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Center(
              child: useSecurityFallback
                  ? FallbackSecurityChallenge(
                      controller: fallbackController,
                      onVerified: onTurnstileVerified ?? (_) {},
                    )
                  : TurnstileWidget(
                      controller: turnstileController,
                      onVerified: onTurnstileVerified ?? (_) {},
                      onExpired: onTurnstileExpired,
                      onError: onTurnstileError,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Primary Signup Button (With loading spinner state)
          AppButton(
            isFullWidth: true,
            text: isSubmitting ? null : strings.authSignupBtn,
            onPressed: (isSubmitting || !isTurnstileVerified) ? null : onSignup,
            child: isSubmitting
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

          const SizedBox(height: AppSpacing.xl),

          // Social divider
          _LabelDivider(label: strings.authOrWith),

          const SizedBox(height: AppSpacing.md),

          // Social signup buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  icon: FaIcon(
                    FontAwesomeIcons.google,
                    size: 14,
                    color: colors.tx,
                  ),
                  text: 'Google',
                  onPressed: isSubmitting ? null : onGoogleSignup,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Opacity(
                  opacity: 0.45,
                  child: AppButton(
                    variant: AppButtonVariant.secondary,
                    icon: FaIcon(
                      FontAwesomeIcons.apple,
                      size: 16,
                      color: colors.mu,
                    ),
                    text: 'Apple',
                    onPressed: null,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Back to login toggle
          Center(
            child: AppTextButton(
              text: strings.authSwitchToLogin,
              onPressed: isSubmitting ? null : onSwitchToLogin,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real-Time Password Strength Indicator Widget
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthIndicator extends StatelessWidget {
  final PasswordValidationState state;
  final AppStrings strings;
  final AppColors colors;

  const _PasswordStrengthIndicator({
    required this.state,
    required this.strings,
    required this.colors,
  });

  Color _resolveBarColor(double fraction) {
    if (fraction <= 0.4) return colors.orColor;
    if (fraction <= 0.8) return colors.wn;
    return colors.ok;
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _resolveBarColor(state.strengthFraction);

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: colors.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with progress bar
          Row(
            children: [
              Text(
                strings.authPwStrengthLabel,
                style: AppTypography.caption(color: colors.mu),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.rFull,
                  child: LinearProgressIndicator(
                    value: state.strengthFraction,
                    backgroundColor: colors.bd,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Checklist rules
          _RequirementRow(
            label: strings.authPwRuleLen,
            isMet: state.hasMinLength,
            colors: colors,
          ),
          _RequirementRow(
            label: strings.authPwRuleUpper,
            isMet: state.hasUppercase,
            colors: colors,
          ),
          _RequirementRow(
            label: strings.authPwRuleLower,
            isMet: state.hasLowercase,
            colors: colors,
          ),
          _RequirementRow(
            label: strings.authPwRuleDigit,
            isMet: state.hasDigit,
            colors: colors,
          ),
          _RequirementRow(
            label: strings.authPwRuleSpecial,
            isMet: state.hasSpecialChar,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool isMet;
  final AppColors colors;

  const _RequirementRow({
    required this.label,
    required this.isMet,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 13,
            color: isMet ? colors.ok : colors.mu,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                color: isMet ? colors.tx : colors.mu,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. FORGOT PASSWORD FORM (NEW)
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotPasswordForm extends StatelessWidget {
  final TextEditingController emailController;
  final bool isSubmitting;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onResetPassword;
  final VoidCallback onBackToLogin;

  const _ForgotPasswordForm({
    required this.emailController,
    required this.isSubmitting,
    required this.onEmailChanged,
    required this.onResetPassword,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            strings.authForgotTitle,
            style: AppTypography.titleMedium(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.authForgotSubtitle,
            style: AppTypography.bodySmall(color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Single Email field
          AppTextField(
            label: strings.authEmailLabel,
            placeholder: strings.authEmailHint,
            controller: emailController,
            onChanged: onEmailChanged,
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined, size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Reset Password Button (With loading spinner state)
          AppButton(
            isFullWidth: true,
            text: isSubmitting ? null : strings.authForgotBtn,
            onPressed: isSubmitting ? null : onResetPassword,
            child: isSubmitting
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

          const SizedBox(height: AppSpacing.xl),

          // Back to Login text button
          Center(
            child: AppTextButton(
              text: strings.authBackToLogin,
              onPressed: isSubmitting ? null : onBackToLogin,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}
