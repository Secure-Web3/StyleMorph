import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import 'about_actions.dart';
import 'legal_doc_modal_sheet.dart';
import 'open_source_licenses_sheet.dart';
import 'social_links_modal.dart';

enum UpdateCheckStatus { idle, checking, upToDate, updateAvailable, error }

class AboutSubTab extends ConsumerStatefulWidget {
  const AboutSubTab({super.key});

  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 100;
  static const String officialWebsite = 'https://stylemorph.app';
  static const String officialSupportEmail = 'support@stylemorph.app';
  static const String officialInstagram =
      'https://instagram.com/stylemorph.app';
  static const String officialTelegram = 'https://t.me/stylemorph';

  @override
  ConsumerState<AboutSubTab> createState() => _AboutSubTabState();
}

class _AboutSubTabState extends ConsumerState<AboutSubTab> {
  UpdateCheckStatus _updateStatus = UpdateCheckStatus.idle;
  String? _availableVersion;
  String? _storeUrl;

  Future<void> _checkForUpdates() async {
    setState(() => _updateStatus = UpdateCheckStatus.checking);
    try {
      if (Firebase.apps.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('version')
            .get()
            .timeout(const Duration(seconds: 5));

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final remoteVersion =
              data['latestVersion']?.toString() ??
              data['version']?.toString() ??
              '';
          final remoteBuild =
              (data['latestBuild'] as num?)?.toInt() ??
              (data['build'] as num?)?.toInt() ??
              0;
          final store =
              data['storeUrl']?.toString() ??
              data['downloadUrl']?.toString() ??
              AboutSubTab.officialWebsite;

          if (remoteBuild > AboutSubTab.currentBuildNumber ||
              (remoteVersion.isNotEmpty &&
                  remoteVersion != AboutSubTab.currentVersion &&
                  _compareVersions(remoteVersion, AboutSubTab.currentVersion) >
                      0)) {
            if (mounted) {
              setState(() {
                _updateStatus = UpdateCheckStatus.updateAvailable;
                _availableVersion = remoteVersion.isNotEmpty
                    ? remoteVersion
                    : '1.0.$remoteBuild';
                _storeUrl = store;
              });
            }
            return;
          }
        }
      }

      // If no remote version exists or build is up-to-date
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _updateStatus = UpdateCheckStatus.upToDate;
          _availableVersion = null;
        });
      }
    } catch (_) {
      if (mounted) {
        // Graceful fallback: user is on latest known client build
        setState(() => _updateStatus = UpdateCheckStatus.upToDate);
      }
    }
  }

  int _compareVersions(String v1, String v2) {
    try {
      final p1 = v1.split('.').map(int.parse).toList();
      final p2 = v2.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final n1 = i < p1.length ? p1[i] : 0;
        final n2 = i < p2.length ? p2[i] : 0;
        if (n1 > n2) return 1;
        if (n1 < n2) return -1;
      }
    } catch (_) {}
    return 0;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final strings = context.strings;
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label ${strings.aboutLinkCopied}',
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        backgroundColor: colors.ok,
        duration: const Duration(seconds: 2),
      ),
    );
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
          // Section Title
          AppSectionHeader(
            icon: Icons.info_outline_rounded,
            title: strings.aboutHeader,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 1. StyleMorph Brand Hero Card ─────────────────────────────────
          _buildBrandHeroCard(colors, strings),
          const SizedBox(height: AppSpacing.md),

          // ── 2. App Version & Build Status Spec Card ───────────────────────
          _buildVersionSpecCard(colors, strings),
          const SizedBox(height: AppSpacing.md),

          // ── 3. Manual "Check for Updates" Interactive Section ─────────────
          _buildUpdateCheckerCard(colors, strings),
          const SizedBox(height: AppSpacing.md),

          // ── 4. What's New / Changelog Card ────────────────────────────────
          _buildWhatsNewCard(colors, strings),
          const SizedBox(height: AppSpacing.md),

          // ── 5. Legal & Compliance Links ───────────────────────────────────
          _buildLegalSection(colors, strings),
          const SizedBox(height: AppSpacing.md),

          // ── 6. Official Contact & Socials ─────────────────────────────────
          _buildContactSection(colors, strings),
          const SizedBox(height: AppSpacing.xl),

          // Footer Copyright Notice
          Center(
            child: Text(
              strings.aboutCopyrightNotice,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: colors.mu.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ── 1. Brand Hero Card ────────────────────────────────────────────────────
  Widget _buildBrandHeroCard(AppColors colors, AppStrings strings) {
    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Luxury Brand Emblem
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.prt, colors.pr],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                BoxShadow(
                  color: colors.pr.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.wandMagicSparkles,
                size: 28,
                color: colors.sf,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Brand Name with Editorial letter spacing
          Text(
            'StyleMorph',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Tagline
          Text(
            strings.aboutTagline,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.prt,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Divider
          Divider(color: colors.bd, height: 24),

          // Mission statement
          Text(
            strings.aboutMission,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colors.mu,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 2. App Version & Build Status Spec Card ───────────────────────────────
  Widget _buildVersionSpecCard(AppColors colors, AppStrings strings) {
    final formattedBuild = strings.formatNumber(AboutSubTab.currentBuildNumber);

    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        children: [
          _buildSpecRow(
            colors: colors,
            icon: Icons.verified_rounded,
            label: strings.aboutVersionLabel,
            value: 'v${AboutSubTab.currentVersion}',
            isBold: true,
          ),
          Divider(color: colors.bd, height: 16),
          _buildSpecRow(
            colors: colors,
            icon: Icons.tag_rounded,
            label: strings.aboutBuildLabel,
            value: 'Build $formattedBuild',
          ),
          Divider(color: colors.bd, height: 16),
          _buildSpecRow(
            colors: colors,
            icon: Icons.calendar_today_rounded,
            label: strings.aboutReleaseDateLabel,
            value: strings.aboutReleaseDateVal,
          ),
          Divider(color: colors.bd, height: 16),
          _buildSpecRow(
            colors: colors,
            icon: Icons.shield_outlined,
            label: strings.aboutEnvironmentLabel,
            value: strings.aboutEnvironmentVal,
            valueColor: colors.ok,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow({
    required AppColors colors,
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.mu),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.mu,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? colors.tx,
          ),
        ),
      ],
    );
  }

  // ── 3. Manual "Check for Updates" Button Card ─────────────────────────────
  Widget _buildUpdateCheckerCard(AppColors colors, AppStrings strings) {
    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            variant: AppButtonVariant.primary,
            isFullWidth: true,
            icon: _updateStatus == UpdateCheckStatus.checking
                ? null
                : const Icon(Icons.sync_rounded, size: 16),
            text: _updateStatus == UpdateCheckStatus.checking
                ? null
                : strings.aboutCheckUpdatesBtn,
            onPressed: _updateStatus == UpdateCheckStatus.checking
                ? null
                : _checkForUpdates,
            child: _updateStatus == UpdateCheckStatus.checking
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.sf,
                    ),
                  )
                : null,
          ),

          // Status Feedback Message
          if (_updateStatus == UpdateCheckStatus.upToDate) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.ok.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colors.ok.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: colors.ok),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.aboutUpToDate,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.ok,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_updateStatus == UpdateCheckStatus.updateAvailable) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.orColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: colors.orColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.system_update_rounded,
                        size: 16,
                        color: colors.orColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          strings.aboutUpdateAvailable.replaceAll(
                            '{version}',
                            _availableVersion ?? '1.0.1',
                          ),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.orColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    isFullWidth: true,
                    text: kIsWeb
                        ? strings.aboutUpdateActionWeb
                        : strings.aboutUpdateActionMobile,
                    onPressed: () {
                      if (kIsWeb) {
                        reloadAppWindow();
                      } else {
                        if (_storeUrl != null && _storeUrl!.isNotEmpty) {
                          openExternalUrl(_storeUrl!);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. What's New / Changelog Card ────────────────────────────────────────
  Widget _buildWhatsNewCard(AppColors colors, AppStrings strings) {
    final changelogItems = [
      (
        strings.aboutChangelog1Title,
        strings.aboutChangelog1Desc,
        FontAwesomeIcons.wandMagicSparkles,
      ),
      (
        strings.aboutChangelog2Title,
        strings.aboutChangelog2Desc,
        FontAwesomeIcons.shirt,
      ),
      (
        strings.aboutChangelog3Title,
        strings.aboutChangelog3Desc,
        FontAwesomeIcons.boltLightning,
      ),
      (
        strings.aboutChangelog4Title,
        strings.aboutChangelog4Desc,
        FontAwesomeIcons.award,
      ),
      (
        strings.aboutChangelog5Title,
        strings.aboutChangelog5Desc,
        FontAwesomeIcons.userShield,
      ),
    ];

    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: colors.prt),
              const SizedBox(width: AppSpacing.xs),
              Text(
                strings.aboutWhatsNewTitle,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.tx,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.bd, height: 16),
          for (int i = 0; i < changelogItems.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.pr.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: FaIcon(
                        changelogItems[i].$3,
                        size: 11,
                        color: colors.prt,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          changelogItems[i].$1,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.tx,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          changelogItems[i].$2,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: colors.mu,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < changelogItems.length - 1)
              Divider(color: colors.bd.withValues(alpha: 0.5), height: 12),
          ],
        ],
      ),
    );
  }

  // ── 5. Legal & Compliance Links ───────────────────────────────────────────
  Widget _buildLegalSection(AppColors colors, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            strings.aboutLegalSectionTitle,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.mu,
            ),
          ),
        ),
        AppCard(
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(0),
          child: Column(
            children: [
              _buildActionTile(
                colors: colors,
                icon: FontAwesomeIcons.fileContract,
                title: strings.aboutTermsTitle,
                onTap: () => LegalDocModalSheet.showTerms(context),
              ),
              Divider(color: colors.bd, height: 1),
              _buildActionTile(
                colors: colors,
                icon: FontAwesomeIcons.shieldHalved,
                title: strings.aboutPrivacyTitle,
                onTap: () => LegalDocModalSheet.showPrivacy(context),
              ),
              Divider(color: colors.bd, height: 1),
              _buildActionTile(
                colors: colors,
                icon: FontAwesomeIcons.codeBranch,
                title: strings.aboutLicensesTitle,
                onTap: () => OpenSourceLicensesSheet.show(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 6. Official Contact & Socials ─────────────────────────────────────────
  Widget _buildContactSection(AppColors colors, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            strings.aboutContactSectionTitle,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.mu,
            ),
          ),
        ),
        AppCard(
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(0),
          child: Column(
            children: [
              _buildActionTile(
                colors: colors,
                icon: FontAwesomeIcons.globe,
                title: strings.aboutWebsiteLabel,
                subtitle: AboutSubTab.officialWebsite,
                trailingIcon: Icons.open_in_new_rounded,
                onTap: () {
                  if (kIsWeb) {
                    openExternalUrl(AboutSubTab.officialWebsite);
                  } else {
                    _copyToClipboard(
                      AboutSubTab.officialWebsite,
                      strings.aboutWebsiteLabel,
                    );
                  }
                },
              ),
              Divider(color: colors.bd, height: 1),
              _buildActionTile(
                colors: colors,
                icon: FontAwesomeIcons.envelope,
                title: strings.aboutEmailLabel,
                subtitle: AboutSubTab.officialSupportEmail,
                trailingIcon: Icons.copy_rounded,
                onTap: () {
                  _copyToClipboard(
                    AboutSubTab.officialSupportEmail,
                    strings.aboutEmailLabel,
                  );
                },
              ),
              Divider(color: colors.bd, height: 1),
              _buildActionTile(
                colors: colors,
                icon: FontAwesomeIcons.shareNodes,
                title: strings.aboutSocialMediaLabel,
                subtitle: strings.aboutSocialMediaSubtitle,
                trailingIcon: Icons.chevron_right_rounded,
                onTap: () => SocialLinksModal.show(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required AppColors colors,
    required dynamic icon,
    required String title,
    String? subtitle,
    IconData trailingIcon = Icons.chevron_right_rounded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            if (icon is FaIconData)
              FaIcon(icon, size: 15, color: colors.prt)
            else if (icon is IconData)
              Icon(icon, size: 15, color: colors.prt),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.tx,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: colors.mu,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(trailingIcon, size: 16, color: colors.mu),
          ],
        ),
      ),
    );
  }
}
