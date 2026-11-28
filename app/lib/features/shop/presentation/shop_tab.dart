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
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/extracted_web_product.dart';
import '../domain/shop_product.dart';
import '../domain/shop_query_builder.dart';
import 'shop_provider.dart';
import 'widgets/shop_filter_sheet.dart';
import 'widgets/shop_web_discovery_view.dart';

class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();

  static const _categoryCodes = [
    'all',
    'cloth',
    'shoe',
    'bag',
    'acc',
    'beauty',
  ];

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final colors = context.colors;
    final strings = context.strings;
    final shopState = ref.watch(shopProvider);
    final notifier = ref.read(shopProvider.notifier);
    final appCoins = ref.watch(appStateProvider).coins;
    final activeFilters = shopState.filter.activeFilterCount;
    final isWishlistSelected = shopState.filter.category == 'fav';
    final savedCount = shopState.totalWishlistCount;
    final profileFit = shopState.profileFit;
    final searchQuery = ShopSearchQueryBuilder.buildQuery(
      filter: shopState.filter,
      localeCode: strings.localeCode,
      clothingSize: profileFit?.clothingSize ?? 'M',
      shoeSize: profileFit?.shoeSize ?? '42',
      profileGender: profileFit?.normalizedGenderCode,
      fitPreference: profileFit?.fitPreference,
    );
    final searchUri = ShopSearchQueryBuilder.buildSearchUri(
      filter: shopState.filter,
      localeCode: strings.localeCode,
      clothingSize: profileFit?.clothingSize ?? 'M',
      shoeSize: profileFit?.shoeSize ?? '42',
      profileGender: profileFit?.normalizedGenderCode,
      fitPreference: profileFit?.fitPreference,
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

        // --- Row 2: Wishlist (1st), Fit For Me (2nd), Categories Horizontal Pills ---
        Container(
          height: 44,
          color: colors.sf,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppChip(
                        label: strings.shopCatFav,
                        isSelected: isWishlistSelected,
                        leading: Icon(
                          Icons.favorite_rounded,
                          size: 13,
                          color: isWishlistSelected
                              ? colors.prt
                              : colors.orColor,
                        ),
                        onTap: () => notifier.setCategory(
                          isWishlistSelected ? 'all' : 'fav',
                        ),
                      ),
                      if (savedCount > 0)
                        PositionedDirectional(
                          top: -4,
                          end: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.orColor,
                              borderRadius: AppRadius.rFull,
                              border: Border.all(color: colors.sf, width: 1.2),
                            ),
                            child: Text(
                              strings.formatNumber(savedCount),
                              style: AppTypography.caption(
                                color: colors.prt,
                              ).copyWith(fontSize: 9, height: 1.1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AppChip(
                  label: strings.shopFitMeChip,
                  isSelected: shopState.filter.fitFilter,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  leading: Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: shopState.filter.fitFilter ? colors.prt : colors.pr,
                  ),
                  onTap: notifier.toggleFitFilter,
                ),
                ..._categoryCodes.map((code) {
                  final label = _categoryLabel(strings, code);
                  final isSel = shopState.filter.category == code;
                  return AppChip(
                    label: label,
                    isSelected: isSel,
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    onTap: () => notifier.setCategory(code),
                  );
                }),
              ],
            ),
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

        // --- Image-First Google Search WebView / Web Fallback & Wishlist ---
        Expanded(
          child: IndexedStack(
            index: isWishlistSelected ? 1 : 0,
            sizing: StackFit.expand,
            children: [
              Offstage(
                offstage: isWishlistSelected,
                child: ShopWebDiscoveryView(
                  searchUri: searchUri,
                  searchQuery: searchQuery,
                  activeFilterLabels: activeFilterLabels,
                ),
              ),
              _ShopWishlistView(
                webItems: shopState.webWishlist,
                catalogItems: shopState.products
                    .where((p) => shopState.wishlist.contains(p.id))
                    .toList(),
                onReopenUrl: (uri) => notifier.reopenInBrowser(uri),
                onReopenCatalog: (product) {
                  _searchCtrl.text = product.name;
                  notifier.updateFilter(
                    shopState.filter.copyWith(
                      category: 'all',
                      searchQuery: product.name,
                    ),
                  );
                },
                onSendToStylist: (product) {
                  ref.read(shopHandoffProvider.notifier).sendToStylist(product);
                  ref.read(appStateProvider.notifier).switchTab(AppTab.stylist);
                  AppToast.showSuccess(
                    context,
                    strings.shopWebSentToStylistMsg,
                  );
                },
                onSendToAtelier: (product) {
                  ref.read(shopHandoffProvider.notifier).sendToAtelier(product);
                  ref.read(appStateProvider.notifier).switchTab(AppTab.atelier);
                  AppToast.showSuccess(
                    context,
                    strings.shopWebSentToAtelierMsg,
                  );
                },
                onRemoveWeb: notifier.removeWebProductFromWishlist,
                onRemoveCatalog: notifier.toggleWishlist,
              ),
            ],
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

class _ShopWishlistView extends StatelessWidget {
  const _ShopWishlistView({
    required this.webItems,
    required this.catalogItems,
    required this.onReopenUrl,
    required this.onReopenCatalog,
    required this.onSendToStylist,
    required this.onSendToAtelier,
    required this.onRemoveWeb,
    required this.onRemoveCatalog,
  });

  final List<ExtractedWebProduct> webItems;
  final List<ShopProduct> catalogItems;
  final ValueChanged<Uri> onReopenUrl;
  final ValueChanged<ShopProduct> onReopenCatalog;
  final ValueChanged<ExtractedWebProduct> onSendToStylist;
  final ValueChanged<ExtractedWebProduct> onSendToAtelier;
  final ValueChanged<String> onRemoveWeb;
  final ValueChanged<int> onRemoveCatalog;

  ExtractedWebProduct _catalogToWebProduct(ShopProduct p) {
    return ExtractedWebProduct(
      title: p.name,
      imageUrl: '',
      pageUrl: 'https://stylemorph.style/shop/${p.id}',
      sourceHost: p.brand,
      priceText: p.lowestPrice > 0 ? p.lowestPrice.toString() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (webItems.isEmpty && catalogItems.isEmpty) {
      return Container(
        color: colors.bg,
        alignment: AlignmentDirectional.center,
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 40,
              color: colors.mu.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              strings.shopWishlistEmpty,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle(color: colors.mu),
            ),
          ],
        ),
      );
    }

    return Container(
      color: colors.bg,
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          ...webItems.map((item) {
            final uri = Uri.tryParse(item.pageUrl);
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: _WishlistItemCard(
                title: item.title,
                subtitle: [
                  item.sourceHost,
                  if (item.priceText != null)
                    '${item.priceText} ${item.currency ?? ''}'.trim(),
                ].where((e) => e.isNotEmpty).join(' · '),
                imageUrl: item.imageUrl,
                onReopen: uri != null ? () => onReopenUrl(uri) : null,
                onStylist: () => onSendToStylist(item),
                onAtelier: () => onSendToAtelier(item),
                onRemove: () => onRemoveWeb(item.wishlistKey),
              ),
            );
          }),
          ...catalogItems.map((p) {
            final payload = _catalogToWebProduct(p);
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: _WishlistItemCard(
                title: p.name,
                subtitle:
                    '${strings.tr(p.brand)} · ${strings.formatCurrency(p.lowestPrice)}',
                imageUrl: '',
                onReopen: () => onReopenCatalog(p),
                onStylist: () => onSendToStylist(payload),
                onAtelier: () => onSendToAtelier(payload),
                onRemove: () => onRemoveCatalog(p.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  const _WishlistItemCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onReopen,
    required this.onStylist,
    required this.onAtelier,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onReopen;
  final VoidCallback onStylist;
  final VoidCallback onAtelier;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.rMd,
                child: Container(
                  width: 52,
                  height: 52,
                  color: colors.bg,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.shopping_bag_outlined,
                            color: colors.pr,
                          ),
                        )
                      : Icon(Icons.shopping_bag_outlined, color: colors.pr),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle(color: colors.tx),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption(color: colors.mu),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.shopWishlistRemove,
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: colors.orColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (onReopen != null)
                AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 14),
                  text: strings.shopWishlistReopenBrowser,
                  onPressed: onReopen,
                ),
              AppButton(
                size: AppButtonSize.sm,
                icon: const Icon(Icons.checkroom_rounded, size: 14),
                text: strings.shopWebSendToStylistBtn,
                onPressed: onStylist,
              ),
              AppButton(
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                text: strings.shopWebSendToAtelierBtn,
                onPressed: onAtelier,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
