import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

class ReferralSubTab extends ConsumerWidget {
  const ReferralSubTab({super.key});

  void _copyLink(BuildContext context, String link, AppStrings strings) {
    if (link.isEmpty) return;
    Clipboard.setData(ClipboardData(text: link));
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
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final handle = ref
        .watch(appStateProvider.select((s) => s.userHandle))
        .replaceAll('@', '')
        .trim();
    final refCode =
        handle.isNotEmpty ? handle : (uid.length >= 8 ? uid.substring(0, 8) : uid);
    final referralLink =
        refCode.isNotEmpty ? 'https://stylemorph.app/r/$refCode' : '';

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
              // Invited Count (Real default: 0)
              Expanded(
                child: _buildStatCard(
                  label: strings.refInvited,
                  value: strings.countWithUnit(0, strings.refMembersUnit),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Bonus Earned (Real default: 0)
              Expanded(
                child: _buildStatCard(
                  label: strings.refBonus,
                  value: '۰ ${strings.coin}',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Network Tier (Default starter tier)
              Expanded(
                child: _buildStatCard(
                  label: strings.refTier,
                  value: strings.tr('پایه'),
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
                    referralLink.isNotEmpty
                        ? referralLink
                        : 'https://stylemorph.app/r/...',
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
                onPressed: referralLink.isNotEmpty
                    ? () => _copyLink(context, referralLink, strings)
                    : null,
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

          // Clean Empty State for Friends List (Purged fake members)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            decoration: BoxDecoration(
              color: colors.sf,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: colors.bd),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.userGroup,
                  size: 20,
                  color: colors.mu,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'هنوز دوستی با کد شما ثبت‌نام نکرده است',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.mu,
                  ),
                ),
              ],
            ),
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
}
