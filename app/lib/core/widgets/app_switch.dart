import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'shad_theme_scope.dart';

/// Unified shadcn switch row for Settings, Persona, and Shop Filters.
class AppSwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsDirectional? padding;

  const AppSwitchTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final row = InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: padding ??
            const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.tx,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.caption(color: colors.mu),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ShadSwitch(
              value: value,
              checkedTrackColor: colors.pr,
              uncheckedTrackColor: colors.bd,
              thumbColor: colors.sf,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );

    return ensureShadTheme(context, row);
  }
}

/// Unified shadcn checkbox row for confirmation terms and checklists.
class AppCheckboxTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsDirectional? padding;

  const AppCheckboxTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final row = InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: padding ??
            const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShadCheckbox(
              value: value,
              size: 18,
              color: colors.pr,
              onChanged: onChanged,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  color: colors.mu,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ensureShadTheme(context, row);
  }
}
