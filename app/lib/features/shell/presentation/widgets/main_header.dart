import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/loyalty_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/email_verification_provider.dart';
import '../../../profile/presentation/widgets/loyalty_rank_modal.dart';
import 'notification_sheet.dart';

class MainHeader extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onOpenDrawer;

  const MainHeader({super.key, this.onOpenDrawer});

  static const double _baseHeight = 66.0;
  static const double _profileExtraHeight = 44.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_baseHeight + _profileExtraHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final isProfileMode = appState.currentTab == AppTab.profile;
    final isEmailVerified = ref.watch(
      emailVerificationProvider.select((s) => s.isVerified),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.sf,
        border: Border(bottom: BorderSide(color: colors.bd)),
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
              vertical: 4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Top Row ─────────────────────────────────────────────────
                Row(
                  children: [
                    // Start: Larger circular user avatar with colored loyalty-tier border ring
                    InkWell(
                      onTap: () {
                        if (onOpenDrawer != null) {
                          onOpenDrawer!();
                        } else {
                          Scaffold.of(context).openDrawer();
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: _buildAvatar(colors, strings, appState),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Center (Expanded): User full name above email address
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          User? user;
                          try {
                            if (Firebase.apps.isNotEmpty) {
                              user = FirebaseAuth.instance.currentUser;
                            }
                          } catch (_) {}
                          final isKycVerified = appState.kycData.isVerified;
                          final isVerified = isKycVerified || isEmailVerified;
                          final displayName = appState.userName.isNotEmpty
                              ? strings.tr(appState.userName)
                              : (user?.displayName ??
                                    (user?.email?.split('@').first ??
                                        strings.newUser));
                          final userEmail =
                              user?.email ??
                              (appState.identityValues['email'] ?? '');
                          final showEmail =
                              appState.preferences.showEmailInHeader &&
                              userEmail.isNotEmpty;

                          final nameRow = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.tx,
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: AppSpacing.xs),
                                FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  size: 12,
                                  color: isKycVerified
                                      ? colors.ok
                                      : colors.inColor,
                                ),
                              ],
                            ],
                          );

                          if (showEmail) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                nameRow,
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11,
                                    color: colors.mu,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: nameRow,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // End: Compact vertical stack with Notification Bell on top & Coins pill below
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Notification Bell
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              key: const Key('header_notifications_bell'),
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
                                size: 15,
                                color: colors.tx,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: strings.notificationsTitle,
                            ),
                            // Orange notification dot (only when unread > 0)
                            if (appState.unreadNotificationsCount > 0)
                              PositionedDirectional(
                                top: 4,
                                end: 4,
                                child: Container(
                                  width: 7,
                                  height: 7,
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

                        // StyleCoin Chip
                        if (appState.showHeaderCoins) ...[
                          const SizedBox(height: 1),
                          _buildCoinsBadge(colors, strings, appState),
                        ],
                      ],
                    ),
                  ],
                ),

                // ── Bottom Row (Full Width - only on Profile tab) ───────────
                if (isProfileMode) ...[
                  const SizedBox(height: 6),
                  _buildProfileProgressSection(
                    ref,
                    context,
                    colors,
                    strings,
                    appState,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Coins pill badge ───────────────────────────────────────────────────────
  Widget _buildCoinsBadge(
    AppColors colors,
    AppStrings strings,
    AppState appState,
  ) {
    return InkWell(
      key: const Key('header_coins_chip'),
      onTap: null,
      borderRadius: AppRadius.rFull,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 7,
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
            FaIcon(FontAwesomeIcons.coins, size: 10, color: colors.wn),
            const SizedBox(width: 4),
            Text(
              strings.formatNumber(appState.coins),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.tx,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              strings.coin,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                color: colors.mu,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar with Loyalty Rank border ───────────────────────────────────────
  Widget _buildAvatar(AppColors colors, AppStrings strings, AppState appState) {
    const double avatarSize = 42.0;
    final rank = LoyaltyRankExtension.fromString(appState.loyaltyRank);
    final rankColor = rank.color;

    return Container(
      width: avatarSize,
      height: avatarSize,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: rankColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.22),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.sf),
        child: Builder(
          builder: (context) {
            User? user;
            try {
              if (Firebase.apps.isNotEmpty) {
                user = FirebaseAuth.instance.currentUser;
              }
            } catch (_) {}
            final photoUrl =
                (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                ? user.photoURL!
                : appState.photoUrl;
            if (photoUrl.isNotEmpty) {
              return Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _buildInitialsWidget(appState, colors, strings),
              );
            }
            return _buildInitialsWidget(appState, colors, strings);
          },
        ),
      ),
    );
  }

  // ── Minimal, tappable Loyalty Rank + Points badge ────────────────────────
  Widget _buildRankPointsBadge(
    BuildContext context,
    AppColors colors,
    AppStrings strings,
    AppState appState,
  ) {
    final rank = LoyaltyRankExtension.fromString(appState.loyaltyRank);
    final rankColor = rank.color;
    final rankLabel = rank.getLocalizedName(strings);
    final ptsText =
        '${strings.formatNumber(appState.stylePoints)} ${strings.pts}';

    return GestureDetector(
      key: const Key('header_loyalty_rank_badge'),
      onTap: () {
        LoyaltyModalSheet.show(
          context,
          points: appState.stylePoints,
          rank: rank,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: rankColor.withValues(alpha: 0.12),
          borderRadius: AppRadius.rFull,
          border: Border.all(
            color: rankColor.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$rankLabel • $ptsText',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.tx,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsWidget(
    AppState appState,
    AppColors colors,
    AppStrings strings,
  ) {
    String initials = 'SM';
    final first = appState.identityValues['firstName']?.trim() ?? '';
    final last = appState.identityValues['lastName']?.trim() ?? '';
    final resolvedName = appState.userName.isNotEmpty
        ? strings.tr(appState.userName)
        : '';

    if (resolvedName.isNotEmpty) {
      final parts = resolvedName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts[0].characters.first}${parts[1].characters.first}'
            .toUpperCase();
      } else {
        initials = parts[0].characters.take(2).toString().toUpperCase();
      }
    } else if (first.isNotEmpty && last.isNotEmpty) {
      final localizedFirst = strings.tr(first);
      final localizedLast = strings.tr(last);
      initials =
          '${localizedFirst.characters.first}${localizedLast.characters.first}'
              .toUpperCase();
    } else if (first.isNotEmpty) {
      initials = strings.tr(first).characters.take(2).toString().toUpperCase();
    } else {
      String email = '';
      try {
        if (Firebase.apps.isNotEmpty) {
          email = FirebaseAuth.instance.currentUser?.email ?? '';
        }
      } catch (_) {}
      if (email.isNotEmpty) {
        initials = email
            .split('@')
            .first
            .characters
            .take(2)
            .toString()
            .toUpperCase();
      }
    }

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.tx,
        ),
      ),
    );
  }

  // ── Profile completion progress bar ─────────────────────────────────────
  Widget _buildProfileProgressSection(
    WidgetRef ref,
    BuildContext context,
    AppColors colors,
    AppStrings strings,
    AppState appState,
  ) {
    return Row(
      children: [
        // 1. Start: Loyalty tier & points pill badge (tapping opens LoyaltyModalSheet)
        _buildRankPointsBadge(context, colors, strings, appState),
        const SizedBox(width: AppSpacing.sm),

        // 2. Middle (Expanded): Smooth horizontal profile completion progress bar + localized percentage
        Expanded(
          key: const Key('header_profile_progress_bar'),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.bd,
                        borderRadius: AppRadius.rFull,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: appState.profileProgress.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.pr,
                          borderRadius: AppRadius.rFull,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                strings.formatPercent((appState.profileProgress * 100).round()),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.tx,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 3. End: Compact dark pill action button (Complete Profile)
        InkWell(
          key: const Key('header_complete_profile_btn'),
          onTap: () {
            ref.read(appStateProvider.notifier).switchProfileTab('p-identity');
          },
          borderRadius: AppRadius.rFull,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.pr,
              borderRadius: AppRadius.rFull,
            ),
            child: Text(
              strings.hFin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
