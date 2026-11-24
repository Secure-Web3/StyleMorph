import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_media_image.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/wardrobe_item.dart';
import '../wardrobe_provider.dart';
import 'add_item_bottom_sheet.dart';

class WardrobeItemDetailSheet extends ConsumerStatefulWidget {
  const WardrobeItemDetailSheet({
    super.key,
    required this.item,
    required this.onFav,
    required this.onArchive,
    required this.onDelete,
    this.onEdit,
  });

  final WardrobeItem item;
  final VoidCallback onFav;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  ConsumerState<WardrobeItemDetailSheet> createState() =>
      _WardrobeItemDetailSheetState();
}

class _WardrobeItemDetailSheetState
    extends ConsumerState<WardrobeItemDetailSheet> {
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

  String _categoryLabel(String cat, AppStrings strings) {
    switch (cat) {
      case 'cl':
        return strings.wardCatCl;
      case 'sh':
        return strings.wardCatSh;
      case 'bg':
        return strings.wardCatBg;
      case 'jw':
        return strings.wardCatJw;
      case 'ac':
        return strings.wardCatAc;
      default:
        return strings.wardCategory;
    }
  }

  Widget _buildPlaceholder(Color itemColor, String category) {
    return Center(
      child: Icon(_categoryIcon(category), size: 56, color: itemColor),
    );
  }

  void _openEditSheet(BuildContext context, WardrobeItem currentItem) {
    if (widget.onEdit != null) {
      widget.onEdit!();
      return;
    }
    AppModal.showSheet(
      context: context,
      child: AddItemBottomSheet(
        itemToEdit: currentItem,
        onEdit: (updated) =>
            ref.read(wardrobeProvider.notifier).updateItem(updated),
        onEditWithImage:
            ({
              required String id,
              Uint8List? newImageBytes,
              String? mimeType,
              required String title,
              required String category,
              required String subCategory,
              required String colorName,
              required String colorHex,
              required String season,
              required String occasion,
              required String material,
              required String size,
            }) => ref
                .read(wardrobeProvider.notifier)
                .updateItemWithImage(
                  id: id,
                  newImageBytes: newImageBytes,
                  mimeType: mimeType,
                  title: title,
                  category: category,
                  subCategory: subCategory,
                  colorName: colorName,
                  colorHex: colorHex,
                  season: season,
                  occasion: occasion,
                  material: material,
                  size: size,
                ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    AppStrings strings,
    AppColors colors,
    String localizedName,
  ) {
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
                    widget.onDelete();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final ws = ref.watch(wardrobeProvider);
    final item = ws.items.cast<WardrobeItem?>().firstWhere(
      (e) => e?.id == widget.item.id,
      orElse: () => widget.item,
    )!;
    final itemColor = _parseColor(item.colorHex);
    final localizedName = strings.tr(item.name);

    return AppBottomSheetShell(
      title: localizedName,
      headerActions: [
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 20, color: colors.mu),
          tooltip: strings.wardEditItem,
          onPressed: () => _openEditSheet(context, item),
        ),
        IconButton(
          icon: Icon(
            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            size: 20,
            color: item.isFavorite ? const Color(0xFFD99A06) : colors.mu,
          ),
          onPressed: widget.onFav,
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
                  icon: Icon(Icons.edit_outlined, size: 15, color: colors.tx),
                  text: strings.wardEditItem,
                  onPressed: () => _openEditSheet(context, item),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                    widget.onArchive();
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
                  text: strings.wardDelete,
                  onPressed: () => _showDeleteDialog(
                    context,
                    strings,
                    colors,
                    localizedName,
                  ),
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
          // Big preview tile: 260px height for prominent presentation
          AppCard(
            height: 260,
            backgroundColor: itemColor.withValues(alpha: 0.18),
            clipBehavior: Clip.antiAlias,
            padding: EdgeInsetsDirectional.zero,
            child: (item.originalUrl.isNotEmpty || item.thumbUrl.isNotEmpty)
                ? AppMediaImage(
                    item.originalUrl.isNotEmpty
                        ? item.originalUrl
                        : item.thumbUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 260,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(itemColor, item.category),
                  )
                : _buildPlaceholder(itemColor, item.category),
          ),
          const SizedBox(height: AppSpacing.md),

          // Specs list: displays category label instead of raw subCategory
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              children: [
                _SpecRow(
                  label: strings.wardCategory,
                  value: _categoryLabel(item.category, strings),
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
