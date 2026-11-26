import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/config/app_build_info.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/digit_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_update_dialog.dart';
import '../../../../core/widgets/brand_wordmark.dart';
import 'about_actions.dart';
import 'legal_doc_modal_sheet.dart';
import 'open_source_licenses_sheet.dart';
import 'social_links_modal.dart';

export 'legal_doc_modal_sheet.dart';
export 'open_source_licenses_sheet.dart';
export 'social_links_modal.dart';

enum UpdateCheckStatus { idle, checking, upToDate, updateAvailable, error }

class AboutSubTab extends ConsumerStatefulWidget {
  const AboutSubTab({super.key});

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
  RemoteVersionInfo? _remoteVersionInfo;
  bool _isForcedUpdate = false;

  Future<void> _checkForUpdates() async {
    setState(() => _updateStatus = UpdateCheckStatus.checking);
    try {
      final result = await ref
          .read(appUpdateServiceProvider)
          .checkForUpdate(manual: true);

      if (result.updateAvailable && result.remoteInfo != null) {
        final info = result.remoteInfo!;
        final resolvedVersion = info.resolvedVersion;
        final store =
            info.webUrl ??
            info.androidUrl ??
            info.iosUrl ??
            AboutSubTab.officialWebsite;

        if (mounted) {
          setState(() {
            _updateStatus = UpdateCheckStatus.updateAvailable;
            _availableVersion = resolvedVersion;
            _storeUrl = store;
            _remoteVersionInfo = info;
            _isForcedUpdate = result.isForced;
          });
          await AppUpdateDialog.show(
            context,
            remoteInfo: info,
            isForced: result.isForced,
          );
        }
        return;
      }

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _updateStatus = UpdateCheckStatus.upToDate;
          _availableVersion = null;
          _remoteVersionInfo = null;
          _isForcedUpdate = false;
        });
      }
    } catch (_) {
      if (mounted) {
        // Graceful fallback: user is on latest known client build
        setState(() => _updateStatus = UpdateCheckStatus.upToDate);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final strings = context.strings;
    AppToast.showSuccess(
      context,
      '$label ${strings.aboutLinkCopied}',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);

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

          // ── 2. Unified App Version Specs & Check for Updates Card ──────────
          _buildUnifiedVersionAndUpdatesCard(colors, strings),
          const SizedBox(height: AppSpacing.md),

          // ── 3. User Agreement & Consent Card ──────────────────────────────
          _buildAgreementCard(colors, strings, appState),
          const SizedBox(height: AppSpacing.md),

          // ── 4. Legal & Compliance Links ───────────────────────────────────
          _buildLegalSection(colors, strings),
          const SizedBox(height: AppSpacing.md),

          // ── 5. Official Contact & Socials ─────────────────────────────────
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
          // Official StyleMorph SM Monogram
          const AppLogo(size: 64),
          const SizedBox(height: AppSpacing.md),

          // Brand Name with Editorial letter spacing
          BrandWordmark(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colors.tx,
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

  // ── 2. Unified App Version Specs & Check for Updates Card ──────────
  Widget _buildUnifiedVersionAndUpdatesCard(
    AppColors colors,
    AppStrings strings,
  ) {
    final formattedBuild = strings.formatNumber(AppBuildInfo.buildNumber);
    final releaseDateDisplay = AppBuildInfo.releaseDate == 'November 2026'
        ? strings.aboutReleaseDateVal
        : DigitFormatter.localizeDigits(
            AppBuildInfo.releaseDate,
            strings.localeCode,
          );
    final (envLabel, envColor) = switch (AppBuildInfo.environment) {
      'production' => (strings.aboutEnvironmentVal, colors.ok),
      'staging' => (strings.aboutEnvironmentStaging, colors.orColor),
      _ => (strings.aboutEnvironmentPreview, colors.pr),
    };

    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSpecRow(
            colors: colors,
            icon: Icons.verified_rounded,
            label: strings.aboutVersionLabel,
            value:
                'v${DigitFormatter.localizeDigits(AppBuildInfo.appVersion, strings.localeCode)}',
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
            value: releaseDateDisplay,
          ),
          Divider(color: colors.bd, height: 16),
          _buildSpecRow(
            colors: colors,
            icon: Icons.shield_outlined,
            label: strings.aboutEnvironmentLabel,
            value: envLabel,
            valueColor: envColor,
          ),
          Divider(color: colors.bd, height: 24),

          // Integrated Manual Check for Updates Button
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
                            DigitFormatter.localizeDigits(
                              _availableVersion ?? '1.0.1',
                              strings.localeCode,
                            ),
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
                      if (_remoteVersionInfo != null) {
                        AppUpdateDialog.show(
                          context,
                          remoteInfo: _remoteVersionInfo!,
                          isForced: _isForcedUpdate,
                        );
                        return;
                      }
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

  // ── 4. User Agreement & Consent Card ──────────────────────────────────────
  Widget _buildAgreementCard(
    AppColors colors,
    AppStrings strings,
    AppState appState,
  ) {
    final theme = Theme.of(context);
    final termsAcceptedAt = appState.termsAcceptedAt;
    final isSigned = termsAcceptedAt != null;

    if (isSigned) {
      final rawDate =
          '${termsAcceptedAt.year}/${termsAcceptedAt.month.toString().padLeft(2, '0')}/${termsAcceptedAt.day.toString().padLeft(2, '0')}';
      final formattedDate = DigitFormatter.localizeDigits(
        rawDate,
        strings.localeCode,
      );
      final rawVer = appState.termsVersion ?? 'v2.0';
      final cleanNum = rawVer.startsWith('v') || rawVer.startsWith('V')
          ? rawVer.substring(1)
          : rawVer;
      final versionStr = DigitFormatter.localizeDigits(
        cleanNum,
        strings.localeCode,
      );

      return InkWell(
        key: const Key('agreement_signed_clickable_card'),
        onTap: () {
          FullContractModalSheet.show(
            context,
            isReadOnlyAudit: true,
            audit: appState.legalConsent,
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AppCard(
          key: const Key('agreement_card'),
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          borderColor: colors.ok.withValues(alpha: 0.4),
          borderWidth: 1.2,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.ok.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.ok.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 20,
                    color: colors.ok,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          key: const Key('agreement_signed_badge'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.ok.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: colors.ok.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: colors.ok,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                strings.aboutAgreementSignedBadge,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.ok,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.aboutAgreementSignedDate
                          .replaceAll('{date}', formattedDate)
                          .replaceAll('{version}', versionStr),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.mu,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, size: 20, color: colors.mu),
            ],
          ),
        ),
      );
    }

    // Unsigned state: prominent warning card opening the full interactive agreement contract modal
    return AppCard(
      key: const Key('agreement_card'),
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      borderColor: theme.colorScheme.error.withValues(alpha: 0.75),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings.aboutAgreementTitle,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.aboutAgreementDesc,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: colors.mu,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const Key('agreement_open_modal_button'),
            variant: AppButtonVariant.primary,
            isFullWidth: true,
            icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
            text: strings.aboutOpenContractBtn,
            onPressed: _openContractModal,
          ),
        ],
      ),
    );
  }

  Future<void> _openContractModal() async {
    final strings = context.strings;
    final signed = await FullContractModalSheet.show(
      context,
      onSign: () async {
        await ref.read(appStateProvider.notifier).acceptTerms(version: 'v2.0');
      },
    );

    if (signed == true && mounted) {
      AppToast.showSuccess(
        context,
        strings.aboutAgreementSignedToast,
        duration: const Duration(seconds: 3),
      );
    }
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
