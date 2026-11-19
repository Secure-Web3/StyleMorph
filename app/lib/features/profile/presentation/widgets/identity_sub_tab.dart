import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/email_verification_provider.dart';
import 'change_email_dialog.dart';
import 'email_verification_banner.dart';

class IdentitySubTab extends ConsumerStatefulWidget {
  const IdentitySubTab({super.key});

  @override
  ConsumerState<IdentitySubTab> createState() => _IdentitySubTabState();
}

class _IdentitySubTabState extends ConsumerState<IdentitySubTab> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nickController;
  late final TextEditingController _nidController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _countryController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    final values = ref.read(appStateProvider).identityValues;
    String initialFirst = values['firstName'] ?? '';
    String initialLast = values['lastName'] ?? '';
    if (initialFirst.isEmpty &&
        initialLast.isEmpty &&
        user?.displayName != null &&
        user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) initialFirst = parts.first;
      if (parts.length > 1) initialLast = parts.sublist(1).join(' ');
    }
    final initialEmail = values['email']?.isNotEmpty == true
        ? values['email']!
        : (user?.email ?? '');

    _firstNameController = TextEditingController(text: initialFirst);
    _lastNameController = TextEditingController(text: initialLast);
    _nickController = TextEditingController(text: values['nick'] ?? '');
    _nidController = TextEditingController(text: values['nid'] ?? '');
    _mobileController = TextEditingController(text: values['mobile'] ?? '');
    _emailController = TextEditingController(text: initialEmail);
    _countryController = TextEditingController(text: values['country'] ?? '');
    _provinceController = TextEditingController(text: values['province'] ?? '');
    _cityController = TextEditingController(text: values['city'] ?? '');
    _addressController = TextEditingController(text: values['address'] ?? '');
    _zipController = TextEditingController(text: values['zip'] ?? '');
  }

  void _syncControllers(Map<String, String> values) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    void update(TextEditingController ctrl, String? val) {
      final text = val ?? '';
      if (ctrl.text != text) {
        ctrl.text = text;
      }
    }

    update(_firstNameController, values['firstName']);
    update(_lastNameController, values['lastName']);
    update(_nickController, values['nick']);
    update(_nidController, values['nid']);
    update(_mobileController, values['mobile']);
    update(_emailController, values['email'] ?? user?.email);
    update(_countryController, values['country']);
    update(_provinceController, values['province']);
    update(_cityController, values['city']);
    update(_addressController, values['address']);
    update(_zipController, values['zip']);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nickController.dispose();
    _nidController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _onFieldChanged(String key, String value) {
    ref.read(appStateProvider.notifier).updateIdentityField(key, value);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppState>(appStateProvider, (previous, next) {
      if (previous?.identityValues != next.identityValues &&
          !next.hasUnsavedProfileChanges) {
        _syncControllers(next.identityValues);
      }
    });

    final colors = context.colors;
    final strings = context.strings;
    final verificationState = ref.watch(emailVerificationProvider);
    final isEmailVerified = verificationState.isVerified;

    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}

    final bool isSocialUser = user?.providerData.any(
      (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
    ) ?? false;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Non-blocking Email Verification Status Banner
          const EmailVerificationBanner(),

          AppSectionHeader(
            faIcon: FontAwesomeIcons.userShield,
            title: strings.idHeader,
          ),
          const SizedBox(height: AppSpacing.md),

          // First Name & Last Name
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.idFirstName,
                  controller: _firstNameController,
                  onChanged: (val) => _onFieldChanged('firstName', val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: strings.idLastName,
                  controller: _lastNameController,
                  onChanged: (val) => _onFieldChanged('lastName', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Nickname & National ID
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.idNick,
                  controller: _nickController,
                  onChanged: (val) => _onFieldChanged('nick', val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: strings.idNationalId,
                  controller: _nidController,
                  onChanged: (val) => _onFieldChanged('nid', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Mobile Number with Disabled Verification Button & "Coming Soon" Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.idMobile,
                style: AppTypography.inputLabel(color: colors.tx),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _mobileController,
                      onChanged: (val) => _onFieldChanged('mobile', val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.outline,
                    onPressed: null,
                    text: strings.idVerifyMobile,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppBadge(
                    variant: AppBadgeVariant.standard,
                    size: AppBadgeSize.sm,
                    child: Text(
                      strings.commonComingSoon,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.mu,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Email with Smart Verification Status Indicator & Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.idEmail,
                style: AppTypography.inputLabel(color: colors.tx),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _emailController,
                      onChanged: (val) => _onFieldChanged('email', val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppBadge(
                    variant: isEmailVerified
                        ? AppBadgeVariant.success
                        : AppBadgeVariant.warning,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          isEmailVerified
                              ? FontAwesomeIcons.check
                              : FontAwesomeIcons.triangleExclamation,
                          size: 11,
                          color: isEmailVerified ? colors.ok : colors.wn,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          isEmailVerified
                              ? strings.idVerified
                              : strings.idUnverified,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: isSocialUser ? strings.idSocialEmailNote : '',
                    child: AppButton(
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.outline,
                      height: 34,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 10),
                      text: strings.idChangeEmail,
                      onPressed: isSocialUser
                          ? null
                          : () => ChangeEmailDialog.show(context, user: user),
                    ),
                  ),
                ],
              ),
              if (isSocialUser) ...[
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: colors.mu),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        strings.idSocialEmailNote,
                        style: AppTypography.caption(color: colors.mu),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isEmailVerified) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppButton(
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.primary,
                      height: 32,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 2,
                      ),
                      icon: verificationState.isResending
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.prt,
                              ),
                            )
                          : const FaIcon(FontAwesomeIcons.paperPlane, size: 10),
                      text: verificationState.cooldownSeconds > 0
                          ? '${strings.idVerifyEmail} (${verificationState.cooldownSeconds})'
                          : strings.idVerifyEmail,
                      onPressed: (verificationState.cooldownSeconds > 0 ||
                              verificationState.isResending ||
                              verificationState.isChecking)
                          ? null
                          : () async {
                              final success = await ref
                                  .read(emailVerificationProvider.notifier)
                                  .resendVerificationEmail();
                              if (!context.mounted) return;
                              if (success) {
                                AppFeedback.showSuccess(
                                  context,
                                  strings.authVerificationEmailSent,
                                );
                              }
                            },
                    ),
                    AppButton(
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.outline,
                      height: 32,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 2,
                      ),
                      icon: verificationState.isChecking
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.mu,
                              ),
                            )
                          : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 10),
                      text: strings.idCheckEmailStatus,
                      onPressed: (verificationState.isChecking ||
                              verificationState.isResending)
                          ? null
                          : () async {
                              final verified = await ref
                                  .read(emailVerificationProvider.notifier)
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
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Country / Province / City (3 columns)
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.idCountry,
                  controller: _countryController,
                  onChanged: (val) => _onFieldChanged('country', val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: strings.idProvince,
                  controller: _provinceController,
                  onChanged: (val) => _onFieldChanged('province', val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: strings.idCity,
                  controller: _cityController,
                  onChanged: (val) => _onFieldChanged('city', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Postal Address & Postal Code
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: strings.idAddress,
                  controller: _addressController,
                  maxLines: 2,
                  onChanged: (val) => _onFieldChanged('address', val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 1,
                child: AppTextField(
                  label: strings.idZip,
                  controller: _zipController,
                  onChanged: (val) => _onFieldChanged('zip', val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
