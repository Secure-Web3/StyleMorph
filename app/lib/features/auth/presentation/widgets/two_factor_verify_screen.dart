import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/two_factor_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'auth_footer.dart';
import 'auth_top_bar.dart';

/// Full-screen 2FA verification gate shown after sign-in when `twoFactorEnabled == true`.
class TwoFactorVerifyScreen extends ConsumerStatefulWidget {
  final String uid;
  final String email;
  final TwoFactorConfig config;

  const TwoFactorVerifyScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.config,
  });

  @override
  ConsumerState<TwoFactorVerifyScreen> createState() =>
      _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends ConsumerState<TwoFactorVerifyScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isBusy = false;
  bool _isPreviewFallback = false;
  String? _previewCode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.config.method == TwoFactorMethod.email) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestEmailOtp();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestEmailOtp() async {
    setState(() {
      _isBusy = true;
      _errorText = null;
    });
    try {
      final result = await ref
          .read(twoFactorServiceProvider)
          .requestEmailOtp(uid: widget.uid, email: widget.email);
      if (!mounted) return;
      setState(() {
        _isPreviewFallback = result.isPreviewFallback;
        _previewCode = result.previewCode;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _verifyCode() {
    final strings = context.strings;
    final code = _codeController.text.trim();
    final ok = ref
        .read(twoFactorServiceProvider)
        .verifyLoginCode(config: widget.config, uid: widget.uid, code: code);
    if (ok) {
      ref.read(twoFactorSessionVerifiedProvider.notifier).state = true;
    } else {
      setState(() => _errorText = strings.twoFaInvalidCode);
    }
  }

  Future<void> _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
      ref.read(twoFactorSessionVerifiedProvider.notifier).state = false;
      ref.read(appStateProvider.notifier).logout();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final isEmailMethod = widget.config.method == TwoFactorMethod.email;

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: AppCard(
                      variant: AppCardVariant.subtle,
                      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: AppLogo(size: 56)),
                          const SizedBox(height: AppSpacing.md),
                          Center(
                            child: FaIcon(
                              FontAwesomeIcons.shieldHalved,
                              size: 32,
                              color: colors.pr,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            strings.twoFaLoginTitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineMedium(
                              color: colors.tx,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isEmailMethod
                                ? strings.twoFaLoginEmailDesc
                                : strings.twoFaLoginTotpDesc,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(color: colors.mu),
                          ),
                          if (_isPreviewFallback) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _previewCode != null
                                  ? '${strings.twoFaEmailPreviewNotice} ($_previewCode)'
                                  : strings.twoFaEmailPreviewNotice,
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(color: colors.wn),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _codeController,
                            placeholder: strings.twoFaCodePlaceholder,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            errorText: _errorText,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            isFullWidth: true,
                            variant: AppButtonVariant.primary,
                            text: strings.twoFaVerifyContinueBtn,
                            onPressed: _isBusy ? null : _verifyCode,
                          ),
                          if (isEmailMethod) ...[
                            const SizedBox(height: AppSpacing.sm),
                            AppButton(
                              isFullWidth: true,
                              variant: AppButtonVariant.outline,
                              text: strings.twoFaResendCodeBtn,
                              onPressed: _isBusy ? null : _requestEmailOtp,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            isFullWidth: true,
                            variant: AppButtonVariant.ghost,
                            text: strings.authBackOrSignOut,
                            onPressed: _signOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const AuthFooter(),
          ],
        ),
      ),
    );
  }
}
