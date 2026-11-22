import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(localeProvider);

    // Drawer width: min(288, 84% of screen width).
    final drawerWidth = (MediaQuery.of(context).size.width * 0.84).clamp(
      0.0,
      288.0,
    );

    return Drawer(
      width: drawerWidth,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: Logo + App name ──────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xl,
                end: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  const AppLogo(size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      strings.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colors.tx,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.bd),

            // ── Menu Items ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  _DrawerItem(
                    icon: FontAwesomeIcons.solidUser,
                    title: strings.nProf,
                    trailing: Consumer(
                      builder: (context, ref, _) {
                        final progress = ref.watch(
                          appStateProvider.select((s) => s.profileProgress),
                        );
                        return Text(
                          strings.formatPercent((progress * 100).round()),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.mu,
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(appStateProvider.notifier)
                          .switchProfileTab('p-identity');
                    },
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.wallet,
                    title: strings.tWal,
                    badgeText: strings.commonComingSoon,
                    enabled: false,
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.gift,
                    title: strings.tRef,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(appStateProvider.notifier)
                          .switchProfileTab('p-referral');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Divider(height: 1, color: colors.bd),
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.clockRotateLeft,
                    title: strings.mHist,
                    badgeText: strings.soon,
                    enabled: false,
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.bookmark,
                    title: strings.mSaved,
                    badgeText: strings.soon,
                    enabled: false,
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.bagShopping,
                    title: strings.mOrders,
                    badgeText: strings.soon,
                    enabled: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Divider(height: 1, color: colors.bd),
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.sliders,
                    title: strings.tSet,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(appStateProvider.notifier)
                          .switchProfileTab('p-settings');
                    },
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.circleInfo,
                    title: strings.tAbout,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(appStateProvider.notifier)
                          .switchProfileTab('p-about');
                    },
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.wandMagicSparkles,
                    title: strings.tComp,
                    badgeText: strings.commonComingSoon,
                    enabled: false,
                  ),
                  _DrawerItem(
                    icon: FontAwesomeIcons.headset,
                    title: strings.mSupport,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(appStateProvider.notifier).toggleSupport(true);
                    },
                  ),
                ],
              ),
            ),

            // ── Footer: Palettes / Dark / Language / Sign-out ────────────
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.bd)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Quick-Access Mode Switcher Pill (Simple / Advanced) ──
                  const _DrawerModeSwitcher(),

                  // Row: palette dots + 3-mode brightness toggle + language
                  Row(
                    children: [
                      // 5 palette color dots
                      _PaletteDot(
                        palette: AppPalette.white,
                        color: const Color(0xFFFFFFFF),
                        isSelected: themeState.palette == AppPalette.white,
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setPalette(AppPalette.white),
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.beige,
                        color: const Color(0xFFD9C3A5),
                        isSelected: themeState.palette == AppPalette.beige,
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setPalette(AppPalette.beige),
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.slate,
                        color: const Color(0xFF4A5056),
                        isSelected: themeState.palette == AppPalette.slate,
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setPalette(AppPalette.slate),
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.obsidian,
                        color: const Color(0xFF111111),
                        isSelected: themeState.palette == AppPalette.obsidian,
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setPalette(AppPalette.obsidian),
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.editorial,
                        color: const Color(0xFF8C6D46),
                        isSelected: themeState.palette == AppPalette.editorial,
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setPalette(AppPalette.editorial),
                      ),
                      const Spacer(),
                      // 3-state brightness cycle: Light -> Dark -> System Auto
                      Tooltip(
                        message: themeState.mode == ThemeMode.light
                            ? strings.drawerThemeLightTip
                            : themeState.mode == ThemeMode.dark
                            ? strings.drawerThemeDarkTip
                            : strings.drawerThemeSystemTip,
                        child: InkWell(
                          onTap: () =>
                              ref.read(themeProvider.notifier).cycleThemeMode(),
                          borderRadius: AppRadius.rFull,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeState.mode != ThemeMode.light
                                  ? colors.pr.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: Border.all(
                                color: themeState.mode == ThemeMode.system
                                    ? colors.pr
                                    : colors.bd,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                themeState.mode == ThemeMode.light
                                    ? Icons.light_mode_rounded
                                    : themeState.mode == ThemeMode.dark
                                    ? Icons.dark_mode_rounded
                                    : Icons.brightness_auto_rounded,
                                size: 14,
                                color: themeState.mode == ThemeMode.system
                                    ? colors.pr
                                    : colors.tx,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Language selector
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.bg,
                            borderRadius: AppRadius.rFull,
                            border: Border.all(color: colors.bd),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentLang.code,
                              isDense: true,
                              isExpanded: true,
                              dropdownColor: colors.sf,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                size: 14,
                                color: colors.mu,
                              ),
                              items: AppLanguage.supportedLanguages.map((lang) {
                                return DropdownMenuItem<String>(
                                  value: lang.code,
                                  child: Text(
                                    lang.nativeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.tx,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (code) {
                                if (code != null) {
                                  ref
                                      .read(localeProvider.notifier)
                                      .setLanguage(code);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Sign-out button
                  InkWell(
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        await ref.read(authRepositoryProvider).signOut();
                      } catch (_) {}
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (_) {}
                      ref.read(appStateProvider.notifier).logout();
                    },
                    borderRadius: AppRadius.rMd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.rightFromBracket,
                            size: 15,
                            color: colors.orColor,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            strings.mOut,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.orColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick-Access Mode Switcher Pill ──────────────────────────────────────────

class _DrawerModeSwitcher extends ConsumerWidget {
  const _DrawerModeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final (isSimpleMode, isAdvancedMode) = ref.watch(
      appStateProvider.select((s) => (s.isSimpleMode, s.isAdvancedMode)),
    );

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.rFull,
        border: Border.all(color: colors.bd),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                ref
                    .read(appStateProvider.notifier)
                    .setAppMode('simple', persistImmediately: true);
              },
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isSimpleMode ? colors.pr : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: isSimpleMode ? colors.prt : colors.mu,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        strings.appModeSimple,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          fontWeight: isSimpleMode
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSimpleMode ? colors.prt : colors.mu,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                ref
                    .read(appStateProvider.notifier)
                    .setAppMode('advanced', persistImmediately: true);
              },
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isAdvancedMode ? colors.pr : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 13,
                      color: isAdvancedMode ? colors.prt : colors.mu,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        strings.appModeAdvanced,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          fontWeight: isAdvancedMode
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isAdvancedMode ? colors.prt : colors.mu,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Menu Item ──────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final Widget? trailing;
  final String? badgeText;
  final VoidCallback? onTap;
  final bool enabled;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.badgeText,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.rMd,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: FaIcon(icon, size: 15, color: colors.mu),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.tx,
                  ),
                ),
              ),
              ?trailing,
              if (badgeText != null)
                AppBadge(size: AppBadgeSize.sm, child: Text(badgeText!)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Palette Color Dot ─────────────────────────────────────────────────────────

class _PaletteDot extends StatelessWidget {
  final AppPalette palette;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteDot({
    required this.palette,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.pr : colors.bd,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.pr.withValues(alpha: 0.35),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
