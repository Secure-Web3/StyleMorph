import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Controllers — not wired to Firebase yet (UI phase only)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    ref.read(authModeProvider.notifier).state = mode;
    ref.read(authPasswordVisibleProvider.notifier).state = false;
    _animController
      ..reset()
      ..forward();
  }

  void _handleLogin() {
    // UI-only: delegates to AppState mock login
    ref.read(appStateProvider.notifier).login();
  }

  void _handleSignup() {
    // UI-only: same mock login for now
    ref.read(appStateProvider.notifier).login();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mode = ref.watch(authModeProvider);
    final currentLang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top bar ───────────────────────────────────────────
                  _TopBar(
                    onBack: () => Navigator.of(context).maybePop(),
                    currentLang: currentLang,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Logo + branding ───────────────────────────────────
                  _BrandingHeader(colors: colors),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Form card (animated fade on mode switch) ──────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: mode == AuthMode.login
                        ? _LoginForm(
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onLogin: _handleLogin,
                            onSwitchToSignup: () =>
                                _switchMode(AuthMode.signup),
                          )
                        : _SignupForm(
                            fullNameController: _fullNameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onSignup: _handleSignup,
                            onSwitchToLogin: () =>
                                _switchMode(AuthMode.login),
                          ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Footer ────────────────────────────────────────────
                  Center(
                    child: Text(
                      '© 2026 StyleMorph',
                      style: AppTypography.caption(color: colors.mu),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final VoidCallback onBack;
  final AppLanguage currentLang;

  const _TopBar({required this.onBack, required this.currentLang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        _PillButton(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 13, color: colors.tx),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'بازگشت',
                style: AppTypography.inputLabel(color: colors.tx),
              ),
            ],
          ),
        ),

        // Right-side controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Language selector
            _LanguageDropdown(currentLang: currentLang),
            const SizedBox(width: AppSpacing.xs),

            // Theme palette cycle
            _CircleIconButton(
              onTap: () =>
                  ref.read(themeProvider.notifier).cyclePalette(),
              child: FaIcon(FontAwesomeIcons.palette,
                  size: 13, color: colors.tx),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Dark/light toggle
            _CircleIconButton(
              onTap: () =>
                  ref.read(themeProvider.notifier).toggleDark(),
              child: FaIcon(FontAwesomeIcons.circleHalfStroke,
                  size: 13, color: colors.tx),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PillButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rFull,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.sf,
          borderRadius: AppRadius.rFull,
          border: Border.all(color: colors.bd),
        ),
        child: child,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CircleIconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rFull,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.sf,
          shape: BoxShape.circle,
          border: Border.all(color: colors.bd),
        ),
        child: child,
      ),
    );
  }
}

class _LanguageDropdown extends ConsumerWidget {
  final AppLanguage currentLang;

  const _LanguageDropdown({required this.currentLang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rFull,
        border: Border.all(color: colors.bd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLang.code,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down_rounded,
              size: 16, color: colors.mu),
          dropdownColor: colors.sf,
          items: AppLanguage.supportedLanguages.map((l) {
            return DropdownMenuItem<String>(
              value: l.code,
              child: Text(
                l.nativeName,
                style: AppTypography.inputLabel(color: colors.tx),
              ),
            );
          }).toList(),
          onChanged: (code) {
            if (code != null) {
              ref.read(localeProvider.notifier).setLanguage(code);
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding Header (Logo + App name)
// ─────────────────────────────────────────────────────────────────────────────

class _BrandingHeader extends StatelessWidget {
  final AppColors colors;

  const _BrandingHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: 56),
        const SizedBox(height: AppSpacing.md),
        Text(
          'StyleMorph',
          style: AppTypography.headlineMedium(color: colors.tx),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'پرو مجازی و پیشنهاد استایل هوشمند',
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
// AppTextButton (inline text-style tap target)
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
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: AppTypography.inputLabel(
          color: isPrimary ? colors.pr : colors.mu,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Form
// ─────────────────────────────────────────────────────────────────────────────

class _LoginForm extends ConsumerWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onSwitchToSignup;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onSwitchToSignup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isPasswordVisible = ref.watch(authPasswordVisibleProvider);

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Form title ────────────────────────────────────────────────
          Text(
            'ورود به حساب کاربری',
            style: AppTypography.titleMedium(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'برای استفاده از پرو مجازی وارد شوید',
            style: AppTypography.bodySmall(color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Email field ───────────────────────────────────────────────
          AppTextField(
            label: 'ایمیل',
            placeholder: 'example@email.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined,
                size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Password field ────────────────────────────────────────────
          AppTextField(
            label: 'رمز عبور',
            placeholder: '••••••••',
            controller: passwordController,
            obscureText: !isPasswordVisible,
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

          // ── Primary login button ──────────────────────────────────────
          AppButton(
            isFullWidth: true,
            text: 'ورود  ·  Login',
            onPressed: onLogin,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Social divider ────────────────────────────────────────────
          const _LabelDivider(label: 'یا ورود با'),

          const SizedBox(height: AppSpacing.md),

          // ── Social login buttons ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  icon: FaIcon(FontAwesomeIcons.google,
                      size: 14, color: colors.tx),
                  text: 'Google',
                  onPressed: onLogin,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  icon: FaIcon(FontAwesomeIcons.apple,
                      size: 16, color: colors.tx),
                  text: 'Apple',
                  onPressed: onLogin,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Secondary text buttons ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AppTextButton(
                text: 'ثبت‌نام جدید',
                onTap: onSwitchToSignup,
                isPrimary: true,
              ),
              _AppTextButton(
                text: 'فراموشی رمز عبور؟',
                onTap: () {
                  // Feature Flag: forgot password — not yet wired
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signup Form
// ─────────────────────────────────────────────────────────────────────────────

class _SignupForm extends ConsumerWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSignup;
  final VoidCallback onSwitchToLogin;

  const _SignupForm({
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.onSignup,
    required this.onSwitchToLogin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isPasswordVisible = ref.watch(authPasswordVisibleProvider);

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Form title ────────────────────────────────────────────────
          Text(
            'ثبت‌نام در StyleMorph',
            style: AppTypography.titleMedium(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'یک حساب کاربری رایگان بسازید',
            style: AppTypography.bodySmall(color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Full name field ───────────────────────────────────────────
          AppTextField(
            label: 'نام و نام خانوادگی',
            placeholder: 'مثلاً: سارا احمدی',
            controller: fullNameController,
            keyboardType: TextInputType.name,
            prefix: Icon(Icons.person_outline_rounded,
                size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Email field ───────────────────────────────────────────────
          AppTextField(
            label: 'ایمیل',
            placeholder: 'example@email.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(Icons.email_outlined,
                size: 16, color: colors.mu),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Password field ────────────────────────────────────────────
          AppTextField(
            label: 'رمز عبور',
            placeholder: 'حداقل ۸ کاراکتر',
            controller: passwordController,
            obscureText: !isPasswordVisible,
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

          // ── Primary signup button ─────────────────────────────────────
          AppButton(
            isFullWidth: true,
            text: 'ثبت‌نام  ·  Sign Up',
            onPressed: onSignup,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Back to login ─────────────────────────────────────────────
          Center(
            child: _AppTextButton(
              text: 'از قبل حساب دارید؟  ورود',
              onTap: onSwitchToLogin,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}
