import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/wardrobe_item.dart';

class AddItemBottomSheet extends StatefulWidget {
  const AddItemBottomSheet({super.key, required this.onAdd});

  final void Function(WardrobeItem) onAdd;

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _subCtrl = TextEditingController(text: 'بالاتنه');
  final _matCtrl = TextEditingController(text: 'نخ / پنبه');
  final _sizeCtrl = TextEditingController(text: 'M');

  String _selectedCat = 'cl';
  String _selectedSeason = 'همه';
  String _selectedOccasion = 'روزمره';
  String _selectedColorName = 'آبی';
  String _selectedColorHex = '#3b6ea5';
  bool _imageSelected = false;

  static const _catOptions = [
    ('cl', 'لباس'),
    ('sh', 'کفش'),
    ('bg', 'کیف'),
    ('jw', 'زیورآلات'),
    ('ac', 'اکسسوری'),
  ];

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

  static const _seasons = ['همه', 'بهار', 'تابستان', 'پاییز', 'زمستان'];
  static const _occasions = ['روزمره', 'رسمی', 'ورزشی', 'مجلسی'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subCtrl.dispose();
    _matCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final newItem = WardrobeItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: _selectedCat,
      subCategory: _subCtrl.text.trim().isEmpty
          ? 'عمومی'
          : _subCtrl.text.trim(),
      colorName: _selectedColorName,
      colorHex: _selectedColorHex,
      season: _selectedSeason,
      occasion: _selectedOccasion,
      material: _matCtrl.text.trim().isEmpty ? 'پارچه' : _matCtrl.text.trim(),
      size: _sizeCtrl.text.trim().isEmpty ? 'یونیورسال' : _sizeCtrl.text.trim(),
      isFavorite: false,
      isArchived: false,
    );

    widget.onAdd(newItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return AppBottomSheetShell(
      title: strings.wardAddSheetTitle,
      bottomBar: AppButton(
        isFullWidth: true,
        text: strings.wardSaveInWardrobe,
        onPressed: _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mock Image Upload Box
          AppCard(
            height: 90,
            variant: AppCardVariant.subtle,
            borderColor: _imageSelected ? colors.ok : colors.bd,
            onTap: () {
              setState(() => _imageSelected = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    strings.wardImgToast,
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _imageSelected
                        ? Icons.check_circle_rounded
                        : Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: _imageSelected ? colors.ok : colors.pr,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _imageSelected
                        ? strings.wardImgLoaded
                        : strings.wardImgClick,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _imageSelected ? colors.ok : colors.mu,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Item Name
          AppTextField(
            label: strings.wardItemName,
            controller: _nameCtrl,
            placeholder: strings.wardItemNameHint,
          ),
          const SizedBox(height: AppSpacing.md),

          // Category Chips
          Text(
            strings.wardCategory,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _catOptions.map((opt) {
              return AppChip(
                label: strings.tr(opt.$2),
                isSelected: _selectedCat == opt.$1,
                onTap: () => setState(() => _selectedCat = opt.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Color Selector
          Text(
            '${strings.wardSelectedColor}: ${strings.tr(_selectedColorName)}',
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _swatches.map((sw) {
              final isSel = _selectedColorHex == sw.$2;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorName = sw.$1;
                    _selectedColorHex = sw.$2;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: sw.$3,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? colors.pr : colors.bd,
                      width: isSel ? 2.5 : 1,
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

          // Season & Occasion Rows
          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: strings.wardSeason,
                  value: _selectedSeason,
                  items: _seasons
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(strings.tr(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSeason = v);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdown<String>(
                  label: strings.wardOccasion,
                  value: _selectedOccasion,
                  items: _occasions
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text(strings.tr(o)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedOccasion = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
