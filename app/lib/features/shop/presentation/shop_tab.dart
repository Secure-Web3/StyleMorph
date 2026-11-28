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
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_section_header.dart';
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

  List<({String label, VoidCallback onRemove})> _buildDismissibleFilterPills(
    AppStrings strings,
    ShopFilter filter,
    ShopNotifier notifier,
  ) {
    final pills = <({String label, VoidCallback onRemove})>[];
    if (filter.fitFilter) {
      pills.add((
        label: strings.shopFitMeChip,
        onRemove: notifier.toggleFitFilter,
      ));
    }
    if (filter.gender != 'all') {
      final genderLabel = switch (filter.gender) {
        'w' => strings.shopGenderW,
        'm' => strings.shopGenderM,
        _ => strings.shopGenderU,
      };
      pills.add((
        label: genderLabel,
        onRemove: () => notifier.updateFilter(filter.copyWith(gender: 'all')),
      ));
    }
    for (final brand in filter.brands) {
      pills.add((
        label: strings.tr(brand),
        onRemove: () => notifier.updateFilter(
          filter.copyWith(
            brands: filter.brands.where((b) => b != brand).toList(),
          ),
        ),
      ));
    }
    for (final color in filter.colors) {
      pills.add((
        label: strings.tr(color),
        onRemove: () => notifier.updateFilter(
          filter.copyWith(
            colors: filter.colors.where((c) => c != color).toList(),
          ),
        ),
      ));
    }
    for (final size in filter.sizes) {
      pills.add((
        label: strings.formatNumber(size),
        onRemove: () => notifier.updateFilter(
          filter.copyWith(sizes: filter.sizes.where((s) => s != size).toList()),
        ),
      ));
    }
    if (filter.maxPrice > 0) {
      pills.add((
        label:
            '${strings.shopMaxPrice}: ${strings.formatCurrency(filter.maxPrice)}',
        onRemove: () => notifier.updateFilter(filter.copyWith(maxPrice: 0)),
      ));
    }
    if (filter.saleType != 'all') {
      pills.add((
        label: filter.saleType == 'app'
            ? strings.shopSaleApp
            : strings.shopSaleSite,
        onRemove: () => notifier.updateFilter(filter.copyWith(saleType: 'all')),
      ));
    }
    if (filter.availableOnly) {
      pills.add((
        label: strings.shopToggleAvail,
        onRemove: () =>
            notifier.updateFilter(filter.copyWith(availableOnly: false)),
      ));
    }
    if (filter.discountOnly) {
      pills.add((
        label: strings.shopToggleDisc,
        onRemove: () =>
            notifier.updateFilter(filter.copyWith(discountOnly: false)),
      ));
    }
    if (filter.verifiedOnly) {
      pills.add((
        label: strings.shopToggleVerified,
        onRemove: () =>
            notifier.updateFilter(filter.copyWith(verifiedOnly: false)),
      ));
    }
    return pills;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final shopState = ref.watch(shopProvider);
    final notifier = ref.read(shopProvider.notifier);
    final appCoins = ref.watch(appStateProvider).coins;
    final activeFilters = shopState.filter.activeFilterCount;
    final searchQuery = ShopSearchQueryBuilder.buildQuery(
      filter: shopState.filter,
      localeCode: strings.localeCode,
    );
    final searchUri = ShopSearchQueryBuilder.buildSearchUri(
      filter: shopState.filter,
      localeCode: strings.localeCode,
    );
    final dismissiblePills = _buildDismissibleFilterPills(
      strings,
      shopState.filter,
      notifier,
    );
    final activeFilterLabels = dismissiblePills.map((p) => p.label).toList();

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

        // --- Row 1: Search, Advanced Filter & Compact Sort Menu ---
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
              PopupMenuButton<String>(
                tooltip: strings.shopSortTitle,
                initialValue: shopState.filter.sortOption,
                onSelected: notifier.setSortOption,
                color: colors.sf,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rLg,
                  side: BorderSide(color: colors.bd),
                ),
                itemBuilder: (_) => _sortCodes.map((code) {
                  final isSel = shopState.filter.sortOption == code;
                  return PopupMenuItem<String>(
                    value: code,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSel
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 16,
                          color: isSel ? colors.pr : colors.mu,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _sortLabel(strings, code),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSel ? colors.pr : colors.tx,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: shopState.filter.sortOption != 'rel'
                        ? colors.pr.withValues(alpha: 0.12)
                        : colors.bg,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(
                      color: shopState.filter.sortOption != 'rel'
                          ? colors.pr
                          : colors.bd,
                    ),
                  ),
                  child: Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: shopState.filter.sortOption != 'rel'
                        ? colors.pr
                        : colors.tx,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Row 2: Fit For Me Toggle + Categories Horizontal Pills ---
        Container(
          height: 44,
          color: colors.sf,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            itemCount: _categoryCodes.length + 1,
            itemBuilder: (_, idx) {
              if (idx == 0) {
                final isFit = shopState.filter.fitFilter;
                return AppChip(
                  label: strings.shopFitMeChip,
                  isSelected: isFit,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  leading: Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: isFit ? colors.prt : colors.pr,
                  ),
                  onTap: notifier.toggleFitFilter,
                );
              }
              final code = _categoryCodes[idx - 1];
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

        // --- Active Filter Pills Strip (only when filters are active) ---
        if (dismissiblePills.isNotEmpty)
          Container(
            height: 36,
            color: colors.sf,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              itemCount: dismissiblePills.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                if (idx == dismissiblePills.length) {
                  return InkWell(
                    borderRadius: AppRadius.rFull,
                    onTap: notifier.resetFilters,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.rFull,
                        border: Border.all(
                          color: colors.orColor.withValues(alpha: 0.4),
                        ),
                      ),
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        strings.shopClearAllFilters,
                        style: AppTypography.caption(color: colors.orColor),
                      ),
                    ),
                  );
                }
                final pill = dismissiblePills[idx];
                return InkWell(
                  borderRadius: AppRadius.rFull,
                  onTap: pill.onRemove,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.pr.withValues(alpha: 0.1),
                      borderRadius: AppRadius.rFull,
                      border: Border.all(
                        color: colors.pr.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pill.label,
                          style: AppTypography.caption(color: colors.pr),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.close_rounded, size: 12, color: colors.pr),
                      ],
                    ),
                  ),
                );
              },
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
