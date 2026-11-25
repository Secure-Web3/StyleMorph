import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/prefetch/app_prefetch_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../atelier/presentation/atelier_tab.dart';
import '../../profile/presentation/profile_tab.dart';
import '../../profile/presentation/widgets/unsaved_changes_dialog.dart';
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
  static const List<AppTab> _moduleTabs = [
    AppTab.wardrobe,
    AppTab.wellness,
    AppTab.stylist,
    AppTab.atelier,
    AppTab.shop,
  ];
  static const double _drawerOverscrollThreshold = 24.0;

  // Keep the key as a field so it is not recreated on every rebuild.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageController;
  bool _isSyncingPageFromState = false;
  double _startEdgeOverscroll = 0.0;
  bool _drawerTriggeredThisDrag = false;

  int _moduleIndexFor(AppTab tab) {
    final idx = _moduleTabs.indexOf(tab);
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(appStateProvider).currentTab;
    _pageController = PageController(initialPage: _moduleIndexFor(initialTab));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionServiceProvider).upsertSession().catchError((e) {
        debugPrint('[MainShellScreen] upsertSession error: $e');
      });
      ref
          .read(appPrefetchServiceProvider)
          .prefetchOnAuth(ref: ref, context: context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageControllerToTab(AppTab? previous, AppTab next) {
    if (next == AppTab.profile) return;
    final targetIndex = _moduleIndexFor(next);

    if (previous == AppTab.profile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _isSyncingPageFromState = true;
        _pageController.jumpToPage(targetIndex);
        _isSyncingPageFromState = false;
      });
      return;
    }

    if (!_pageController.hasClients) return;
    final currentPage =
        _pageController.page?.round() ?? _pageController.initialPage;
    if (currentPage == targetIndex) return;

    _isSyncingPageFromState = true;
    _pageController
        .animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          _isSyncingPageFromState = false;
        });
  }

  bool _handlePageScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }

    if (notification is ScrollStartNotification ||
        notification is ScrollEndNotification) {
      _startEdgeOverscroll = 0.0;
      _drawerTriggeredThisDrag = false;
      return false;
    }

    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        !_drawerTriggeredThisDrag) {
      final atStartEdge =
          notification.metrics.pixels <=
          notification.metrics.minScrollExtent + 0.5;
      if (atStartEdge && notification.overscroll < 0) {
        _startEdgeOverscroll += notification.overscroll.abs();
        if (_startEdgeOverscroll >= _drawerOverscrollThreshold) {
          _triggerDrawerFromEdgeSwipe();
        }
      } else {
        _startEdgeOverscroll = 0.0;
      }
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        !_drawerTriggeredThisDrag) {
      final bounceOverscroll =
          notification.metrics.minScrollExtent - notification.metrics.pixels;
      if (bounceOverscroll >= _drawerOverscrollThreshold) {
        _triggerDrawerFromEdgeSwipe();
      }
    }

    return false;
  }

  void _triggerDrawerFromEdgeSwipe() {
    _drawerTriggeredThisDrag = true;
    _startEdgeOverscroll = 0.0;
    if (!(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  Future<void> _handleTabSwitch(AppTab targetTab) async {
    // Guard against navigation to temporarily disabled tabs
    if (AppBottomNav.disabledTabs.contains(targetTab)) return;

    final (currentTab, hasUnsavedChanges) = ref.read(
      appStateProvider.select((s) => (s.currentTab, s.hasUnsavedChanges)),
    );
    if (targetTab == currentTab) return;

    if (hasUnsavedChanges) {
      final action = await UnsavedChangesDialog.show(context);
      if (!mounted) return;

      if (action == UnsavedChangesAction.saveAndContinue) {
        final success = await ref
            .read(appStateProvider.notifier)
            .saveProfileToFirestore();
        if (!mounted) return;
        if (success) {
          ref.read(appStateProvider.notifier).switchTab(targetTab);
        }
      } else if (action == UnsavedChangesAction.discardAndLeave) {
        ref.read(appStateProvider.notifier).clearDirty();
        ref.read(appStateProvider.notifier).switchTab(targetTab);
      }
      return;
    }

    ref.read(appStateProvider.notifier).switchTab(targetTab);
  }

  Widget _buildModulePage(AppTab tab) {
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

  Widget _buildModulesPageView() {
    return NotificationListener<ScrollNotification>(
      onNotification: _handlePageScrollNotification,
      child: PageView.builder(
        controller: _pageController,
        physics: const PageScrollPhysics(),
        itemCount: _moduleTabs.length,
        onPageChanged: (index) {
          if (_isSyncingPageFromState) return;
          final targetTab = _moduleTabs[index];
          final current = ref.read(appStateProvider).currentTab;
          if (current != targetTab) {
            ref.read(appStateProvider.notifier).switchTab(targetTab);
          }
        },
        itemBuilder: (context, index) => _buildModulePage(_moduleTabs[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppTab>(
      appStateProvider.select((s) => s.currentTab),
      _syncPageControllerToTab,
    );

    final colors = context.colors;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(localeProvider);
    final isDark = themeState.resolveIsDark(context);
    final currentTab = ref.watch(appStateProvider.select((s) => s.currentTab));
    final isProfile = currentTab == AppTab.profile;
    final hasUnsavedChanges = ref.watch(
      appStateProvider.select((s) => s.hasUnsavedChanges),
    );
    final showSupport = ref.watch(
      appStateProvider.select((s) => s.showFloatingSupport || s.isSupportOpen),
    );

    // Outer background: slightly darker than surface for desktop web frame effect.
    final outerColor = isDark
        ? const Color(0xFF050505)
        : const Color(0xFFD4D4D4);

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: colors.bg,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: colors.bg,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Directionality(
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
                  child: PopScope(
                    canPop: !hasUnsavedChanges,
                    onPopInvokedWithResult: (didPop, result) async {
                      if (didPop) return;
                      if (hasUnsavedChanges) {
                        final navigator = Navigator.of(context);
                        final action = await UnsavedChangesDialog.show(context);
                        if (!mounted) return;
                        if (action == UnsavedChangesAction.saveAndContinue) {
                          final success = await ref
                              .read(appStateProvider.notifier)
                              .saveProfileToFirestore();
                          if (success && mounted) {
                            navigator.maybePop(result);
                          }
                        } else if (action ==
                            UnsavedChangesAction.discardAndLeave) {
                          ref.read(appStateProvider.notifier).clearDirty();
                          if (mounted) {
                            navigator.maybePop(result);
                          }
                        }
                      }
                    },
                    child: Scaffold(
                      key: _scaffoldKey,
                      backgroundColor: colors.bg,
                      drawerEnableOpenDragGesture: isProfile,
                      appBar: MainHeader(
                        onOpenDrawer: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      drawer: const AppDrawer(),
                      body: LayoutBuilder(
                        builder: (context, bodyConstraints) {
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: isProfile
                                    ? const ProfileTab()
                                    : _buildModulesPageView(),
                              ),
                              if (showSupport)
                                Positioned.fill(
                                  child: SupportWidget(
                                    bodySize: bodyConstraints.biggest,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      bottomNavigationBar: AppBottomNav(
                        onTabSelected: _handleTabSwitch,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
