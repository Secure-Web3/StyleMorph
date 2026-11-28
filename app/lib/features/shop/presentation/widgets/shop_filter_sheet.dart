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
  bool _membersExpanded = false;

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

  static const _apparelSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _shoeSizes = ['36', '37', '38', '39', '40', '41', '42', '43'];

  List<String>? _contextualSizes() {
    switch (_f.category) {
      case 'shoe':
        return _shoeSizes;
      case 'cloth':
        return _apparelSizes;
      case 'bag':
      case 'acc':
      case 'beauty':
        return null;
      default:
        return [..._apparelSizes, ..._shoeSizes];
    }
  }

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

          // Colors (single-line horizontal 26px circular swatches)
          _SectionTitle(title: strings.wardFilterColor, colors: colors),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, idx) {
                final c = _colors[idx];
                final isSelected = _f.colors.contains(c.$1);
                final isLight = c.$2.computeLuminance() > 0.6;
                return Semantics(
                  label: strings.tr(c.$1),
                  button: true,
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () => _toggleInList(
                      _f.colors,
                      c.$1,
                      (l) => setState(() => _f = _f.copyWith(colors: l)),
                    ),
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c.$2,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colors.pr : colors.bd,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: isLight ? Colors.black87 : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Brands (single-line horizontal chip strip)
          _SectionTitle(title: strings.shopBrands, colors: colors),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _brands.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final b = _brands[idx];
                return AppChip(
                  label: strings.tr(b),
                  isSelected: _f.brands.contains(b),
                  onTap: () => _toggleInList(
                    _f.brands,
                    b,
                    (l) => setState(() => _f = _f.copyWith(brands: l)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Context-aware Sizes (hidden for bags/accessories/beauty)
          if (_contextualSizes() case final sizes?) ...[
            _SectionTitle(title: strings.wardSpecSize, colors: colors),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sizes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, idx) {
                  final s = sizes[idx];
                  return AppChip(
                    label: strings.formatNumber(s),
                    isSelected: _f.sizes.contains(s),
                    onTap: () => _toggleInList(
                      _f.sizes,
                      s,
                      (l) => setState(() => _f = _f.copyWith(sizes: l)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Member-store-only controls inside collapsed-by-default accordion
          InkWell(
            onTap: () => setState(() => _membersExpanded = !_membersExpanded),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.shopMembersOnly,
                      style: AppTypography.inputLabel(color: colors.tx),
                    ),
                  ),
                  Icon(
                    _membersExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.mu,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_membersExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
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
            AppSwitchTile(
              label: strings.shopToggleAvail,
              value: _f.availableOnly,
              onChanged: (v) =>
                  setState(() => _f = _f.copyWith(availableOnly: v)),
            ),
            AppSwitchTile(
              label: strings.shopToggleDisc,
              value: _f.discountOnly,
              onChanged: (v) =>
                  setState(() => _f = _f.copyWith(discountOnly: v)),
            ),
            AppSwitchTile(
              label: strings.shopToggleVerified,
              value: _f.verifiedOnly,
              onChanged: (v) =>
                  setState(() => _f = _f.copyWith(verifiedOnly: v)),
            ),
          ],
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
