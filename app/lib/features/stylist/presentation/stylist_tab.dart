import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/health_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_section_header.dart';
import '../domain/stylist_models.dart';
import 'stylist_provider.dart';
import 'widgets/try_on_dialog.dart';
import 'widgets/stylist_chat_sheet.dart';
import 'widgets/stylist_modals.dart';

class StylistTab extends ConsumerStatefulWidget {
  const StylistTab({super.key});

  @override
  ConsumerState<StylistTab> createState() => _StylistTabState();
}

class _StylistTabState extends ConsumerState<StylistTab> {
  final _pageCtrl = PageController();
  int _activePage = 0;

  static const _occasions = ['روزمره', 'کار', 'مهمانی', 'سفر'];
  static const _userPalette = ['#c9a227', '#7a5230', '#4f7a5a', '#d6bf9b', '#c0392b'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openTryOn(StylistOutfit outfit) {
    AppModal.showSheet(
      context: context,
      child: TryOnDialog(outfit: outfit),
    );
  }

  void _openChat() {
    AppModal.showSheet(
      context: context,
      child: const StylistChatSheet(),
    );
  }

  void _openModal(Widget modal) {
    AppModal.showSheet(
      context: context,
      child: modal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final stylistState = ref.watch(stylistProvider);
    final health = ref.watch(healthServiceProvider);
    final notifier = ref.read(stylistProvider.notifier);
    final outfits = stylistState.outfits;

    return Column(
      children: [
        // --- Top Header ---
        AppModuleHeader(
          icon: Icons.auto_awesome_rounded,
          title: strings.stylistTitle,
          trailing: AppIconButton(
            icon: Icons.tune_rounded,
            onTap: () => _openModal(const StyleAndColorSheet()),
          ),
        ),

        // --- Content Area ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Weather & Occasions pills row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppBadge(
                        size: AppBadgeSize.sm,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wb_sunny_rounded,
                              size: 13,
                              color: Color(0xFFD99A06),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(strings.styWeather),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ..._occasions.map((occ) {
                        return AppChip(
                          label: strings.tr(occ),
                          isSelected: stylistState.activeOccasion == occ,
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          onTap: () => notifier.setOccasion(occ),
                        );
                      }),
                      AppBadge(
                        size: AppBadgeSize.sm,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 7,
                        ),
                        child: Text(
                          strings.styEnergy,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colors.mu,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Palette Preview Row
                Row(
                  children: [
                    Text(
                      strings.styMyPalette,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: colors.mu,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._userPalette.map((hex) {
                      return Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsetsDirectional.only(end: 5),
                        decoration: BoxDecoration(
                          color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.bd, width: 0.5),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Biometric Health Context Insight Banner (when wearable connected)
                if (health.isConnected) ...[
                  _StylistBiometricBanner(
                    health: health,
                    colors: colors,
                    strings: strings,
                    onChatTap: _openChat,
                  ),
                  const SizedBox(height: 12),
                ],

                // Outfits Carousel
                SizedBox(
                  height: 290,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (idx) => setState(() => _activePage = idx),
                    itemCount: outfits.length,
                    itemBuilder: (_, i) {
                      final outfit = outfits[i];
                      return _OutfitCard(
                        outfit: outfit,
                        colors: colors,
                        onLock: () => notifier.toggleLock(outfit.id),
                        onSave: () => notifier.toggleSave(outfit.id),
                        onTryOn: () => _openTryOn(outfit),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(outfits.length, (idx) {
                    final isActive = _activePage == idx;
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: isActive ? colors.pr : colors.bd,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // AI Consultant Banner Card
                AppCard(
                  onTap: _openChat,
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2B7A78),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            strings.tr('رامین').substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.styChatTitle,
                              style: AppTypography.cardTitle(color: colors.tx),
                            ),
                            Text(
                              strings.styChatBannerSub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(color: colors.mu),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: colors.mu),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom 4 Quick Modules
                Row(
                  children: [
                    Expanded(
                      child: _BottomActionTile(
                        icon: Icons.calendar_month_rounded,
                        label: strings.styPlanner,
                        colors: colors,
                        onTap: () => _openModal(const WeeklyPlannerSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BottomActionTile(
                        icon: Icons.palette_outlined,
                        label: strings.styStyleColor,
                        colors: colors,
                        onTap: () => _openModal(const StyleAndColorSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BottomActionTile(
                        icon: Icons.shopping_bag_outlined,
                        label: strings.stySmartShop,
                        colors: colors,
                        onTap: () => _openModal(const SmartShoppingSheet()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BottomActionTile(
                        icon: Icons.bar_chart_rounded,
                        label: strings.styStats,
                        colors: colors,
                        onTap: () => _openModal(const StyleStatsSheet()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({
    required this.outfit,
    required this.colors,
    required this.onLock,
    required this.onSave,
    required this.onTryOn,
  });

  final StylistOutfit outfit;
  final AppColors colors;
  final VoidCallback onLock;
  final VoidCallback onSave;
  final VoidCallback onTryOn;

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
    final items = outfit.items;

    return AppCard(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual garments collage
          Expanded(
            child: Row(
              children: [
                // Main big garment
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: items.isNotEmpty
                          ? _parse(items.first.colorHex).withValues(alpha: 0.18)
                          : colors.bg,
                      borderRadius: AppRadius.rXl,
                    ),
                    child: Center(
                      child: Icon(
                        items.isNotEmpty
                            ? items.first.icon
                            : Icons.checkroom_rounded,
                        size: 44,
                        color: items.isNotEmpty
                            ? _parse(items.first.colorHex)
                            : colors.pr,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Secondary smaller garments
                Expanded(
                  child: Column(
                    children: [
                      if (items.length > 1)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: _parse(items[1].colorHex)
                                  .withValues(alpha: 0.18),
                              borderRadius: AppRadius.rLg,
                            ),
                            child: Center(
                              child: Icon(
                                items[1].icon,
                                size: 24,
                                color: _parse(items[1].colorHex),
                              ),
                            ),
                          ),
                        ),
                      if (items.length > 2)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _parse(items[2].colorHex)
                                  .withValues(alpha: 0.18),
                              borderRadius: AppRadius.rLg,
                            ),
                            child: Center(
                              child: Icon(
                                items[2].icon,
                                size: 24,
                                color: _parse(items[2].colorHex),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            strings.tr(outfit.title),
            style: AppTypography.sectionTitle(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: outfit.tags.map((t) {
              return AppBadge(
                size: AppBadgeSize.sm,
                child: Text(
                  strings.tr(t),
                  style: TextStyle(fontSize: 9, color: colors.mu),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Actions
          Row(
            children: [
              Expanded(
                child: _CardBtn(
                  icon: outfit.isLocked
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  label: outfit.isLocked ? strings.styLocked : strings.styLock,
                  isActive: outfit.isLocked,
                  colors: colors,
                  onTap: onLock,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CardBtn(
                  icon: Icons.sync_rounded,
                  label: strings.stySwap,
                  isActive: false,
                  colors: colors,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          strings.stySwapToast,
                          style: const TextStyle(fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CardBtn(
                  icon: outfit.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: outfit.isSaved ? strings.stySaved : strings.stySave,
                  isActive: outfit.isSaved,
                  colors: colors,
                  onTap: onSave,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppButton(
                  size: AppButtonSize.sm,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  icon: Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: colors.prt,
                  ),
                  text: strings.styTryOn,
                  onPressed: onTryOn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  const _CardBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rLg,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? colors.pr.withValues(alpha: 0.12) : colors.bg,
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: isActive ? colors.pr : colors.bd,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? colors.pr : colors.tx),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? colors.pr : colors.tx,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionTile extends StatelessWidget {
  const _BottomActionTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      height: 62,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colors.pr),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _StylistBiometricBanner extends StatelessWidget {
  const _StylistBiometricBanner({
    required this.health,
    required this.colors,
    required this.strings,
    required this.onChatTap,
  });

  final HealthDnaSnapshot health;
  final AppColors colors;
  final AppStrings strings;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    final isLowSleep = health.sleepHours != null && health.sleepHours! < 5.5;
    final isHighSteps = health.steps != null && health.steps! >= 10000;

    final String message = isLowSleep
        ? strings.stylistBiometricComfortHint
        : isHighSteps
            ? strings.stylistBiometricActiveHint
            : 'شاخص آمادگی شما ${strings.formatNumber(health.energyReadinessScore)}٪ است؛ ست‌های امروز برای تعادل کامل فرم و راحتی پیشنهاد شده‌اند.';

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                switch (health.sourceDevice) {
                  WearableDeviceType.appleHealth => Icons.watch_rounded,
                  WearableDeviceType.healthConnect =>
                    Icons.health_and_safety_rounded,
                  WearableDeviceType.galaxyWatch => Icons.watch_outlined,
                  WearableDeviceType.miBand => Icons.fitness_center_rounded,
                },
                size: 16,
                color: colors.pr,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  strings.stylistBiometricBannerTitle,
                  style: AppTypography.cardTitle(color: colors.tx),
                ),
              ),
              AppBadge(
                size: AppBadgeSize.sm,
                child: Text(
                  health.sourceDevice.hardwareModel,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.bodySmall(color: colors.tx),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onChatTap,
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: colors.pr,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'مشاهده جزییات پیشنهاد و گفتگو با استایلیست',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.pr,
                      decoration: TextDecoration.underline,
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
}
