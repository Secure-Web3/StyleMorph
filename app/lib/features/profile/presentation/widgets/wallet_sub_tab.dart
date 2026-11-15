import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';

class WalletSubTab extends ConsumerStatefulWidget {
  const WalletSubTab({super.key});

  @override
  ConsumerState<WalletSubTab> createState() => _WalletSubTabState();
}

class _WalletSubTabState extends ConsumerState<WalletSubTab> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    // Award bonus coins for promo code
    ref.read(appStateProvider.notifier).addCoins(50);
    _promoController.clear();
    final strings = context.strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.walPromoApplied(code),
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        backgroundColor: Colors.green[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            faIcon: FontAwesomeIcons.wallet,
            title: strings.walHeader,
            trailing: AppBadge(
              variant: AppBadgeVariant.warning,
              size: AppBadgeSize.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.coins, size: 11, color: colors.wn),
                  const SizedBox(width: AppSpacing.xs),
                  Text(strings.coinsText(appState.coins)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Active Plan Card
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.walActivePlan,
                          style: AppTypography.cardTitle(color: colors.tx),
                        ),
                        Text(
                          strings.tr(appState.currentPlan),
                          style: AppTypography.caption(color: colors.mu),
                        ),
                      ],
                    ),
                    AppBadge(
                      variant: AppBadgeVariant.success,
                      size: AppBadgeSize.sm,
                      child: Text(strings.walActive),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 3 Upgrade Options
                Row(
                  children: [
                    Expanded(
                      child: _buildPlanButton(
                        planName: 'Plus',
                        price: '${strings.formatCurrency(99000)} / ${strings.walMonthShort}',
                        isHighlighted: false,
                        colors: colors,
                        strings: strings,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPlanButton(
                        planName: 'Pro',
                        price: '${strings.formatCurrency(199000)} / ${strings.walMonthShort}',
                        isHighlighted: true,
                        colors: colors,
                        strings: strings,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPlanButton(
                        planName: 'Ultra',
                        price: '${strings.formatCurrency(299000)} / ${strings.walMonthShort}',
                        isHighlighted: false,
                        colors: colors,
                        strings: strings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // StyleCoin Purchase Packages Header
          Text(
            strings.walBuyCoins,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // 2-Column Packages Grid
          Row(
            children: [
              Expanded(
                child: _buildCoinPackageCard(
                  title: strings.coinsText(50),
                  price: strings.formatCurrency(99000),
                  coinsToAdd: 50,
                  colors: colors,
                  strings: strings,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildCoinPackageCard(
                  title: strings.walPkg200,
                  price: strings.formatCurrency(350000),
                  coinsToAdd: 220,
                  badge: strings.walPopular,
                  colors: colors,
                  strings: strings,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Gift / Discount Code Box
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _promoController,
                  placeholder: strings.walPromoHint,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                size: AppButtonSize.sm,
                height: 40,
                text: strings.walApply,
                onPressed: _applyPromo,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Recent Transactions Header
          Text(
            strings.walRecentTx,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Transaction Items
          _buildTransactionItem(
            title: strings.walTxTopup,
            time: strings.walTxTopupTime,
            coinChange: '+${strings.formatNumber(150)}',
            isPositive: true,
            colors: colors,
            strings: strings,
          ),
          const SizedBox(height: 4),
          _buildTransactionItem(
            title: strings.walTxTryon,
            time: strings.walTxTryonTime,
            coinChange: '-${strings.formatNumber(10)}',
            isPositive: false,
            colors: colors,
            strings: strings,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanButton({
    required String planName,
    required String price,
    required bool isHighlighted,
    required AppColors colors,
    required AppStrings strings,
  }) {
    return InkWell(
      onTap: () {
        ref.read(appStateProvider.notifier).setPlan('پلن $planName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.walPlanChanged(planName),
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        );
      },
      borderRadius: AppRadius.rMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isHighlighted ? colors.pr : colors.bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: isHighlighted ? colors.pr : colors.bd,
          ),
        ),
        child: Column(
          children: [
            Text(
              planName,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isHighlighted ? colors.prt : colors.tx,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 9,
                color: isHighlighted ? colors.prt.withValues(alpha: 0.8) : colors.mu,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinPackageCard({
    required String title,
    required String price,
    required int coinsToAdd,
    String? badge,
    required AppColors colors,
    required AppStrings strings,
  }) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle(color: colors.tx),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.xs),
                AppBadge(
                  variant: AppBadgeVariant.warning,
                  size: AppBadgeSize.sm,
                  child: Text(badge, style: const TextStyle(fontSize: 9)),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            size: AppButtonSize.sm,
            isFullWidth: true,
            text: price,
            onPressed: () {
              ref.read(appStateProvider.notifier).addCoins(coinsToAdd);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    strings.walCoinsAdded(coinsToAdd),
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                  backgroundColor: Colors.green[800],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String time,
    required String coinChange,
    required bool isPositive,
    required AppColors colors,
    required AppStrings strings,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.tx,
                  ),
                ),
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    color: colors.mu,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$coinChange ${strings.coin}',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPositive ? colors.ok : colors.orColor,
            ),
          ),
        ],
      ),
    );
  }
}
