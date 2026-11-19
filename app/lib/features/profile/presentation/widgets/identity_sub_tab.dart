import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/email_verification_provider.dart';
import '../../data/identity_validator.dart';
import '../../data/iso_location_data.dart';
import 'change_email_dialog.dart';
import 'email_verification_banner.dart';
import 'kyc_verification_section.dart';
import 'searchable_location_picker_sheet.dart';

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
  late final TextEditingController _dobController;
  late final TextEditingController _mobileSubscriberController;
  late final TextEditingController _emailController;
  late final TextEditingController _countryController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _zipController;

  IsoCountry _selectedCountry = IsoLocationData.defaultCountry;
  IsoProvince? _selectedProvince;
  IsoCountry _mobileCountry = IsoLocationData.defaultCountry;

  String? _nidError;
  String? _zipError;
  String? _mobileError;

  @override
  void initState() {
    super.initState();
    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
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

    // Resolve Country & Province from saved data
    final savedCountryCode = values['countryCode'] ?? '';
    final savedCountryName = values['country'] ?? '';
    _selectedCountry = IsoLocationData.findByCode(savedCountryCode) ??
        IsoLocationData.findByName(savedCountryName) ??
        IsoLocationData.defaultCountry;

    final savedProvinceName = values['province'] ?? '';
    final savedProvinceCode = values['provinceCode'] ?? '';
    for (final p in _selectedCountry.provinces) {
      if (p.code.toLowerCase() == savedProvinceCode.toLowerCase() ||
          p.nameEn.toLowerCase() == savedProvinceName.toLowerCase() ||
          p.nameFa == savedProvinceName ||
          p.nameTr == savedProvinceName ||
          p.nameAr == savedProvinceName) {
        _selectedProvince = p;
        break;
      }
    }

    // Resolve Mobile E.164
    final rawMobile = values['mobile'] ?? '';
    final parsedMobile = IdentityValidator.parseE164(rawMobile);
    _mobileCountry = parsedMobile.country;
    _mobileSubscriberController =
        TextEditingController(text: parsedMobile.subscriber);

    _firstNameController = TextEditingController(text: initialFirst);
    _lastNameController = TextEditingController(text: initialLast);
    _nickController = TextEditingController(text: values['nick'] ?? '');
    _nidController = TextEditingController(text: values['nid'] ?? '');
    _dobController = TextEditingController(text: values['dob'] ?? '');
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
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
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
    update(_dobController, values['dob']);
    update(_emailController, values['email'] ?? user?.email);
    update(_countryController, values['country']);
    update(_provinceController, values['province']);
    update(_cityController, values['city']);
    update(_addressController, values['address']);
    update(_zipController, values['zip']);

    final rawMobile = values['mobile'] ?? '';
    final parsed = IdentityValidator.parseE164(rawMobile);
    if (_mobileCountry.code != parsed.country.code) {
      _mobileCountry = parsed.country;
    }
    update(_mobileSubscriberController, parsed.subscriber);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nickController.dispose();
    _nidController.dispose();
    _dobController.dispose();
    _mobileSubscriberController.dispose();
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

  void _validateNid(String? val, AppStrings strings) {
    if (val == null || val.trim().isEmpty) {
      _nidError = null;
      return;
    }
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR') {
      _nidError = IdentityValidator.isValidIranianNationalId(val)
          ? null
          : strings.idErrInvalidNidIran;
    } else if (code == 'TR') {
      _nidError = IdentityValidator.isValidTurkishKimlik(val)
          ? null
          : strings.idErrInvalidNidTurkey;
    } else {
      _nidError = IdentityValidator.isValidInternationalNationalId(val)
          ? null
          : strings.idErrInvalidNidInternational;
    }
  }

  void _validateZip(String? val, AppStrings strings) {
    if (val == null || val.trim().isEmpty) {
      _zipError = null;
      return;
    }
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR') {
      _zipError = IdentityValidator.isValidIranianPostalCode(val)
          ? null
          : strings.idErrInvalidZipIran;
    } else if (code == 'TR') {
      _zipError = IdentityValidator.isValidTurkishPostalCode(val)
          ? null
          : strings.idErrInvalidZipTurkey;
    } else {
      _zipError = IdentityValidator.isValidInternationalPostalCode(val)
          ? null
          : strings.idErrInvalidZipInternational;
    }
  }

  void _validateMobile(String? val, AppStrings strings) {
    if (val == null || val.trim().isEmpty) {
      _mobileError = null;
      return;
    }
    _mobileError = IdentityValidator.isValidSubscriber(val, _mobileCountry)
        ? null
        : strings.idErrInvalidMobile;
  }

  Future<void> _pickCountry() async {
    final picked = await SearchableLocationPickerSheet.showCountryPicker(
      context,
      selectedCode: _selectedCountry.code,
    );
    if (!mounted) return;
    if (picked != null) {
      final locale = Localizations.localeOf(context).languageCode;
      final strings = context.strings;
      final localizedName = picked.localizedName(locale);
      setState(() {
        _selectedCountry = picked;
        _selectedProvince = null;
        _countryController.text = localizedName;
        _provinceController.text = '';
        _cityController.text = '';

        // Sync mobile dial code with selected country
        _mobileCountry = picked;
        final currentSub = _mobileSubscriberController.text.trim();
        if (currentSub.isNotEmpty) {
          final canonical = IdentityValidator.formatE164(
            dialCode: _mobileCountry.dialCode,
            subscriber: currentSub,
          );
          _onFieldChanged('mobile', canonical);
        }

        _validateNid(_nidController.text, strings);
        _validateZip(_zipController.text, strings);
        _validateMobile(_mobileSubscriberController.text, strings);
      });

      _onFieldChanged('country', localizedName);
      _onFieldChanged('countryCode', picked.code);
      _onFieldChanged('province', '');
      _onFieldChanged('provinceCode', '');
      _onFieldChanged('city', '');
    }
  }

  Future<void> _pickProvince() async {
    final picked = await SearchableLocationPickerSheet.showProvincePicker(
      context,
      country: _selectedCountry,
      selectedCode: _selectedProvince?.code,
    );
    if (!mounted) return;
    if (picked != null) {
      final locale = Localizations.localeOf(context).languageCode;
      final localizedName = picked.localizedName(locale);
      setState(() {
        _selectedProvince = picked;
        _provinceController.text = localizedName;
        _cityController.text = '';
      });
      _onFieldChanged('province', localizedName);
      _onFieldChanged('provinceCode', picked.code);
      _onFieldChanged('city', '');
    }
  }

  Future<void> _pickCity() async {
    if (_selectedProvince == null) {
      if (_selectedCountry.provinces.isNotEmpty) {
        await _pickProvince();
        if (_selectedProvince == null) return;
      } else {
        // Country has no predefined provinces
        final defaultProv = IsoProvince(
          code: _selectedCountry.code,
          nameEn: _selectedCountry.nameEn,
          nameFa: _selectedCountry.nameFa,
          nameAr: _selectedCountry.nameAr,
          nameTr: _selectedCountry.nameTr,
        );
        _selectedProvince = defaultProv;
      }
    }

    if (!mounted) return;
    final picked = await SearchableLocationPickerSheet.showCityPicker(
      context,
      province: _selectedProvince!,
      currentCity: _cityController.text,
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _cityController.text = picked;
      });
      _onFieldChanged('city', picked);
    }
  }

  Future<void> _pickDialCode() async {
    final picked = await SearchableLocationPickerSheet.showDialCodePicker(
      context,
      selectedDialCode: _mobileCountry.dialCode,
    );
    if (!mounted) return;
    if (picked != null) {
      final strings = context.strings;
      setState(() {
        _mobileCountry = picked;
        final currentSub = _mobileSubscriberController.text.trim();
        if (currentSub.isNotEmpty) {
          final canonical = IdentityValidator.formatE164(
            dialCode: _mobileCountry.dialCode,
            subscriber: currentSub,
          );
          _onFieldChanged('mobile', canonical);
        }
        _validateMobile(_mobileSubscriberController.text, strings);
      });
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year - 13, now.month, now.day);
    final firstDate = DateTime(now.year - 120, 1, 1);

    DateTime initialDate = DateTime(now.year - 20, now.month, now.day);
    final currentText = _dobController.text.trim();
    if (currentText.isNotEmpty) {
      final parsed = DateTime.tryParse(currentText);
      if (parsed != null &&
          !parsed.isAfter(lastDate) &&
          !parsed.isBefore(firstDate)) {
        initialDate = parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final colors = context.colors;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: colors.pr,
                    onPrimary: colors.prt,
                    surface: colors.sf,
                    onSurface: colors.tx,
                  )
                : ColorScheme.light(
                    primary: colors.pr,
                    onPrimary: colors.prt,
                    surface: colors.sf,
                    onSurface: colors.tx,
                  ),
            dialogBackgroundColor: colors.sf,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      final isoString =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _dobController.text = isoString;
      _onFieldChanged('dob', isoString);
    }
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

          // First Name & Last Name (Completely Unrestricted in Script/Language)
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.idFirstName,
                  placeholder: strings.idFirstNamePlaceholder,
                  controller: _firstNameController,
                  onChanged: (val) => _onFieldChanged('firstName', val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: strings.idLastName,
                  placeholder: strings.idLastNamePlaceholder,
                  controller: _lastNameController,
                  onChanged: (val) => _onFieldChanged('lastName', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Nickname / Handle (Unrestricted) & National ID (Country-Aware Validated)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.idNick,
                  placeholder: strings.idNickPlaceholder,
                  controller: _nickController,
                  onChanged: (val) => _onFieldChanged('nick', val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: strings.idNationalId,
                  placeholder: strings.idNationalIdPlaceholder,
                  controller: _nidController,
                  errorText: _nidError,
                  keyboardType: TextInputType.text,
                  maxLength: 25,
                  onChanged: (val) {
                    _onFieldChanged('nid', val);
                    setState(() {
                      _validateNid(val, strings);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Date of Birth
          AppTextField(
            label: strings.idDob,
            labelTrailing: Text(
              strings.idDobAgeRequirement,
              style: TextStyle(
                fontSize: 10,
                color: colors.mu,
              ),
            ),
            placeholder: strings.idDobPlaceholder,
            controller: _dobController,
            readOnly: true,
            onTap: _pickDateOfBirth,
            suffix: IconButton(
              icon: FaIcon(
                FontAwesomeIcons.calendar,
                size: 14,
                color: colors.mu,
              ),
              onPressed: _pickDateOfBirth,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Structured International E.164 Mobile Input + Coming Soon Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.idMobile,
                style: AppTypography.inputLabel(color: colors.tx),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flag + Dial Code Picker Button
                  InkWell(
                    onTap: _pickDialCode,
                    borderRadius: AppRadius.rLg,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: AppRadius.rLg,
                        border: Border.all(color: colors.bd, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _mobileCountry.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _mobileCountry.dialCode,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.tx,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down,
                              size: 16, color: colors.mu),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),

                  // Numeric Subscriber Input
                  Expanded(
                    child: AppTextField(
                      placeholder: strings.idMobilePlaceholder,
                      keyboardType: TextInputType.phone,
                      controller: _mobileSubscriberController,
                      errorText: _mobileError,
                      onChanged: (val) {
                        final canonical = IdentityValidator.formatE164(
                          dialCode: _mobileCountry.dialCode,
                          subscriber: val,
                        );
                        _onFieldChanged('mobile', canonical);
                        setState(() {
                          _validateMobile(val, strings);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Mobile Verification Button (Disabled + Coming Soon)
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
                      placeholder: strings.idEmailPlaceholder,
                      keyboardType: TextInputType.emailAddress,
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

          // Cascading, Searchable Location Selectors (Country -> Province -> City)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country Selector
              Expanded(
                child: AppTextField(
                  label: strings.idCountry,
                  placeholder: strings.idCountryPlaceholder,
                  controller: _countryController,
                  readOnly: true,
                  prefix: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  suffix: const Icon(Icons.arrow_drop_down, size: 20),
                  onTap: _pickCountry,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Province / State Selector
              Expanded(
                child: AppTextField(
                  label: strings.idProvince,
                  placeholder: strings.idProvincePlaceholder,
                  controller: _provinceController,
                  readOnly: true,
                  suffix: const Icon(Icons.arrow_drop_down, size: 20),
                  onTap: _pickProvince,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // City Selector
              Expanded(
                child: AppTextField(
                  label: strings.idCity,
                  placeholder: strings.idCityPlaceholder,
                  controller: _cityController,
                  readOnly: true,
                  suffix: const Icon(Icons.arrow_drop_down, size: 20),
                  onTap: _pickCity,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Postal Address & Postal / ZIP Code (Country-Aware Validated)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: strings.idAddress,
                  placeholder: strings.idAddressPlaceholder,
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
                  placeholder: strings.idZipPlaceholder,
                  controller: _zipController,
                  errorText: _zipError,
                  keyboardType: TextInputType.text,
                  maxLength: 12,
                  onChanged: (val) {
                    _onFieldChanged('zip', val);
                    setState(() {
                      _validateZip(val, strings);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // KYC Verification Module
          const KycVerificationSection(),
        ],
      ),
    );
  }
}
