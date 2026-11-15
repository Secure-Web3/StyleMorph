import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/shop_product.dart';
import 'shop_provider.dart';
import 'widgets/shop_product_card.dart';
import 'widgets/shop_filter_sheet.dart';
import 'widgets/shop_product_detail_sheet.dart';
import 'widgets/try_on_sheet.dart';

class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab> {
  final _searchCtrl = TextEditingController();

  static const _categoryCodes = [
    'all',
    'cloth',
    'shoe',
    'bag',
    'acc',
    'beauty',
    'fav',
  ];

  static const _sortCodes = ['rel', 'lo', 'hi', 'rt', 'dc'];

  String _categoryLabel(AppStrings strings, String code) {
    switch (code) {
      case 'all':
        return strings.allText;
      case 'cloth':
        return strings.shopCatCloth;
      case 'shoe':
        return strings.wardCatSh;
      case 'bag':
        return strings.wardCatBg;
      case 'acc':
        return strings.wardCatAc;
      case 'beauty':
        return strings.shopCatBeauty;
      case 'fav':
        return strings.shopCatFav;
      default:
        return code;
    }
  }

  String _sortLabel(AppStrings strings, String key) {
    switch (key) {
      case 'rel':
        return strings.shopSortRel;
      case 'lo':
        return strings.shopSortLo;
      case 'hi':
        return strings.shopSortHi;
      case 'rt':
        return strings.shopSortRt;
      case 'dc':
        return strings.shopSortDc;
      default:
        return key;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDetailSheet(ShopProduct product) {
    ref.read(shopProvider.notifier).addRecentlyViewed(product.id);
    final notifier = ref.read(shopProvider.notifier);

    AppModal.showSheet(
      context: context,
      child: Consumer(
        builder: (ctx, watchRef, _) {
          final currentShop = watchRef.watch(shopProvider);
          return ShopProductDetailSheet(
            product: product,
            isWishlisted: currentShop.wishlist.contains(product.id),
            isCompared: currentShop.compareList.contains(product.id),
            hasPriceAlert: currentShop.priceAlerts.containsKey(product.id),
            onWishlist: () => notifier.toggleWishlist(product.id),
            onCompare: () => notifier.toggleCompare(product.id),
            onPriceAlert: () => notifier.setPriceAlert(product.id, 10),
          );
        },
      ),
    );
  }

  void _openFilterSheet() {
    final shopState = ref.read(shopProvider);
    final notifier = ref.read(shopProvider.notifier);

    AppModal.showSheet(
      context: context,
      child: ShopFilterSheet(
        initialFilter: shopState.filter,
        products: shopState.products,
        onApply: (f) => notifier.updateFilter(f),
        onReset: () => notifier.resetFilters(),
      ),
    );
  }

  void _openSortSheet() {
    final shopState = ref.read(shopProvider);
    final notifier = ref.read(shopProvider.notifier);
    final colors = context.colors;
    final strings = context.strings;

    AppModal.showSheet(
      context: context,
      child: AppBottomSheetShell(
        title: strings.shopSortTitle,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _sortCodes.map((code) {
            final isSel = shopState.filter.sortOption == code;
            return ListTile(
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
              title: Text(
                _sortLabel(strings, code),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? colors.pr : colors.tx,
                ),
              ),
              trailing: isSel
                  ? Icon(Icons.check_circle_rounded, color: colors.pr, size: 18)
                  : null,
              dense: true,
              onTap: () {
                notifier.setSortOption(code);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final shopState = ref.watch(shopProvider);
    final notifier = ref.read(shopProvider.notifier);
    final appCoins = ref.watch(appStateProvider).coins;
    final products = shopState.filteredProducts;
    final activeFilters = shopState.filter.activeFilterCount;

    return Column(
      children: [
        // --- Top Bar: Title & Coin Chip ---
        AppModuleHeader(
          icon: Icons.storefront_rounded,
          title: strings.shopTitle,
          subtitle: strings.shopSub,
          trailing: AppBadge(
            variant: AppBadgeVariant.warning,
            size: AppBadgeSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  size: 13,
                  color: colors.wn,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(strings.coinsText(appCoins)),
              ],
            ),
          ),
        ),

        // --- Search & Filter Row ---
        Container(
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          color: colors.sf,
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _searchCtrl,
                  hintText: strings.shopSearchHint,
                  onChanged: notifier.setSearchQuery,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: Icons.tune_rounded,
                isActive: activeFilters > 0,
                badgeCount: activeFilters,
                onTap: _openFilterSheet,
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: Icons.sort_rounded,
                onTap: _openSortSheet,
              ),
            ],
          ),
        ),

        // --- Categories Horizontal Pills ---
        Container(
          height: 44,
          color: colors.sf,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            itemCount: _categoryCodes.length,
            itemBuilder: (_, idx) {
              final code = _categoryCodes[idx];
              final label = _categoryLabel(strings, code);
              final isSel = shopState.filter.category == code;
              return AppChip(
                label: label,
                isSelected: isSel,
                margin: const EdgeInsetsDirectional.only(end: 6),
                leading: code == 'fav'
                    ? Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: isSel ? colors.prt : colors.orColor,
                      )
                    : null,
                onTap: () => notifier.setCategory(code),
              );
            },
          ),
        ),

        // --- Main Scrollable Products Grid ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "Fit For Me" Banner
                AppCard(
                  margin: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_pin_circle_rounded,
                        size: 18,
                        color: colors.pr,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppSwitchTile(
                          padding: EdgeInsetsDirectional.zero,
                          label: strings.shopFitMeBanner,
                          subtitle: strings.shopFitMeSub,
                          value: shopState.filter.fitFilter,
                          onChanged: (_) => notifier.toggleFitFilter(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results count & sort indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.countWithUnit(
                          products.length,
                          strings.shopProductUnit,
                        ),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                      Text(
                        '${strings.shopSortPrefix}: ${_sortLabel(strings, shopState.filter.sortOption)}',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Products 2-Column Grid
                if (products.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sentiment_dissatisfied_rounded,
                            size: 44,
                            color: colors.mu,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.shopEmpty,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              color: colors.mu,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => notifier.resetFilters(),
                            child: Text(strings.shopClearAllFilters),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return ShopProductCard(
                        product: p,
                        colors: colors,
                        isWishlisted: shopState.wishlist.contains(p.id),
                        isCompared: shopState.compareList.contains(p.id),
                        onTap: () => _openDetailSheet(p),
                        onWishlist: () => notifier.toggleWishlist(p.id),
                        onCompare: () => notifier.toggleCompare(p.id),
                        onTryOn: () {
                          AppModal.showSheet(
                            context: context,
                            child: TryOnSheet(product: p),
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: AppSpacing.lg),
                // Disclaimer text
                AppCard(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 15, color: colors.mu),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          strings.shopDisclaimer,
                          style: AppTypography.caption(color: colors.mu),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // --- Comparison Sticky Bar (if items selected) ---
        if (shopState.compareList.isNotEmpty)
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.sf,
              border: Border(top: BorderSide(color: colors.bd)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.shopCompareCount(shopState.compareList.length),
                    style: AppTypography.cardTitle(color: colors.tx),
                  ),
                ),
                AppButton(
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  text: strings.shopClear,
                  onPressed: notifier.clearCompare,
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton(
                  size: AppButtonSize.sm,
                  text: strings.compare,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          strings.shopCompareReady(shopState.compareList.length),
                          style: const TextStyle(fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
