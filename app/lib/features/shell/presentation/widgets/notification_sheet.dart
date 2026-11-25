import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../atelier/presentation/atelier_provider.dart';
import '../shell_state_provider.dart';

class NotificationSheet extends ConsumerStatefulWidget {
  const NotificationSheet({super.key});

  @override
  ConsumerState<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends ConsumerState<NotificationSheet> {
  static const List<String> _statusOrder = ['all', 'unread', 'read'];

  String _selectedCategory = 'all';
  int _selectedStatusIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedStatusIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<({String id, String label})> _categories(AppStrings strings) => [
    (id: 'all', label: strings.allText),
    (id: 'account', label: strings.notifCatAccount),
    (id: 'wardrobe', label: strings.notifCatWardrobe),
    (id: 'wellness', label: strings.notifCatWellness),
    (id: 'stylist', label: strings.notifCatStylist),
    (id: 'atelier', label: strings.notifCatAtelier),
    (id: 'shop', label: strings.notifCatShop),
    (id: 'wallet', label: strings.notifCatWallet),
  ];

  List<({String id, String label})> _statusFilters(AppStrings strings) => [
    (id: 'all', label: strings.notifFilterAll),
    (id: 'unread', label: strings.notifFilterUnread),
    (id: 'read', label: strings.notifFilterRead),
  ];

  void _selectStatusTab(int index) {
    if (_selectedStatusIndex == index) return;
    setState(() => _selectedStatusIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _markSingleAsRead(String notificationId, String? authUid) {
    if (authUid != null) {
      ref.read(notificationServiceProvider).markAsRead(authUid, notificationId);
    } else {
      ref
          .read(shellStateProvider.notifier)
          .markNotificationRead(notificationId);
    }
  }

  void _deleteSingleNotification(String notificationId, String? authUid) {
    if (authUid != null) {
      ref
          .read(notificationServiceProvider)
          .deleteNotification(authUid, notificationId);
    } else {
      ref.read(shellStateProvider.notifier).deleteNotification(notificationId);
    }
  }

  void _handleNotificationTap(AppNotification notif, String? authUid) {
    final shellNotifier = ref.read(shellStateProvider.notifier);
    final appNotifier = ref.read(appStateProvider.notifier);
    _markSingleAsRead(notif.id, authUid);
    Navigator.of(context).pop();

    switch (notif.targetRoute) {
      case 'wardrobe':
        shellNotifier.switchTab(AppTab.wardrobe);
        break;
      case 'wellness':
        shellNotifier.switchTab(AppTab.wellness);
        break;
      case 'atelier_creations':
        ref.read(atelierProvider.notifier).switchTab('creations');
        shellNotifier.switchTab(AppTab.atelier);
        break;
      case 'shop':
        shellNotifier.switchTab(AppTab.shop);
        break;
      case 'profile_wallet':
        appNotifier.switchProfileTab('p-wallet');
        shellNotifier.switchTab(AppTab.profile);
        break;
      case 'stylist':
        shellNotifier.switchTab(AppTab.stylist);
        break;
      case 'profile_identity':
        appNotifier.switchProfileTab('p-identity');
        shellNotifier.switchTab(AppTab.profile);
        break;
      case 'profile_settings':
        appNotifier.switchProfileTab('p-settings');
        shellNotifier.switchTab(AppTab.profile);
        break;
      case 'profile_about':
        appNotifier.switchProfileTab('p-about');
        shellNotifier.switchTab(AppTab.profile);
        break;
      case 'profile_sessions':
        appNotifier.switchProfileTab('p-sessions');
        shellNotifier.switchTab(AppTab.profile);
        break;
      case 'profile_referral':
        appNotifier.switchProfileTab('p-referral');
        shellNotifier.switchTab(AppTab.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final shellState = ref.watch(shellStateProvider);
    final authUid = currentAuthenticatedUid();
    final List<AppNotification> allNotifications = authUid != null
        ? ref
              .watch(notificationsStreamProvider(authUid))
              .maybeWhen(data: (items) => items, orElse: () => const [])
        : shellState.notifications;
    final unreadCount = NotificationService.countUnread(allNotifications);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;
    final statusFilters = _statusFilters(strings);

    return SizedBox(
      key: const Key('notification_sheet_fixed_container'),
      height: sheetHeight,
      child: AppBottomSheetShell(
        title: strings.notificationsTitle,
        scrollable: false,
        maxHeightFactor: 0.75,
        contentPadding: EdgeInsetsDirectional.zero,
        headerActions: [
          if (unreadCount > 0) ...[
            AppBadge(
              variant: AppBadgeVariant.destructive,
              size: AppBadgeSize.sm,
              child: Text(strings.unreadNewCount(unreadCount)),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          InkWell(
            onTap: unreadCount > 0
                ? () {
                    if (authUid != null) {
                      ref
                          .read(notificationServiceProvider)
                          .markAllAsRead(authUid);
                    } else {
                      ref
                          .read(shellStateProvider.notifier)
                          .markAllNotificationsRead();
                    }
                  }
                : null,
            borderRadius: AppRadius.rMd,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                strings.markAllRead,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: unreadCount > 0 ? colors.pr : colors.mu,
                ),
              ),
            ),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact Category Filter Chips with Subtle Edge Fade
            SizedBox(
              height: 44,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.04, 0.96, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: _categories(strings).length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final cat = _categories(strings)[index];
                    return AppChip(
                      label: cat.label,
                      isSelected: _selectedCategory == cat.id,
                      onTap: () => setState(() => _selectedCategory = cat.id),
                    );
                  },
                ),
              ),
            ),

            // Quick Read/Unread Segmented Status Filter Bar
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Container(
                key: const Key('notification_status_filter_bar'),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: AppRadius.rMd,
                  border: Border.all(color: colors.bd),
                ),
                child: Row(
                  children: List.generate(statusFilters.length, (index) {
                    final status = statusFilters[index];
                    final isSelected = _selectedStatusIndex == index;
                    return Expanded(
                      child: InkWell(
                        key: Key('notif_status_${status.id}'),
                        onTap: () => _selectStatusTab(index),
                        borderRadius: AppRadius.rSm,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: 5,
                            horizontal: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.sf : Colors.transparent,
                            borderRadius: AppRadius.rSm,
                            border: isSelected
                                ? Border.all(color: colors.bd)
                                : null,
                          ),
                          child: Text(
                            status.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? colors.tx : colors.mu,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            Divider(height: 1, color: colors.bd),

            // Swipeable Status Pages (All / Unread / Read) respecting RTL/LTR Directionality
            Expanded(
              child: PageView.builder(
                key: const Key('notification_status_page_view'),
                controller: _pageController,
                itemCount: _statusOrder.length,
                onPageChanged: (index) {
                  if (_selectedStatusIndex != index) {
                    setState(() => _selectedStatusIndex = index);
                  }
                },
                itemBuilder: (context, pageIndex) {
                  final filtered = NotificationService.filterNotifications(
                    allNotifications,
                    category: _selectedCategory,
                    status: _statusOrder[pageIndex],
                  );
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      child: Center(
                        child: Text(
                          strings.noNotifications,
                          style: AppTypography.bodySmall(color: colors.mu),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return AppCard(
                        key: Key('notif_card_${notif.id}'),
                        onTap: () => _handleNotificationTap(notif, authUid),
                        variant: AppCardVariant.subtle,
                        backgroundColor: notif.isRead
                            ? colors.bg
                            : colors.pr.withValues(alpha: 0.05),
                        borderColor: notif.isRead
                            ? colors.bd
                            : colors.pr.withValues(alpha: 0.28),
                        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.sf,
                                borderRadius: AppRadius.rLg,
                                border: Border.all(color: colors.bd),
                              ),
                              child: Center(
                                child: Text(
                                  notif.emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!notif.isRead)
                                        Container(
                                          width: 7,
                                          height: 7,
                                          margin:
                                              const EdgeInsetsDirectional.only(
                                                top: 5,
                                                end: 6,
                                              ),
                                          decoration: BoxDecoration(
                                            color: colors.orColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          strings.tr(notif.title),
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 12,
                                            fontWeight: notif.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            color: colors.tx,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    strings.tr(notif.body),
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 10,
                                      color: colors.mu,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    strings.tr(notif.timestampLabel),
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 9,
                                      color: colors.mu,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!notif.isRead) ...[
                                  IconButton(
                                    key: ValueKey(
                                      'notif_mark_read_${notif.id}',
                                    ),
                                    tooltip: strings.markAsReadTooltip,
                                    onPressed: () =>
                                        _markSingleAsRead(notif.id, authUid),
                                    icon: Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 18,
                                      color: colors.pr,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                IconButton(
                                  key: ValueKey('notif_delete_${notif.id}'),
                                  tooltip: strings.deleteNotificationTooltip,
                                  onPressed: () => _deleteSingleNotification(
                                    notif.id,
                                    authUid,
                                  ),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: colors.mu,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
