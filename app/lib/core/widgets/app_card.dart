import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppCardVariant { surface, subtle }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsDirectional? padding;
  final EdgeInsetsDirectional? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final AppCardVariant variant;
  final Clip clipBehavior;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.width,
    this.height,
    this.variant = AppCardVariant.surface,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? AppRadius.rCard;
    final bg =
        backgroundColor ??
        (variant == AppCardVariant.surface ? colors.sf : colors.bg);
    final border = borderColor ?? colors.bd;

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: borderWidth),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: content),
      );
    }

    return content;
  }
}
