import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/wardrobe_item.dart';
import 'wardrobe_provider.dart';
import 'widgets/wardrobe_item_card.dart';
import 'widgets/wardrobe_filter_panel.dart';
import 'widgets/add_item_bottom_sheet.dart';
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
    final ws = ref.watch(wardrobeProvider);
    final notifier = ref.read(wardrobeProvider.notifier);
    final totalActive = ws.countByCategory('all');
    const totalCapacity = 30;

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
                wardrobeState: ws,
                colors: colors,
                onSelect: notifier.setCategory,
              ),
              // Divider
              VerticalDivider(width: 1, thickness: 1, color: colors.bd),
              // Content area
              Expanded(
                child: Column(
                  children: [
                    // Search + action buttons
                    _SearchBar(
                      colors: colors,
                      filterOpen: ws.filterPanelOpen,
                      showArchived: ws.filter.showArchived,
                      onSearch: notifier.setSearch,
                      onToggleFilter: notifier.toggleFilterPanel,
                      onToggleArchive: notifier.toggleArchiveView,
                    ),
                    // Collapsible filter panel
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: ws.filterPanelOpen
                          ? WardrobeFilterPanel(
                              filter: ws.filter,
                              onColor: notifier.setColorFilter,
                              onSeason: notifier.setSeasonFilter,
                              onOccasion: notifier.setOccasionFilter,
                              onClear: notifier.clearFilters,
                              colors: colors,
                            )
                          : const SizedBox.shrink(),
                    ),
                    // Grid
                    Expanded(
                      child: _WardrobeGrid(
                        items: ws.filteredItems,
                        colors: colors,
                        onTap: (item) => _showDetailSheet(context, ref, item),
                        onFav: notifier.toggleFavorite,
                        onAdd: () => _showAddSheet(context, ref),
                        showArchived: ws.filter.showArchived,
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
        onFav: () => ref.read(wardrobeProvider.notifier).toggleFavorite(item.id),
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
    required this.wardrobeState,
    required this.colors,
    required this.onSelect,
  });

  final List<(String, String, IconData)> categories;
  final String selected;
  final WardrobeState wardrobeState;
  final AppColors colors;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SizedBox(
      width: 72,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final (code, label, icon) = categories[i];
          final isActive = selected == code;
          final count = wardrobeState.countByCategory(code);
          return GestureDetector(
            onTap: () => onSelect(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? colors.pr.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? Border.all(color: colors.pr, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isActive ? colors.pr : colors.mu,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.tr(label),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 9,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.normal,
                      color: isActive ? colors.pr : colors.mu,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? colors.pr : colors.bd,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        strings.formatNumber(count),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 9,
                          color: isActive ? colors.prt : colors.mu,
                        ),
                      ),
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
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.colors,
    required this.filterOpen,
    required this.showArchived,
    required this.onSearch,
    required this.onToggleFilter,
    required this.onToggleArchive,
  });

  final AppColors colors;
  final bool filterOpen;
  final bool showArchived;
  final void Function(String) onSearch;
  final VoidCallback onToggleFilter;
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
          AppIconButton(
            icon: Icons.tune_rounded,
            isActive: widget.filterOpen,
            onTap: widget.onToggleFilter,
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
    required this.onTap,
    required this.onFav,
    required this.onAdd,
    required this.showArchived,
  });

  final List<WardrobeItem> items;
  final AppColors colors;
  final void Function(WardrobeItem) onTap;
  final void Function(String) onFav;
  final VoidCallback onAdd;
  final bool showArchived;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined, size: 48, color: colors.mu),
            const SizedBox(height: AppSpacing.md),
            Text(
              showArchived ? strings.wardArchiveEmpty : strings.wardNotFound,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                color: colors.mu,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length + 1,
      itemBuilder: (_, i) {
        if (i == items.length) {
          return _AddDashedCard(colors: colors, onTap: onAdd);
        }
        final item = items[i];
        return WardrobeItemCard(
          item: item,
          colors: colors,
          onTap: () => onTap(item),
          onFav: () => onFav(item.id),
        );
      },
    );
  }
}

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
      canvas.drawPath(
        metrics.extractPath(dist, dist + dashWidth),
        paint,
      );
      dist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
