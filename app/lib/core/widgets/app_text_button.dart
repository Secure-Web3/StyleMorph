import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Standard Design System text button widget.
/// Used for secondary inline actions (e.g. "Forgot password?", "Sign up", "Back to Login").
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? textColor;
  final double? fontSize;
  final Widget? icon;
  final EdgeInsetsDirectional? padding;

  const AppTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.textColor,
    this.fontSize,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedColor = textColor ?? (isPrimary ? colors.pr : colors.mu);
    final resolvedFontSize = fontSize ?? 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.rSm,
        child: Padding(
          padding:
              padding ??
              const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                text,
                style: AppTypography.inputLabel(color: resolvedColor).copyWith(
                  fontSize: resolvedFontSize,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
