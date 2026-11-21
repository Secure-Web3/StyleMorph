import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../domain/shop_product.dart';

class SellerRedirectSheet extends StatelessWidget {
  const SellerRedirectSheet({
    super.key,
    required this.product,
    required this.seller,
  });

  final ShopProduct product;
  final ShopSeller seller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final localizedStore = strings.tr(seller.storeName);

    return AppBottomSheetShell(
      title: localizedStore,
      bottomBar: Row(
        children: [
          Expanded(
            child: AppButton(
              variant: AppButtonVariant.outline,
              text: strings.back,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppButton(
              isFullWidth: true,
              icon: Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: colors.prt,
              ),
              text: strings.shopRedirectBtn,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      strings.shopRedirectMsg(localizedStore),
                      style: const TextStyle(fontFamily: 'Vazirmatn'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: AppRadius.rLg,
                  border: Border.all(color: colors.bd),
                ),
                child: Icon(Icons.store_rounded, size: 22, color: colors.pr),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedStore,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                    Text(
                      seller.type == 'agent'
                          ? strings.shopOfficialAgent
                          : strings.shopIndSeller,
                      style: AppTypography.caption(color: colors.mu),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    strings.formatCurrency(seller.price),
                    style: AppTypography.cardTitle(color: colors.tx),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFD9A406),
                      ),
                      Text(
                        ' ${strings.formatNumber(seller.rating)}',
                        style: AppTypography.caption(color: colors.mu),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Security & Info Notices
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NoticeRow(
                  icon: Icons.open_in_new_rounded,
                  text: strings.shopLeavingNotice(localizedStore),
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.sm),
                _NoticeRow(
                  icon: Icons.credit_card_rounded,
                  text: strings.shopNoticePay,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.sm),
                _NoticeRow(
                  icon: Icons.shield_outlined,
                  text: strings.shopNoticeShield,
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.icon,
    required this.text,
    required this.colors,
  });

  final IconData icon;
  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: colors.mu),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: colors.mu,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
