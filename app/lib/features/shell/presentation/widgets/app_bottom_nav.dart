import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;

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
        border: Border(
          top: BorderSide(color: colors.bd),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: items.map((item) {
              return Expanded(
                child: Opacity(
                  opacity: 0.38,
                  child: InkWell(
                    onTap: null, // Disabled / non-selectable
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal: 2,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            item.icon,
                            size: 16,
                            color: colors.mu,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: colors.mu,
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

  const _NavItem({
    required this.tab,
    required this.label,
    required this.icon,
  });
}
