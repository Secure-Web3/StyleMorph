import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/wardrobe_item.dart';

class WardrobeItemDetailSheet extends StatelessWidget {
  const WardrobeItemDetailSheet({
    super.key,
    required this.item,
    required this.onFav,
    required this.onArchive,
    required this.onDelete,
  });

  final WardrobeItem item;
  final VoidCallback onFav;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

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
    final colors = context.colors;
    final strings = context.strings;
    final itemColor = _parseColor(item.colorHex);
    final localizedName = strings.tr(item.name);

    return AppBottomSheetShell(
      title: localizedName,
      headerActions: [
        IconButton(
          icon: Icon(
            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            size: 20,
            color: item.isFavorite ? const Color(0xFFD99A06) : colors.mu,
          ),
          onPressed: onFav,
        ),
      ],
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            isFullWidth: true,
            icon: Icon(Icons.auto_awesome_rounded, size: 16, color: colors.prt),
            text: strings.wardStyleInStylist,
            onPressed: () {
              Navigator.pop(context);
              AppToast.showSuccess(
                context,
                strings.wardSentToStylist(localizedName),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  icon: Icon(
                    item.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    size: 15,
                    color: colors.tx,
                  ),
                  text: item.isArchived
                      ? strings.wardUnarchive
                      : strings.wardArchiveAction,
                  onPressed: () {
                    onArchive();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 15,
                    color: colors.orColor,
                  ),
                  text: strings.wardDeleteFromWardrobe,
                  onPressed: () {
                    AppModal.showAppDialog(
                      context: context,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.wardDeleteTitle,
                            style: AppTypography.sectionTitle(color: colors.tx),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            strings.wardDeleteConfirm(localizedName),
                            style: AppTypography.bodySmall(color: colors.mu),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  variant: AppButtonVariant.outline,
                                  size: AppButtonSize.sm,
                                  text: strings.wardCancel,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppButton(
                                  variant: AppButtonVariant.destructive,
                                  size: AppButtonSize.sm,
                                  text: strings.wardDelete,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onDelete();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Big preview tile
          AppCard(
            height: 130,
            backgroundColor: itemColor.withValues(alpha: 0.18),
            child: Center(
              child: Icon(
                _categoryIcon(item.category),
                size: 56,
                color: itemColor,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Specs list
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              children: [
                _SpecRow(
                  label: strings.wardCategory,
                  value: strings.tr(item.subCategory),
                  colors: colors,
                ),
                _SpecRow(
                  label: strings.wardSpecMainColor,
                  value: strings.tr(item.colorName),
                  colors: colors,
                  trailing: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsetsDirectional.only(start: 6),
                    decoration: BoxDecoration(
                      color: itemColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.bd, width: 0.5),
                    ),
                  ),
                ),
                _SpecRow(
                  label: strings.wardSpecSeason,
                  value: strings.tr(item.season),
                  colors: colors,
                ),
                _SpecRow(
                  label: strings.wardOccasion,
                  value: strings.tr(item.occasion),
                  colors: colors,
                ),
                _SpecRow(
                  label: strings.wardSpecMaterial,
                  value: strings.tr(item.material),
                  colors: colors,
                ),
                _SpecRow(
                  label: strings.wardSpecSize,
                  value: strings.tr(item.size),
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

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.label,
    required this.value,
    required this.colors,
    this.trailing,
    this.isLast = false,
  });

  final String label;
  final String value;
  final AppColors colors;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.bd, width: 0.5)),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.tx,
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}
