import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../atelier/presentation/atelier_tab.dart';
import '../../profile/presentation/profile_tab.dart';
import '../../shop/presentation/shop_tab.dart';
import '../../stylist/presentation/stylist_tab.dart';
import '../../wardrobe/presentation/wardrobe_tab.dart';
import '../../wellness/presentation/wellness_tab.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_drawer.dart';
import 'widgets/main_header.dart';
import 'widgets/support_widget.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  // Keep the key as a field so it is not recreated on every rebuild.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildBody(AppTab tab) {
    switch (tab) {
      case AppTab.wardrobe:
        return const WardrobeTab();
      case AppTab.wellness:
        return const WellnessTab();
      case AppTab.stylist:
        return const StylistTab();
      case AppTab.atelier:
        return const AtelierTab();
      case AppTab.shop:
        return const ShopTab();
      case AppTab.profile:
        return const ProfileTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(localeProvider);
    final isDark = themeState.resolveIsDark(context);
    final currentTab = ref.watch(appStateProvider.select((s) => s.currentTab));
    final showFloatingSupport =
        ref.watch(appStateProvider.select((s) => s.showFloatingSupport));
    final isSupportOpen =
        ref.watch(appStateProvider.select((s) => s.isSupportOpen));

    // Outer background: slightly darker than surface for desktop web frame effect.
    final outerColor = isDark
        ? const Color(0xFF050505)
        : const Color(0xFFD4D4D4);

    return Directionality(
      textDirection: currentLang.textDirection,
      child: Container(
        color: outerColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              decoration: BoxDecoration(
                color: colors.bg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              // ClipRect ensures the drawer and overlays do not render outside the frame.
              child: ClipRect(
                child: Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: colors.bg,
                  appBar: MainHeader(
                    onOpenDrawer: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  ),
                  drawer: const AppDrawer(),
                  body: LayoutBuilder(
                    builder: (context, bodyConstraints) {
                      return Stack(
                        children: [
                          Positioned.fill(child: _buildBody(currentTab)),
                          if (showFloatingSupport || isSupportOpen)
                            Positioned.fill(
                              child: SupportWidget(
                                bodySize: bodyConstraints.biggest,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  bottomNavigationBar: const AppBottomNav(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
