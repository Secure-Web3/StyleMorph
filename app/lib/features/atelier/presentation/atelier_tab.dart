import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../domain/atelier_models.dart';
import 'atelier_provider.dart';
import 'widgets/template_detail_sheet.dart';
import 'widgets/creation_detail_sheet.dart';

class AtelierTab extends ConsumerWidget {
  const AtelierTab({super.key});

  static const _categoryCodes = [
    'all',
    'portrait',
    'fashion',
    'seasonal',
    'travel',
    'fav',
  ];

  static String _categoryLabel(AppStrings strings, String code) {
    switch (code) {
      case 'all':
        return strings.allText;
      case 'portrait':
        return strings.atelCatPortrait;
      case 'fashion':
        return strings.atelCatFashion;
      case 'seasonal':
        return strings.atelCatSeasonal;
      case 'travel':
        return strings.atelCatTravel;
      case 'fav':
        return strings.shopCatFav;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final atelierState = ref.watch(atelierProvider);
    final notifier = ref.read(atelierProvider.notifier);
    final isShowcase = atelierState.activeTab == 'showcase';
    final pendingCount = atelierState.pendingCreationsCount;

    return Column(
      children: [
        // --- Top Bar ---
        AppModuleHeader(
          icon: Icons.camera_alt_rounded,
          title: strings.atelierTitle,
          subtitle: strings.atelSub,
          trailing: AppSegmentedControl<String>(
            value: atelierState.activeTab,
            onChanged: notifier.switchTab,
            items: [
              AppSegmentItem(
                value: 'showcase',
                label: strings.atelShowcase,
              ),
              AppSegmentItem(
                value: 'creations',
                label: strings.myCreations,
                badgeText: pendingCount > 0
                    ? strings.formatNumber(pendingCount)
                    : null,
              ),
            ],
          ),
        ),

        // --- Active View Body ---
        Expanded(
          child: isShowcase
              ? _ShowcaseView(colors: colors)
              : _CreationsView(colors: colors),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
class _ShowcaseView extends ConsumerWidget {
  const _ShowcaseView({required this.colors});

  final AppColors colors;

  void _openTemplate(BuildContext context, AtelierTemplate t) {
    AppModal.showSheet(
      context: context,
      child: TemplateDetailSheet(template: t),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final state = ref.watch(atelierProvider);
    final notifier = ref.read(atelierProvider.notifier);
    final templates = state.filteredTemplates;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AtelierTab._categoryCodes.map((code) {
                return AppChip(
                  label: AtelierTab._categoryLabel(strings, code),
                  isSelected: state.templateCategory == code,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  onTap: () => notifier.setCategory(code),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Media Type Segmented Switcher (همه / عکس / ویدیو)
          AppSegmentedControl<String>(
            expand: true,
            value: state.mediaType,
            onChanged: notifier.setMediaType,
            items: [
              AppSegmentItem(value: 'all', label: strings.atelMediaAll),
              AppSegmentItem(value: 'p', label: strings.atelMediaPhoto),
              AppSegmentItem(value: 'v', label: strings.atelMediaVideo),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2-Column Template Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemCount: templates.length,
            itemBuilder: (_, i) {
              final t = templates[i];
              return _TemplateCard(
                template: t,
                colors: colors,
                isWishlisted: state.wishlist.contains(t.id),
                onTap: () => _openTemplate(context, t),
                onWishlist: () => notifier.toggleWishlist(t.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.colors,
    required this.isWishlisted,
    required this.onTap,
    required this.onWishlist,
  });

  final AtelierTemplate template;
  final AppColors colors;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlist;

  Color _parse(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final t = template;
    final primaryColor = _parse(t.colorHexes.first);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsetsDirectional.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview collage
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: primaryColor.withValues(alpha: 0.18),
                  child: Center(
                    child: Icon(
                      t.icons.first,
                      size: 38,
                      color: primaryColor,
                    ),
                  ),
                ),
                // Media badge
                PositionedDirectional(
                  top: 6,
                  start: 6,
                  child: AppBadge(
                    size: AppBadgeSize.sm,
                    borderRadius: AppRadius.rSm,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      t.type == 'v'
                          ? strings.atelVideoBadge
                          : strings.countWithUnit(
                              t.framesCount,
                              strings.atelPhotosUnit,
                            ),
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                  // Wishlist button
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: GestureDetector(
                      onTap: onWishlist,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: colors.sf.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 14,
                          color: isWishlisted
                              ? const Color(0xFFD1456B)
                              : colors.mu,
                        ),
                      ),
                    ),
                  ),
                  if (t.type == 'v')
                    Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.sf.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.tr(t.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            size: 12,
                            color: Color(0xFFD9A406),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            strings.coinsText(t.price),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.tx,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${strings.formatPercent(t.popularity)} ${strings.atelSatisfaction}',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 9,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

// ─────────────────────────────────────────────
class _CreationsView extends ConsumerWidget {
  const _CreationsView({required this.colors});

  final AppColors colors;

  void _openCreation(BuildContext context, WidgetRef ref, AtelierCreation c) {
    AppModal.showSheet(
      context: context,
      child: CreationDetailSheet(
        creation: c,
        onRetry: () => ref.read(atelierProvider.notifier).retryCreation(c.id),
        onTogglePrivate: () =>
            ref.read(atelierProvider.notifier).togglePrivate(c.id),
        onDelete: () => ref.read(atelierProvider.notifier).deleteCreation(c.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final state = ref.watch(atelierProvider);
    final notifier = ref.read(atelierProvider.notifier);
    final creations = state.filteredCreations;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Capacity Bar
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${strings.tr('ظرفیت پلن عادی')} (${strings.tasksProgress(state.creations.length, 20)})',
                        style: AppTypography.caption(color: colors.mu),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: AppRadius.rFull,
                        child: LinearProgressIndicator(
                          value: (state.creations.length / 20).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: colors.bd,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.pr),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppChip(
                  label: strings.allText,
                  isSelected: state.creationsFilter == 'all',
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  onTap: () => notifier.setCreationsFilter('all'),
                ),
                AppChip(
                  label: strings.atelStatusReady,
                  isSelected: state.creationsFilter == 'r',
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  onTap: () => notifier.setCreationsFilter('r'),
                ),
                AppChip(
                  label: strings.atelStatusProcessing,
                  isSelected: state.creationsFilter == 'p',
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  onTap: () => notifier.setCreationsFilter('p'),
                ),
                AppChip(
                  label: strings.atelStatusFailed,
                  isSelected: state.creationsFilter == 'f',
                  onTap: () => notifier.setCreationsFilter('f'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Creations List
          if (creations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  strings.atelEmptyCreations,
                  style: AppTypography.bodySmall(color: colors.mu),
                ),
              ),
            )
          else
            ...creations.map((c) {
              return AppCard(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Column(
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
                          child: Icon(
                            c.type == 'v'
                                ? Icons.videocam_rounded
                                : Icons.photo_camera_rounded,
                            color: colors.pr,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.tr(c.templateTitle),
                                style: AppTypography.cardTitle(color: colors.tx),
                              ),
                              Text(
                                '${strings.tr(c.date)} · ${c.type == 'v' ? strings.atelVideoBadge : strings.atelPhotosUnit}',
                                style: AppTypography.caption(color: colors.mu),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.status.color.withValues(alpha: 0.12),
                            borderRadius: AppRadius.rFull,
                            border: Border.all(
                              color: c.status.color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            strings.tr(c.status.label),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: c.status.color,
                            ),
                          ),
                        ),
                        if (c.status == CreationStatus.ready) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 15),
                            onPressed: () => _openCreation(context, ref, c),
                          ),
                        ],
                      ],
                    ),
                    if (c.status == CreationStatus.processing) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: AppRadius.rFull,
                        child: LinearProgressIndicator(
                          value: c.progress / 100,
                          minHeight: 4,
                          backgroundColor: colors.bd,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.pr),
                        ),
                      ),
                    ],
                    if (c.status == CreationStatus.failed) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.atelCoinsRefunded,
                            style: AppTypography.caption(color: colors.orColor),
                          ),
                          AppButton(
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.sm,
                            height: 30,
                            text: strings.atelRetryFree,
                            onPressed: () => notifier.retryCreation(c.id),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
