import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/email_verification_gate.dart';
import '../../domain/shop_product.dart';

class TryOnSheet extends ConsumerWidget {
  const TryOnSheet({
    super.key,
    required this.product,
  });

  final ShopProduct product;

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return const Color(0xFF6B8FB5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final itemColor = _parseColor(product.colorHex);
    final appState = ref.watch(appStateProvider);
    final userCoins = appState.coins;
    final localizedName = strings.tr(product.name);

    return AppBottomSheetShell(
      title: localizedName,
      bottomBar: AppButton(
        isFullWidth: true,
        text: strings.shopSendToTryOn,
        onPressed: () {
          if (!checkEmailVerificationGate(context, ref)) return;
          if (userCoins < 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  strings.shopInsufficientCoins,
                  style: const TextStyle(fontFamily: 'Vazirmatn'),
                ),
              ),
            );
            return;
          }

          ref.read(appStateProvider.notifier).addCoins(-5);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                strings.shopTryOnSent(localizedName),
                style: const TextStyle(fontFamily: 'Vazirmatn'),
              ),
            ),
          );
        },
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon preview
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: itemColor.withValues(alpha: 0.2),
                borderRadius: AppRadius.rCard,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 34,
                color: colors.pr,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            strings.shopTryOnDesc,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.md),

          // Coin box
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 18,
                      color: Color(0xFFD9A406),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strings.shopTryOnCost5,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                  ],
                ),
                Text(
                  strings.balanceText(userCoins),
                  style: AppTypography.caption(color: colors.mu),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
