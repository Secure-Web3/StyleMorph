import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../auth/presentation/auth_provider.dart';

class SettingsSubTab extends ConsumerStatefulWidget {
  const SettingsSubTab({super.key});

  @override
  ConsumerState<SettingsSubTab> createState() => _SettingsSubTabState();
}

class _SettingsSubTabState extends ConsumerState<SettingsSubTab> {
  String _backupFrequency = 'weekly';
  bool _biometricLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _backupFrequency = ref.read(appStateProvider).preferences.autoDataBackup;
    _loadBiometricPref();
  }

  Future<void> _loadBiometricPref() async {
    final enabled =
        await ref.read(biometricServiceProvider).isBiometricLockEnabled();
    final prefBiometric =
        ref.read(appStateProvider).preferences.biometricLock;
    if (mounted) {
      setState(() => _biometricLockEnabled = enabled || prefBiometric);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (kIsWeb) return;
    final service = ref.read(biometricServiceProvider);
    final strings = context.strings;

    if (value) {
      // Immediately prompt biometric authentication once before saving
      final success = await service.authenticate(
        localizedReason: strings.setBiometricAuthReason,
      );
      if (success && mounted) {
        await service.setBiometricLockEnabled(true);
        ref.read(appStateProvider.notifier).setBiometricLock(true);
        ref.invalidate(biometricLockEnabledProvider);
        setState(() => _biometricLockEnabled = true);
      }
    } else {
      await service.setBiometricLockEnabled(false);
      ref.read(appStateProvider.notifier).setBiometricLock(false);
      ref.invalidate(biometricLockEnabledProvider);
      setState(() => _biometricLockEnabled = false);
    }
  }

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
                ref.read(appStateProvider.notifier).setFashionThemePalette(palette.name);
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
                ref.read(appStateProvider.notifier).setBrightnessMode(mode.name);
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
                ref.read(appStateProvider.notifier).setAppLanguage(code);
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
                Divider(height: 1, color: colors.bd),
                AppSwitchTile(
                  label: strings.setShowEmailInHeader,
                  value: appState.preferences.showEmailInHeader,
                  onChanged: (val) {
                    ref
                        .read(appStateProvider.notifier)
                        .toggleShowEmailInHeader(val);
                    ref.read(appStateProvider.notifier).markProfileDirty();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 5. Security & Biometric Section (Fingerprint / Face ID)
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                AppSwitchTile(
                  label: strings.setBiometricTitle,
                  subtitle: kIsWeb
                      ? strings.setBiometricMobileOnly
                      : strings.setBiometricDesc,
                  value: kIsWeb ? false : _biometricLockEnabled,
                  onChanged: (val) {
                    if (!kIsWeb) {
                      _toggleBiometric(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 6. Backup Period
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
                ref.read(appStateProvider.notifier).setAutoDataBackup(val);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Save Changes Button (Persist to users/{uid}.preferences in Firestore)
          AppButton(
            variant: AppButtonVariant.primary,
            isFullWidth: true,
            icon: appState.isSavingProfile
                ? null
                : FaIcon(
                    FontAwesomeIcons.floppyDisk,
                    size: 14,
                    color: colors.prt,
                  ),
            text: appState.isSavingProfile ? null : strings.saveChanges,
            onPressed: appState.isSavingProfile
                ? null
                : () async {
                    final success = await ref
                        .read(appStateProvider.notifier)
                        .saveProfileToFirestore();
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.profileSavedToast,
                            style: const TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                          backgroundColor: colors.ok,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.profileSaveErrorToast,
                            style: const TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                          backgroundColor: colors.orColor,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            child: appState.isSavingProfile
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.prt,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),

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
            onPressed: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (_) {}
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              ref.read(appStateProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
