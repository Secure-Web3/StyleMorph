import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'shad_theme_scope.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
}

enum AppButtonSize {
  sm,
  md,
}

class AppButton extends StatelessWidget {
  final Widget? child;
  final String? text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isFullWidth;
  final EdgeInsetsDirectional? padding;
  final double? height;

  const AppButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isFullWidth = false,
    this.padding,
    this.height,
  }) : assert(
          child != null || text != null,
          'Either child or text must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEnabled = onPressed != null;

    final resolvedHeight = height ?? (size == AppButtonSize.sm ? 36.0 : 44.0);
    final resolvedRadius =
        size == AppButtonSize.sm ? AppRadius.rLg : AppRadius.rXl;
    final resolvedFontSize = size == AppButtonSize.sm ? 12.0 : 13.0;
    final resolvedHorizontalPad =
        size == AppButtonSize.sm ? AppSpacing.md : AppSpacing.lg;

    Color bg;
    Color fg;
    BorderSide borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isEnabled ? colors.pr : colors.bd.withValues(alpha: 0.65);
        fg = isEnabled ? colors.prt : colors.mu;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        bg = colors.sf;
        fg = isEnabled ? colors.tx : colors.mu;
        borderSide = BorderSide(color: colors.bd);
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = isEnabled ? colors.tx : colors.mu;
        borderSide = BorderSide(color: colors.bd);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isEnabled ? colors.tx : colors.mu;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.destructive:
        bg = colors.orColor.withValues(alpha: 0.08);
        fg = colors.orColor;
        borderSide = BorderSide(color: colors.orColor.withValues(alpha: 0.45));
        break;
    }

    final labelWidget = child ??
        Text(
          text!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.buttonLabel(
            color: fg,
            fontSize: resolvedFontSize,
          ),
        );

    final content = IconTheme(
      data: IconThemeData(size: size == AppButtonSize.sm ? 14 : 16, color: fg),
      child: DefaultTextStyle(
        style: AppTypography.buttonLabel(
          color: fg,
          fontSize: resolvedFontSize,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(child: labelWidget),
          ],
        ),
      ),
    );

    final button = SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: resolvedHeight,
      child: ShadButton.raw(
        onPressed: onPressed,
        enabled: isEnabled,
        expands: isFullWidth,
        variant: ShadButtonVariant.primary,
        width: isFullWidth ? double.infinity : null,
        height: resolvedHeight,
        backgroundColor: bg,
        hoverBackgroundColor: bg.withValues(alpha: 0.92),
        foregroundColor: fg,
        hoverForegroundColor: fg,
        decoration: ShadDecoration(
          border: borderSide != BorderSide.none
              ? ShadBorder.all(
                  color: borderSide.color,
                  width: borderSide.width,
                  radius: resolvedRadius,
                )
              : ShadBorder.none.copyWith(radius: resolvedRadius),
        ),
        padding: padding != null
            ? EdgeInsetsDirectional.only(
                start: padding!.start,
                end: padding!.end,
                top: padding!.top,
                bottom: padding!.bottom,
              )
            : EdgeInsets.symmetric(
                horizontal: resolvedHorizontalPad,
                vertical: 0,
              ),
        child: content,
      ),
    );

    return ensureShadTheme(context, button);
  }
}
