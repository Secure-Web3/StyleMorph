import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AppBottomNav extends ConsumerWidget {
  final ValueChanged<AppTab>? onTabSelected;
  const AppBottomNav({super.key, this.onTabSelected});

  /// Central set of temporarily disabled tab indices.
  /// Index 0: Wardrobe (Active)
  /// Index 1: Wellness (Disabled)
  /// Index 2: Stylist (Disabled)
  /// Index 3: Atelier (Disabled)
  /// Index 4: Shop (Disabled)
  static const Set<int> disabledTabIndices = {1, 2, 3, 4};

  /// Set of temporarily disabled [AppTab] targets.
  static const Set<AppTab> disabledTabs = {
    AppTab.wellness,
    AppTab.stylist,
    AppTab.atelier,
    AppTab.shop,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final currentTab = ref.watch(appStateProvider.select((s) => s.currentTab));

    final items = [
      _NavItem(
        tab: AppTab.wardrobe,
        label: strings.nWard,
        icon: FontAwesomeIcons.shirt,
      ),
      _NavItem(
        tab: AppTab.wellness,
        label: strings.nWell,
        icon: FontAwesomeIcons.heartPulse,
      ),
      _NavItem(
        tab: AppTab.stylist,
        label: strings.nSty,
        icon: FontAwesomeIcons.wandMagicSparkles,
      ),
      _NavItem(
        tab: AppTab.atelier,
        label: strings.nAtel,
        icon: FontAwesomeIcons.cameraRetro,
      ),
      _NavItem(
        tab: AppTab.shop,
        label: strings.nShop,
        icon: FontAwesomeIcons.store,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.sf,
        border: Border(top: BorderSide(color: colors.bd)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isDisabled =
                  disabledTabIndices.contains(index) ||
                  disabledTabs.contains(item.tab);
              final isActive = !isDisabled && currentTab == item.tab;
              final itemColor = isActive
                  ? colors.pr
                  : (isDisabled
                        ? colors.mu.withValues(alpha: 0.38)
                        : colors.mu);

              return Expanded(
                child: Opacity(
                  opacity: isDisabled ? 0.38 : 1.0,
                  child: InkWell(
                    onTap: isDisabled
                        ? null
                        : () {
                            if (onTabSelected != null) {
                              onTabSelected!(item.tab);
                            } else {
                              ref
                                  .read(appStateProvider.notifier)
                                  .switchTab(item.tab);
                            }
                          },
                    splashColor: isDisabled
                        ? Colors.transparent
                        : colors.pr.withValues(alpha: 0.1),
                    highlightColor: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          // Active indicator: 2px solid primary at top of nav item.
                          top: BorderSide(
                            color: isActive ? colors.pr : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(item.icon, size: 16, color: itemColor),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: itemColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final AppTab tab;
  final String label;
  final FaIconData icon;

  const _NavItem({required this.tab, required this.label, required this.icon});
}
