import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_switch.dart';
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
  final void Function(
    String color,
    String season,
    String occasion, {
    bool multiSelectMode,
    Set<String> selectedColors,
    Set<String> selectedSeasons,
    Set<String> selectedOccasions,
  })
  onApply;
  final VoidCallback onClear;

  @override
  State<WardrobeFilterSheet> createState() => _WardrobeFilterSheetState();
}

class _WardrobeFilterSheetState extends State<WardrobeFilterSheet> {
  late String _color;
  late String _season;
  late String _occasion;
  late bool _multiSelectMode;
  late Set<String> _selectedColors;
  late Set<String> _selectedSeasons;
  late Set<String> _selectedOccasions;

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
    _multiSelectMode = widget.initialFilter.multiSelectMode;
    _selectedColors = Set<String>.from(widget.initialFilter.selectedColors);
    if (_color.isNotEmpty && !_selectedColors.contains(_color)) {
      _selectedColors.add(_color);
    }
    _selectedSeasons = Set<String>.from(widget.initialFilter.selectedSeasons);
    if (_season.isNotEmpty && !_selectedSeasons.contains(_season)) {
      _selectedSeasons.add(_season);
    }
    _selectedOccasions = Set<String>.from(
      widget.initialFilter.selectedOccasions,
    );
    if (_occasion.isNotEmpty && !_selectedOccasions.contains(_occasion)) {
      _selectedOccasions.add(_occasion);
    }
  }

  void _handleClear() {
    setState(() {
      _color = '';
      _season = '';
      _occasion = '';
      _selectedColors.clear();
      _selectedSeasons.clear();
      _selectedOccasions.clear();
    });
    widget.onClear();
    Navigator.of(context).pop();
  }

  void _handleApply() {
    widget.onApply(
      _color,
      _season,
      _occasion,
      multiSelectMode: _multiSelectMode,
      selectedColors: _selectedColors,
      selectedSeasons: _selectedSeasons,
      selectedOccasions: _selectedOccasions,
    );
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
            // Multi-Select toggle checkbox
            AppCheckboxTile(
              label: strings.wardMultiSelectFilter,
              value: _multiSelectMode,
              onChanged: (val) {
                setState(() {
                  _multiSelectMode = val;
                  if (!_multiSelectMode) {
                    if (_selectedColors.isNotEmpty) {
                      _color = _selectedColors.first;
                      _selectedColors = {_color};
                    }
                    if (_selectedSeasons.isNotEmpty) {
                      _season = _selectedSeasons.first;
                      _selectedSeasons = {_season};
                    }
                    if (_selectedOccasions.isNotEmpty) {
                      _occasion = _selectedOccasions.first;
                      _selectedOccasions = {_occasion};
                    }
                  } else {
                    if (_color.isNotEmpty) _selectedColors.add(_color);
                    if (_season.isNotEmpty) _selectedSeasons.add(_season);
                    if (_occasion.isNotEmpty) _selectedOccasions.add(_occasion);
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),

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
                  final isSel = _multiSelectMode
                      ? _selectedColors.contains(sw.$2)
                      : _color == sw.$2;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_multiSelectMode) {
                            if (_selectedColors.contains(sw.$2)) {
                              _selectedColors.remove(sw.$2);
                              if (_color == sw.$2) {
                                _color = _selectedColors.isNotEmpty
                                    ? _selectedColors.first
                                    : '';
                              }
                            } else {
                              _selectedColors.add(sw.$2);
                              _color = sw.$2;
                            }
                          } else {
                            final wasSel = _color == sw.$2;
                            _color = wasSel ? '' : sw.$2;
                            _selectedColors = _color.isNotEmpty
                                ? {_color}
                                : <String>{};
                          }
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
                final isSel = _multiSelectMode
                    ? _selectedSeasons.contains(s)
                    : _season == s;
                return AppChip(
                  label: strings.tr(s),
                  isSelected: isSel,
                  onTap: () {
                    setState(() {
                      if (_multiSelectMode) {
                        if (_selectedSeasons.contains(s)) {
                          _selectedSeasons.remove(s);
                          if (_season == s) {
                            _season = _selectedSeasons.isNotEmpty
                                ? _selectedSeasons.first
                                : '';
                          }
                        } else {
                          _selectedSeasons.add(s);
                          _season = s;
                        }
                      } else {
                        final wasSel = _season == s;
                        _season = wasSel ? '' : s;
                        _selectedSeasons = _season.isNotEmpty
                            ? {_season}
                            : <String>{};
                      }
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
                final isSel = _multiSelectMode
                    ? _selectedOccasions.contains(o)
                    : _occasion == o;
                return AppChip(
                  label: strings.tr(o),
                  isSelected: isSel,
                  onTap: () {
                    setState(() {
                      if (_multiSelectMode) {
                        if (_selectedOccasions.contains(o)) {
                          _selectedOccasions.remove(o);
                          if (_occasion == o) {
                            _occasion = _selectedOccasions.isNotEmpty
                                ? _selectedOccasions.first
                                : '';
                          }
                        } else {
                          _selectedOccasions.add(o);
                          _occasion = o;
                        }
                      } else {
                        final wasSel = _occasion == o;
                        _occasion = wasSel ? '' : o;
                        _selectedOccasions = _occasion.isNotEmpty
                            ? {_occasion}
                            : <String>{};
                      }
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
