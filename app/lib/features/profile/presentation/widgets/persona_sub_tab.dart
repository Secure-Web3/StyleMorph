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
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/app_text_field.dart';

class _PersonaMeta {
  final String id;
  final String name;
  final String role;
  final String trait;
  final String defaultVoice;
  final Color bgTint;
  final Color accent;
  final IconData icon;

  const _PersonaMeta({
    required this.id,
    required this.name,
    required this.role,
    required this.trait,
    required this.defaultVoice,
    required this.bgTint,
    required this.accent,
    required this.icon,
  });
}

const List<_PersonaMeta> _kPersonas = [
  _PersonaMeta(
    id: 'ramin',
    name: 'رامین',
    role: 'استایلیست ارشد',
    trait: 'خوش‌سلیقه، رک و سریع',
    defaultVoice: 'مرد — گرم و دوستانه',
    bgTint: Color(0xFFE3ECF7),
    accent: Color(0xFF3D5A80),
    icon: Icons.style_rounded,
  ),
  _PersonaMeta(
    id: 'lena',
    name: 'لنا',
    role: 'مشاور زیبایی و مد',
    trait: 'خلاق، لطیف و به‌روز',
    defaultVoice: 'زن — گرم و مهربان',
    bgTint: Color(0xFFFBE4EE),
    accent: Color(0xFFC2547A),
    icon: Icons.auto_awesome_rounded,
  ),
  _PersonaMeta(
    id: 'arash',
    name: 'آرش',
    role: 'مربی تندرستی',
    trait: 'پرانرژی، دقیق و انگیزه‌بخش',
    defaultVoice: 'مرد — جوان و پرانرژی',
    bgTint: Color(0xFFFFF0D9),
    accent: Color(0xFFD98324),
    icon: Icons.fitness_center_rounded,
  ),
  _PersonaMeta(
    id: 'sara',
    name: 'سارا',
    role: 'مشاور شخصی',
    trait: 'همدل، صبور و خوش‌برخورد',
    defaultVoice: 'زن — آرام و دلگرم‌کننده',
    bgTint: Color(0xFFFDE8E4),
    accent: Color(0xFFE07A5F),
    icon: Icons.support_agent_rounded,
  ),
  _PersonaMeta(
    id: 'farzaneh',
    name: 'فرزانه',
    role: 'راهنمای آرامش',
    trait: 'آرام، دقیق و باحوصله',
    defaultVoice: 'زن — آرام و شمرده',
    bgTint: Color(0xFFE4F3EC),
    accent: Color(0xFF5FA383),
    icon: Icons.spa_rounded,
  ),
  _PersonaMeta(
    id: 'nilo',
    name: 'نیلو',
    role: 'فشنیستا',
    trait: 'شیک، مدرن و بااعتمادبه‌نفس',
    defaultVoice: 'زن — جوان و شاد',
    bgTint: Color(0xFFEFE7FB),
    accent: Color(0xFF8E6BBF),
    icon: Icons.diamond_outlined,
  ),
];

class PersonaSubTab extends ConsumerStatefulWidget {
  const PersonaSubTab({super.key});

  @override
  ConsumerState<PersonaSubTab> createState() => _PersonaSubTabState();
}

class _PersonaSubTabState extends ConsumerState<PersonaSubTab> {
  late final TextEditingController _customNameController;

  @override
  void initState() {
    super.initState();
    _customNameController = TextEditingController(
      text: ref.read(appStateProvider).companionSettings.customName,
    );
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  String _strictnessLabel(double val) {
    if (val <= 0.25) return 'ملایم و انعطاف‌پذیر';
    if (val <= 0.65) return 'متعادل و استاندارد';
    return 'سخت‌گیر و تخصصی';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final settings = ref.watch(
      appStateProvider.select((s) => s.companionSettings),
    );
    final notifier = ref.read(appStateProvider.notifier);

    final selectedMeta = _kPersonas.firstWhere(
      (p) => p.id == settings.characterId,
      orElse: () => _kPersonas.first,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            faIcon: FontAwesomeIcons.wandMagicSparkles,
            title: strings.perHeader,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.perSub,
            style: AppTypography.caption(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.md),

          // 1. Companion Selection Card
          _SectionCard(
            colors: colors,
            icon: FontAwesomeIcons.userAstronaut,
            title: strings.perSelectTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _kPersonas.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.35,
                  ),
                  itemBuilder: (context, index) {
                    final persona = _kPersonas[index];
                    final isSelected = persona.id == selectedMeta.id;
                    return InkWell(
                      onTap: () {
                        notifier.updateCompanionSettings(
                          settings.copyWith(characterId: persona.id),
                        );
                      },
                      borderRadius: AppRadius.rMd,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.pr.withValues(alpha: 0.08)
                              : colors.bg,
                          borderRadius: AppRadius.rMd,
                          border: Border.all(
                            color: isSelected ? colors.pr : colors.bd,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: persona.bgTint,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                persona.icon,
                                size: 16,
                                color: persona.accent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.tr(persona.name),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.tx,
                                    ),
                                  ),
                                  Text(
                                    strings.tr(persona.role),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 9,
                                      color: colors.mu,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Active Persona Summary
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedMeta.bgTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          selectedMeta.icon,
                          size: 20,
                          color: selectedMeta.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${strings.tr(selectedMeta.name)} — ${strings.tr(selectedMeta.role)}',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.tx,
                              ),
                            ),
                            Text(
                              strings.tr(selectedMeta.trait),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                color: colors.tx,
                              ),
                            ),
                            Text(
                              '${strings.perDefaultVoice}: ${strings.tr(selectedMeta.defaultVoice)}',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                color: colors.mu,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                AppTextField(
                  label: strings.perCustomName,
                  controller: _customNameController,
                  placeholder: strings.perCustomNameHint,
                  maxLength: 20,
                  onChanged: (val) {
                    notifier.updateCompanionSettings(
                      settings.copyWith(customName: val),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Tone of Voice & Critique Strictness
          _SectionCard(
            colors: colors,
            icon: FontAwesomeIcons.comments,
            title: strings.perToneSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdown<String>(
                  label: strings.perToneLabel,
                  value: settings.tone,
                  items: const [
                    'صمیمی و دوستانه',
                    'رسمی و تخصصی',
                    'منتقد صریح و رک',
                    'الهام‌بخش و انگیزشی',
                  ].map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(strings.tr(t)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateCompanionSettings(
                        settings.copyWith(tone: val),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Critique Strictness Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        strings.perStrictness,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inputLabel(color: colors.tx),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge(
                      variant: AppBadgeVariant.info,
                      size: AppBadgeSize.sm,
                      child: Text(
                        strings.tr(_strictnessLabel(settings.critiqueStrictness)),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.critiqueStrictness,
                  min: 0.0,
                  max: 1.0,
                  divisions: 4,
                  activeColor: colors.pr,
                  onChanged: (val) {
                    notifier.updateCompanionSettings(
                      settings.copyWith(critiqueStrictness: val),
                    );
                  },
                ),

                AppDropdown<String>(
                  label: strings.perRespLen,
                  value: settings.responseLength,
                  items: const ['کوتاه', 'متوسط', 'مفصل'].map((len) {
                    return DropdownMenuItem(
                      value: len,
                      child: Text(strings.tr(len)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateCompanionSettings(
                        settings.copyWith(responseLength: val),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Voice & Visibility Preferences
          _SectionCard(
            colors: colors,
            icon: FontAwesomeIcons.microphone,
            title: strings.perVoiceSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdown<String>(
                  label: strings.perScopeLabel,
                  value: settings.activeScope,
                  items: const [
                    'همه بخش‌ها',
                    'فقط تندرستی و استایلیست',
                    'خاموش',
                  ].map((scope) {
                    return DropdownMenuItem(
                      value: scope,
                      child: Text(strings.tr(scope)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateCompanionSettings(
                        settings.copyWith(activeScope: val),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSwitchTile(
                  label: strings.perVoiceActive,
                  value: settings.voiceEnabled,
                  onChanged: (val) {
                    notifier.updateCompanionSettings(
                      settings.copyWith(voiceEnabled: val),
                    );
                  },
                ),
                if (settings.voiceEnabled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.perSpeechSpeed,
                        style: AppTypography.inputLabel(color: colors.tx),
                      ),
                      Text(
                        '${strings.formatNumber(settings.speechSpeed)}x',
                        textDirection: TextDirection.ltr,
                        style: AppTypography.cardTitle(color: colors.tx),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.speechSpeed,
                    min: 0.75,
                    max: 1.5,
                    divisions: 3,
                    activeColor: colors.pr,
                    onChanged: (val) {
                      notifier.updateCompanionSettings(
                        settings.copyWith(speechSpeed: val),
                      );
                    },
                  ),
                  AppSwitchTile(
                    label: strings.perSubtitle,
                    value: settings.subtitleEnabled,
                    onChanged: (val) {
                      notifier.updateCompanionSettings(
                        settings.copyWith(subtitleEnabled: val),
                      );
                    },
                  ),
                ],
                AppSwitchTile(
                  label: strings.perDailyTip,
                  value: settings.dailyTipEnabled,
                  onChanged: (val) {
                    notifier.updateCompanionSettings(
                      settings.copyWith(dailyTipEnabled: val),
                    );
                  },
                ),
                AppSwitchTile(
                  label: strings.perSaveHistory,
                  value: settings.saveHistory,
                  onChanged: (val) {
                    notifier.updateCompanionSettings(
                      settings.copyWith(saveHistory: val),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  text: strings.perResetBtn,
                  onPressed: () {
                    _customNameController.clear();
                    notifier.resetCompanionSettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppColors colors;
  final FaIconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.colors,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            faIcon: icon,
            title: title,
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
