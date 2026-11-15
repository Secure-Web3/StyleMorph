import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppBadgeVariant {
  standard,
  active,
  warning,
  success,
  info,
  destructive,
}

enum AppBadgeSize {
  sm,
  md,
}

class AppBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final EdgeInsetsDirectional? padding;
  final BorderRadius? borderRadius;

  const AppBadge({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppBadgeVariant.standard,
    this.size = AppBadgeSize.md,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color bg;
    Color border;
    Color fg;

    switch (variant) {
      case AppBadgeVariant.active:
        bg = colors.pr;
        border = colors.pr;
        fg = colors.prt;
        break;
      case AppBadgeVariant.warning:
        bg = colors.wnb;
        border = colors.wn.withValues(alpha: 0.3);
        fg = colors.wn;
        break;
      case AppBadgeVariant.success:
        bg = colors.okb;
        border = colors.ok.withValues(alpha: 0.35);
        fg = colors.ok;
        break;
      case AppBadgeVariant.info:
        bg = colors.inb;
        border = colors.inColor.withValues(alpha: 0.35);
        fg = colors.inColor;
        break;
      case AppBadgeVariant.destructive:
        bg = colors.orb;
        border = colors.orColor.withValues(alpha: 0.35);
        fg = colors.orColor;
        break;
      case AppBadgeVariant.standard:
        bg = colors.sf;
        border = colors.bd;
        fg = colors.tx;
        break;
    }

    final resolvedPadding = padding ??
        (size == AppBadgeSize.sm
            ? const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              )
            : const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ));

    final resolvedFontSize = size == AppBadgeSize.sm ? 10.0 : 11.0;
    final resolvedIconSize = size == AppBadgeSize.sm ? 11.0 : 13.0;
    final resolvedRadius = borderRadius ?? AppRadius.rFull;

    final content = Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: resolvedRadius,
        border: Border.all(color: border, width: 1.0),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: resolvedFontSize,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1.2,
        ),
        child: IconTheme(
          data: IconThemeData(size: resolvedIconSize, color: fg),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: resolvedRadius,
        child: content,
      );
    }
    return content;
  }
}
