import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../domain/shop_product.dart';
import 'try_on_sheet.dart';
import 'seller_redirect_sheet.dart';

class ShopProductDetailSheet extends StatefulWidget {
  const ShopProductDetailSheet({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.isCompared,
    required this.hasPriceAlert,
    required this.onWishlist,
    required this.onCompare,
    required this.onPriceAlert,
  });

  final ShopProduct product;
  final bool isWishlisted;
  final bool isCompared;
  final bool hasPriceAlert;
  final VoidCallback onWishlist;
  final VoidCallback onCompare;
  final VoidCallback onPriceAlert;

  @override
  State<ShopProductDetailSheet> createState() => _ShopProductDetailSheetState();
}

class _ShopProductDetailSheetState extends State<ShopProductDetailSheet> {
  int _activeImageIndex = 0;

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return const Color(0xFF6B8FB5);
  }

  IconData _productIcon(String name) {
    switch (name) {
      case 'shirt':
        return Icons.checkroom_rounded;
      case 'shoe':
        return Icons.snowshoeing_rounded;
      case 'vest':
        return Icons.dry_cleaning_rounded;
      case 'bag':
        return Icons.shopping_bag_outlined;
      case 'briefcase':
        return Icons.work_outline_rounded;
      case 'clock':
        return Icons.watch_outlined;
      case 'gem':
        return Icons.diamond_outlined;
      case 'mitten':
        return Icons.style_outlined;
      case 'person':
        return Icons.accessibility_new_rounded;
      case 'palette':
        return Icons.palette_outlined;
      case 'wand':
        return Icons.auto_awesome_rounded;
      case 'tie':
        return Icons.person_pin_rounded;
      case 'glasses':
        return Icons.visibility_outlined;
      default:
        return Icons.checkroom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final p = widget.product;
    final localizedName = strings.tr(p.name);
    final itemColor = _parseColor(p.colorHex);
    final sortedSellers = List<ShopSeller>.from(p.sellers)
      ..sort((a, b) => a.price.compareTo(b.price));
    final cheapest = sortedSellers.isNotEmpty ? sortedSellers.first : null;

    return AppBottomSheetShell(
      title: localizedName,
      maxHeightFactor: 0.90,
      headerActions: [
        IconButton(
          icon: Icon(
            widget.isWishlisted
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 20,
            color: widget.isWishlisted
                ? const Color(0xFFD1456B)
                : colors.mu,
          ),
          onPressed: widget.onWishlist,
        ),
      ],
      bottomBar: AppButton(
        isFullWidth: true,
        text: cheapest?.purchaseMethod == 'site'
            ? strings.shopViewOnSite
            : '${strings.shopBuyFromApp} · ${strings.formatCurrency(p.lowestPrice)}',
        onPressed: () {
          if (cheapest == null) return;
          if (cheapest.purchaseMethod == 'site') {
            AppModal.showSheet(
              context: context,
              child: SellerRedirectSheet(
                product: p,
                seller: cheapest,
              ),
            );
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  strings.shopOrderPlaced(localizedName),
                  style: const TextStyle(fontFamily: 'Vazirmatn'),
                ),
              ),
            );
          }
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Carousel
          Stack(
            children: [
              SizedBox(
                height: 180,
                child: PageView(
                  onPageChanged: (idx) =>
                      setState(() => _activeImageIndex = idx),
                  children: [
                    _CarouselSlide(
                      color: itemColor.withValues(alpha: 0.24),
                      icon: _productIcon(p.iconName),
                      iconColor: itemColor,
                    ),
                    _CarouselSlide(
                      color: itemColor.withValues(alpha: 0.14),
                      icon: _productIcon(p.iconName),
                      iconColor: itemColor,
                    ),
                  ],
                ),
              ),
              if (p.discountPercent > 0)
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: AppBadge(
                    variant: AppBadgeVariant.destructive,
                    size: AppBadgeSize.sm,
                    borderRadius: AppRadius.rSm,
                    child: Text(
                      '${strings.formatPercent(p.discountPercent)} ${strings.shopDiscountWord}',
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (idx) {
                    final isActive = _activeImageIndex == idx;
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isActive ? colors.pr : colors.bd,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Brand & Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.tr(p.brand),
                style: AppTypography.cardTitle(color: colors.pr),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: Color(0xFFD9A406),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${strings.formatNumber(p.rating)} (${strings.countWithUnit(p.reviewCount, strings.shopReviewUnit)})',
                    style: AppTypography.caption(color: colors.mu),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.auto_awesome_rounded,
                  label: strings.tryOnShortcut,
                  color: colors.pr,
                  onTap: () {
                    AppModal.showSheet(
                      context: context,
                      child: TryOnSheet(product: p),
                    );
                  },
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionTile(
                  icon: widget.hasPriceAlert
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  label: widget.hasPriceAlert
                      ? strings.shopAlertActive
                      : strings.priceAlert,
                  color: widget.hasPriceAlert
                      ? colors.wn
                      : colors.mu,
                  onTap: widget.onPriceAlert,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionTile(
                  icon: Icons.balance_rounded,
                  label: widget.isCompared
                      ? strings.shopCompareActive
                      : strings.compare,
                  color: widget.isCompared ? colors.pr : colors.mu,
                  onTap: widget.onCompare,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // "Fit Me" Box
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.shopFitTitle,
                  style: AppTypography.cardTitle(color: colors.tx),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: colors.ok,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strings.shopFitSizeOk,
                        style: AppTypography.caption(color: colors.tx),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 14,
                      color: colors.pr,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${strings.shopFitColorsOk}: ${p.colors.map(strings.tr).join(', ')}',
                        style: AppTypography.caption(color: colors.mu),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Wardrobe Fit Box (if exists)
          if (p.wardrobeFit.isNotEmpty) ...[
            AppCard(
              backgroundColor: colors.pr.withValues(alpha: 0.06),
              borderColor: colors.pr.withValues(alpha: 0.2),
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checkroom_rounded,
                          size: 16, color: colors.pr),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          strings.shopWardrobeMatchTitle,
                          style: AppTypography.cardTitle(color: colors.pr),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.wardrobeFit.map((item) {
                      return AppBadge(
                        size: AppBadgeSize.sm,
                        child: Text(strings.tr(item)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Seller Comparison List
          Text(
            strings.shopSellersTitle,
            style: AppTypography.cardTitle(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: sortedSellers.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isCheapest = idx == 0;

              return AppCard(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                borderColor: isCheapest ? colors.pr : colors.bd,
                borderWidth: isCheapest ? 1.5 : 1.0,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                strings.tr(s.storeName),
                                style: AppTypography.cardTitle(color: colors.tx),
                              ),
                              if (isCheapest) ...[
                                const SizedBox(width: 6),
                                AppBadge(
                                  variant: AppBadgeVariant.active,
                                  size: AppBadgeSize.sm,
                                  borderRadius: AppRadius.rSm,
                                  child: Text(
                                    strings.shopCheapest,
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${strings.shopDelivery}: ${strings.tr(s.deliveryTime)} · ${s.purchaseMethod == 'app' ? strings.shopBuyInApp : strings.shopGoToSite}',
                            style: AppTypography.caption(color: colors.mu),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          strings.formatCurrency(s.price),
                          style: AppTypography.cardTitle(color: colors.tx),
                        ),
                        const SizedBox(height: 4),
                        if (s.purchaseMethod == 'site')
                          AppButton(
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.sm,
                            height: 28,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            icon: Icon(
                              Icons.arrow_outward_rounded,
                              size: 12,
                              color: colors.mu,
                            ),
                            text: strings.shopSellerSiteBtn,
                            onPressed: () {
                              AppModal.showSheet(
                                context: context,
                                child: SellerRedirectSheet(
                                  product: p,
                                  seller: s,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Specs
          Text(
            strings.shopProductSpecs,
            style: AppTypography.cardTitle(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              children: [
                _SpecLine(
                  label: strings.shopBrand,
                  value: strings.tr(p.brand),
                  colors: colors,
                ),
                _SpecLine(
                  label: strings.shopMaterial,
                  value: strings.tr(p.material),
                  colors: colors,
                ),
                _SpecLine(
                  label: strings.wardSeason,
                  value: strings.tr(p.season),
                  colors: colors,
                ),
                _SpecLine(
                  label: strings.shopColorsLabel,
                  value: p.colors.map(strings.tr).join(', '),
                  colors: colors,
                ),
                if (p.sizes.isNotEmpty)
                  _SpecLine(
                    label: strings.shopSizesLabel,
                    value: p.sizes.map(strings.tr).join(', '),
                    colors: colors,
                    isLast: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselSlide extends StatelessWidget {
  const _CarouselSlide({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.rCard,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: iconColor,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      variant: AppCardVariant.subtle,
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecLine extends StatelessWidget {
  const _SpecLine({
    required this.label,
    required this.value,
    required this.colors,
    this.isLast = false,
  });

  final String label;
  final String value;
  final AppColors colors;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: colors.bd, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: colors.mu,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}
