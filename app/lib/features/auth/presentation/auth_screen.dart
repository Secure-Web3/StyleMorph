import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'auth_provider.dart';
import 'widgets/auth_top_bar.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  PasswordValidationState _passwordValidation = const PasswordValidationState();
  bool _passwordsMatch = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  void _onPasswordChanged() {
    final text = _passwordController.text;
    setState(() {
      _passwordValidation = PasswordValidationState.validate(text);
      if (_confirmPasswordController.text.isNotEmpty) {
        _passwordsMatch = text == _confirmPasswordController.text;
      } else {
        _passwordsMatch = true;
      }
    });
  }

  void _onConfirmPasswordChanged() {
    final confirm = _confirmPasswordController.text;
    setState(() {
      if (confirm.isEmpty) {
        _passwordsMatch = true;
      } else {
        _passwordsMatch = confirm == _passwordController.text;
      }
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    ref.read(authModeProvider.notifier).state = mode;
    ref.read(authPasswordVisibleProvider.notifier).state = false;
    ref.read(authConfirmPasswordVisibleProvider.notifier).state = false;
    _animController
      ..reset()
      ..forward();
  }

  void _handleLogin() {
    // UI-only phase: triggers mock login state
    ref.read(appStateProvider.notifier).login();
  }

  void _handleSignup() {
    // UI-only phase: triggers mock login state
    ref.read(appStateProvider.notifier).login();
  }

  void _handleResetPassword() {
    // UI-only phase: feedback toast or return to login
    _switchMode(AuthMode.login);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final mode = ref.watch(authModeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Universal Top Header (Theme, Palette, Language) ───────
            const AuthTopBar(isTransparent: false),

            // ── 2. Scrollable Body (Form card) ───────────────────────────
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
                        // App Logo & title
                        _BrandingHeader(colors: colors, strings: strings),

                        const SizedBox(height: AppSpacing.xl),

                        // Animated form switch
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildForm(mode, colors, strings),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 3. Pinned Footer (Always pinned at the bottom) ────────────
            _PinnedFooter(colors: colors, strings: strings),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthMode mode, AppColors colors, AppStrings strings) {
    switch (mode) {
      case AuthMode.login:
        return _LoginForm(
          emailController: _emailController,
          passwordController: _passwordController,
          onLogin: _handleLogin,
          onSwitchToSignup: () => _switchMode(AuthMode.signup),
          onForgotPassword: () => _switchMode(AuthMode.forgotPassword),
        );
      case AuthMode.signup:
        return _SignupForm(
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          validationState: _passwordValidation,
          passwordsMatch: _passwordsMatch,
          onSignup: _handleSignup,
          onSwitchToLogin: () => _switchMode(AuthMode.login),
        );
      case AuthMode.forgotPassword:
        return _ForgotPasswordForm(
          emailController: _forgotEmailController,
          onResetPassword: _handleResetPassword,
          onBackToLogin: () => _switchMode(AuthMode.login),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned Bottom Footer
// ─────────────────────────────────────────────────────────────────────────────

class _PinnedFooter extends StatelessWidget {
  final AppColors colors;
  final AppStrings strings;

  const _PinnedFooter({required this.colors, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(
          top: BorderSide(color: colors.bd.withValues(alpha: 0.5), width: 1.0),
        ),
      ),
      child: Center(
        child: Text(
          strings.authCopyrightYear,
          style: AppTypography.caption(color: colors.mu),
        ),
      ),
    );
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
          child: Text(
            label,
            style: AppTypography.caption(color: colors.mu),
          ),
        ),
        Expanded(child: Divider(color: colors.bd, height: 1)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Text Button
// ─────────────────────────────────────────────────────────────────────────────

class _AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AppTextButton({
    required this.text,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          text,
          style: AppTypography.inputLabel(
            color: isPrimary ? colors.pr : colors.mu,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. LOGIN FORM
// ─────────────────────────────────────────────────────────────────────────────

class _LoginForm extends ConsumerWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onSwitchToSignup;
  final VoidCallback onForgotPassword;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onSwitchToSignup,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final isPasswordVisible = ref.watch(authPasswordVisibleProvider);

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
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined, size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.md),

          // Password Field
          AppTextField(
            label: strings.authPasswordLabel,
            placeholder: strings.authPasswordHint,
            controller: passwordController,
            obscureText: !isPasswordVisible,
            prefix: Icon(Icons.lock_outline_rounded, size: 16, color: colors.mu),
            suffix: GestureDetector(
              onTap: () {
                ref.read(authPasswordVisibleProvider.notifier).state =
                    !isPasswordVisible;
              },
              child: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: colors.mu,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Primary Login Button (Localized text)
          AppButton(
            isFullWidth: true,
            text: strings.authLoginBtn,
            onPressed: onLogin,
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
                  onPressed: onLogin,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  icon: FaIcon(
                    FontAwesomeIcons.apple,
                    size: 16,
                    color: colors.tx,
                  ),
                  text: 'Apple',
                  onPressed: onLogin,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Secondary actions: Sign Up & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AppTextButton(
                text: strings.authSwitchToSignup,
                onTap: onSwitchToSignup,
                isPrimary: true,
              ),
              _AppTextButton(
                text: strings.authForgotPassword,
                onTap: onForgotPassword,
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

class _SignupForm extends ConsumerWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final PasswordValidationState validationState;
  final bool passwordsMatch;
  final VoidCallback onSignup;
  final VoidCallback onSwitchToLogin;

  const _SignupForm({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.validationState,
    required this.passwordsMatch,
    required this.onSignup,
    required this.onSwitchToLogin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final isPasswordVisible = ref.watch(authPasswordVisibleProvider);
    final isConfirmPasswordVisible =
        ref.watch(authConfirmPasswordVisibleProvider);

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
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined, size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.md),

          // 2. Password Field
          AppTextField(
            label: strings.authPasswordLabel,
            placeholder: strings.authPasswordHint,
            controller: passwordController,
            obscureText: !isPasswordVisible,
            prefix: Icon(Icons.lock_outline_rounded, size: 16, color: colors.mu),
            suffix: GestureDetector(
              onTap: () {
                ref.read(authPasswordVisibleProvider.notifier).state =
                    !isPasswordVisible;
              },
              child: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: colors.mu,
              ),
            ),
          ),

          // Visual Password Strength Indicator
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
            obscureText: !isConfirmPasswordVisible,
            prefix: Icon(Icons.lock_reset_rounded, size: 16, color: colors.mu),
            suffix: GestureDetector(
              onTap: () {
                ref.read(authConfirmPasswordVisibleProvider.notifier).state =
                    !isConfirmPasswordVisible;
              },
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
                Icon(Icons.error_outline_rounded,
                    size: 14, color: colors.orColor),
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

          const SizedBox(height: AppSpacing.xl),

          // Primary Signup Button
          AppButton(
            isFullWidth: true,
            text: strings.authSignupBtn,
            onPressed: (validationState.isValid && passwordsMatch)
                ? onSignup
                : onSignup, // Enabled for testing UX
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
                  onPressed: onSignup,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  icon: FaIcon(
                    FontAwesomeIcons.apple,
                    size: 16,
                    color: colors.tx,
                  ),
                  text: 'Apple',
                  onPressed: onSignup,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Back to login toggle
          Center(
            child: _AppTextButton(
              text: strings.authSwitchToLogin,
              onTap: onSwitchToLogin,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password Strength Indicator Widget
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
  final VoidCallback onResetPassword;
  final VoidCallback onBackToLogin;

  const _ForgotPasswordForm({
    required this.emailController,
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
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined, size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Reset Password Button
          AppButton(
            isFullWidth: true,
            text: strings.authForgotBtn,
            onPressed: onResetPassword,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Back to Login text button
          Center(
            child: _AppTextButton(
              text: strings.authBackToLogin,
              onTap: onBackToLogin,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}
