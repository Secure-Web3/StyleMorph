import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/shop_product.dart';

class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    super.key,
    required this.product,
    required this.colors,
    required this.isWishlisted,
    required this.isCompared,
    required this.onTap,
    required this.onWishlist,
    required this.onCompare,
    required this.onTryOn,
  });

  final ShopProduct product;
  final AppColors colors;
  final bool isWishlisted;
  final bool isCompared;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  final VoidCallback onCompare;
  final VoidCallback onTryOn;

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
    final strings = context.strings;
    final itemColor = _parseColor(product.colorHex);
    final disc = product.discountPercent;
    final own = product.isOwn;
    final avail = product.isAvailable;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsetsDirectional.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / Tile Area
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: itemColor.withOpacity(0.18),
                    child: Center(
                      child: Icon(
                        _productIcon(product.iconName),
                        size: 38,
                        color: itemColor,
                      ),
                    ),
                  ),
                  // Badges top-start
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (own)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: AppBadge(
                              size: AppBadgeSize.sm,
                              borderRadius: AppRadius.rSm,
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 10,
                                    color: colors.ok,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    strings.shopAppBadge,
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (disc > 0)
                          AppBadge(
                            variant: AppBadgeVariant.destructive,
                            size: AppBadgeSize.sm,
                            borderRadius: AppRadius.rSm,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              strings.formatPercent(disc),
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Wishlist Button (top-end)
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: GestureDetector(
                      onTap: onWishlist,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colors.sf.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 15,
                          color: isWishlisted
                              ? const Color(0xFFD1456B)
                              : colors.mu,
                        ),
                      ),
                    ),
                  ),
                  // Compare Button (bottom-start)
                  PositionedDirectional(
                    bottom: 6,
                    start: 6,
                    child: GestureDetector(
                      onTap: onCompare,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isCompared ? colors.pr : colors.sf.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.bd, width: 0.5),
                        ),
                        child: Icon(
                          Icons.balance_rounded,
                          size: 13,
                          color: isCompared ? colors.prt : colors.mu,
                        ),
                      ),
                    ),
                  ),
                  // Try-on Shortcut (bottom-end)
                  PositionedDirectional(
                    bottom: 6,
                    end: 6,
                    child: GestureDetector(
                      onTap: onTryOn,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: colors.sf.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.bd, width: 0.5),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: colors.pr,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details Area
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tr(product.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.tx,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.tr(product.brand),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: colors.mu,
                          ),
                        ),
                      ],
                    ),
                    // Price
                    if (avail)
                      Text(
                        product.sellers.length > 1
                            ? '${strings.shopFromPrice} ${strings.formatCurrency(product.lowestPrice)}'
                            : strings.formatCurrency(product.lowestPrice),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.tx,
                        ),
                      )
                    else
                      Text(
                        strings.shopOutOfStock,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.mu,
                        ),
                      ),
                    // Sellers count + Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          own
                              ? 'StyleMorph'
                              : strings.countWithUnit(
                                  product.sellers.length,
                                  strings.shopStoreUnit,
                                ),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 9,
                            color: colors.mu,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFFD9A406),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              strings.formatNumber(product.rating),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colors.tx,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Wardrobe Fit indicator
                    if (product.wardrobeFit.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.checkroom_rounded,
                            size: 10,
                            color: colors.pr,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              strings.matchWardrobe,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colors.pr,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
