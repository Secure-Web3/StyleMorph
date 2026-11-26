import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/digit_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_modal.dart';
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
    ('all', Icons.grid_view_rounded),
    ('tops', Icons.checkroom_outlined),
    ('bottoms', Icons.view_agenda_outlined),
    ('outfit', Icons.woman_2_outlined),
    ('outerwear', Icons.wb_cloudy_outlined),
    ('underwear', Icons.bedtime_outlined),
    ('activewear', Icons.fitness_center_rounded),
    ('footwear', Icons.snowshoeing_outlined),
    ('bags', Icons.shopping_bag_outlined),
    ('jewelry', Icons.diamond_outlined),
    ('accessories', Icons.watch_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final ws = ref.watch(wardrobeProvider);
    final notifier = ref.read(wardrobeProvider.notifier);
    final totalActive = ws.countByCategory('all');
    const totalCapacity = 30;

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
                    // Blue Capsule Info Box when active category has helper hint
                    if (ws.filter.category != 'all' &&
                        strings
                            .wardrobeCategoryHint(ws.filter.category)
                            .isNotEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.sm,
                          0,
                          AppSpacing.sm,
                          AppSpacing.xs,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.inb,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: colors.inColor.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: colors.inColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  strings.wardrobeCategoryHint(
                                    ws.filter.category,
                                  ),
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: colors.inColor,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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
        onAddWithImages:
            ({
              required images,
              mimeTypes,
              required title,
              required category,
              required subCategory,
              required colorName,
              required colorHex,
              required season,
              required occasion,
              required material,
              required size,
            }) => ref
                .read(wardrobeProvider.notifier)
                .addItemWithImages(
                  images: images,
                  mimeTypes: mimeTypes,
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
        onApply:
            (
              color,
              season,
              occasion, {
              multiSelectMode = false,
              selectedColors = const {},
              selectedSeasons = const {},
              selectedOccasions = const {},
            }) {
              notifier.applyAdvancedFilters(
                color: color,
                season: season,
                occasion: occasion,
                multiSelectMode: multiSelectMode,
                selectedColors: selectedColors,
                selectedSeasons: selectedSeasons,
                selectedOccasions: selectedOccasions,
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
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        border: Border(bottom: BorderSide(color: colors.bd, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.checkroom_rounded, size: 18, color: colors.pr),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        strings.wardrobeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.moduleTitle(color: colors.tx),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      strings.capacityRatioText(totalActive, totalCapacity),
                      style: AppTypography.caption(color: colors.mu),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.rFull,
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: colors.bd,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.inColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppButton(
            size: AppButtonSize.sm,
            icon: Icon(Icons.add_rounded, size: 15, color: colors.prt),
            text: strings.uploadItem,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _CategorySidebar extends StatefulWidget {
  const _CategorySidebar({
    required this.categories,
    required this.selected,
    required this.colors,
    required this.itemCount,
    required this.onSelect,
  });

  final List<(String, IconData)> categories;
  final String selected;
  final AppColors colors;
  final int Function(String) itemCount;
  final void Function(String) onSelect;

  @override
  State<_CategorySidebar> createState() => _CategorySidebarState();
}

class _CategorySidebarState extends State<_CategorySidebar> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollDown = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleScrollMetrics(ScrollMetrics metrics) {
    final canScroll = metrics.maxScrollExtent - metrics.pixels > 4.0;
    if (canScroll != _canScrollDown && mounted) {
      setState(() => _canScrollDown = canScroll);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final isCompactHeight = MediaQuery.sizeOf(context).height < 720;
    final itemVerticalPadding = isCompactHeight ? 8.0 : 12.0;

    return SizedBox(
      width: 72,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) => _handleScrollMetrics(n.metrics),
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (n) => _handleScrollMetrics(n.metrics),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: widget.categories.length,
                itemBuilder: (_, i) {
                  final (code, icon) = widget.categories[i];
                  final isActive = widget.selected == code;
                  final count = widget.itemCount(code);
                  return InkWell(
                    onTap: () => widget.onSelect(code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: itemVerticalPadding,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? widget.colors.pr.withValues(alpha: 0.08)
                            : Colors.transparent,
                        border: BorderDirectional(
                          start: BorderSide(
                            color: isActive
                                ? widget.colors.pr
                                : Colors.transparent,
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
                                color: isActive
                                    ? widget.colors.pr
                                    : widget.colors.mu,
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
                                        ? widget.colors.pr
                                        : (count > 0
                                              ? widget.colors.sf
                                              : widget.colors.sf.withValues(
                                                  alpha: 0.5,
                                                )),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive
                                          ? widget.colors.pr
                                          : (count > 0
                                                ? widget.colors.bd
                                                : widget.colors.bd.withValues(
                                                    alpha: 0.6,
                                                  )),
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
                                      fontSize: 8.5,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isActive
                                          ? widget.colors.prt
                                          : (count > 0
                                                ? widget.colors.tx
                                                : widget.colors.mu.withValues(
                                                    alpha: 0.7,
                                                  )),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.wardrobeCategoryName(code),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9.5,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? widget.colors.pr
                                  : widget.colors.mu,
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
            ),
          ),
          if (_canScrollDown)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 28,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const Key('wardrobe_sidebar_scroll_fade'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.colors.bg.withValues(alpha: 0.0),
                        widget.colors.bg.withValues(alpha: 0.94),
                      ],
                    ),
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
