import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/loyalty_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../auth/presentation/email_verification_provider.dart';

class LoyaltyModalSheet extends ConsumerWidget {
  final int points;
  final LoyaltyRank rank;
  final LoyaltyPointsBreakdown? breakdown;

  const LoyaltyModalSheet({
    super.key,
    required this.points,
    required this.rank,
    this.breakdown,
  });

  static Future<void> show(
    BuildContext context, {
    required int points,
    required LoyaltyRank rank,
    LoyaltyPointsBreakdown? breakdown,
  }) {
    return AppModal.showSheet(
      context: context,
      child: LoyaltyModalSheet(
        points: points,
        rank: rank,
        breakdown: breakdown,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final rankColor = rank.color;
    final rankName = rank.getLocalizedName(strings);
    final progressToNext = LoyaltyService.calculateProgressToNextRank(points);
    final nextThreshold = rank.nextRankThreshold;

    final resolvedBreakdown =
        breakdown ??
        () {
          final (
            profileProgress,
            referralCount,
            aiUsageCount,
            coins,
          ) = ref.watch(
            appStateProvider.select(
              (s) =>
                  (s.profileProgress, s.referralCount, s.aiUsageCount, s.coins),
            ),
          );
          final isEmailVerified = ref.watch(
            emailVerificationProvider.select((s) => s.isVerified),
          );
          return LoyaltyService.calculateBreakdown(
            profileProgress: profileProgress,
            isEmailVerified: isEmailVerified,
            referralCount: referralCount,
            aiUsageCount: aiUsageCount,
            coinActivity: coins,
          );
        }();

    return AppBottomSheetShell(
      title: strings.loyaltyTitle,
      titleLeading: FaIcon(FontAwesomeIcons.award, size: 16, color: rankColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Current Rank & Points Hero Card ─────────────────────────────
          AppCard(
            variant: AppCardVariant.surface,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.rFull,
                        border: Border.all(color: rankColor, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: rankColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            rankName,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.tx,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          strings.formatNumber(points),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colors.tx,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.pts,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.mu,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Progress to next rank bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.bd,
                        borderRadius: AppRadius.rFull,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressToNext,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: AppRadius.rFull,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (nextThreshold != null) ...[
                  Text(
                    strings.pointsToNextRank(
                      strings.formatNumber(nextThreshold - points),
                    ),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.mu,
                    ),
                  ),
                ] else ...[
                  Text(
                    strings.maxRankReached,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: rankColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 1B. Itemized Earned Points Breakdown ──────────────────────────
          Text(
            strings.loyaltyYourEarnedPointsTitle,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            key: const Key('loyalty_earned_points_breakdown_card'),
            variant: AppCardVariant.surface,
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            child: Column(
              children: [
                _buildBreakdownRow(
                  colors,
                  strings,
                  FontAwesomeIcons.solidUser,
                  strings.loyaltyBreakdownProfile(
                    strings.formatPercent(
                      resolvedBreakdown.profileCompletionPercent,
                    ),
                  ),
                  resolvedBreakdown.profilePoints,
                  accentColor: rankColor,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildBreakdownRow(
                  colors,
                  strings,
                  FontAwesomeIcons.envelopeCircleCheck,
                  strings.loyaltyBreakdownEmail,
                  resolvedBreakdown.emailPoints,
                  accentColor: rankColor,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildBreakdownRow(
                  colors,
                  strings,
                  FontAwesomeIcons.userPlus,
                  strings.loyaltyBreakdownReferrals(
                    strings.formatNumber(resolvedBreakdown.referralCount),
                  ),
                  resolvedBreakdown.referralPoints,
                  accentColor: rankColor,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildBreakdownRow(
                  colors,
                  strings,
                  FontAwesomeIcons.wandMagicSparkles,
                  strings.loyaltyBreakdownAiUsage(
                    strings.formatNumber(resolvedBreakdown.aiUsageCount),
                  ),
                  resolvedBreakdown.aiPoints,
                  accentColor: rankColor,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildBreakdownRow(
                  colors,
                  strings,
                  FontAwesomeIcons.coins,
                  strings.loyaltyBreakdownWallet(
                    strings.formatNumber(resolvedBreakdown.coinActivity),
                  ),
                  resolvedBreakdown.walletPoints,
                  accentColor: rankColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 2. How to Earn Points Section ──────────────────────────────────
          Text(
            strings.howToEarnPoints,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            child: Column(
              children: [
                _buildRuleRow(
                  colors,
                  FontAwesomeIcons.solidUser,
                  strings.earnProfileRule,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildRuleRow(
                  colors,
                  FontAwesomeIcons.envelopeCircleCheck,
                  strings.earnEmailRule,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildRuleRow(
                  colors,
                  FontAwesomeIcons.userPlus,
                  strings.earnReferralRule,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildRuleRow(
                  colors,
                  FontAwesomeIcons.wandMagicSparkles,
                  strings.earnAiRule,
                ),
                Divider(height: 12, color: colors.bd.withValues(alpha: 0.5)),
                _buildRuleRow(
                  colors,
                  FontAwesomeIcons.coins,
                  strings.earnWalletRule,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 3. Loyalty Rank Perks Section ──────────────────────────────────
          Text(
            strings.loyaltyPerksTitle,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...LoyaltyRank.values.map((r) {
            final isCurrent = r == rank;
            final rColor = r.color;
            final rName = r.getLocalizedName(strings);
            final rPerk = r.getLocalizedPerk(strings);
            final rangeStr = r.nextRankThreshold != null
                ? '${strings.formatNumber(r.minPoints)} – ${strings.formatNumber(r.maxPoints)} ${strings.pts}'
                : '${strings.formatNumber(r.minPoints)}+ ${strings.pts}';

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isCurrent ? rColor.withValues(alpha: 0.08) : colors.sf,
                borderRadius: AppRadius.rMd,
                border: Border.all(
                  color: isCurrent ? rColor : colors.bd,
                  width: isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: rColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            rName,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isCurrent ? rColor : colors.tx,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: rColor,
                                borderRadius: AppRadius.rFull,
                              ),
                              child: Text(
                                strings.walActive,
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        rangeStr,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rPerk,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colors.tx,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    AppColors colors,
    AppStrings strings,
    FaIconData icon,
    String label,
    int earnedPoints, {
    required Color accentColor,
  }) {
    final hasEarned = earnedPoints > 0;
    final ptsLabel = '+${strings.formatNumber(earnedPoints)} ${strings.pts}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          FaIcon(icon, size: 12, color: hasEarned ? accentColor : colors.mu),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.tx,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            ptsLabel,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hasEarned ? accentColor : colors.mu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(AppColors colors, FaIconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 12, color: colors.mu),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: colors.tx,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
