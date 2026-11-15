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
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';

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
    final values = ref.read(appStateProvider).identityValues;
    _firstNameController =
        TextEditingController(text: values['firstName'] ?? 'سارا');
    _lastNameController =
        TextEditingController(text: values['lastName'] ?? 'احمدی');
    _nickController =
        TextEditingController(text: values['nick'] ?? '@sara_ahmadi');
    _nidController =
        TextEditingController(text: values['nid'] ?? '0012345678');
    _mobileController =
        TextEditingController(text: values['mobile'] ?? '09123456789');
    _emailController =
        TextEditingController(text: values['email'] ?? 'sara.ahmadi@gmail.com');
    _countryController =
        TextEditingController(text: values['country'] ?? 'ایران');
    _provinceController =
        TextEditingController(text: values['province'] ?? 'تهران');
    _cityController = TextEditingController(text: values['city'] ?? 'تهران');
    _addressController = TextEditingController(
      text: values['address'] ?? 'خیابان ولیعصر، بالاتر از ونک، پلاک ۲۴',
    );
    _zipController =
        TextEditingController(text: values['zip'] ?? '1994512345');
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
    final colors = context.colors;
    final strings = context.strings;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          // Mobile with Verified Badge
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
                  AppBadge(
                    variant: AppBadgeVariant.success,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.check,
                            size: 11, color: colors.ok),
                        const SizedBox(width: AppSpacing.xs),
                        Text(strings.idVerified),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Email with Send Code button
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
                  AppButton(
                    size: AppButtonSize.sm,
                    height: 40,
                    variant: AppButtonVariant.outline,
                    text: strings.idSendCode,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.idCodeSentToast,
                            style: const TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
