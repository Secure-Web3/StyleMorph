import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/loyalty_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_media_image.dart';
import '../../../../core/widgets/gender_3d_avatar.dart';
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
    final isProfileMode = ref.watch(
      appStateProvider.select((s) => s.currentTab == AppTab.profile),
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
            child: isProfileMode
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HeaderAvatar(
                        onOpenDrawer: onOpenDrawer,
                        isProfileMode: true,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _HeaderUserInfo()),
                                SizedBox(width: AppSpacing.sm),
                                _HeaderActions(),
                              ],
                            ),
                            SizedBox(height: 6),
                            _HeaderProfileProgressSection(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HeaderAvatar(
                        onOpenDrawer: onOpenDrawer,
                        isProfileMode: false,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(child: _HeaderUserInfo()),
                      const SizedBox(width: AppSpacing.sm),
                      const _HeaderActions(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar with Loyalty Rank border ─────────────────────────────────────────

class _HeaderAvatar extends ConsumerWidget {
  final VoidCallback? onOpenDrawer;
  final bool isProfileMode;

  const _HeaderAvatar({this.onOpenDrawer, required this.isProfileMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final (loyaltyRank, stylePoints, effectiveAvatarUrl, gender) = ref.watch(
      appStateProvider.select(
        (s) => (s.loyaltyRank, s.stylePoints, s.effectiveAvatarUrl, s.gender),
      ),
    );

    final double avatarSize = isProfileMode ? 66.0 : 54.0;

    final avatarTapTarget = InkWell(
      key: const Key('header_avatar'),
      onTap: () {
        if (onOpenDrawer != null) {
          onOpenDrawer!();
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
      borderRadius: BorderRadius.circular(avatarSize / 2),
      child: _buildAvatar(
        colors,
        avatarSize: avatarSize,
        loyaltyRank: loyaltyRank,
        effectiveAvatarUrl: effectiveAvatarUrl,
        gender: gender,
      ),
    );

    if (!isProfileMode) {
      return avatarTapTarget;
    }

    final rank = LoyaltyRankExtension.fromString(loyaltyRank);
    final rankColor = rank.color;
    final rankLabel = rank.getLocalizedName(strings);
    final ptsText = '${strings.formatNumber(stylePoints)} ${strings.pts}';

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 66.0, maxWidth: 112.0),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: avatarTapTarget,
            ),
            Positioned(
              bottom: 0,
              child: GestureDetector(
                key: const Key('header_loyalty_rank_badge'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  LoyaltyModalSheet.show(
                    context,
                    points: stylePoints,
                    rank: rank,
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 112.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.sf,
                    borderRadius: AppRadius.rFull,
                    border: Border.all(color: colors.sf, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colors.tx.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.14),
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
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '$rankLabel • $ptsText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: colors.tx,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    AppColors colors, {
    required double avatarSize,
    required String loyaltyRank,
    required String? effectiveAvatarUrl,
    required String? gender,
  }) {
    final rank = LoyaltyRankExtension.fromString(loyaltyRank);
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
            final resolvedUrl = effectiveAvatarUrl?.trim();
            if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
              return AppMediaImage(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Gender3dAvatar(gender: gender),
              );
            }

            return Gender3dAvatar(gender: gender);
          },
        ),
      ),
    );
  }
}

// ── User Full Name, KYC badge, & Email ───────────────────────────────────────

class _HeaderUserInfo extends ConsumerWidget {
  const _HeaderUserInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final (userName, isKycVerified, identityEmail, showEmailInHeader) = ref
        .watch(
          appStateProvider.select(
            (s) => (
              s.userName,
              s.kycData.isVerified,
              s.identityValues['email'] ?? '',
              s.preferences.showEmailInHeader,
            ),
          ),
        );
    final isEmailVerified = ref.watch(
      emailVerificationProvider.select((s) => s.isVerified),
    );

    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}

    final isVerified = isKycVerified || isEmailVerified;
    final displayName = userName.isNotEmpty
        ? strings.tr(userName)
        : (user?.displayName ??
              (user?.email?.split('@').first ?? strings.newUser));
    final userEmail = user?.email ?? identityEmail;
    final showEmail = showEmailInHeader && userEmail.isNotEmpty;

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
            color: isKycVerified ? colors.ok : colors.inColor,
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
      return Align(alignment: AlignmentDirectional.centerStart, child: nameRow);
    }
  }
}

// ── Notification Bell & Coins Pill ──────────────────────────────────────────

class _HeaderActions extends ConsumerWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final (localUnreadCount, showHeaderCoins, coins) = ref.watch(
      appStateProvider.select(
        (s) => (s.unreadNotificationsCount, s.showHeaderCoins, s.coins),
      ),
    );
    final authUid = currentAuthenticatedUid();
    final unreadCount = authUid != null
        ? ref
              .watch(notificationsStreamProvider(authUid))
              .maybeWhen(
                data: NotificationService.countUnread,
                orElse: () => localUnreadCount,
              )
        : localUnreadCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
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
                  constraints: const BoxConstraints(maxWidth: 430),
                  builder: (_) => const NotificationSheet(),
                );
              },
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(AppSpacing.xs),
              ),
              visualDensity: VisualDensity.compact,
              icon: FaIcon(FontAwesomeIcons.bell, size: 15, color: colors.tx),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: strings.notificationsTitle,
            ),
            // Pulsing/glowing orange notification dot (only when unread > 0)
            if (unreadCount > 0)
              PositionedDirectional(
                top: 3,
                end: 3,
                child: _PulsingNotificationDot(
                  key: const Key('header_notifications_unread_dot'),
                  color: colors.orColor,
                  borderColor: colors.sf,
                  isActive: unreadCount > 0,
                ),
              ),
          ],
        ),

        // StyleCoin Chip
        if (showHeaderCoins) ...[
          const SizedBox(height: 1),
          _buildCoinsBadge(colors, strings, coins),
        ],
      ],
    );
  }

  Widget _buildCoinsBadge(AppColors colors, AppStrings strings, int coins) {
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
              strings.formatNumber(coins),
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
}

// ── Profile completion progress bar ─────────────────────────────────────────

class _HeaderProfileProgressSection extends ConsumerWidget {
  const _HeaderProfileProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final profileProgress = ref.watch(
      appStateProvider.select((s) => s.profileProgress),
    );

    return Row(
      children: [
        // 1. Start (Expanded): Smooth horizontal profile completion progress bar + localized percentage
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
                      widthFactor: profileProgress.clamp(0.0, 1.0),
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
                strings.formatPercent((profileProgress * 100).round()),
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

        // 2. End: Compact dark pill action button (Complete Profile)
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

class _PulsingNotificationDot extends StatefulWidget {
  final Color color;
  final Color borderColor;
  final bool isActive;

  const _PulsingNotificationDot({
    super.key,
    required this.color,
    required this.borderColor,
    required this.isActive,
  });

  @override
  State<_PulsingNotificationDot> createState() =>
      _PulsingNotificationDotState();
}

class _PulsingNotificationDotState extends State<_PulsingNotificationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  bool get _isWidgetTestBinding =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.isActive) {
      if (_isWidgetTestBinding) {
        _controller.value = 0.5;
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingNotificationDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      if (_isWidgetTestBinding) {
        _controller.value = 0.5;
      } else {
        _controller.repeat(reverse: true);
      }
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        final scale = 0.92 + (0.20 * t);
        final opacity = 0.72 + (0.28 * t);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: widget.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.25 + (0.35 * t)),
                    blurRadius: 4 + (4 * t),
                    spreadRadius: 0.5 + (1.2 * t),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
