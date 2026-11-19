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
    final isEmailVerified =
        ref.watch(emailVerificationProvider.select((s) => s.isVerified));

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
                                                'کاربر جدید'));
                                    final userEmail = user?.email ??
                                        (appState.identityValues['email'] ?? '');

                                    return Column(
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
                                                displayName,
                                                style: TextStyle(
                                                  fontFamily: 'Vazirmatn',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: colors.tx,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
                                            const SizedBox(width: AppSpacing.xs),
                                            _buildRankPointsBadge(
                                              context,
                                              colors,
                                              strings,
                                              appState,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        // Subtitle: verification | @username
                                        if (appState.preferences.showEmailInHeader &&
                                            userEmail.isNotEmpty) ...[
                                          Text(
                                            userEmail,
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 11,
                                              color: colors.mu,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ] else if (appState.userHandle.isNotEmpty) ...[
                                          Text(
                                            isKycVerified
                                                ? '${strings.kycVerifiedBadge} | ${appState.userHandle}'
                                                : appState.userHandle,
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 11,
                                              color: colors.mu,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    );
                                  },
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
                            onTap: null, // Tap navigation disabled while Wallet & Plan is temporarily disabled
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

  // ── Avatar with Loyalty Rank border (no conic ring, no Lv1 badge) ──────
  Widget _buildAvatar(AppColors colors, AppStrings strings, AppState appState) {
    const double avatarSize = 40.0;
    final rank = LoyaltyRankExtension.fromString(appState.loyaltyRank);
    final rankColor = rank.color;

    return Container(
      width: avatarSize,
      height: avatarSize,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: rankColor,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.22),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.sf,
        ),
        child: Builder(
          builder: (context) {
            User? user;
            try {
              if (Firebase.apps.isNotEmpty) {
                user = FirebaseAuth.instance.currentUser;
              }
            } catch (_) {}
            if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
              return Image.network(
                user.photoURL!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _buildInitialsWidget(appState, colors),
              );
            }
            return _buildInitialsWidget(appState, colors);
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
          color: rankColor.withOpacity(0.12),
          borderRadius: AppRadius.rFull,
          border: Border.all(
            color: rankColor.withOpacity(0.45),
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
            Text(
              '$rankLabel • $ptsText',
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
    );
  }

  Widget _buildInitialsWidget(AppState appState, AppColors colors) {
    String initials = 'SM';
    final first = appState.identityValues['firstName']?.trim() ?? '';
    final last = appState.identityValues['lastName']?.trim() ?? '';
    if (first.isNotEmpty && last.isNotEmpty) {
      initials = '${first.characters.first}${last.characters.first}'.toUpperCase();
    } else if (first.isNotEmpty) {
      initials = first.characters.take(2).toString().toUpperCase();
    } else if (appState.userName.isNotEmpty) {
      final parts = appState.userName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts[0].characters.first}${parts[1].characters.first}'.toUpperCase();
      } else {
        initials = parts[0].characters.take(2).toString().toUpperCase();
      }
    } else {
      String email = '';
      try {
        if (Firebase.apps.isNotEmpty) {
          email = FirebaseAuth.instance.currentUser?.email ?? '';
        }
      } catch (_) {}
      if (email.isNotEmpty) {
        initials = email.split('@').first.characters.take(2).toString().toUpperCase();
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
    AppColors colors,
    AppStrings strings,
    AppState appState,
  ) {
    return Row(
      children: [
        // 1. Pin "Profile completion" to start edge
        Text(
          strings.pcT,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.tx,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 2. Middle span fills the entire space: Expanded progress bar + percentage
        Expanded(
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
                  fontWeight: FontWeight.w700,
                  color: colors.tx,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 3. Pin "Complete" action button to end edge
        InkWell(
          onTap: () {
            ref
                .read(appStateProvider.notifier)
                .switchProfileTab('p-identity');
          },
          borderRadius: AppRadius.rSm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
