import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../stylist/domain/stylist_models.dart';
import '../../../stylist/presentation/widgets/try_on_dialog.dart';
import '../../../wardrobe/domain/wardrobe_item.dart';
import '../../../wardrobe/presentation/wardrobe_provider.dart';
import '../../domain/extracted_web_product.dart';

/// Floating StyleMorph product action bar displayed over external merchant
/// pages inside the Shop WebView, offering Try On, Save to Wardrobe, and
/// Result Feedback handoffs.
class WebProductActionBar extends ConsumerWidget {
  const WebProductActionBar({
    super.key,
    required this.product,
    this.onFeedbackRecorded,
  });

  final ExtractedWebProduct product;
  final void Function(WebProductFeedbackType type)? onFeedbackRecorded;

  void _openTryOnPreview(BuildContext context) {
    final strings = context.strings;
    final colors = context.colors;

    AppModal.showSheet(
      context: context,
      child: AppBottomSheetShell(
        title: strings.shopWebTryOnConfirmTitle,
        bottomBar: AppButton(
          isFullWidth: true,
          text: strings.shopWebTryOnContinue,
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          onPressed: () {
            Navigator.pop(context);
            final outfit = StylistOutfit(
              id: 'web_${DateTime.now().millisecondsSinceEpoch}',
              title: product.title,
              occasion: 'روزمره',
              tags: [
                if (product.sourceHost.isNotEmpty) product.sourceHost,
                'Web Discovery',
              ],
              items: [
                StylistOutfitItem(
                  title: product.title,
                  category: 'tops',
                  colorHex: '#8C6D46',
                  icon: Icons.checkroom_rounded,
                ),
              ],
            );
            AppModal.showSheet(
              context: context,
              child: TryOnDialog(outfit: outfit),
            );
          },
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard(
              variant: AppCardVariant.subtle,
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Row(
                children: [
                  _ProductThumbnail(
                    imageUrl: product.imageUrl,
                    colors: colors,
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: AppTypography.cardTitle(color: colors.tx),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          product.sourceHost,
                          style: AppTypography.caption(color: colors.mu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.priceText != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${product.priceText} ${product.currency ?? ''}'
                                .trim(),
                            style: AppTypography.cardTitle(color: colors.pr),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSaveWardrobeSheet(BuildContext context, WidgetRef ref) {
    AppModal.showSheet(
      context: context,
      child: _SaveToWardrobeSheet(
        product: product,
        onSave: (title, category) async {
          final item = WardrobeItem(
            id: 'web_${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            category: category,
            subCategory: product.sourceHost,
            thumbUrl: product.imageUrl,
            originalUrl: product.pageUrl,
            imageUrls: product.imageUrl.isNotEmpty
                ? [product.imageUrl]
                : const [],
          );
          await ref.read(wardrobeProvider.notifier).addItem(item);
        },
      ),
    );
  }

  void _openFeedbackSheet(BuildContext context) {
    final strings = context.strings;
    final colors = context.colors;

    final options = [
      (
        WebProductFeedbackType.accurate,
        strings.shopWebFeedbackAccurate,
        Icons.thumb_up_alt_outlined,
        colors.ok,
      ),
      (
        WebProductFeedbackType.outOfStock,
        strings.shopWebFeedbackOutOfStock,
        Icons.inventory_2_outlined,
        colors.wn,
      ),
      (
        WebProductFeedbackType.brokenLink,
        strings.shopWebFeedbackBrokenLink,
        Icons.link_off_rounded,
        colors.orColor,
      ),
      (
        WebProductFeedbackType.wrongItem,
        strings.shopWebFeedbackWrongItem,
        Icons.report_problem_outlined,
        colors.mu,
      ),
    ];

    AppModal.showSheet(
      context: context,
      child: AppBottomSheetShell(
        title: strings.shopWebFeedbackTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options.map((opt) {
            return Material(
              type: MaterialType.transparency,
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.rLg,
                ),
                leading: Icon(opt.$3, color: opt.$4, size: 20),
                title: Text(
                  opt.$2,
                  style: AppTypography.inputLabel(color: colors.tx),
                ),
                dense: true,
                onTap: () {
                  onFeedbackRecorded?.call(opt.$1);
                  debugPrint(
                    '[ShopWebFeedback] ${opt.$1.name} -> ${product.pageUrl}',
                  );
                  Navigator.pop(context);
                  AppToast.showInfo(context, strings.shopWebFeedbackThanks);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;

    return Container(
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rXl,
        border: Border.all(color: colors.bd),
        boxShadow: [
          BoxShadow(
            color: colors.tx.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProductThumbnail(
                imageUrl: product.imageUrl,
                colors: colors,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      style: AppTypography.cardTitle(color: colors.tx),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        product.sourceHost,
                        if (product.priceText != null)
                          '${product.priceText} ${product.currency ?? ''}'
                              .trim(),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: AppTypography.caption(color: colors.mu),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  onPressed: () => _openTryOnPreview(context),
                  child: _ActionButtonLabel(
                    icon: Icons.checkroom_rounded,
                    label: strings.shopWebTryOnBtn,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  onPressed: () => _openSaveWardrobeSheet(context, ref),
                  child: _ActionButtonLabel(
                    icon: Icons.bookmark_add_rounded,
                    label: strings.shopWebSaveWardrobeBtn,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  onPressed: () => _openFeedbackSheet(context),
                  child: _ActionButtonLabel(
                    icon: Icons.flag_outlined,
                    label: strings.shopWebFeedbackBtn,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtonLabel extends StatelessWidget {
  const _ActionButtonLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, maxLines: 1),
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.imageUrl,
    required this.colors,
    required this.size,
  });

  final String imageUrl;
  final AppColors colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.rMd,
      child: Container(
        width: size,
        height: size,
        color: colors.bg,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.shopping_bag_outlined,
                  color: colors.pr,
                  size: 18,
                ),
              )
            : Icon(Icons.shopping_bag_outlined, color: colors.pr, size: 18),
      ),
    );
  }
}

class _SaveToWardrobeSheet extends StatefulWidget {
  const _SaveToWardrobeSheet({required this.product, required this.onSave});

  final ExtractedWebProduct product;
  final Future<void> Function(String title, String category) onSave;

  @override
  State<_SaveToWardrobeSheet> createState() => _SaveToWardrobeSheetState();
}

class _SaveToWardrobeSheetState extends State<_SaveToWardrobeSheet> {
  late final TextEditingController _titleCtrl;
  String _selectedCategory = 'tops';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.product.title);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.colors;

    final categories = [
      ('tops', strings.shopCatCloth),
      ('footwear', strings.wardCatSh),
      ('bags', strings.wardCatBg),
      ('accessories', strings.wardCatAc),
    ];

    return AppBottomSheetShell(
      title: strings.shopWebSaveTitle,
      bottomBar: AppButton(
        isFullWidth: true,
        text: strings.shopWebSaveWardrobeBtn,
        onPressed: _saving
            ? null
            : () async {
                final title = _titleCtrl.text.trim().isNotEmpty
                    ? _titleCtrl.text.trim()
                    : widget.product.title;
                setState(() => _saving = true);
                try {
                  await widget.onSave(title, _selectedCategory);
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppToast.showSuccess(context, strings.shopWebSavedSuccess);
                  }
                } finally {
                  if (mounted) {
                    setState(() => _saving = false);
                  }
                }
              },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _titleCtrl,
            label: strings.shopWebItemTitleLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings.shopWebCategoryLabel,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: categories.map((cat) {
              return AppChip(
                label: cat.$2,
                isSelected: _selectedCategory == cat.$1,
                onTap: () => setState(() => _selectedCategory = cat.$1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
