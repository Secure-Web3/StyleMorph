import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/wardrobe_item.dart';

class WardrobeItemCard extends StatelessWidget {
  const WardrobeItemCard({
    super.key,
    required this.item,
    required this.colors,
    required this.onTap,
    required this.onFav,
    this.onTryOn,
  });

  final WardrobeItem item;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onFav;
  final VoidCallback? onTryOn;

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return const Color(0xFF888888);
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'cl':
        return Icons.checkroom_rounded;
      case 'sh':
        return Icons.snowshoeing_rounded;
      case 'bg':
        return Icons.shopping_bag_outlined;
      case 'jw':
        return Icons.diamond_outlined;
      case 'ac':
        return Icons.watch_outlined;
      default:
        return Icons.checkroom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final itemColor = _parseColor(item.colorHex);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsetsDirectional.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Tile Area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: itemColor.withValues(alpha: 0.18),
                  child: Center(
                    child: Icon(
                      _categoryIcon(item.category),
                      size: 34,
                      color: itemColor,
                    ),
                  ),
                ),
                // Favorite Star Button (top-end)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: GestureDetector(
                    onTap: onFav,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.sf.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 16,
                        color: item.isFavorite
                            ? const Color(0xFFD99A06)
                            : colors.mu,
                      ),
                    ),
                  ),
                ),
                // Season / Occasion badge (top-start)
                if (item.season != 'همه')
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: AppBadge(
                      size: AppBadgeSize.sm,
                      borderRadius: AppRadius.rSm,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        strings.tr(item.season),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                // Quick Try-on button (bottom-end)
                PositionedDirectional(
                  bottom: 6,
                  end: 6,
                  child: GestureDetector(
                    onTap: onTryOn ?? onTap,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: colors.sf.withValues(alpha: 0.9),
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
          // Info Area
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.tr(item.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: itemColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.bd, width: 0.5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${strings.tr(item.colorName)} · ${strings.tr(item.subCategory)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
