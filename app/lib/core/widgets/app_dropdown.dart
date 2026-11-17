import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Unified shadcn-styled dropdown selector matching `AppTextField` (`40px` height,
/// `10px` radius, `1px` border, `colors.bg` fill, and consistent label above).
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final Widget? labelTrailing;
  final T? value;
  final String? placeholder;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const AppDropdown({
    super.key,
    this.label,
    this.labelTrailing,
    required this.value,
    this.placeholder,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inputLabel(color: colors.tx),
                ),
              ),
              if (labelTrailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                labelTrailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          height: 40,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border.all(color: colors.bd, width: 1.0),
            borderRadius: AppRadius.rLg,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: placeholder != null
                  ? Text(
                      placeholder!,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: colors.mu,
                      ),
                    )
                  : null,
              isExpanded: true,
              isDense: true,
              dropdownColor: colors.sf,
              borderRadius: AppRadius.rLg,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: colors.mu,
              ),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: colors.tx,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
