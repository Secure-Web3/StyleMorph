import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Unified section header used inside Profile sub-tabs and module sub-sections.
/// Features a consistent 18px icon, unified title typography, optional trailing
/// badge/action, and a subtle bottom divider.
class AppSectionHeader extends StatelessWidget {
  final IconData? icon;
  final FaIconData? faIcon;
  final String title;
  final Widget? trailing;
  final bool showDivider;
  final EdgeInsetsDirectional? padding;

  const AppSectionHeader({
    super.key,
    this.icon,
    this.faIcon,
    required this.title,
    this.trailing,
    this.showDivider = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: padding ??
          const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.bd, width: 1.0))
            : null,
      ),
      child: Row(
        children: [
          if (faIcon != null) ...[
            FaIcon(faIcon!, size: 18, color: colors.pr),
            const SizedBox(width: AppSpacing.sm),
          ] else if (icon != null) ...[
            Icon(icon!, size: 18, color: colors.pr),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sectionTitle(color: colors.tx),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Unified top header bar for main feature tabs (Wardrobe, Shop, Stylist,
/// Atelier, Wellness) matching the exact surface, typography, spacing, and
/// bottom border across the app.
class AppModuleHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;

  const AppModuleHeader({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        border: Border(bottom: BorderSide(color: colors.bd, width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon!, size: 18, color: colors.pr),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.moduleTitle(color: colors.tx),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(color: colors.mu),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.xs),
            bottom!,
          ],
        ],
      ),
    );
  }
}
