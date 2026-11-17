import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';

class AiDnaSubTab extends ConsumerWidget {
  const AiDnaSubTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final genderVal = appState.aiDnaValues['gender'];

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            faIcon: FontAwesomeIcons.dna,
            title: strings.aiHeader,
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            'اطلاعات آناتومی و اندازه‌های بدن خود را به صورت دستی وارد و ذخیره کنید.',
            style: AppTypography.caption(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.md),

          // 1. Gender Dropdown (Defaults unselected with prompt)
          AppDropdown<String>(
            label: strings.aiGender,
            placeholder: strings.tr('انتخاب جنسیت'),
            value: (genderVal != null && genderVal.isNotEmpty) ? genderVal : null,
            items: [
              DropdownMenuItem(
                value: 'female',
                child: Text(strings.aiFemale),
              ),
              DropdownMenuItem(
                value: 'male',
                child: Text(strings.aiMale),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                ref
                    .read(appStateProvider.notifier)
                    .updateAiDnaField('gender', val);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Height & Weight (2 Columns)
          Row(
            children: [
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'height',
                  label: strings.aiHeight,
                  unit: 'cm',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'weight',
                  label: strings.aiWeight,
                  unit: 'kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3. Skin Tone & Body Shape (2 Columns)
          Row(
            children: [
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'skinTone',
                  label: strings.aiSkinTone,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'bodyShape',
                  label: strings.aiBodyShape,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 4. Face Shape & Hair (2 Columns)
          Row(
            children: [
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'faceShape',
                  label: strings.aiFaceShape,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'hair',
                  label: strings.aiHair,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tailoring Grid Header
          AppSectionHeader(
            faIcon: FontAwesomeIcons.rulerCombined,
            title: strings.aiTailoringHeader,
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Shoulder & Chest (2 Columns)
          Row(
            children: [
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'shoulder',
                  label: strings.aiShoulder,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'chest',
                  label: strings.aiChest,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 6. Waist, Belly, Hips (3 Columns)
          Row(
            children: [
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'waist',
                  label: strings.aiWaist,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'belly',
                  label: strings.aiBelly,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextEditField(
                  context: context,
                  ref: ref,
                  fieldKey: 'hips',
                  label: strings.aiHips,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditField({
    required BuildContext context,
    required WidgetRef ref,
    required String fieldKey,
    required String label,
    String? unit,
  }) {
    final strings = context.strings;
    final rawVal = ref.watch(
      appStateProvider.select((s) => s.aiDnaValues[fieldKey] ?? ''),
    );
    final displayVal = strings.tr(rawVal);

    return AppTextField(
      key: ValueKey('$fieldKey-${strings.localeCode}'),
      label: label,
      initialValue: displayVal,
      suffixText: unit,
      onChanged: (val) {
        ref.read(appStateProvider.notifier).updateAiDnaField(fieldKey, val);
      },
    );
  }
}
