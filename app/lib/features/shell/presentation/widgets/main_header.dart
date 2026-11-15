import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'notification_sheet.dart';

class MainHeader extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onOpenDrawer;

  const MainHeader({
    super.key,
    this.onOpenDrawer,
  });

  static const double _baseHeight = 58.0;
  static const double _profileExtraHeight = 52.0;

  @override
  Size get preferredSize => const Size.fromHeight(_baseHeight + _profileExtraHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final isProfileMode = appState.currentTab == AppTab.profile;

    return Container(
      decoration: BoxDecoration(
        color: colors.sf,
        border: Border(
          bottom: BorderSide(color: colors.bd),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: isProfileMode
              ? _baseHeight + _profileExtraHeight
              : _baseHeight,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Top Row ─────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Info → taps to open Drawer
                    Expanded(
                      child: InkWell(
                        onTap: onOpenDrawer,
                        borderRadius: AppRadius.rMd,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(colors, strings, appState),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Name + verified icon
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            strings.tr(appState.userName),
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: colors.tx,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        FaIcon(
                                          FontAwesomeIcons.circleCheck,
                                          size: 12,
                                          color: colors.inColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    // Subtitle: verification | @username
                                    Text(
                                      '${strings.verif} | ${appState.userHandle}',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 11,
                                        color: colors.mu,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Action Buttons ───────────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // StyleCoin Chip
                        if (appState.showHeaderCoins) ...[
                          InkWell(
                            onTap: () {
                              ref
                                  .read(appStateProvider.notifier)
                                  .switchProfileTab('p-wallet');
                            },
                            borderRadius: AppRadius.rFull,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.wnb,
                                borderRadius: AppRadius.rFull,
                                border: Border.all(color: colors.bd),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.coins,
                                    size: 12,
                                    color: colors.wn,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    strings.formatNumber(appState.coins),
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.tx,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    strings.coin,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      color: colors.mu,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.wn,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],

                        // Notification Bell
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  constraints: const BoxConstraints(
                                    maxWidth: 430,
                                  ),
                                  builder: (_) => const NotificationSheet(),
                                );
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.bell,
                                size: 16,
                                color: colors.tx,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              tooltip: strings.notificationsTitle,
                            ),
                            // Orange notification dot (only when unread > 0)
                            if (appState.unreadNotificationsCount > 0)
                              PositionedDirectional(
                                top: 7,
                                end: 7,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.orColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.sf,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Profile Completion Row (only on Profile tab) ─────────────
                if (isProfileMode) ...[
                  const SizedBox(height: 6),
                  _buildProfileProgressSection(ref, colors, strings, appState),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Avatar with conic-gradient ring + LVL badge ──────────────────────────
  Widget _buildAvatar(AppColors colors, AppStrings strings, AppState appState) {
    const double avatarSize = 40.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                colors.pr,
                colors.pr,
                colors.bd,
                colors.bd,
              ],
              stops: [
                0.0,
                appState.profileProgress,
                appState.profileProgress,
                1.0,
              ],
              transform: const GradientRotation(-1.5708), // start from top
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.sf,
            ),
            child: Center(
              child: Text(
                'SA',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.tx,
                ),
              ),
            ),
          ),
        ),
        // LVL badge — always shown
        PositionedDirectional(
          bottom: -2,
          end: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: colors.wnb,
              borderRadius: AppRadius.rFull,
              border: Border.all(color: colors.sf, width: 1.5),
            ),
            child: Text(
              'Lv${strings.formatNumber(appState.userLevel)}',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: colors.wn,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Profile completion progress bar ─────────────────────────────────────
  Widget _buildProfileProgressSection(
    WidgetRef ref,
    AppColors colors,
    AppStrings strings,
    AppState appState,
  ) {
    return Row(
      children: [
        // Progress label & plan chip
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  strings.pcT,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.wnb,
                  borderRadius: AppRadius.rFull,
                  border: Border.all(color: colors.bd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.crown,
                      size: 9,
                      color: colors.wn,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      strings.tr(appState.currentPlan),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: colors.tx,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Completion progress bar
        SizedBox(
          width: 50,
          child: Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: colors.bd,
                  borderRadius: AppRadius.rFull,
                ),
              ),
              FractionallySizedBox(
                widthFactor: appState.profileProgress,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.pr,
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          strings.formatPercent((appState.profileProgress * 100).round()),
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.tx,
          ),
        ),
        const SizedBox(width: 6),
        // Complete documents button
        InkWell(
          onTap: () {
            ref
                .read(appStateProvider.notifier)
                .switchProfileTab('p-identity');
          },
          borderRadius: AppRadius.rSm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.pr,
              borderRadius: AppRadius.rSm,
            ),
            child: Text(
              strings.hFin,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.prt,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
