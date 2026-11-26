import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/presentation/widgets/about_actions.dart';
import '../config/app_build_info.dart';
import '../localization/app_strings.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/digit_formatter.dart';
import 'app_badge.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Modal dialog presenting an optional or forced application update with
/// release notes, live Android APK download progress, and Web reload support.
class AppUpdateDialog extends ConsumerStatefulWidget {
  final RemoteVersionInfo remoteInfo;
  final bool isForced;
  final String? currentVersionOverride;
  final Future<void> Function(
    String url, {
    required void Function(double progress) onProgress,
  })?
  onDownloadAndInstall;
  final VoidCallback? onWebReload;
  final void Function(String url)? onOpenExternalUrl;

  const AppUpdateDialog({
    super.key,
    required this.remoteInfo,
    required this.isForced,
    this.currentVersionOverride,
    this.onDownloadAndInstall,
    this.onWebReload,
    this.onOpenExternalUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required RemoteVersionInfo remoteInfo,
    required bool isForced,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isForced,
      builder: (_) =>
          AppUpdateDialog(remoteInfo: remoteInfo, isForced: isForced),
    );
  }

  @override
  ConsumerState<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends ConsumerState<AppUpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _errorMessage;

  Future<void> _startAndroidDownload(String url) async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      final downloader =
          widget.onDownloadAndInstall ??
          ref.read(appUpdateServiceProvider).downloadAndInstallApk;
      await downloader(
        url,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = context.strings.updateDialogError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final currentVersion =
        widget.currentVersionOverride ?? AppBuildInfo.appVersion;
    final currentVerDisplay =
        'v${DigitFormatter.localizeDigits(currentVersion, strings.localeCode)}';
    final newVerDisplay =
        'v${DigitFormatter.localizeDigits(widget.remoteInfo.resolvedVersion, strings.localeCode)}';
    final isAndroidApk =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (widget.remoteInfo.androidUrl?.isNotEmpty ?? false);
    final releaseNotes = widget.remoteInfo.releaseNotes?.trim() ?? '';

    return PopScope(
      canPop: !widget.isForced,
      child: Dialog(
        backgroundColor: colors.sf,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rCard,
          side: BorderSide(color: colors.bd),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (widget.isForced ? colors.wn : colors.pr)
                            .withValues(alpha: 0.12),
                        borderRadius: AppRadius.rMd,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.isForced
                            ? Icons.security_update_warning_rounded
                            : Icons.system_update_rounded,
                        size: 20,
                        color: widget.isForced ? colors.wn : colors.pr,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.isForced
                            ? strings.updateDialogForcedTitle
                            : strings.updateDialogTitle,
                        style: AppTypography.cardTitle(color: colors.tx),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Version comparison badges
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppBadge(
                      variant: AppBadgeVariant.standard,
                      child: Text(
                        '${strings.updateDialogCurrentLabel}: $currentVerDisplay',
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: colors.mu,
                    ),
                    AppBadge(
                      variant: widget.isForced
                          ? AppBadgeVariant.warning
                          : AppBadgeVariant.active,
                      child: Text(
                        '${strings.updateDialogNewLabel}: $newVerDisplay',
                      ),
                    ),
                  ],
                ),

                if (widget.isForced) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    strings.updateDialogForcedDesc,
                    style: AppTypography.bodySmall(color: colors.mu),
                  ),
                ],

                if (releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    variant: AppCardVariant.subtle,
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.updateDialogReleaseNotesTitle,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.tx,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 140),
                          child: SingleChildScrollView(
                            child: Text(
                              releaseNotes,
                              style: AppTypography.bodySmall(color: colors.mu),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_isDownloading) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: AppRadius.rFull,
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      minHeight: 6,
                      color: colors.pr,
                      backgroundColor: colors.bd,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _progress >= 1.0
                            ? strings.updateDialogInstalling
                            : strings.updateDialogDownloading,
                        style: AppTypography.caption(color: colors.mu),
                      ),
                      Text(
                        DigitFormatter.localizeDigits(
                          '${(_progress * 100).round()}%',
                          strings.localeCode,
                        ),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.pr,
                        ),
                      ),
                    ],
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.wnb,
                      borderRadius: AppRadius.rMd,
                      border: Border.all(
                        color: colors.wn.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.caption(color: colors.wn),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    if (!widget.isForced && !_isDownloading) ...[
                      Expanded(
                        child: AppButton(
                          variant: AppButtonVariant.ghost,
                          text: strings.updateDialogLaterBtn,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: AppButton(
                        variant: AppButtonVariant.primary,
                        text: kIsWeb
                            ? strings.updateDialogWebReloadBtn
                            : (isAndroidApk
                                  ? (_errorMessage != null
                                        ? strings.updateDialogRetryBtn
                                        : strings
                                              .updateDialogDownloadInstallBtn)
                                  : strings.updateDialogStoreBtn),
                        onPressed: _isDownloading
                            ? null
                            : () {
                                if (kIsWeb) {
                                  (widget.onWebReload ?? reloadAppWindow)();
                                  return;
                                }
                                if (isAndroidApk) {
                                  _startAndroidDownload(
                                    widget.remoteInfo.androidUrl!,
                                  );
                                  return;
                                }
                                final fallbackUrl =
                                    widget.remoteInfo.iosUrl ??
                                    widget.remoteInfo.androidUrl ??
                                    widget.remoteInfo.webUrl;
                                if (fallbackUrl != null &&
                                    fallbackUrl.isNotEmpty) {
                                  (widget.onOpenExternalUrl ?? openExternalUrl)(
                                    fallbackUrl,
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
