import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/referral_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/auth_provider.dart';
import 'share_actions.dart' as share_actions;

final referralsStreamProvider = StreamProvider.autoDispose
    .family<List<ReferralEntry>, String>((ref, uid) {
      if (uid.isEmpty) return const Stream.empty();
      return ref.watch(referralServiceProvider).referralsStream(uid);
    });

class ReferralSubTab extends ConsumerStatefulWidget {
  const ReferralSubTab({super.key});

  @override
  ConsumerState<ReferralSubTab> createState() => _ReferralSubTabState();
}

class _ReferralSubTabState extends ConsumerState<ReferralSubTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      String uid = '';
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        }
      } catch (_) {}
      if (uid.isNotEmpty) {
        final referralService = ref.read(referralServiceProvider);
        final ensuredCode = await referralService.ensureUserReferralCode(uid);
        final fresh = await referralService.getReferrals(uid);
        if (mounted) {
          final currentCode = ref.read(appStateProvider).referralCode;
          if (fresh.isNotEmpty ||
              (ensuredCode.isNotEmpty && currentCode.isEmpty)) {
            ref
                .read(appStateProvider.notifier)
                .setReferralData(
                  referralCode: ensuredCode.isNotEmpty && currentCode.isEmpty
                      ? ensuredCode
                      : null,
                  referrals: fresh.isNotEmpty ? fresh : null,
                );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _shareOrCopyLink(
    BuildContext context,
    String link,
    AppStrings strings,
  ) async {
    if (link.isEmpty) return;
    final shared = await share_actions.shareLink(link, 'StyleMorph');

    if (!shared) {
      Clipboard.setData(ClipboardData(text: link));
      if (!context.mounted) return;
      AppToast.showSuccess(context, strings.refCopiedToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    String uid = ref.watch(currentUidProvider) ?? '';
    if (uid.isEmpty) {
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        }
      } catch (_) {
        uid = '';
      }
    }

    final refCode = appState.referralCode.isNotEmpty
        ? appState.referralCode
        : (uid.length >= 8 ? uid.substring(0, 8).toUpperCase() : uid);
    final referralLink = refCode.isNotEmpty
        ? 'https://stylemorph-preview.web.app/?ref=$refCode'
        : 'https://stylemorph-preview.web.app/?ref=...';

    if (uid.isNotEmpty) {
      ref.listen<AsyncValue<List<ReferralEntry>>>(
        referralsStreamProvider(uid),
        (prev, next) {
          final list = next.valueOrNull;
          if (list != null) {
            ref
                .read(appStateProvider.notifier)
                .setReferralData(referrals: list);
          }
        },
      );
    }

    final liveReferralsAsync = uid.isNotEmpty
        ? ref.watch(referralsStreamProvider(uid))
        : null;

    final referrals = liveReferralsAsync?.valueOrNull ?? appState.referrals;
    final invitedCount = referrals.isNotEmpty
        ? referrals.length
        : appState.referralCount;
    final networkTier = referrals.isNotEmpty
        ? ReferralService.calculateTier(referrals.length)
        : appState.networkTier;
    final earnedCoins = referrals.isNotEmpty
        ? referrals.fold<int>(0, (sum, r) => sum + r.rewardEarned)
        : (invitedCount * 100);

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top (Fixed) ──────────────────────────────────────────────
          AppSectionHeader(
            faIcon: FontAwesomeIcons.gift,
            title: strings.refHeader,
          ),
          const SizedBox(height: AppSpacing.md),

          // 3-Column Stats Grid
          Row(
            children: [
              // Invited Count
              Expanded(
                child: _buildStatCard(
                  label: strings.refInvited,
                  value: strings.countWithUnit(
                    invitedCount,
                    strings.refMembersUnit,
                  ),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Bonus Earned
              Expanded(
                child: _buildStatCard(
                  label: strings.refBonus,
                  value: '${strings.formatNumber(earnedCoins)} ${strings.coin}',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Network Tier
              Expanded(
                child: _buildStatCard(
                  label: strings.refTier,
                  value: strings.getTierLabel(networkTier),
                  valueColor: colors.wn,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Compact Tap-to-Copy 8-Character Referral Code Box (no separate copy button)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: refCode.isNotEmpty
                  ? () {
                      Clipboard.setData(ClipboardData(text: refCode));
                      AppToast.showSuccess(context, strings.refCopiedToast);
                    }
                  : null,
              borderRadius: AppRadius.rLg,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.sf,
                  borderRadius: AppRadius.rLg,
                  border: Border.all(color: colors.bd),
                ),
                child: Text(
                  refCode.isNotEmpty ? refCode : '...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: colors.pr,
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Referral Link Box (Full-Width, Single-Tap Native Share / Copy)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.refLinkLabel,
                style: AppTypography.inputLabel(color: colors.tx),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  strings.refTapToShare,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    color: colors.mu,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: referralLink.isNotEmpty
                  ? () => _shareOrCopyLink(context, referralLink, strings)
                  : null,
              borderRadius: AppRadius.rLg,
              child: Container(
                height: 44,
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: AppRadius.rLg,
                  border: Border.all(color: colors.bd),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        referralLink,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: colors.tx,
                        ),
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FaIcon(
                      FontAwesomeIcons.shareNodes,
                      size: 13,
                      color: colors.pr,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Joined Friends Header
          Text(
            strings.refJoinedTitle,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Middle (Expanded — Fills ALL Remaining Vertical Space) ─────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.sf,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: colors.bd),
              ),
              clipBehavior: Clip.antiAlias,
              child: referrals.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.userGroup,
                              size: 24,
                              color: colors.mu,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              strings.refEmptyFriends,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: colors.mu,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        itemCount: referrals.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: colors.bd.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (context, index) {
                          final item = referrals[index];
                          return _buildFriendItem(item, colors, strings);
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Bottom (Pinned to Bottom Edge) ─────────────────────────────
          AppCard(
            backgroundColor: colors.wnb.withValues(alpha: 0.5),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleQuestion,
                  size: 14,
                  color: colors.wn,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings.refRuleInfo,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: colors.tx,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(
    ReferralEntry item,
    AppColors colors,
    AppStrings strings,
  ) {
    final name = item.displayName.isNotEmpty
        ? item.displayName
        : (item.email.isNotEmpty ? item.email.split('@').first : 'User');
    final coinsStr = strings.formatNumber(item.rewardEarned);
    final badgeText = '+ $coinsStr ${strings.coin}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Name on start side, Earned Coins Badge on end side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.tx,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                variant: AppBadgeVariant.success,
                size: AppBadgeSize.sm,
                child: Text(badgeText),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Row 2: Invitee email address in clean, compact, smaller muted font directly underneath
          Text(
            item.email,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: colors.mu,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    Color? valueColor,
    required AppColors colors,
  }) {
    return AppCard(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 9,
              color: colors.mu,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}
