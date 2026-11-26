import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/totp_helper.dart';
import '../../../../core/services/two_factor_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/email_verification_provider.dart';
import 'about_actions.dart';

/// Modal dialog for configuring, switching, or disabling Two-Factor Authentication.
class TwoFactorSetupDialog extends ConsumerStatefulWidget {
  final TwoFactorConfig currentConfig;
  final String? initialTotpSecret;
  final String? uidOverride;

  const TwoFactorSetupDialog({
    super.key,
    required this.currentConfig,
    this.initialTotpSecret,
    this.uidOverride,
  });

  static Future<void> show(
    BuildContext context, {
    required TwoFactorConfig currentConfig,
    String? initialTotpSecret,
  }) {
    return AppModal.showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      child: TwoFactorSetupDialog(
        currentConfig: currentConfig,
        initialTotpSecret: initialTotpSecret,
      ),
    );
  }

  @override
  ConsumerState<TwoFactorSetupDialog> createState() =>
      _TwoFactorSetupDialogState();
}

class _TwoFactorSetupDialogState extends ConsumerState<TwoFactorSetupDialog> {
  late TwoFactorMethod _selectedMethod;
  late String _totpSecret;
  final TextEditingController _codeController = TextEditingController();

  bool _isBusy = false;
  bool _emailCodeSent = false;
  bool _isPreviewFallback = false;
  String? _previewCode;
  String? _errorText;
  bool _confirmingDisable = false;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.currentConfig.method;
    _totpSecret = widget.initialTotpSecret ?? TotpHelper.generateSecret();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _resolveUid() {
    if (widget.uidOverride != null && widget.uidOverride!.isNotEmpty) {
      return widget.uidOverride!;
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance.currentUser?.uid ?? '';
      }
    } catch (_) {}
    return '';
  }

  String _resolveEmail() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance.currentUser?.email ??
            'user@stylemorph.style';
      }
    } catch (_) {}
    return 'user@stylemorph.style';
  }

  Future<void> _copySecret(AppStrings strings) async {
    await Clipboard.setData(ClipboardData(text: _totpSecret));
    if (!mounted) return;
    AppFeedback.showSuccess(context, strings.twoFaKeyCopied);
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

  Future<void> _sendEmailCode(AppStrings strings) async {
    final uid = _resolveUid();
    if (uid.isEmpty) return;
    setState(() {
      _isBusy = true;
      _errorText = null;
    });
    try {
      final result = await ref
          .read(twoFactorServiceProvider)
          .requestEmailOtp(uid: uid, email: _resolveEmail());
      if (!mounted) return;
      setState(() {
        _emailCodeSent = result.sent || _emailCodeSent;
        _isPreviewFallback = result.isPreviewFallback;
        _previewCode = result.previewCode;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmAndActivate(AppStrings strings) async {
    final uid = _resolveUid();
    final code =
        TwoFactorService.extractSixDigitOtp(_codeController.text) ??
        _codeController.text.trim();
    if (uid.isEmpty || code.length != 6) {
      setState(() => _errorText = strings.twoFaInvalidCode);
      return;
    }

    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    try {
      final service = ref.read(twoFactorServiceProvider);
      final ok = _selectedMethod == TwoFactorMethod.totp
          ? await service.enrollTotp(uid: uid, secret: _totpSecret, code: code)
          : await service.enrollEmail(uid: uid, code: code);

      if (!mounted) return;
      if (ok) {
        ref.read(twoFactorSessionVerifiedProvider.notifier).state = true;
        Navigator.of(context).pop();
        AppFeedback.showSuccess(context, strings.twoFaEnabledSuccess);
      } else {
        setState(() => _errorText = strings.twoFaInvalidCode);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _disableTwoFactor(AppStrings strings) async {
    final uid = _resolveUid();
    if (uid.isEmpty) return;
    setState(() => _isBusy = true);
    try {
      await ref.read(twoFactorServiceProvider).disableTwoFactor(uid);
      if (!mounted) return;
      ref.read(twoFactorSessionVerifiedProvider.notifier).state = false;
      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, strings.twoFaDisabledSuccess);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  static const String _playStoreAuthUrl =
      'https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2';
  static const String _appStoreAuthUrl =
      'https://apps.apple.com/app/google-authenticator/id388497605';

  Widget _buildActiveStatusCard(AppColors colors, AppStrings strings) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.ok.withValues(alpha: 0.08),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: colors.ok.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.ok.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: FaIcon(
              FontAwesomeIcons.shieldHalved,
              size: 16,
              color: colors.ok,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.twoFaActiveCardTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.twoFaActiveCardDesc,
                  style: TextStyle(fontSize: 12, color: colors.mu, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatorLinks(AppColors colors, AppStrings strings) {
    final showAndroid =
        kIsWeb || defaultTargetPlatform == TargetPlatform.android;
    final showIos = kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.twoFaGetAppLabel,
          style: TextStyle(fontSize: 11, color: colors.mu),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (showAndroid)
              _StoreLinkChip(
                icon: FontAwesomeIcons.googlePlay,
                label: strings.twoFaGetOnGooglePlay,
                onTap: () => openExternalUrl(_playStoreAuthUrl),
              ),
            if (showIos)
              _StoreLinkChip(
                icon: FontAwesomeIcons.appStoreIos,
                label: strings.twoFaGetOnAppStore,
                onTap: () => openExternalUrl(_appStoreAuthUrl),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final isEmailVerified = ref.watch(emailVerificationProvider).isVerified;
    final email = _resolveEmail();
    final otpUri = TotpHelper.buildOtpAuthUri(
      accountLabel: email,
      secret: _totpSecret,
    );
    final isSelectedActive =
        widget.currentConfig.enabled &&
        _selectedMethod == widget.currentConfig.method;
    final isSwitchingMethod =
        widget.currentConfig.enabled &&
        _selectedMethod != widget.currentConfig.method;
    final primaryCtaLabel = isSwitchingMethod
        ? (_selectedMethod == TwoFactorMethod.email
              ? strings.twoFaSwitchToEmailBtn
              : strings.twoFaSwitchToTotpBtn)
        : strings.twoFaActivateBtn;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.shieldHalved,
                  size: 18,
                  color: colors.pr,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    strings.twoFaTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: colors.tx,
                    ),
                  ),
                ),
                AppBadge(
                  variant: widget.currentConfig.enabled
                      ? AppBadgeVariant.success
                      : AppBadgeVariant.standard,
                  child: Text(
                    widget.currentConfig.enabled
                        ? (widget.currentConfig.method == TwoFactorMethod.totp
                              ? strings.twoFaStatusActiveTotp
                              : strings.twoFaStatusActiveEmail)
                        : strings.twoFaStatusDisabled,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Method Selector
            Text(
              strings.twoFaChooseMethod,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.tx,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _MethodOptionCard(
                    title: strings.twoFaMethodTotp,
                    subtitle: strings.twoFaMethodTotpDesc,
                    icon: FontAwesomeIcons.qrcode,
                    selected: _selectedMethod == TwoFactorMethod.totp,
                    onTap: () => setState(() {
                      _selectedMethod = TwoFactorMethod.totp;
                      _errorText = null;
                      _confirmingDisable = false;
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MethodOptionCard(
                    title: strings.twoFaMethodEmail,
                    subtitle: strings.twoFaMethodEmailDesc,
                    icon: FontAwesomeIcons.envelopeOpenText,
                    selected: _selectedMethod == TwoFactorMethod.email,
                    onTap: () => setState(() {
                      _selectedMethod = TwoFactorMethod.email;
                      _errorText = null;
                      _confirmingDisable = false;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (isSelectedActive) ...[
              _buildActiveStatusCard(colors, strings),
              const SizedBox(height: AppSpacing.md),
              if (!_confirmingDisable)
                AppButton(
                  isFullWidth: true,
                  variant: AppButtonVariant.ghost,
                  text: strings.twoFaDisableBtn,
                  onPressed: _isBusy
                      ? null
                      : () => setState(() => _confirmingDisable = true),
                )
              else
                AppCard(
                  variant: AppCardVariant.subtle,
                  padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.twoFaDisableConfirm,
                        style: TextStyle(fontSize: 12, color: colors.tx),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              size: AppButtonSize.sm,
                              variant: AppButtonVariant.outline,
                              text: strings.dialogCancel,
                              onPressed: () =>
                                  setState(() => _confirmingDisable = false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: AppButton(
                              size: AppButtonSize.sm,
                              variant: AppButtonVariant.destructive,
                              text: strings.twoFaDisableBtn,
                              onPressed: _isBusy
                                  ? null
                                  : () => _disableTwoFactor(strings),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ] else ...[
              if (_selectedMethod == TwoFactorMethod.totp) ...[
                Text(
                  strings.twoFaScanQrHint,
                  style: TextStyle(fontSize: 11, color: colors.mu),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.rMd,
                      border: Border.all(color: colors.bd),
                    ),
                    child: QrImageView(
                      data: otpUri,
                      version: QrVersions.auto,
                      size: 164,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  variant: AppCardVariant.subtle,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _totpSecret,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.tx,
                          ),
                        ),
                      ),
                      AppButton(
                        size: AppButtonSize.sm,
                        variant: AppButtonVariant.outline,
                        text: strings.twoFaCopyKey,
                        onPressed: () => _copySecret(strings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildAuthenticatorLinks(colors, strings),
              ] else ...[
                if (!isEmailVerified)
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.wnb,
                      borderRadius: AppRadius.rMd,
                      border: Border.all(
                        color: colors.wn.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      strings.twoFaVerifyEmailFirst,
                      style: TextStyle(fontSize: 12, color: colors.tx),
                    ),
                  )
                else ...[
                  AppButton(
                    isFullWidth: true,
                    variant: AppButtonVariant.outline,
                    text: strings.twoFaSendEmailCodeBtn,
                    onPressed: _isBusy ? null : () => _sendEmailCode(strings),
                  ),
                  if (_isPreviewFallback) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _previewCode != null
                          ? '${strings.twoFaEmailPreviewNotice} ($_previewCode)'
                          : strings.twoFaEmailPreviewNotice,
                      style: TextStyle(fontSize: 11, color: colors.wn),
                    ),
                  ],
                ],
              ],

              if (_selectedMethod == TwoFactorMethod.totp ||
                  (isEmailVerified && _emailCodeSent)) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.twoFaEnterCodeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
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
                      icon: const FaIcon(FontAwesomeIcons.paste, size: 13),
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
                  text: primaryCtaLabel,
                  onPressed: _isBusy
                      ? null
                      : () => _confirmAndActivate(strings),
                ),
                if (isSwitchingMethod) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    strings.twoFaSwitchAutoReplaceNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: colors.mu),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreLinkChip extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  const _StoreLinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rMd,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: colors.sf,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: colors.bd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 12, color: colors.pr),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.tx,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rMd,
      child: Container(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? colors.pr.withValues(alpha: 0.08) : colors.sf,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: selected ? colors.pr : colors.bd,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(icon, size: 15, color: selected ? colors.pr : colors.mu),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.tx,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: colors.mu, height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
