import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../wardrobe_provider.dart';

class WardrobeFilterPanel extends StatelessWidget {
  const WardrobeFilterPanel({
    super.key,
    required this.filter,
    required this.onColor,
    required this.onSeason,
    required this.onOccasion,
    required this.onClear,
    required this.colors,
  });

  final WardrobeFilter filter;
  final void Function(String hex) onColor;
  final void Function(String season) onSeason;
  final void Function(String occasion) onOccasion;
  final VoidCallback onClear;
  final AppColors colors;

  static const _swatches = [
    ('سیاه', '#222222', Color(0xFF222222)),
    ('سفید', '#f4f4f2', Color(0xFFF4F4F2)),
    ('بژ', '#d6bf9b', Color(0xFFD6BF9B)),
    ('قهوه‌ای', '#7a5230', Color(0xFF7A5230)),
    ('آبی', '#3b6ea5', Color(0xFF3B6EA5)),
    ('سرمه‌ای', '#1f2f56', Color(0xFF1F2F56)),
    ('قرمز', '#c0392b', Color(0xFFC0392B)),
    ('سبز', '#4f7a5a', Color(0xFF4F7A5A)),
    ('صورتی', '#e29bb0', Color(0xFFE29BB0)),
    ('طلایی', '#c9a227', Color(0xFFC9A227)),
    ('نقره‌ای', '#a9aeb4', Color(0xFFA9AEB4)),
    ('طوسی', '#8a8f94', Color(0xFF8A8F94)),
  ];

  static const _seasons = ['بهار', 'تابستان', 'پاییز', 'زمستان'];
  static const _occasions = ['روزمره', 'رسمی', 'ورزشی', 'مجلسی'];

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AppCard(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colors
          Text(
            strings.wardFilterColor,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _swatches.map((sw) {
              final isSel = filter.colorFilter == sw.$2;
              return GestureDetector(
                onTap: () => onColor(sw.$2),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: sw.$3,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? colors.pr : colors.bd,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: isSel
                      ? Icon(
                          Icons.check,
                          size: 13,
                          color: sw.$2 == '#f4f4f2'
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // Season
          Text(
            strings.wardSeason,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _seasons.map((s) {
              return AppChip(
                label: strings.tr(s),
                isSelected: filter.seasonFilter == s,
                onTap: () => onSeason(s),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // Occasion
          Text(
            strings.wardOccasion,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _occasions.map((o) {
              return AppChip(
                label: strings.tr(o),
                isSelected: filter.occasionFilter == o,
                onTap: () => onOccasion(o),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: onClear,
              child: Text(
                strings.clearFilters,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.pr,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
