import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppSegmentItem<T> {
  final T value;
  final String label;
  final String? badgeText;

  const AppSegmentItem({
    required this.value,
    required this.label,
    this.badgeText,
  });
}

/// Unified shadcn-style horizontal segmented control / mode switcher.
class AppSegmentedControl<T> extends StatelessWidget {
  final List<AppSegmentItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;
  final double height;

  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.expand = false,
    this.height = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: colors.bd, width: 1.0),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: items.map((item) {
          final isActive = item.value == value;
          final pill = InkWell(
            onTap: () => onChanged(item.value),
            borderRadius: AppRadius.rMd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: expand ? AppSpacing.xs : AppSpacing.md,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? colors.pr : Colors.transparent,
                borderRadius: AppRadius.rMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (expand)
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.chipLabel(
                          color: isActive ? colors.prt : colors.tx,
                          isSelected: isActive,
                        ),
                      ),
                    )
                  else
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.chipLabel(
                        color: isActive ? colors.prt : colors.tx,
                        isSelected: isActive,
                      ),
                    ),
                  if (item.badgeText != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colors.prt.withValues(alpha: 0.2)
                            : colors.orColor,
                        borderRadius: AppRadius.rFull,
                      ),
                      child: Text(
                        item.badgeText!,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colors.prt,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

          return expand ? Expanded(child: pill) : pill;
        }).toList(),
      ),
    );
  }
}
