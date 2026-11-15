import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_switch.dart';

class SettingsSubTab extends ConsumerStatefulWidget {
  const SettingsSubTab({super.key});

  @override
  ConsumerState<SettingsSubTab> createState() => _SettingsSubTabState();
}

class _SettingsSubTabState extends ConsumerState<SettingsSubTab> {
  String _backupFrequency = 'weekly';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(localeProvider);
    final appState = ref.watch(appStateProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            faIcon: FontAwesomeIcons.sliders,
            title: strings.setHeader,
          ),
          const SizedBox(height: AppSpacing.md),

          // 1. Theme Palette Selector Dropdown
          AppDropdown<AppPalette>(
            label: strings.setPaletteLabel,
            value: themeState.palette,
            items: [
              DropdownMenuItem(
                value: AppPalette.white,
                child: Text(strings.palWhite),
              ),
              DropdownMenuItem(
                value: AppPalette.beige,
                child: Text(strings.palBeige),
              ),
              DropdownMenuItem(
                value: AppPalette.slate,
                child: Text(strings.palSlate),
              ),
              DropdownMenuItem(
                value: AppPalette.obsidian,
                child: Text(strings.palObsidian),
              ),
              DropdownMenuItem(
                value: AppPalette.editorial,
                child: Text(strings.palEditorial),
              ),
            ],
            onChanged: (palette) {
              if (palette != null) {
                ref.read(themeProvider.notifier).setPalette(palette);
                ref.read(appStateProvider.notifier).markProfileDirty();
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Brightness Mode Dropdown (Light / Dark / System Auto)
          AppDropdown<ThemeMode>(
            label: strings.setBrightnessLabel,
            value: themeState.mode,
            items: [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text(strings.themeLight),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text(strings.themeDark),
              ),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text(strings.themeSystem),
              ),
            ],
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeProvider.notifier).setThemeMode(mode);
                ref.read(appStateProvider.notifier).markProfileDirty();
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3. Language Selector Dropdown
          AppDropdown<String>(
            label: strings.setLangLabel,
            value: currentLang.code,
            items: AppLanguage.supportedLanguages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang.code,
                child: Text('${lang.nativeName} (${lang.code.toUpperCase()})'),
              );
            }).toList(),
            onChanged: (code) {
              if (code != null) {
                ref.read(localeProvider.notifier).setLanguage(code);
                ref.read(appStateProvider.notifier).markProfileDirty();
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Interactive Display Switches
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                AppSwitchTile(
                  label: strings.setShowSupport,
                  value: appState.showFloatingSupport,
                  onChanged: (val) {
                    ref
                        .read(appStateProvider.notifier)
                        .toggleFloatingSupport(val);
                    ref.read(appStateProvider.notifier).markProfileDirty();
                  },
                ),
                Divider(height: 1, color: colors.bd),
                AppSwitchTile(
                  label: strings.setShowHeaderCoins,
                  value: appState.showHeaderCoins,
                  onChanged: (val) {
                    ref
                        .read(appStateProvider.notifier)
                        .toggleHeaderCoins(val);
                    ref.read(appStateProvider.notifier).markProfileDirty();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 5. Backup Period
          AppDropdown<String>(
            label: strings.setBackupLabel,
            value: _backupFrequency,
            items: [
              DropdownMenuItem(
                value: 'weekly',
                child: Text(strings.setBackupWeekly),
              ),
              DropdownMenuItem(
                value: 'monthly',
                child: Text(strings.setBackupMonthly),
              ),
              DropdownMenuItem(
                value: 'off',
                child: Text(strings.setBackupOff),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _backupFrequency = val);
                ref.read(appStateProvider.notifier).markProfileDirty();
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Logout Button
          AppButton(
            variant: AppButtonVariant.destructive,
            isFullWidth: true,
            icon: FaIcon(
              FontAwesomeIcons.rightFromBracket,
              size: 14,
              color: colors.orColor,
            ),
            text: strings.setLogoutBtn,
            onPressed: () {
              ref.read(appStateProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
