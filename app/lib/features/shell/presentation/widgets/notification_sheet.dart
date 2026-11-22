import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
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
  String _selectedCategory = 'all';

  List<({String id, String label})> _categories(AppStrings strings) => [
    (id: 'all', label: strings.allText),
    (id: 'ai', label: strings.notifCatAi),
    (id: 'shop', label: strings.notifCatShop),
    (id: 'finance', label: strings.notifCatFinance),
  ];

  void _handleNotificationTap(AppNotification notif) {
    final shellNotifier = ref.read(shellStateProvider.notifier);
    final appNotifier = ref.read(appStateProvider.notifier);
    shellNotifier.markNotificationRead(notif.id);
    Navigator.of(context).pop();

    switch (notif.targetRoute) {
      case 'atelier_creations':
        ref.read(atelierProvider.notifier).switchTab('creations');
        shellNotifier.switchTab(AppTab.atelier);
        break;
      case 'shop':
        shellNotifier.switchTab(AppTab.shop);
        break;
      case 'profile_wallet':
        appNotifier.switchProfileTab('p-wallet');
        break;
      case 'stylist':
        shellNotifier.switchTab(AppTab.stylist);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final shellState = ref.watch(shellStateProvider);
    final unreadCount = shellState.unreadNotificationsCount;

    final filtered = _selectedCategory == 'all'
        ? shellState.notifications
        : shellState.notifications
              .where((n) => n.category == _selectedCategory)
              .toList();

    return AppBottomSheetShell(
      title: strings.notificationsTitle,
      scrollable: false,
      maxHeightFactor: 0.72,
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
              ? () => ref
                    .read(shellStateProvider.notifier)
                    .markAllNotificationsRead()
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Filter Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              itemCount: _categories(strings).length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
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

          Divider(height: 1, color: colors.bd),

          // Notifications List
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        strings.noNotifications,
                        style: AppTypography.bodySmall(color: colors.mu),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return AppCard(
                        onTap: () => _handleNotificationTap(notif),
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
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 16,
                              color: colors.mu,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
