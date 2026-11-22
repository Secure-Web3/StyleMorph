import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';

class AnatomySubTab extends ConsumerStatefulWidget {
  const AnatomySubTab({super.key});

  @override
  ConsumerState<AnatomySubTab> createState() => _AnatomySubTabState();
}

// Backwards-compatible alias
typedef AiDnaSubTab = AnatomySubTab;

class _AnatomySubTabState extends ConsumerState<AnatomySubTab> {
  // Fitzpatrick Skin Tone definitions (I–VI)
  static const List<Map<String, dynamic>> _fitzpatrickTypes = [
    {'key': 'type_1', 'color': Color(0xFFFBF0E8)},
    {'key': 'type_2', 'color': Color(0xFFF3DEC8)},
    {'key': 'type_3', 'color': Color(0xFFD9B99B)},
    {'key': 'type_4', 'color': Color(0xFFB88358)},
    {'key': 'type_5', 'color': Color(0xFF8C532B)},
    {'key': 'type_6', 'color': Color(0xFF4A2B19)},
  ];

  // Eye color definitions
  static const List<Map<String, dynamic>> _eyeColors = [
    {'key': 'brown', 'color': Color(0xFF5C3826)},
    {'key': 'hazel', 'color': Color(0xFF987654)},
    {'key': 'green', 'color': Color(0xFF2E6B47)},
    {'key': 'blue', 'color': Color(0xFF2F5D9B)},
    {'key': 'gray', 'color': Color(0xFF737373)},
    {'key': 'black', 'color': Color(0xFF1A1A1A)},
  ];

  // Bra Band & Cup options
  static const List<String> _braBands = [
    '65',
    '70',
    '75',
    '80',
    '85',
    '90',
    '95',
    '100',
    '105',
    '110',
  ];
  static const List<String> _braCups = ['A', 'B', 'C', 'D', 'E', 'F'];

  void _updateField(String key, String value) {
    ref.read(appStateProvider.notifier).updateAiDnaField(key, value);
  }

  double? _calculateBmi(String heightStr, String weightStr) {
    final h = double.tryParse(heightStr);
    final w = double.tryParse(weightStr);
    if (h == null || w == null || h <= 50 || w <= 15) return null;
    final heightInMeters = h / 100.0;
    return w / (heightInMeters * heightInMeters);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final isAdvanced = appState.isAdvancedMode;
    final aiDna = appState.aiDnaValues;

    final gender = aiDna['gender'] ?? '';
    final heightStr = aiDna['height'] ?? '';
    final weightStr = aiDna['weight'] ?? '';
    final bmi = _calculateBmi(heightStr, weightStr);

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Global Header
          AppSectionHeader(
            faIcon: FontAwesomeIcons.dna,
            title: strings.aiHeader,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.aiAnthropometricSub,
            style: AppTypography.caption(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.lg),

          // =========================================================
          // LAYER 1: Biometric Base & Silhouette
          // =========================================================
          _buildLayer1Biometrics(
            context,
            gender: gender,
            heightStr: heightStr,
            weightStr: weightStr,
            bmi: bmi,
            selectedSilhouette:
                aiDna['bodySilhouette'] ?? aiDna['bodyShape'] ?? '',
          ),
          const SizedBox(height: AppSpacing.xl),

          // =========================================================
          // LAYER 2: Visual & Colorimetry Specs
          // =========================================================
          _buildLayer2Colorimetry(
            context,
            skinTone: aiDna['skinTone'] ?? '',
            undertone: aiDna['skinUndertone'] ?? '',
            eyeColor: aiDna['eyeColor'] ?? '',
            hairColor: aiDna['hairColor'] ?? '',
            hairTexture: aiDna['hairTexture'] ?? aiDna['hair'] ?? '',
            faceShape: aiDna['faceShape'] ?? '',
          ),
          const SizedBox(height: AppSpacing.xl),

          // =========================================================
          // LAYER 3: Anthropometric Fit Dimensions (Advanced Only)
          // =========================================================
          if (isAdvanced) ...[
            _buildLayer3Anthropometrics(
              context,
              aiDna,
              isFemale: gender == 'female',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // =========================================================
          // LAYER 4: Fit Preference
          // =========================================================
          _buildLayer4FitPreference(
            context,
            selectedFit: aiDna['fitPreference'] ?? 'regular',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LAYER 1 WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildLayer1Biometrics(
    BuildContext context, {
    required String gender,
    required String heightStr,
    required String weightStr,
    required double? bmi,
    required String selectedSilhouette,
  }) {
    final colors = context.colors;
    final strings = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.aiSectionBiometrics,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Gender Selector (3 Options)
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                context,
                value: 'female',
                label: strings.aiFemale,
                icon: FontAwesomeIcons.venus,
                isSelected: gender == 'female',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildGenderOption(
                context,
                value: 'male',
                label: strings.aiMale,
                icon: FontAwesomeIcons.mars,
                isSelected: gender == 'male',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildGenderOption(
                context,
                value: 'non_binary',
                label: strings.aiGenderNonBinary,
                icon: FontAwesomeIcons.genderless,
                isSelected: gender == 'non_binary',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Height & Weight Inputs (2 Columns)
        Row(
          children: [
            Expanded(
              child: AppTextField(
                key: ValueKey('height-${strings.localeCode}'),
                label: strings.aiHeight,
                initialValue: heightStr,
                placeholder: '175',
                suffixText: 'cm',
                keyboardType: TextInputType.number,
                onChanged: (val) => _updateField('height', val),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                key: ValueKey('weight-${strings.localeCode}'),
                label: strings.aiWeight,
                initialValue: weightStr,
                placeholder: '70',
                suffixText: 'kg',
                keyboardType: TextInputType.number,
                onChanged: (val) => _updateField('weight', val),
              ),
            ),
          ],
        ),

        // Live BMI Badge
        if (bmi != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildBmiBadge(context, bmi),
        ],
        const SizedBox(height: AppSpacing.md),

        // Body Silhouette Selector (Tailored to Gender)
        Text(
          strings.aiBodySilhouette,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildSilhouetteChips(
          context,
          gender: gender,
          selected: selectedSilhouette,
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    BuildContext context, {
    required String value,
    required String label,
    required FaIconData icon,
    required bool isSelected,
  }) {
    final colors = context.colors;

    return InkWell(
      onTap: () => _updateField('gender', value),
      borderRadius: AppRadius.rMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? colors.pr.withValues(alpha: 0.12) : colors.bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: isSelected ? colors.pr : colors.bd,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 16, color: isSelected ? colors.pr : colors.mu),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.pr : colors.tx,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiBadge(BuildContext context, double bmi) {
    final colors = context.colors;
    final strings = context.strings;

    String categoryText;
    Color badgeColor;

    if (bmi < 18.5) {
      categoryText = strings.aiBmiUnderweight;
      badgeColor = colors.wn;
    } else if (bmi < 25.0) {
      categoryText = strings.aiBmiNormal;
      badgeColor = colors.ok;
    } else if (bmi < 30.0) {
      categoryText = strings.aiBmiOverweight;
      badgeColor = colors.orColor;
    } else {
      categoryText = strings.aiBmiObese;
      badgeColor = colors.orColor;
    }

    final formattedBmi = strings.formatNumber(bmi.toStringAsFixed(1));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.heartPulse, size: 13, color: badgeColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${strings.aiBmiLabel}: $formattedBmi • $categoryText',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSilhouetteChips(
    BuildContext context, {
    required String gender,
    required String selected,
  }) {
    final strings = context.strings;
    final colors = context.colors;

    List<Map<String, String>> options;
    if (gender == 'female') {
      options = [
        {'key': 'hourglass', 'label': strings.aiSilHourglass},
        {'key': 'pear', 'label': strings.aiSilPear},
        {'key': 'apple', 'label': strings.aiSilApple},
        {'key': 'rectangle', 'label': strings.aiSilRectangle},
        {'key': 'inverted_triangle', 'label': strings.aiSilInvertedTriangle},
      ];
    } else if (gender == 'male') {
      options = [
        {'key': 'trapezoid', 'label': strings.aiSilTrapezoid},
        {'key': 'rectangle', 'label': strings.aiSilRectangle},
        {'key': 'inverted_triangle', 'label': strings.aiSilInvertedTriangle},
        {'key': 'oval', 'label': strings.aiSilOval},
      ];
    } else {
      options = [
        {'key': 'rectangle', 'label': strings.aiSilRectangle},
        {'key': 'trapezoid', 'label': strings.aiSilTrapezoid},
        {'key': 'hourglass', 'label': strings.aiSilHourglass},
        {'key': 'inverted_triangle', 'label': strings.aiSilInvertedTriangle},
        {'key': 'oval', 'label': strings.aiSilOval},
      ];
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: options.map((opt) {
        final isSelected = selected == opt['key'] || selected == opt['label'];
        return ChoiceChip(
          label: Text(
            opt['label']!,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? colors.prt : colors.tx,
            ),
          ),
          selected: isSelected,
          selectedColor: colors.pr,
          backgroundColor: colors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.rMd,
            side: BorderSide(color: isSelected ? colors.pr : colors.bd),
          ),
          onSelected: (_) {
            _updateField('bodySilhouette', opt['key']!);
            _updateField('bodyShape', opt['key']!);
          },
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // LAYER 2 WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildLayer2Colorimetry(
    BuildContext context, {
    required String skinTone,
    required String undertone,
    required String eyeColor,
    required String hairColor,
    required String hairTexture,
    required String faceShape,
  }) {
    final colors = context.colors;
    final strings = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.aiSectionColorimetry,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Fitzpatrick Skin Tone Swatches
        Text(
          strings.aiFitzpatrickLabel,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _fitzpatrickTypes.map((item) {
            final key = item['key'] as String;
            final color = item['color'] as Color;
            final isSelected = skinTone == key || skinTone.contains(key);

            return InkWell(
              onTap: () => _updateField('skinTone', key),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.pr : colors.bd,
                    width: isSelected ? 3.0 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.pr.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Center(
                        child: FaIcon(
                          FontAwesomeIcons.check,
                          size: 13,
                          color: (color.computeLuminance() > 0.5)
                              ? Colors.black
                              : Colors.white,
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _getFitzpatrickLabel(context, skinTone),
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            color: colors.mu,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Skin Undertone
        Text(
          strings.aiUndertone,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildToneChip(
                context,
                key: 'warm',
                label: strings.aiToneWarm,
                isSelected: undertone == 'warm',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildToneChip(
                context,
                key: 'cool',
                label: strings.aiToneCool,
                isSelected: undertone == 'cool',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildToneChip(
                context,
                key: 'neutral',
                label: strings.aiToneNeutral,
                isSelected: undertone == 'neutral',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Eye Color Swatches
        Text(
          strings.aiEyeColor,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _eyeColors.map((item) {
            final key = item['key'] as String;
            final color = item['color'] as Color;
            final isSelected = eyeColor == key;

            return InkWell(
              onTap: () => _updateField('eyeColor', key),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.pr : colors.bd,
                        width: isSelected ? 2.6 : 1.0,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: FaIcon(
                              FontAwesomeIcons.check,
                              size: 11,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getEyeColorLabel(context, key),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 9,
                      color: isSelected ? colors.pr : colors.mu,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // Hair Profile (Color + Length/Texture)
        Row(
          children: [
            Expanded(
              child: AppDropdown<String>(
                label: strings.aiHairColor,
                value: hairColor.isNotEmpty ? hairColor : null,
                placeholder: strings.aiHairColor,
                items: [
                  DropdownMenuItem(
                    value: 'black',
                    child: Text(strings.aiHairBlack),
                  ),
                  DropdownMenuItem(
                    value: 'dark_brown',
                    child: Text(strings.aiHairDarkBrown),
                  ),
                  DropdownMenuItem(
                    value: 'light_brown',
                    child: Text(strings.aiHairLightBrown),
                  ),
                  DropdownMenuItem(
                    value: 'blonde',
                    child: Text(strings.aiHairBlonde),
                  ),
                  DropdownMenuItem(
                    value: 'auburn',
                    child: Text(strings.aiHairAuburn),
                  ),
                  DropdownMenuItem(
                    value: 'gray',
                    child: Text(strings.aiHairGray),
                  ),
                  DropdownMenuItem(
                    value: 'dyed',
                    child: Text(strings.aiHairDyed),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) _updateField('hairColor', val);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppDropdown<String>(
                label: strings.aiHairLength,
                value: hairTexture.isNotEmpty ? hairTexture : null,
                placeholder: strings.aiHairLength,
                items: [
                  DropdownMenuItem(
                    value: 'short_straight',
                    child: Text(
                      '${strings.aiHairShort} • ${strings.aiHairStraight}',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'short_wavy',
                    child: Text(
                      '${strings.aiHairShort} • ${strings.aiHairWavy}',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'medium_straight',
                    child: Text(
                      '${strings.aiHairMedium} • ${strings.aiHairStraight}',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'medium_wavy',
                    child: Text(
                      '${strings.aiHairMedium} • ${strings.aiHairWavy}',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'long_straight',
                    child: Text(
                      '${strings.aiHairLong} • ${strings.aiHairStraight}',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'long_curly',
                    child: Text(
                      '${strings.aiHairLong} • ${strings.aiHairCurly}',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'bald',
                    child: Text(strings.aiHairBald),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _updateField('hairTexture', val);
                    _updateField('hair', val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Face Shape Selector (5 Chips)
        Text(
          strings.aiFaceShape,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children:
              [
                {'key': 'oval', 'label': strings.aiFaceOval},
                {'key': 'round', 'label': strings.aiFaceRound},
                {'key': 'square', 'label': strings.aiFaceSquare},
                {'key': 'heart', 'label': strings.aiFaceHeart},
                {'key': 'oblong', 'label': strings.aiFaceOblong},
              ].map((item) {
                final isSelected = faceShape == item['key'];
                return ChoiceChip(
                  label: Text(
                    item['label']!,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? colors.prt : colors.tx,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colors.pr,
                  backgroundColor: colors.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.rMd,
                    side: BorderSide(color: isSelected ? colors.pr : colors.bd),
                  ),
                  onSelected: (_) => _updateField('faceShape', item['key']!),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildToneChip(
    BuildContext context, {
    required String key,
    required String label,
    required bool isSelected,
  }) {
    final colors = context.colors;

    return InkWell(
      onTap: () => _updateField('skinUndertone', key),
      borderRadius: AppRadius.rMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? colors.pr.withValues(alpha: 0.12) : colors.bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: isSelected ? colors.pr : colors.bd,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.pr : colors.tx,
          ),
        ),
      ),
    );
  }

  String _getFitzpatrickLabel(BuildContext context, String toneKey) {
    final strings = context.strings;
    switch (toneKey) {
      case 'type_1':
        return strings.aiFitz1;
      case 'type_2':
        return strings.aiFitz2;
      case 'type_3':
        return strings.aiFitz3;
      case 'type_4':
        return strings.aiFitz4;
      case 'type_5':
        return strings.aiFitz5;
      case 'type_6':
        return strings.aiFitz6;
      default:
        return strings.aiFitz3;
    }
  }

  String _getEyeColorLabel(BuildContext context, String key) {
    final strings = context.strings;
    switch (key) {
      case 'brown':
        return strings.aiEyeBrown;
      case 'hazel':
        return strings.aiEyeHazel;
      case 'green':
        return strings.aiEyeGreen;
      case 'blue':
        return strings.aiEyeBlue;
      case 'gray':
        return strings.aiEyeGray;
      case 'black':
        return strings.aiEyeBlack;
      default:
        return key;
    }
  }

  // ---------------------------------------------------------------------------
  // LAYER 3 WIDGETS: Anthropometric Fit Dimensions
  // ---------------------------------------------------------------------------
  Widget _buildLayer3Anthropometrics(
    BuildContext context,
    Map<String, String> aiDna, {
    required bool isFemale,
  }) {
    final strings = context.strings;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        AppSectionHeader(
          faIcon: FontAwesomeIcons.rulerCombined,
          title: strings.aiAnthropometricHeader,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings.aiAnthropometricSub,
          style: AppTypography.caption(color: colors.mu),
        ),
        const SizedBox(height: AppSpacing.md),

        // 1. Shoulder & Chest
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'shoulder',
                label: strings.aiShoulder,
                helperHint: strings.aiShoulderHint,
                initialValue: aiDna['shoulder'] ?? '',
                suffix: 'cm',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'chest',
                label: strings.aiChest,
                helperHint: strings.aiChestHint,
                initialValue: aiDna['chest'] ?? '',
                suffix: 'cm',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Conditional Bra Size (ONLY when Female)
        if (isFemale) ...[
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.aiBraSize,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: strings.aiBraBand,
                        value: (aiDna['braBand'] ?? '').isNotEmpty
                            ? aiDna['braBand']
                            : null,
                        placeholder: '75',
                        items: _braBands
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(strings.formatNumber(b)),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) _updateField('braBand', val);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppDropdown<String>(
                        label: strings.aiBraCup,
                        value: (aiDna['braCup'] ?? '').isNotEmpty
                            ? aiDna['braCup']
                            : null,
                        placeholder: 'B',
                        items: _braCups
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) _updateField('braCup', val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // 2. Waist, Abdomen, Hips (3 Columns)
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'waist',
                label: strings.aiWaist,
                helperHint: strings.aiWaistHint,
                initialValue: aiDna['waist'] ?? '',
                suffix: 'cm',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'belly',
                label: strings.aiBelly,
                helperHint: strings.aiBellyHint,
                initialValue: aiDna['belly'] ?? aiDna['abdomen'] ?? '',
                suffix: 'cm',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'hips',
                label: strings.aiHips,
                helperHint: strings.aiHipsHint,
                initialValue: aiDna['hips'] ?? '',
                suffix: 'cm',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 3. Sleeve Length & Inseam Length (2 Columns)
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'sleeve',
                label: strings.aiSleeve,
                helperHint: strings.aiSleeveHint,
                initialValue: aiDna['sleeve'] ?? '',
                suffix: 'cm',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'inseam',
                label: strings.aiInseam,
                helperHint: strings.aiInseamHint,
                initialValue: aiDna['inseam'] ?? '',
                suffix: 'cm',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 4. Neck Circumference & Shoe Size (2 Columns)
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'neck',
                label: strings.aiNeck,
                helperHint: strings.aiNeckHint,
                initialValue: aiDna['neck'] ?? '',
                suffix: 'cm',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildDimensionField(
                context,
                fieldKey: 'shoeSize',
                label: strings.aiShoeSize,
                helperHint: strings.aiShoeSizeHint,
                initialValue: aiDna['shoeSize'] ?? '',
                placeholder: '42 / 9 US',
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDimensionField(
    BuildContext context, {
    required String fieldKey,
    required String label,
    required String helperHint,
    required String initialValue,
    String? suffix,
    String? placeholder,
    TextInputType keyboardType = TextInputType.number,
  }) {
    final strings = context.strings;
    final colors = context.colors;

    return AppTextField(
      key: ValueKey('$fieldKey-${strings.localeCode}'),
      label: label,
      initialValue: initialValue,
      placeholder: placeholder,
      suffixText: suffix,
      keyboardType: keyboardType,
      labelTrailing: Tooltip(
        message: helperHint,
        child: FaIcon(
          FontAwesomeIcons.circleQuestion,
          size: 11,
          color: colors.mu,
        ),
      ),
      onChanged: (val) {
        _updateField(fieldKey, val);
        if (fieldKey == 'belly') _updateField('abdomen', val);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LAYER 4 WIDGETS: Fit Preference
  // ---------------------------------------------------------------------------
  Widget _buildLayer4FitPreference(
    BuildContext context, {
    required String selectedFit,
  }) {
    final strings = context.strings;
    final colors = context.colors;

    final fits = [
      {
        'key': 'slim',
        'title': strings.aiFitSlim,
        'desc': strings.aiFitSlimDesc,
        'icon': FontAwesomeIcons.person,
      },
      {
        'key': 'regular',
        'title': strings.aiFitRegular,
        'desc': strings.aiFitRegularDesc,
        'icon': FontAwesomeIcons.personWalking,
      },
      {
        'key': 'relaxed',
        'title': strings.aiFitRelaxed,
        'desc': strings.aiFitRelaxedDesc,
        'icon': FontAwesomeIcons.personRays,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          faIcon: FontAwesomeIcons.shirt,
          title: strings.aiFitPrefHeader,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...fits.map((fit) {
          final isSelected = selectedFit == fit['key'];

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: InkWell(
              onTap: () => _updateField('fitPreference', fit['key'] as String),
              borderRadius: AppRadius.rMd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.pr.withValues(alpha: 0.08)
                      : colors.bg,
                  borderRadius: AppRadius.rMd,
                  border: Border.all(
                    color: isSelected ? colors.pr : colors.bd,
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.pr.withValues(alpha: 0.15)
                            : colors.sf,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? colors.pr : colors.bd,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          fit['icon'] as FaIconData,
                          size: 15,
                          color: isSelected ? colors.pr : colors.mu,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fit['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected ? colors.pr : colors.tx,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fit['desc'] as String,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              color: colors.mu,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      FaIcon(
                        FontAwesomeIcons.solidCircleCheck,
                        size: 16,
                        color: colors.pr,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
