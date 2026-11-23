import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/digit_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/wardrobe_item.dart';
import 'wardrobe_provider.dart';
import 'widgets/add_item_bottom_sheet.dart';
import 'widgets/wardrobe_filter_panel.dart';
import 'widgets/wardrobe_item_card.dart';
import 'widgets/wardrobe_item_detail_sheet.dart';

class WardrobeTab extends ConsumerWidget {
  const WardrobeTab({super.key});

  static const _categories = [
    ('all', 'همه', Icons.grid_view_rounded),
    ('cl', 'لباس', Icons.checkroom_outlined),
    ('sh', 'کفش', Icons.snowshoeing_outlined),
    ('bg', 'کیف', Icons.shopping_bag_outlined),
    ('jw', 'زیورآلات', Icons.diamond_outlined),
    ('ac', 'اکسسوری', Icons.watch_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final ws = ref.watch(wardrobeProvider);
    final notifier = ref.read(wardrobeProvider.notifier);
    final totalActive = ws.countByCategory('all');
    const totalCapacity = 30;

    final String activeCategoryTitle;
    final int activeCategoryCount;
    if (ws.filter.showArchived) {
      activeCategoryTitle = strings.wardArchive;
      activeCategoryCount = ws.items.where((e) => e.isArchived).length;
    } else {
      final catTuple = _categories.firstWhere(
        (c) => c.$1 == ws.filter.category,
        orElse: () => _categories.first,
      );
      activeCategoryTitle = strings.tr(catTuple.$2);
      activeCategoryCount = ws.countByCategory(ws.filter.category);
    }

    final hasActiveFilters =
        ws.filter.searchQuery.isNotEmpty || ws.filter.activeFilterCount > 0;

    return Column(
      children: [
        // --- Top bar: title + capacity + add button ---
        _TopBar(
          totalActive: totalActive,
          totalCapacity: totalCapacity,
          colors: colors,
          onAdd: () => _showAddSheet(context, ref),
        ),
        // --- Main body: sidebar + content ---
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Right sidebar: category buttons (RTL-first → sidebar on right)
              _CategorySidebar(
                categories: _categories,
                selected: ws.filter.category,
                colors: colors,
                itemCount: ws.countByCategory,
                onSelect: notifier.setCategory,
              ),
              // Divider
              VerticalDivider(width: 1, thickness: 1, color: colors.bd),
              // Content area
              Expanded(
                child: Column(
                  children: [
                    // Search + filter trigger + archive toggle
                    _SearchBar(
                      colors: colors,
                      activeFilterCount: ws.filter.activeFilterCount,
                      showArchived: ws.filter.showArchived,
                      onSearch: notifier.setSearch,
                      onOpenFilter: () => _showFilterSheet(context, ref),
                      onToggleArchive: notifier.toggleArchiveView,
                    ),
                    // Active category header + count badge
                    _CategoryHeader(
                      title: activeCategoryTitle,
                      count: activeCategoryCount,
                      colors: colors,
                    ),
                    // Garment Grid or Empty States
                    Expanded(
                      child: _WardrobeGrid(
                        items: ws.filteredItems,
                        colors: colors,
                        isLoading: ws.isLoading,
                        isLoadingMore: ws.isLoadingMore,
                        hasMore: ws.hasMore,
                        onLoadMore: notifier.loadMore,
                        onTap: (item) => _showDetailSheet(context, ref, item),
                        onFav: notifier.toggleFavorite,
                        onArchive: notifier.toggleArchive,
                        onAdd: () => _showAddSheet(context, ref),
                        onClearFilters: notifier.clearFilters,
                        showArchived: ws.filter.showArchived,
                        hasActiveFilters: hasActiveFilters,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    AppModal.showSheet(
      context: context,
      child: AddItemBottomSheet(
        onAdd: (item) => ref.read(wardrobeProvider.notifier).addItem(item),
        onAddWithImage:
            ({
              required Uint8List imageBytes,
              required String mimeType,
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
                .addItemWithImage(
                  imageBytes: imageBytes,
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

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final ws = ref.read(wardrobeProvider);
    final notifier = ref.read(wardrobeProvider.notifier);
    AppModal.showSheet(
      context: context,
      child: WardrobeFilterSheet(
        initialFilter: ws.filter,
        colors: context.colors,
        onApply: (color, season, occasion) {
          notifier.applyAdvancedFilters(
            color: color,
            season: season,
            occasion: occasion,
          );
        },
        onClear: notifier.clearFilters,
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    WardrobeItem item,
  ) {
    AppModal.showSheet(
      context: context,
      child: WardrobeItemDetailSheet(
        item: item,
        onFav: () =>
            ref.read(wardrobeProvider.notifier).toggleFavorite(item.id),
        onArchive: () =>
            ref.read(wardrobeProvider.notifier).toggleArchive(item.id),
        onDelete: () {
          Navigator.pop(context);
          ref.read(wardrobeProvider.notifier).deleteItem(item.id);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.totalActive,
    required this.totalCapacity,
    required this.colors,
    required this.onAdd,
  });

  final int totalActive;
  final int totalCapacity;
  final AppColors colors;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final pct = (totalActive / totalCapacity).clamp(0.0, 1.0);
    return AppModuleHeader(
      icon: Icons.checkroom_rounded,
      title: strings.wardrobeTitle,
      trailing: AppButton(
        size: AppButtonSize.sm,
        icon: Icon(Icons.add_rounded, size: 15, color: colors.prt),
        text: strings.uploadItem,
        onPressed: onAdd,
      ),
      bottom: Row(
        children: [
          AppBadge(
            variant: AppBadgeVariant.info,
            size: AppBadgeSize.sm,
            child: Text(
              strings.countWithUnit(totalActive, strings.wardItemUnit),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.rFull,
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: colors.bd,
                valueColor: AlwaysStoppedAnimation<Color>(colors.inColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            strings.capacityRatioText(totalActive, totalCapacity),
            style: AppTypography.caption(color: colors.mu),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.categories,
    required this.selected,
    required this.colors,
    required this.itemCount,
    required this.onSelect,
  });

  final List<(String, String, IconData)> categories;
  final String selected;
  final AppColors colors;
  final int Function(String) itemCount;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SizedBox(
      width: 72,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final (code, label, icon) = categories[i];
          final isActive = selected == code;
          final count = itemCount(code);
          return InkWell(
            onTap: () => onSelect(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.pr.withValues(alpha: 0.08)
                    : Colors.transparent,
                border: BorderDirectional(
                  start: BorderSide(
                    color: isActive ? colors.pr : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isActive ? colors.pr : colors.mu,
                      ),
                      PositionedDirectional(
                        top: -5,
                        end: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? colors.pr
                                : (count > 0
                                      ? colors.sf
                                      : colors.sf.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? colors.pr
                                  : (count > 0
                                        ? colors.bd
                                        : colors.bd.withValues(alpha: 0.6)),
                              width: 0.8,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            DigitFormatter.localizeDigits(
                              count,
                              strings.localeCode,
                            ),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 8.5,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? colors.prt
                                  : (count > 0
                                        ? colors.tx
                                        : colors.mu.withValues(alpha: 0.7)),
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.tr(label),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? colors.pr : colors.mu,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.title,
    required this.count,
    required this.colors,
  });

  final String title;
  final int count;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppBadge(
            variant: AppBadgeVariant.standard,
            size: AppBadgeSize.sm,
            child: Text(
              DigitFormatter.localizeDigits(count, strings.localeCode),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.pr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.colors,
    required this.activeFilterCount,
    required this.showArchived,
    required this.onSearch,
    required this.onOpenFilter,
    required this.onToggleArchive,
  });

  final AppColors colors;
  final int activeFilterCount;
  final bool showArchived;
  final void Function(String) onSearch;
  final VoidCallback onOpenFilter;
  final VoidCallback onToggleArchive;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final strings = context.strings;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      color: c.sf,
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              controller: _ctrl,
              hintText: strings.searchWardrobe,
              onChanged: widget.onSearch,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppIconButton(
                icon: Icons.tune_rounded,
                isActive: widget.activeFilterCount > 0,
                onTap: widget.onOpenFilter,
              ),
              if (widget.activeFilterCount > 0)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: c.pr,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 14,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DigitFormatter.localizeDigits(
                        widget.activeFilterCount,
                        strings.localeCode,
                      ),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: c.prt,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: Icons.inventory_2_outlined,
            isActive: widget.showArchived,
            tooltip: strings.wardArchive,
            onTap: widget.onToggleArchive,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _WardrobeGrid extends StatelessWidget {
  const _WardrobeGrid({
    required this.items,
    required this.colors,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    required this.onTap,
    required this.onFav,
    required this.onArchive,
    required this.onAdd,
    required this.onClearFilters,
    required this.showArchived,
    required this.hasActiveFilters,
  });

  final List<WardrobeItem> items;
  final AppColors colors;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final void Function(WardrobeItem) onTap;
  final void Function(String) onFav;
  final void Function(String) onArchive;
  final VoidCallback onAdd;
  final VoidCallback onClearFilters;
  final bool showArchived;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    if (isLoading && items.isEmpty) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.pr),
        ),
      );
    }

    if (items.isEmpty) {
      if (showArchived) {
        // Archived View Empty State: No items in archive, NO add button
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: colors.mu),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.wardArchiveEmpty,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.mu,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      if (hasActiveFilters) {
        // Filtered No-Results State: items exist in wardrobe but current filters/search have 0 matches
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: colors.mu),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.wardNotFound,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.mu,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  text: strings.clearFilters,
                  onPressed: onClearFilters,
                ),
              ],
            ),
          ),
        );
      }

      // Active Wardrobe Empty State: 0 items in category/view, prompt to add first item
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checkroom_outlined, size: 48, color: colors.mu),
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.wardEmptyState,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.mu,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                icon: const Icon(Icons.add_rounded, size: 16),
                text: strings.wardAddFirstItem,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      );
    }

    final gridCount = showArchived ? items.length : items.length + 1;

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (hasMore &&
            !isLoadingMore &&
            onLoadMore != null &&
            scrollInfo.metrics.extentAfter < 200) {
          onLoadMore!();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate((_, i) {
                if (!showArchived && i == items.length) {
                  return _AddDashedCard(colors: colors, onTap: onAdd);
                }
                final item = items[i];
                return WardrobeItemCard(
                  item: item,
                  colors: colors,
                  onTap: () => onTap(item),
                  onFav: () => onFav(item.id),
                  onArchive: () => onArchive(item.id),
                );
              }, childCount: gridCount),
            ),
          ),
          if (hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Center(
                  child: AppButton(
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    icon: isLoadingMore
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.tx,
                            ),
                          )
                        : const Icon(Icons.expand_more_rounded, size: 16),
                    text: isLoadingMore
                        ? strings.wardSaving
                        : strings.wardLoadMore,
                    onPressed: isLoadingMore ? null : onLoadMore,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _AddDashedCard extends StatelessWidget {
  const _AddDashedCard({required this.colors, required this.onTap});

  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.bd,
            width: 1.5,
            style: BorderStyle.none,
          ),
          borderRadius: AppRadius.rCard,
          color: colors.bg,
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: colors.bd),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 28, color: colors.mu),
                const SizedBox(height: 6),
                Text(
                  strings.wardAddItem,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.mu,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = AppRadius.card;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().first;
    double dist = 0;
    while (dist < metrics.length) {
      canvas.drawPath(metrics.extractPath(dist, dist + dashWidth), paint);
      dist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
