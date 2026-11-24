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
  // Keep the key as a field so it is not recreated on every rebuild.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionServiceProvider).upsertSession().catchError((e) {
        debugPrint('[MainShellScreen] upsertSession error: $e');
      });
      ref
          .read(appPrefetchServiceProvider)
          .prefetchOnAuth(ref: ref, context: context);
    });
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
