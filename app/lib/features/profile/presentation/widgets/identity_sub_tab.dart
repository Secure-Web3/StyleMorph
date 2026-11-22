import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/email_verification_provider.dart';
import '../../domain/identity_validator.dart';
import '../../domain/iso_location_data.dart';
import 'change_email_dialog.dart';
import 'kyc_verification_section.dart';
import 'searchable_location_picker_sheet.dart';

/// Formatter that automatically inserts hyphens for YYYY-MM-DD dates as the user types digits.
class _DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = rawDigits.length > 8 ? rawDigits.substring(0, 8) : rawDigits;

    final int digitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 6) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();

    int newCursor = 0;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        newCursor = i + 1;
        break;
      }
    }
    if (digitsBeforeCursor == 0) newCursor = 0;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursor.clamp(0, formatted.length),
      ),
    );
  }
}

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

  String? _firstNameError;
  String? _lastNameError;
  String? _nickError;
  String? _dobError;
  String? _nidError;
  String? _zipError;
  String? _mobileError;
  int? _calculatedAge;

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
    _selectedCountry =
        IsoLocationData.findByCode(savedCountryCode) ??
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
    _mobileSubscriberController = TextEditingController(
      text: parsedMobile.subscriber,
    );

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

    final initialDob = values['dob'] ?? '';
    if (initialDob.isNotEmpty) {
      _calculatedAge = IdentityValidator.calculateAge(initialDob);
    }
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

    final currentDob = values['dob'] ?? '';
    if (currentDob.isNotEmpty) {
      _calculatedAge = IdentityValidator.calculateAge(currentDob);
    } else {
      _calculatedAge = null;
    }

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

  void _validateFirstName(String? val, AppStrings strings) {
    if (val == null || val.trim().isEmpty) {
      _firstNameError = null;
      return;
    }
    _firstNameError = IdentityValidator.isValidName(val)
        ? null
        : strings.idErrFirstName;
  }

  void _validateLastName(String? val, AppStrings strings) {
    if (val == null || val.trim().isEmpty) {
      _lastNameError = null;
      return;
    }
    _lastNameError = IdentityValidator.isValidName(val)
        ? null
        : strings.idErrLastName;
  }

  void _validateNick(String? val, AppStrings strings) {
    if (val == null || val.trim().isEmpty) {
      _nickError = null;
      return;
    }
    _nickError = IdentityValidator.isValidHandle(val)
        ? null
        : strings.idErrFirstName;
  }

  void _validateDob(String? val, AppStrings strings) {
    if (val == null || val.trim().isEmpty) {
      _dobError = null;
      _calculatedAge = null;
      return;
    }
    final trimmed = val.trim();
    final regex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final match = regex.firstMatch(trimmed);
    if (match == null) {
      _dobError = strings.idErrDobInvalid;
      _calculatedAge = null;
      return;
    }
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null ||
        month == null ||
        day == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      _dobError = strings.idErrDobInvalid;
      _calculatedAge = null;
      return;
    }
    try {
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        _dobError = strings.idErrDobInvalid;
        _calculatedAge = null;
        return;
      }
      final now = DateTime.now();
      if (parsed.isAfter(now)) {
        _dobError = strings.idErrDobFuture;
        _calculatedAge = null;
        return;
      }
      final age = IdentityValidator.calculateAge(trimmed);
      if (age == null) {
        _dobError = strings.idErrDobInvalid;
        _calculatedAge = null;
        return;
      }
      if (age < 13) {
        _dobError = strings.idDobAgeRequirement;
        _calculatedAge = age;
        return;
      }
      _dobError = null;
      _calculatedAge = age;
    } catch (_) {
      _dobError = strings.idErrDobInvalid;
      _calculatedAge = null;
    }
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

  void _onMobileChanged(String val, AppStrings strings) {
    String cleaned = val;
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');
      _mobileSubscriberController.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
    final canonical = IdentityValidator.formatE164(
      dialCode: _mobileCountry.dialCode,
      subscriber: cleaned,
    );
    _onFieldChanged('mobile', canonical);
    setState(() {
      _validateMobile(cleaned, strings);
    });
  }

  int _getNidMaxLength() {
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR') return 10;
    if (code == 'TR') return 11;
    return 20;
  }

  TextInputType _getNidKeyboardType() {
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR' || code == 'TR') return TextInputType.number;
    return TextInputType.text;
  }

  List<TextInputFormatter> _getNidFormatters() {
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR' || code == 'TR') {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]'))];
  }

  int _getMobileMaxLength() {
    final code = _mobileCountry.code.toUpperCase();
    if (code == 'IR' || code == 'TR') return 10;
    return 15;
  }

  int _getZipMaxLength() {
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR') return 10;
    if (code == 'TR') return 5;
    return 12;
  }

  TextInputType _getZipKeyboardType() {
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR' || code == 'TR') return TextInputType.number;
    return TextInputType.text;
  }

  List<TextInputFormatter> _getZipFormatters() {
    final code = _selectedCountry.code.toUpperCase();
    if (code == 'IR' || code == 'TR') {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]'))];
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
      countryCode: _selectedCountry.code,
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
    final strings = context.strings;
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
            dialogTheme: DialogThemeData(backgroundColor: colors.sf),
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
      setState(() {
        _validateDob(isoString, strings);
      });
    }
  }

  Widget _buildAgePill(AppColors colors, AppStrings strings) {
    final hasAge = _calculatedAge != null && _dobError == null;
    final text = hasAge ? strings.idAgeYears(_calculatedAge!) : '—';

    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: hasAge ? colors.pr.withValues(alpha: 0.35) : colors.bd,
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: hasAge ? colors.tx : colors.mu,
        ),
      ),
    );
  }

  Widget _buildDobRow(AppColors colors, AppStrings strings) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            label: strings.idDob,
            labelTrailing: Text(
              strings.idDobAgeRequirement,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: colors.mu),
            ),
            placeholder: strings.idDobPlaceholder,
            controller: _dobController,
            errorText: _dobError,
            keyboardType: TextInputType.datetime,
            textDirection: TextDirection.ltr,
            maxLength: 10,
            inputFormatters: [_DateTextInputFormatter()],
            suffix: IconButton(
              icon: FaIcon(
                FontAwesomeIcons.calendar,
                size: 14,
                color: colors.mu,
              ),
              onPressed: _pickDateOfBirth,
            ),
            onTap: _pickDateOfBirth,
            onChanged: (val) {
              _onFieldChanged('dob', val);
              setState(() {
                _validateDob(val, strings);
              });
            },
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: _buildAgePill(colors, strings),
        ),
      ],
    );
  }

  Widget _buildMobileField(AppColors colors, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: 4,
          children: [
            Text(
              strings.idMobile,
              style: AppTypography.inputLabel(color: colors.tx),
            ),
            AppBadge(
              variant: AppBadgeVariant.standard,
              size: AppBadgeSize.sm,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              child: Text(
                strings.commonComingSoon,
                style: TextStyle(
                  fontSize: 9,
                  color: colors.mu,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
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
                    Icon(Icons.arrow_drop_down, size: 16, color: colors.mu),
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
                maxLength: _getMobileMaxLength(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.telephoneNumberNational],
                onChanged: (val) => _onMobileChanged(val, strings),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailField(
    AppColors colors,
    AppStrings strings,
    bool isEmailVerified,
    bool isAppleUser,
    User? user,
    EmailVerificationState verificationState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier 1: Label Row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: 4,
          children: [
            Text(
              strings.idEmail,
              style: AppTypography.inputLabel(color: colors.tx),
            ),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppBadge(
                  variant: isEmailVerified
                      ? AppBadgeVariant.success
                      : AppBadgeVariant.warning,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        isEmailVerified
                            ? FontAwesomeIcons.check
                            : FontAwesomeIcons.triangleExclamation,
                        size: 10,
                        color: isEmailVerified ? colors.ok : colors.wn,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isEmailVerified
                            ? strings.idVerified
                            : strings.idUnverified,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: isAppleUser ? strings.authAppleEmailManagedNote : '',
                  child: AppButton(
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.ghost,
                    height: 28,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 10),
                    text: strings.idChangeEmail,
                    onPressed: isAppleUser
                        ? null
                        : () => ChangeEmailDialog.show(context, user: user),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Tier 2: Input Row (Full Width)
        AppTextField(
          placeholder: strings.idEmailPlaceholder,
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
          readOnly: isEmailVerified,
          autofillHints: const [AutofillHints.email],
          onChanged: isEmailVerified
              ? null
              : (val) => _onFieldChanged('email', val),
        ),
        if (isAppleUser) ...[
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Icon(Icons.info_outline, size: 12, color: colors.mu),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  strings.authAppleEmailManagedNote,
                  style: AppTypography.caption(color: colors.mu),
                ),
              ),
            ],
          ),
        ],

        // Tier 3: Action Row (Shown ONLY when !isEmailVerified)
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
                height: 34,
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
                onPressed:
                    (verificationState.cooldownSeconds > 0 ||
                        verificationState.isResending ||
                        verificationState.isChecking)
                    ? null
                    : () async {
                        final success = await ref
                            .read(emailVerificationProvider.notifier)
                            .resendVerificationEmail();
                        if (!mounted) return;
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
                height: 34,
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
                onPressed:
                    (verificationState.isChecking ||
                        verificationState.isResending)
                    ? null
                    : () async {
                        final verified = await ref
                            .read(emailVerificationProvider.notifier)
                            .reloadAndCheckVerification();
                        if (!mounted) return;
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
    );
  }

  Widget _buildTopVerificationNotice(
    AppColors colors,
    AppStrings strings,
    bool isEmailVerified,
  ) {
    if (isEmailVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: AppCard(
        variant: AppCardVariant.surface,
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: colors.wn, width: 3),
            ),
          ),
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.wn.withValues(alpha: 0.12),
                      borderRadius: AppRadius.rSm,
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      size: 15,
                      color: colors.wn,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      strings.emailVerificationBannerTitle,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.emailVerificationBannerDesc,
                style: AppTypography.caption(
                  color: colors.mu,
                ).copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
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
    final appState = ref.watch(appStateProvider);
    final isAdvanced = appState.isAdvancedMode;
    final verificationState = ref.watch(emailVerificationProvider);
    final isEmailVerified = verificationState.isVerified;

    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}

    final bool isAppleUser =
        user?.providerData.any((p) => p.providerId == 'apple.com') ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;

        return Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Non-blocking Email Verification Status Banner (information only, action buttons are on email field)
              _buildTopVerificationNotice(colors, strings, isEmailVerified),

              AppSectionHeader(
                faIcon: FontAwesomeIcons.userShield,
                title: strings.idHeader,
              ),
              const SizedBox(height: AppSpacing.md),

              // ════════════════════════════════════════════════════════════════
              // 1. PERSONAL INFO: First Name, Last Name, Handle, DOB (+ Age)
              // ════════════════════════════════════════════════════════════════
              if (isCompact) ...[
                AppTextField(
                  label: strings.idFirstName,
                  placeholder: strings.idFirstNamePlaceholder,
                  controller: _firstNameController,
                  errorText: _firstNameError,
                  keyboardType: TextInputType.name,
                  maxLength: 40,
                  autofillHints: const [AutofillHints.givenName],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[\p{L}\p{M}\s\-']", unicode: true),
                    ),
                  ],
                  onChanged: (val) {
                    _onFieldChanged('firstName', val);
                    setState(() {
                      _validateFirstName(val, strings);
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: strings.idLastName,
                  placeholder: strings.idLastNamePlaceholder,
                  controller: _lastNameController,
                  errorText: _lastNameError,
                  keyboardType: TextInputType.name,
                  maxLength: 40,
                  autofillHints: const [AutofillHints.familyName],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[\p{L}\p{M}\s\-']", unicode: true),
                    ),
                  ],
                  onChanged: (val) {
                    _onFieldChanged('lastName', val);
                    setState(() {
                      _validateLastName(val, strings);
                    });
                  },
                ),
                if (isAdvanced) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: strings.idNick,
                    placeholder: strings.idNickPlaceholder,
                    controller: _nickController,
                    errorText: _nickError,
                    keyboardType: TextInputType.text,
                    maxLength: 30,
                    autofillHints: const [AutofillHints.username],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[\p{L}\p{M}0-9@_\.\-]", unicode: true),
                      ),
                    ],
                    onChanged: (val) {
                      _onFieldChanged('nick', val);
                      setState(() {
                        _validateNick(val, strings);
                      });
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _buildDobRow(colors, strings),
              ] else ...[
                // Row 1: First Name & Last Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: strings.idFirstName,
                        placeholder: strings.idFirstNamePlaceholder,
                        controller: _firstNameController,
                        errorText: _firstNameError,
                        keyboardType: TextInputType.name,
                        maxLength: 40,
                        autofillHints: const [AutofillHints.givenName],
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[\p{L}\p{M}\s\-']", unicode: true),
                          ),
                        ],
                        onChanged: (val) {
                          _onFieldChanged('firstName', val);
                          setState(() {
                            _validateFirstName(val, strings);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        label: strings.idLastName,
                        placeholder: strings.idLastNamePlaceholder,
                        controller: _lastNameController,
                        errorText: _lastNameError,
                        keyboardType: TextInputType.name,
                        maxLength: 40,
                        autofillHints: const [AutofillHints.familyName],
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[\p{L}\p{M}\s\-']", unicode: true),
                          ),
                        ],
                        onChanged: (val) {
                          _onFieldChanged('lastName', val);
                          setState(() {
                            _validateLastName(val, strings);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Row 2: Handle / Nickname & Date of Birth (+ Live Age Pill)
                if (isAdvanced)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: strings.idNick,
                          placeholder: strings.idNickPlaceholder,
                          controller: _nickController,
                          errorText: _nickError,
                          keyboardType: TextInputType.text,
                          maxLength: 30,
                          autofillHints: const [AutofillHints.username],
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r"[\p{L}\p{M}0-9@_\.\-]", unicode: true),
                            ),
                          ],
                          onChanged: (val) {
                            _onFieldChanged('nick', val);
                            setState(() {
                              _validateNick(val, strings);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _buildDobRow(colors, strings)),
                    ],
                  )
                else
                  _buildDobRow(colors, strings),
              ],
              const SizedBox(height: AppSpacing.md),

              // ════════════════════════════════════════════════════════════════
              // 2. LOCATION (BEFORE dependent fields): Country -> Province -> City
              // ════════════════════════════════════════════════════════════════
              if (isCompact) ...[
                AppTextField(
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
                if (isAdvanced) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: strings.idProvince,
                    placeholder: strings.idProvincePlaceholder,
                    controller: _provinceController,
                    readOnly: true,
                    suffix: const Icon(Icons.arrow_drop_down, size: 20),
                    onTap: _pickProvince,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: strings.idCity,
                  placeholder: strings.idCityPlaceholder,
                  controller: _cityController,
                  readOnly: true,
                  suffix: const Icon(Icons.arrow_drop_down, size: 20),
                  onTap: _pickCity,
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: strings.idCountry,
                        placeholder: strings.idCountryPlaceholder,
                        controller: _countryController,
                        readOnly: true,
                        prefix: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 8,
                            end: 4,
                          ),
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
                    if (isAdvanced) ...[
                      const SizedBox(width: AppSpacing.sm),
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
                    ],
                    const SizedBox(width: AppSpacing.sm),
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
              ],
              const SizedBox(height: AppSpacing.md),

              // ════════════════════════════════════════════════════════════════
              // 3. COUNTRY-DEPENDENT & CONTACT INFO: NID, Mobile, Email, Address, Zip
              // ════════════════════════════════════════════════════════════════
              if (isCompact) ...[
                if (isAdvanced) ...[
                  AppTextField(
                    label: strings.idNationalId,
                    placeholder: strings.idNationalIdPlaceholder,
                    controller: _nidController,
                    errorText: _nidError,
                    keyboardType: _getNidKeyboardType(),
                    maxLength: _getNidMaxLength(),
                    inputFormatters: _getNidFormatters(),
                    onChanged: (val) {
                      _onFieldChanged('nid', val);
                      setState(() {
                        _validateNid(val, strings);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMobileField(colors, strings),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _buildEmailField(
                  colors,
                  strings,
                  isEmailVerified,
                  isAppleUser,
                  user,
                  verificationState,
                ),
                if (isAdvanced) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: strings.idAddress,
                    placeholder: strings.idAddressPlaceholder,
                    controller: _addressController,
                    maxLines: 2,
                    autofillHints: const [AutofillHints.fullStreetAddress],
                    onChanged: (val) => _onFieldChanged('address', val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: strings.idZip,
                    placeholder: strings.idZipPlaceholder,
                    controller: _zipController,
                    errorText: _zipError,
                    keyboardType: _getZipKeyboardType(),
                    maxLength: _getZipMaxLength(),
                    inputFormatters: _getZipFormatters(),
                    autofillHints: const [AutofillHints.postalCode],
                    onChanged: (val) {
                      _onFieldChanged('zip', val);
                      setState(() {
                        _validateZip(val, strings);
                      });
                    },
                  ),
                ],
              ] else ...[
                if (isAdvanced) ...[
                  // Row 1: National ID & Mobile
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: strings.idNationalId,
                          placeholder: strings.idNationalIdPlaceholder,
                          controller: _nidController,
                          errorText: _nidError,
                          keyboardType: _getNidKeyboardType(),
                          maxLength: _getNidMaxLength(),
                          inputFormatters: _getNidFormatters(),
                          onChanged: (val) {
                            _onFieldChanged('nid', val);
                            setState(() {
                              _validateNid(val, strings);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _buildMobileField(colors, strings)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Row 2: Email (Full Width)
                _buildEmailField(
                  colors,
                  strings,
                  isEmailVerified,
                  isAppleUser,
                  user,
                  verificationState,
                ),
                if (isAdvanced) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // Row 3: Address & Postal / ZIP Code
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
                          autofillHints: const [
                            AutofillHints.fullStreetAddress,
                          ],
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
                          keyboardType: _getZipKeyboardType(),
                          maxLength: _getZipMaxLength(),
                          inputFormatters: _getZipFormatters(),
                          autofillHints: const [AutofillHints.postalCode],
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
                ],
              ],
              if (isAdvanced) ...[
                const SizedBox(height: AppSpacing.lg),
                // ════════════════════════════════════════════════════════════════
                // 4. KYC VERIFICATION MODULE
                // ════════════════════════════════════════════════════════════════
                const KycVerificationSection(),
              ],
            ],
          ),
        );
      },
    );
  }
}
