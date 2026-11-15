import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/admin_state.dart';

class NavItemData {
  final String titleFa;
  final IconData icon;

  const NavItemData({
    required this.titleFa,
    required this.icon,
  });
}

const List<NavItemData> kSidebarNavItems = [
  NavItemData(
    titleFa: 'داشبورد کلان',
    icon: Icons.dashboard_outlined,
  ),
  NavItemData(
    titleFa: 'امور مالی و دفتر کل',
    icon: Icons.account_balance_wallet_outlined,
  ),
  NavItemData(
    titleFa: 'مدیریت ماژولهای اپ',
    icon: Icons.widgets_outlined,
  ),
  NavItemData(
    titleFa: 'دروازه هوش مصنوعی',
    icon: Icons.psychology_outlined,
  ),
  NavItemData(
    titleFa: 'مدیریت فروشندگان',
    icon: Icons.storefront_outlined,
  ),
  NavItemData(
    titleFa: 'تنظیمات زیرساختی',
    icon: Icons.tune_outlined,
  ),
  NavItemData(
    titleFa: 'تبلیغات درونبرنامهای',
    icon: Icons.campaign_outlined,
  ),
  NavItemData(
    titleFa: 'پشتیبانی و تیکتینگ',
    icon: Icons.confirmation_number_outlined,
  ),
];

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selectedIndex = ref.watch(selectedSectionIndexProvider);
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    final sidebarWidth = isCollapsed ? 80.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: colors.sf,
        border: Border(
          left: BorderSide(color: colors.bd), // In RTL, sidebar is on the right, so border is on left
        ),
      ),
      child: Column(
        children: [
          // Header / Brand
          Container(
            height: 64,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.bd)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.pr,
                    borderRadius: AppRadius.rMd,
                  ),
                  child: Center(
                    child: Text(
                      'SM',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.prt,
                      ),
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'StyleMorph Admin',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.tx,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'پنل جامع مدیریت ابری',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: colors.mu,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.chevron_left : Icons.chevron_right,
                    size: 18,
                    color: colors.mu,
                  ),
                  tooltip: isCollapsed ? 'گسترش منو' : 'جمع‌کردن منو',
                  onPressed: () {
                    ref.read(sidebarCollapsedProvider.notifier).state =
                        !isCollapsed;
                  },
                ),
              ],
            ),
          ),

          // Nav Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              itemCount: kSidebarNavItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 3),
              itemBuilder: (context, index) {
                final item = kSidebarNavItems[index];
                final isSelected = selectedIndex == index;

                return InkWell(
                  onTap: () {
                    ref.read(selectedSectionIndexProvider.notifier).state =
                        index;
                  },
                  borderRadius: AppRadius.rMd,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.pr.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: AppRadius.rMd,
                      border: isSelected
                          ? Border.all(
                              color: colors.pr.withValues(alpha: 0.2),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected ? colors.pr : colors.mu,
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              item.titleFa,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? colors.pr : colors.tx,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // User info and Logout
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.bd)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.pr.withValues(alpha: 0.1),
                  child: Icon(Icons.person_outline, color: colors.pr, size: 20),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'مهندس سهرابی',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'مدیر ارشد (Super Admin)',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            color: colors.mu,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  color: const Color(0xFFDC2626),
                  tooltip: 'خروج به درگاه اصلی',
                  onPressed: () {
                    ref.read(authRoleProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
