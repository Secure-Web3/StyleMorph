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
import '../../../core/widgets/app_toast.dart';
import '../domain/shop_query_builder.dart';
import 'shop_provider.dart';
import 'widgets/shop_filter_sheet.dart';
import 'widgets/shop_web_discovery_view.dart';

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
    final searchQuery = ShopSearchQueryBuilder.buildQuery(
      filter: shopState.filter,
      localeCode: strings.localeCode,
    );
    final searchUri = ShopSearchQueryBuilder.buildSearchUri(
      filter: shopState.filter,
      localeCode: strings.localeCode,
    );
    final activeFilterLabels = <String>[
      if (shopState.filter.category != 'all')
        _categoryLabel(strings, shopState.filter.category),
      ...shopState.filter.brands.map(strings.tr),
      ...shopState.filter.colors.map(strings.tr),
      ...shopState.filter.sizes.map(strings.formatNumber),
      if (shopState.filter.fitFilter) strings.shopFitMeBanner,
    ];

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
                Icon(Icons.monetization_on_rounded, size: 13, color: colors.wn),
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
              AppIconButton(icon: Icons.sort_rounded, onTap: _openSortSheet),
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

        // --- Row 3: "Fit For Me" Banner ---
        Container(
          color: colors.sf,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: AppCard(
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
        ),

        // --- Row 4: Status & Active Sort Bar ---
        Container(
          color: colors.sf,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.countWithUnit(products.length, strings.shopProductUnit),
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

        // --- Image-First Google Search WebView / Web Fallback ---
        Expanded(
          child: ShopWebDiscoveryView(
            searchUri: searchUri,
            searchQuery: searchQuery,
            activeFilterLabels: activeFilterLabels,
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
                    AppToast.showInfo(
                      context,
                      strings.shopCompareReady(shopState.compareList.length),
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
