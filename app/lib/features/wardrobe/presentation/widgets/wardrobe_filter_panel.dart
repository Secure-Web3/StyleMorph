import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_modal.dart';
import '../wardrobe_provider.dart';

class WardrobeFilterSheet extends StatefulWidget {
  const WardrobeFilterSheet({
    super.key,
    required this.initialFilter,
    required this.colors,
    required this.onApply,
    required this.onClear,
  });

  final WardrobeFilter initialFilter;
  final AppColors colors;
  final void Function(String color, String season, String occasion) onApply;
  final VoidCallback onClear;

  @override
  State<WardrobeFilterSheet> createState() => _WardrobeFilterSheetState();
}

class _WardrobeFilterSheetState extends State<WardrobeFilterSheet> {
  late String _color;
  late String _season;
  late String _occasion;

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
  void initState() {
    super.initState();
    _color = widget.initialFilter.colorFilter;
    _season = widget.initialFilter.seasonFilter;
    _occasion = widget.initialFilter.occasionFilter;
  }

  void _handleClear() {
    setState(() {
      _color = '';
      _season = '';
      _occasion = '';
    });
    widget.onClear();
    Navigator.of(context).pop();
  }

  void _handleApply() {
    widget.onApply(_color, _season, _occasion);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final c = widget.colors;

    return AppBottomSheetShell(
      title: strings.wardFilterSheetTitle,
      bottomBar: Row(
        children: [
          Expanded(
            child: AppButton(
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.md,
              text: strings.clearFilters,
              onPressed: _handleClear,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              variant: AppButtonVariant.primary,
              size: AppButtonSize.md,
              text: strings.wardApplyFilters,
              onPressed: _handleApply,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Colors (compact single-line horizontally scrollable dots)
            Text(
              strings.wardFilterColor,
              style: AppTypography.inputLabel(color: c.tx),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _swatches.map((sw) {
                  final isSel = _color == sw.$2;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _color = isSel ? '' : sw.$2;
                        });
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: sw.$3,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? c.pr : c.bd,
                            width: isSel ? 2.5 : 1,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: c.pr.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSel
                            ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: sw.$2 == '#f4f4f2'
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Row 2: Season (compact row of AppChip pills)
            Text(
              strings.wardSeason,
              style: AppTypography.inputLabel(color: c.tx),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _seasons.map((s) {
                final isSel = _season == s;
                return AppChip(
                  label: strings.tr(s),
                  isSelected: isSel,
                  onTap: () {
                    setState(() {
                      _season = isSel ? '' : s;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Row 3: Occasion (compact row of AppChip pills)
            Text(
              strings.wardOccasion,
              style: AppTypography.inputLabel(color: c.tx),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _occasions.map((o) {
                final isSel = _occasion == o;
                return AppChip(
                  label: strings.tr(o),
                  isSelected: isSel,
                  onTap: () {
                    setState(() {
                      _occasion = isSel ? '' : o;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}
