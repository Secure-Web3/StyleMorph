import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/connection_health_service.dart';
import '../../../../core/services/prefetch/app_prefetch_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
  static const double _profileDrawerSwipeThreshold = 32.0;
  static const double _profileExitSwipeThreshold = 48.0;

  // Keep the key as a field so it is not recreated on every rebuild.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageController;
  bool _isSyncingPageFromState = false;
  double _startEdgeOverscroll = 0.0;
  bool _drawerTriggeredThisDrag = false;
  int? _profileActivePointer;
  Offset _profilePointerDelta = Offset.zero;
  bool _profileSwipeHandledThisDrag = false;

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
      if (!kIsWeb) {
        ref.read(connectionHealthProvider.notifier).checkReachability();
      }
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

  void _resetProfilePointerTracking() {
    _profileActivePointer = null;
    _profilePointerDelta = Offset.zero;
    _profileSwipeHandledThisDrag = false;
  }

  Widget _buildProfileWithDrawerSwipe(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (_profileActivePointer != null) return;
        _profileActivePointer = event.pointer;
        _profilePointerDelta = Offset.zero;
        _profileSwipeHandledThisDrag = false;
      },
      onPointerMove: (event) {
        if (event.pointer != _profileActivePointer ||
            _profileSwipeHandledThisDrag) {
          return;
        }
        _profilePointerDelta += event.delta;
        final dx = _profilePointerDelta.dx;
        final dy = _profilePointerDelta.dy;

        // Ignore vertical scrolls or diagonal drifts that are not clearly horizontal.
        if (dy.abs() > 40.0 || dx.abs() <= dy.abs() * 1.5) {
          return;
        }

        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final shouldOpenDrawer = isRtl
            ? dx <= -_profileDrawerSwipeThreshold
            : dx >= _profileDrawerSwipeThreshold;
        final shouldExitToWardrobe = isRtl
            ? dx >= _profileExitSwipeThreshold
            : dx <= -_profileExitSwipeThreshold;

        if (shouldOpenDrawer) {
          _profileSwipeHandledThisDrag = true;
          if (!(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
            _scaffoldKey.currentState?.openDrawer();
          }
        } else if (shouldExitToWardrobe) {
          _profileSwipeHandledThisDrag = true;
          _handleTabSwitch(AppTab.wardrobe);
        }
      },
      onPointerUp: (event) {
        if (event.pointer == _profileActivePointer) {
          _resetProfilePointerTracking();
        }
      },
      onPointerCancel: (event) {
        if (event.pointer == _profileActivePointer) {
          _resetProfilePointerTracking();
        }
      },
      child: const ProfileTab(),
    );
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
    final connectionHealth = ref.watch(connectionHealthProvider);

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
                      drawerEdgeDragWidth: isProfile ? 64.0 : 20.0,
                      appBar: MainHeader(
                        onOpenDrawer: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      drawer: const AppDrawer(),
                      body: Column(
                        children: [
                          if (connectionHealth.shouldShowBanner)
                            _ServerConnectivityBanner(
                              isChecking: connectionHealth.isChecking,
                              onRetry: () => ref
                                  .read(connectionHealthProvider.notifier)
                                  .checkReachability(resetDismissed: true),
                              onDismiss: () => ref
                                  .read(connectionHealthProvider.notifier)
                                  .dismissBanner(),
                            ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, bodyConstraints) {
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Offstage(
                                        offstage: isProfile,
                                        child: _buildModulesPageView(),
                                      ),
                                    ),
                                    if (isProfile)
                                      Positioned.fill(
                                        child: _buildProfileWithDrawerSwipe(
                                          context,
                                        ),
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
                          ),
                        ],
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

class _ServerConnectivityBanner extends StatelessWidget {
  final bool isChecking;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _ServerConnectivityBanner({
    required this.isChecking,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Container(
      key: const Key('server_unreachable_banner'),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.orColor.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: colors.orColor.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: colors.orColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              strings.connServerUnreachableBanner,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.tx,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            key: const Key('server_unreachable_retry_btn'),
            onPressed: isChecking ? null : onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: colors.orColor.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
            ),
            child: isChecking
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: colors.orColor,
                    ),
                  )
                : Text(
                    strings.connRetryBtn,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.orColor,
                    ),
                  ),
          ),
          IconButton(
            key: const Key('server_unreachable_dismiss_btn'),
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 16, color: colors.mu),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
