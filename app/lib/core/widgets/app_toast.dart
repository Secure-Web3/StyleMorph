import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppToastType { success, warning, error, info }

/// Unified, centralized semantic floating capsule toast notification.
class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final colors = context.colors;

    final Color borderColor;
    final Color iconColor;
    final Color iconBgColor;
    final IconData iconData;

    switch (type) {
      case AppToastType.success:
        borderColor = colors.ok.withValues(alpha: 0.6);
        iconColor = colors.ok;
        iconBgColor = colors.okb;
        iconData = Icons.check_circle_rounded;
        break;
      case AppToastType.warning:
        borderColor = colors.wn.withValues(alpha: 0.6);
        iconColor = colors.wn;
        iconBgColor = colors.wnb;
        iconData = Icons.warning_amber_rounded;
        break;
      case AppToastType.error:
        borderColor = colors.orColor.withValues(alpha: 0.6);
        iconColor = colors.orColor;
        iconBgColor = colors.orb;
        iconData = Icons.error_outline_rounded;
        break;
      case AppToastType.info:
        borderColor = colors.inColor.withValues(alpha: 0.6);
        iconColor = colors.inColor;
        iconBgColor = colors.inb;
        iconData = Icons.info_outline_rounded;
        break;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.sf,
        elevation: 4,
        margin: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rFull,
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        content: Row(
          key: const Key('app_toast_capsule'),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 16, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall(color: colors.tx).copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Vazirmatn',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: duration,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) => show(context, message, type: AppToastType.success, duration: duration);

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) => show(context, message, type: AppToastType.warning, duration: duration);

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) => show(context, message, type: AppToastType.error, duration: duration);

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) => show(context, message, type: AppToastType.info, duration: duration);
}
