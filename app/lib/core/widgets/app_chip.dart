import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Unified pill-shaped filter/category/tag chip used consistently across all modules.
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? leading;
  final EdgeInsetsDirectional? margin;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.leading,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = isSelected ? colors.pr : colors.bg;
    final border = isSelected ? colors.pr : colors.bd;
    final fg = isSelected ? colors.prt : colors.tx;

    final chip = InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rFull,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.rFull,
          border: Border.all(color: border, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              IconTheme(
                data: IconThemeData(size: 13, color: fg),
                child: leading!,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.chipLabel(color: fg, isSelected: isSelected),
            ),
          ],
        ),
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: chip);
    }
    return chip;
  }
}
