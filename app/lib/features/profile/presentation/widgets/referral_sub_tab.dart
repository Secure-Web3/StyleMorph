import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

class ReferralSubTab extends ConsumerWidget {
  const ReferralSubTab({super.key});

  static const String _referralLink = 'https://stylemorph.app/r/sara88';

  void _copyLink(BuildContext context, AppStrings strings) {
    Clipboard.setData(const ClipboardData(text: _referralLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.refCopiedToast,
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  value: strings.countWithUnit(12, strings.refMembersUnit),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Bonus Earned
              Expanded(
                child: _buildStatCard(
                  label: strings.refBonus,
                  value: '${strings.formatNumber('1,200')} ${strings.coin}',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Network Tier
              Expanded(
                child: _buildStatCard(
                  label: strings.refTier,
                  value: strings.tr('طلایی'),
                  valueColor: colors.wn,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Referral Link Box
          Text(
            strings.refLinkLabel,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: AppRadius.rLg,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Text(
                    _referralLink,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: colors.mu,
                    ),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                size: AppButtonSize.sm,
                height: 40,
                icon: FaIcon(FontAwesomeIcons.copy, size: 12, color: colors.prt),
                text: strings.refCopy,
                onPressed: () => _copyLink(context, strings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Joined Friends Header
          Text(
            strings.refJoinedTitle,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Friend Item 1
          _buildFriendItem(
            name: strings.tr('مریم کاظمی'),
            handle: '@maryam',
            reward: '+${strings.coinsText(100)}',
            colors: colors,
          ),
          const SizedBox(height: 4),
          // Friend Item 2
          _buildFriendItem(
            name: strings.tr('علی رضاپور'),
            handle: '@ali_r',
            reward: '+${strings.coinsText(100)}',
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.md),

          // Bonus Rule Info Card
          AppCard(
            backgroundColor: colors.wnb.withValues(alpha: 0.5),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.circleQuestion, size: 14, color: colors.wn),
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
              fontFamily: 'Vazirmatn',
              fontSize: 9,
              color: colors.mu,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.tx,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem({
    required String name,
    required String handle,
    required String reward,
    required AppColors colors,
  }) {
    return AppCard(
      variant: AppCardVariant.subtle,
      borderRadius: AppRadius.rLg,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.sf,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Center(
                    child: FaIcon(FontAwesomeIcons.userCheck,
                        size: 10, color: colors.mu),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '$name ($handle)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.tx,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            reward,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.ok,
            ),
          ),
        ],
      ),
    );
  }
}
