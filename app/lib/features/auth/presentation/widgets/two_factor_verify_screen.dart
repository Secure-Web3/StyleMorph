import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/two_factor_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/brand_wordmark.dart';
import '../email_verification_provider.dart';
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
  bool _isEmailRecoveryMode = false;
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

  Future<void> _pasteOtpFromClipboard(AppStrings strings) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      final extracted = TwoFactorService.extractSixDigitOtp(data?.text ?? '');
      if (extracted == null) {
        setState(() => _errorText = strings.twoFaClipboardInvalid);
        return;
      }
      setState(() {
        _codeController.text = extracted;
        _codeController.selection = TextSelection.collapsed(
          offset: extracted.length,
        );
        _errorText = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = strings.twoFaClipboardInvalid);
    }
  }

  Future<void> _enterEmailRecoveryMode() async {
    setState(() {
      _isEmailRecoveryMode = true;
      _errorText = null;
      _codeController.clear();
    });
    await _requestEmailOtp();
  }

  void _exitEmailRecoveryMode() {
    setState(() {
      _isEmailRecoveryMode = false;
      _errorText = null;
      _codeController.clear();
    });
  }

  void _verifyCode() {
    final strings = context.strings;
    final code =
        TwoFactorService.extractSixDigitOtp(_codeController.text) ??
        _codeController.text.trim();
    final service = ref.read(twoFactorServiceProvider);
    final ok = _isEmailRecoveryMode
        ? service.verifyEmailOtp(uid: widget.uid, code: code)
        : service.verifyLoginCode(
            config: widget.config,
            uid: widget.uid,
            code: code,
          );
    if (ok) {
      ref.read(twoFactorSessionVerifiedProvider.notifier).state = true;
      if (_isEmailRecoveryMode) {
        AppFeedback.showSuccess(context, strings.twoFaRecoverySuccessNotice);
      }
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
    final isEmailVerified = ref.watch(emailVerificationProvider).isVerified;
    final isEmailMethod = widget.config.method == TwoFactorMethod.email;
    final showEmailInputMode = isEmailMethod || _isEmailRecoveryMode;
    final descriptionText = _isEmailRecoveryMode
        ? strings.twoFaRecoveryModeDesc
        : (isEmailMethod
              ? strings.twoFaLoginEmailDesc
              : strings.twoFaLoginTotpDesc);

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
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: BrandWordmark(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: colors.tx,
                            ),
                          ),
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: colors.tx,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            descriptionText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: colors.mu,
                            ),
                          ),
                          if (_isPreviewFallback && showEmailInputMode) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _previewCode != null
                                  ? '${strings.twoFaEmailPreviewNotice} ($_previewCode)'
                                  : strings.twoFaEmailPreviewNotice,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: colors.wn),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _codeController,
                                  placeholder: strings.twoFaCodePlaceholder,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  errorText: _errorText,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              AppButton(
                                size: AppButtonSize.md,
                                variant: AppButtonVariant.outline,
                                text: strings.twoFaPasteBtn,
                                icon: const FaIcon(
                                  FontAwesomeIcons.paste,
                                  size: 13,
                                ),
                                onPressed: _isBusy
                                    ? null
                                    : () => _pasteOtpFromClipboard(strings),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            isFullWidth: true,
                            variant: AppButtonVariant.primary,
                            text: strings.twoFaVerifyContinueBtn,
                            onPressed: _isBusy ? null : _verifyCode,
                          ),
                          if (showEmailInputMode) ...[
                            const SizedBox(height: AppSpacing.sm),
                            AppButton(
                              isFullWidth: true,
                              variant: AppButtonVariant.outline,
                              text: strings.twoFaResendCodeBtn,
                              onPressed: _isBusy ? null : _requestEmailOtp,
                            ),
                          ],
                          if (_isEmailRecoveryMode) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppButton(
                              isFullWidth: true,
                              variant: AppButtonVariant.ghost,
                              text: strings.twoFaUseTotpInsteadBtn,
                              onPressed: _isBusy
                                  ? null
                                  : _exitEmailRecoveryMode,
                            ),
                          ] else if (!isEmailMethod && isEmailVerified) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppButton(
                              isFullWidth: true,
                              variant: AppButtonVariant.ghost,
                              text: strings.twoFaLostAccessEmailBtn,
                              onPressed: _isBusy
                                  ? null
                                  : _enterEmailRecoveryMode,
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
