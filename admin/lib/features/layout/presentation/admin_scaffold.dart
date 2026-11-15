import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/localization/admin_language.dart';
import '../../../core/state/admin_state.dart';
import 'admin_sidebar.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../finance/presentation/finance_screen.dart';
import '../../modules/presentation/modules_screen.dart';
import '../../ai_gateway/presentation/ai_gateway_screen.dart';
import '../../sellers/presentation/seller_governance_screen.dart';
import '../../settings/presentation/infrastructure_settings_screen.dart';
import '../../ads/presentation/admob_sponsoring_screen.dart';
import '../../support/presentation/support_ticketing_screen.dart';

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selectedIndex = ref.watch(selectedSectionIndexProvider);
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(adminLanguageProvider);

    final currentNavItem = kSidebarNavItems[selectedIndex.clamp(0, kSidebarNavItems.length - 1)];

    Widget bodyContent;
    switch (selectedIndex) {
      case 0:
        bodyContent = const DashboardScreen();
        break;
      case 1:
        bodyContent = const FinanceScreen();
        break;
      case 2:
        bodyContent = const ModulesScreen();
        break;
      case 3:
        bodyContent = const AiGatewayScreen();
        break;
      case 4:
        bodyContent = const SellerGovernanceScreen();
        break;
      case 5:
        bodyContent = const InfrastructureSettingsScreen();
        break;
      case 6:
        bodyContent = const AdMobSponsoringScreen();
        break;
      case 7:
        bodyContent = const SupportTicketingScreen();
        break;
      default:
        bodyContent = const DashboardScreen();
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sidebar (Right in RTL)
          const AdminSidebar(),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 64,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  decoration: BoxDecoration(
                    color: colors.sf,
                    border: Border(bottom: BorderSide(color: colors.bd)),
                  ),
                  child: Row(
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          Icon(Icons.home_outlined, size: 18, color: colors.mu),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'پنل مدیریت کلان',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: colors.mu,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '/',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: colors.mu,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            currentNavItem.titleFa,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.tx,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // System Health Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                          borderRadius: AppRadius.rSm,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Text(
                              'سامانه ابری: پایدار (۹۹.۹۸٪)',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Theme Toggle
                      IconButton(
                        icon: Icon(
                          themeState.isDark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: colors.tx,
                          size: 20,
                        ),
                        tooltip: 'تغییر پوسته (Dark / Light)',
                        onPressed: () =>
                            ref.read(themeProvider.notifier).cycleThemeMode(),
                      ),

                      // Language Selector
                      TextButton.icon(
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(currentLang.label),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.tx,
                          textStyle: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => ref
                            .read(adminLanguageProvider.notifier)
                            .cycleLanguage(),
                      ),

                      const SizedBox(width: AppSpacing.sm),
                      // Notification Bell
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 20),
                        color: colors.tx,
                        tooltip: 'اعلان‌های سیستمی',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمامی اعلان‌ها بررسی شده‌اند.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Body Section
                Expanded(
                  child: bodyContent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
