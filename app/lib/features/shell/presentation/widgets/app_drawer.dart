import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/loyalty_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_media_image.dart';
import '../../../../core/widgets/brand_wordmark.dart';
import '../../../../core/widgets/gender_3d_avatar.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/email_verification_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(localeProvider);

    // Drawer width: min(296, 84% of screen width).
    final drawerWidth = (MediaQuery.of(context).size.width * 0.84).clamp(
      0.0,
      296.0,
    );

    return Drawer(
      width: drawerWidth,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Zone 1: Brand Strip + Interactive Profile Identity Card ─────
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 46),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: BrandWordmark(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: colors.tx,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _DrawerProfileCard(),
                ],
              ),
            ),

            Divider(height: 1, color: colors.bd),

            // ── Zone 2: Focused, Non-Redundant Shortcuts ───────────────────
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Compact Wallet & Plan Card
                          const _DrawerWalletCard(),

                          const Spacer(),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Divider(height: 1, color: colors.bd),
                          ),

                          // App & Support Section anchored above the bottom dock
                          _DrawerSectionLabel(
                            label: strings.drawerSectionAppSupport,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
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
                            icon: FontAwesomeIcons.headset,
                            title: strings.mSupport,
                            onTap: () {
                              Navigator.of(context).pop();
                              ref
                                  .read(appStateProvider.notifier)
                                  .toggleSupport(true);
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Zone 3: Quick Control Dock (Bottom) ────────────────────────
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.bd)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _DrawerModeSwitcher(),
                  Row(
                    children: [
                      _PaletteDot(
                        palette: AppPalette.white,
                        color: const Color(0xFFFFFFFF),
                        isSelected: themeState.palette == AppPalette.white,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setPalette(AppPalette.white);
                          ref
                              .read(appStateProvider.notifier)
                              .setFashionThemePalette(
                                AppPalette.white.name,
                                persistImmediately: true,
                              );
                        },
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.beige,
                        color: const Color(0xFFD9C3A5),
                        isSelected: themeState.palette == AppPalette.beige,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setPalette(AppPalette.beige);
                          ref
                              .read(appStateProvider.notifier)
                              .setFashionThemePalette(
                                AppPalette.beige.name,
                                persistImmediately: true,
                              );
                        },
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.slate,
                        color: const Color(0xFF4A5056),
                        isSelected: themeState.palette == AppPalette.slate,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setPalette(AppPalette.slate);
                          ref
                              .read(appStateProvider.notifier)
                              .setFashionThemePalette(
                                AppPalette.slate.name,
                                persistImmediately: true,
                              );
                        },
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.obsidian,
                        color: const Color(0xFF111111),
                        isSelected: themeState.palette == AppPalette.obsidian,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setPalette(AppPalette.obsidian);
                          ref
                              .read(appStateProvider.notifier)
                              .setFashionThemePalette(
                                AppPalette.obsidian.name,
                                persistImmediately: true,
                              );
                        },
                      ),
                      const SizedBox(width: 5),
                      _PaletteDot(
                        palette: AppPalette.editorial,
                        color: const Color(0xFF8C6D46),
                        isSelected: themeState.palette == AppPalette.editorial,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setPalette(AppPalette.editorial);
                          ref
                              .read(appStateProvider.notifier)
                              .setFashionThemePalette(
                                AppPalette.editorial.name,
                                persistImmediately: true,
                              );
                        },
                      ),
                      const Spacer(),
                      Tooltip(
                        message: themeState.mode == ThemeMode.light
                            ? strings.drawerThemeLightTip
                            : themeState.mode == ThemeMode.dark
                            ? strings.drawerThemeDarkTip
                            : strings.drawerThemeSystemTip,
                        child: InkWell(
                          onTap: () {
                            final nextMode = ref
                                .read(themeProvider.notifier)
                                .cycleThemeMode();
                            ref
                                .read(appStateProvider.notifier)
                                .setBrightnessMode(
                                  nextMode.name,
                                  persistImmediately: true,
                                );
                          },
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
                                  ref
                                      .read(appStateProvider.notifier)
                                      .setAppLanguage(
                                        code,
                                        persistImmediately: true,
                                      );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    key: const Key('drawer_sign_out_button'),
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 42),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.rightFromBracket,
                              size: 14,
                              color: colors.orColor,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              strings.mOut,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.orColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 42),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Zone 1: Interactive Profile Identity Card ─────────────────────────────────

class _DrawerProfileCard extends ConsumerWidget {
  const _DrawerProfileCard();

  String _localizedRank(AppStrings strings, String rank) {
    switch (rank.toLowerCase()) {
      case 'silver':
        return strings.rankSilver;
      case 'gold':
        return strings.rankGold;
      case 'diamond':
        return strings.rankDiamond;
      default:
        return strings.rankBronze;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final colors = context.colors;
    final strings = context.strings;
    final (
      userName,
      avatarUrl,
      gender,
      identityEmail,
      isKycVerified,
      loyaltyRank,
      stylePoints,
      progress,
    ) = ref.watch(
      appStateProvider.select(
        (s) => (
          s.userName,
          s.effectiveAvatarUrl,
          s.aiDnaValues['gender'] ?? 'female',
          s.identityValues['email'] ?? '',
          s.kycData.isVerified,
          s.loyaltyRank,
          s.stylePoints,
          s.profileProgress,
        ),
      ),
    );
    final isEmailVerified = ref.watch(
      emailVerificationProvider.select((s) => s.isVerified),
    );

    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}

    final isVerified = isKycVerified || isEmailVerified;
    final displayName = userName.isNotEmpty
        ? strings.tr(userName)
        : (user?.displayName ??
              (user?.email?.split('@').first ?? strings.newUser));
    final firebaseEmail = (user?.email ?? '').trim();
    final userEmail = firebaseEmail.isNotEmpty
        ? firebaseEmail
        : identityEmail.trim();
    final rankLabel = _localizedRank(strings, loyaltyRank);
    final rankColor = LoyaltyRankExtension.fromString(loyaltyRank).color;
    final pointsText = strings.formatNumber(stylePoints);
    final percentText = strings.formatPercent((progress * 100).round());

    return Material(
      color: colors.bg,
      borderRadius: AppRadius.rLg,
      child: InkWell(
        key: const Key('drawer_profile_card'),
        onTap: () {
          Navigator.of(context).pop();
          ref.read(appStateProvider.notifier).switchProfileTab('p-identity');
        },
        borderRadius: AppRadius.rLg,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(color: colors.bd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with loyalty ring & overlapping rank pill
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 58.0,
                      maxWidth: 132.0,
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Container(
                            width: 58,
                            height: 58,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: rankColor, width: 2.0),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? AppMediaImage(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      width: 53,
                                      height: 53,
                                      errorBuilder: (_, _, _) =>
                                          Gender3dAvatar(gender: gender),
                                    )
                                  : Gender3dAvatar(gender: gender),
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 132.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.bg,
                            borderRadius: AppRadius.rFull,
                            border: Border.all(color: colors.bg, width: 1.5),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.14),
                              borderRadius: AppRadius.rFull,
                              border: Border.all(
                                color: rankColor.withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: rankColor,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '$rankLabel • $pointsText ${strings.pts}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.tx,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Name + Verified badge (line 1), Always-visible Email (line 2)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.tx,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              FaIcon(
                                FontAwesomeIcons.circleCheck,
                                size: 11,
                                color: isKycVerified
                                    ? colors.ok
                                    : colors.inColor,
                              ),
                            ],
                          ],
                        ),
                        if (userEmail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: colors.mu,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.mu),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                key: const Key('drawer_profile_progress_row'),
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.rFull,
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: colors.bd,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.pr),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    percentText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Zone 2: Compact Wallet & Plan Card ────────────────────────────────────────

class _DrawerWalletCard extends ConsumerWidget {
  const _DrawerWalletCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;

    return Material(
      color: colors.bg,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          ref.read(appStateProvider.notifier).switchProfileTab('p-wallet');
        },
        borderRadius: AppRadius.rMd,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(color: colors.bd),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colors.pr.withValues(alpha: 0.1),
                  borderRadius: AppRadius.rSm,
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.wallet,
                    size: 13,
                    color: colors.pr,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings.tWal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.tx,
                  ),
                ),
              ),
              AppBadge(
                size: AppBadgeSize.sm,
                child: Text(strings.commonComingSoon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;

  const _DrawerSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        top: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: colors.mu,
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
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
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
  final VoidCallback? onTap;

  const _DrawerItem({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rMd,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: FaIcon(icon, size: 14, color: colors.mu),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.tx,
                ),
              ),
            ),
          ],
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
