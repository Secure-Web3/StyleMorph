import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../domain/shop_product.dart';
import '../shop_provider.dart';

class ShopFilterSheet extends StatefulWidget {
  const ShopFilterSheet({
    super.key,
    required this.initialFilter,
    required this.products,
    required this.onApply,
    required this.onReset,
  });

  final ShopFilter initialFilter;
  final List<ShopProduct> products;
  final void Function(ShopFilter) onApply;
  final VoidCallback onReset;

  @override
  State<ShopFilterSheet> createState() => _ShopFilterSheetState();
}

class _ShopFilterSheetState extends State<ShopFilterSheet> {
  late ShopFilter _f;

  static const _brands = [
    'زارا',
    'نایک',
    'استایل‌مورف',
    'رز',
    'نورث',
    'اورینت',
    'ژوپیتر',
    'سارا',
    'ال‌سی',
    'نگار',
    'ماوی',
    'ری‌بن',
    'آدیداس',
  ];

  static const _sizes = [
    'S',
    'M',
    'L',
    'XL',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
  ];

  static const _colors = [
    ('سفید', Color(0xFFF4F4F2)),
    ('مشکی', Color(0xFF222222)),
    ('آبی', Color(0xFF3B6EA5)),
    ('قرمز', Color(0xFFC0392B)),
    ('سبز', Color(0xFF4F7A5A)),
    ('بژ', Color(0xFFD6BF9B)),
    ('صورتی', Color(0xFFE29BB0)),
    ('قهوه‌ای', Color(0xFF7A5230)),
    ('طلایی', Color(0xFFC9A227)),
    ('نقره‌ای', Color(0xFFA9AEB4)),
    ('طوسی', Color(0xFF8A8F94)),
  ];

  @override
  void initState() {
    super.initState();
    _f = widget.initialFilter;
  }

  void _toggleInList(
    List<String> list,
    String item,
    void Function(List<String>) update,
  ) {
    final next = List<String>.from(list);
    if (next.contains(item)) {
      next.remove(item);
    } else {
      next.add(item);
    }
    update(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return AppBottomSheetShell(
      title: strings.shopFilterTitle,
      bottomBar: Row(
        children: [
          AppButton(
            variant: AppButtonVariant.outline,
            text: strings.shopRemoveFilters,
            onPressed: () {
              widget.onReset();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              isFullWidth: true,
              text: strings.shopApplyFilters,
              onPressed: () {
                widget.onApply(_f);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sale Type
          _SectionTitle(title: strings.shopSaleType, colors: colors),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                [
                  ('all', strings.allText),
                  ('app', strings.shopSaleApp),
                  ('site', strings.shopSaleSite),
                ].map((opt) {
                  return AppChip(
                    label: opt.$2,
                    isSelected: _f.saleType == opt.$1,
                    onTap: () =>
                        setState(() => _f = _f.copyWith(saleType: opt.$1)),
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Gender
          _SectionTitle(title: strings.shopGender, colors: colors),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                [
                  ('all', strings.allText),
                  ('w', strings.shopGenderW),
                  ('m', strings.shopGenderM),
                  ('u', strings.shopGenderU),
                ].map((opt) {
                  return AppChip(
                    label: opt.$2,
                    isSelected: _f.gender == opt.$1,
                    onTap: () =>
                        setState(() => _f = _f.copyWith(gender: opt.$1)),
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Max price
          _SectionTitle(
            title: _f.maxPrice > 0
                ? '${strings.shopMaxPrice}: ${strings.formatCurrency(_f.maxPrice)}'
                : strings.shopMaxPriceNoLimit,
            colors: colors,
          ),
          Slider(
            value: _f.maxPrice > 0 ? _f.maxPrice.toDouble() : 3000000,
            min: 100000,
            max: 3000000,
            divisions: 29,
            activeColor: colors.pr,
            inactiveColor: colors.bd,
            onChanged: (v) {
              setState(() {
                _f = _f.copyWith(
                  maxPrice: v.toInt() >= 3000000 ? 0 : v.toInt(),
                );
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Brands
          _SectionTitle(title: strings.shopBrands, colors: colors),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _brands.map((b) {
              return AppChip(
                label: strings.tr(b),
                isSelected: _f.brands.contains(b),
                onTap: () => _toggleInList(
                  _f.brands,
                  b,
                  (l) => setState(() => _f = _f.copyWith(brands: l)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sizes
          _SectionTitle(title: strings.wardSpecSize, colors: colors),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _sizes.map((s) {
              return AppChip(
                label: strings.formatNumber(s),
                isSelected: _f.sizes.contains(s),
                onTap: () => _toggleInList(
                  _f.sizes,
                  s,
                  (l) => setState(() => _f = _f.copyWith(sizes: l)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Colors
          _SectionTitle(title: strings.wardFilterColor, colors: colors),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _colors.map((c) {
              return AppChip(
                label: strings.tr(c.$1),
                isSelected: _f.colors.contains(c.$1),
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.$2,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.bd, width: 0.5),
                  ),
                ),
                onTap: () => _toggleInList(
                  _f.colors,
                  c.$1,
                  (l) => setState(() => _f = _f.copyWith(colors: l)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Toggles
          AppSwitchTile(
            label: strings.shopToggleAvail,
            value: _f.availableOnly,
            onChanged: (v) =>
                setState(() => _f = _f.copyWith(availableOnly: v)),
          ),
          AppSwitchTile(
            label: strings.shopToggleDisc,
            value: _f.discountOnly,
            onChanged: (v) => setState(() => _f = _f.copyWith(discountOnly: v)),
          ),
          AppSwitchTile(
            label: strings.shopToggleVerified,
            value: _f.verifiedOnly,
            onChanged: (v) => setState(() => _f = _f.copyWith(verifiedOnly: v)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.colors});

  final String title;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: AppTypography.inputLabel(color: colors.tx)),
    );
  }
}
