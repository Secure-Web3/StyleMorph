import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/localization/admin_language.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/state/admin_state.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(adminLanguageProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.sf,
                border: Border(bottom: BorderSide(color: colors.bd)),
              ),
              child: Row(
                children: [
                  // Brand Logo & Name
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.pr,
                          borderRadius: AppRadius.rMd,
                        ),
                        child: Center(
                          child: Text(
                            'SM',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.prt,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'StyleMorph Unified Gate',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.tx,
                            ),
                          ),
                          Text(
                            'درگاه متمرکز دسترسی به سامانه‌های ابری و پنل‌ها',
                            style: AppTypography.caption(color: colors.mu),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Environment Badge
                  AppBadge(
                    variant: AppBadgeVariant.success,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Text('محیط تولید ابری (Cloud Run EU)'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Theme Toggle
                  IconButton(
                    icon: Icon(
                      themeState.isDark ? Icons.light_mode : Icons.dark_mode,
                      color: colors.tx,
                      size: 20,
                    ),
                    tooltip: 'تغییر حالت روز / شب',
                    onPressed: () =>
                        ref.read(themeProvider.notifier).cycleThemeMode(),
                  ),
                  // Language Toggle
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
                    onPressed: () =>
                        ref.read(adminLanguageProvider.notifier).cycleLanguage(),
                  ),
                ],
              ),
            ),

            // Main Body: 3-Way Portal Cards
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(AppSpacing.xxxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'سامانه مدیریت یکپارچه StyleMorph',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: colors.tx,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'لطفاً جهت ورود به زیرسیستم مورد نظر، بستر و نقش سازمانی خود را انتخاب کنید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            color: colors.mu,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),

                        // 3 Role Cards Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 900;
                            final card1 = _buildPortalCard(
                              context: context,
                              title: 'پنل مدیریت کلان (Admin)',
                              subtitle: 'ویژه Super Admin و کارشناسان فنی',
                              badgeText: 'سطح دسترسی ریشه (Root)',
                              badgeVariant: AppBadgeVariant.active,
                              icon: Icons.admin_panel_settings_outlined,
                              iconBg: colors.pr.withValues(alpha: 0.1),
                              iconColor: colors.pr,
                              description:
                                  'مانیتورینگ زنده هزینه‌های ابری، ترازنامه دفتر کل غیرقابل تغییر، مدیریت ماژول‌ها و استخر کلیدهای هوش مصنوعی.',
                              buttonText: 'ورود به پنل مدیریت',
                              onPressed: () {
                                ref
                                    .read(authRoleProvider.notifier)
                                    .selectRole(AuthGateRole.admin);
                              },
                              isFeatured: true,
                            );

                            final card2 = _buildPortalCard(
                              context: context,
                              title: 'پورتال فروشندگان (Sellers)',
                              subtitle: 'فضای ایزوله شرکا و بوتیک‌ها',
                              badgeText: 'محیط تجاری B2B',
                              badgeVariant: AppBadgeVariant.info,
                              icon: Icons.storefront_outlined,
                              iconBg: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.1),
                              iconColor: const Color(0xFF2563EB),
                              description:
                                  'بارگذاری کاتالوگ کالاها، مدیریت مزایده‌های تبلیغات CPC/CPM، تحلیل نرخ تبدیل و گزارش واریزی‌ها.',
                              buttonText: 'ورود به پورتال فروشندگان',
                              onPressed: () {
                                ref
                                    .read(authRoleProvider.notifier)
                                    .selectRole(AuthGateRole.seller);
                              },
                              isFeatured: false,
                            );

                            final card3 = _buildPortalCard(
                              context: context,
                              title: 'وب‌اپلیکیشن کاربران (Web App)',
                              subtitle: 'تجربه مصرف‌کننده نهایی',
                              badgeText: 'پیش‌نمایش کلاینت',
                              badgeVariant: AppBadgeVariant.standard,
                              icon: Icons.devices_outlined,
                              iconBg: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.1),
                              iconColor: const Color(0xFF16A34A),
                              description:
                                  'دسترسی سریع به کمد مجازی کاربر، گفتگو با دستیار استایلیست، اتاق پرو آنلاین و آتلیه پرتره شخصی.',
                              buttonText: 'ورود به پورتال وب کاربران',
                              onPressed: () {
                                ref
                                    .read(authRoleProvider.notifier)
                                    .selectRole(AuthGateRole.consumerWebapp);
                              },
                              isFeatured: false,
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  card1,
                                  const SizedBox(height: AppSpacing.xl),
                                  card2,
                                  const SizedBox(height: AppSpacing.xl),
                                  card3,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: card1),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(child: card2),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(child: card3),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.xxxl),

                        // Security & Audit footer banner
                        Container(
                          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colors.sf,
                            borderRadius: AppRadius.rCard,
                            border: Border.all(color: colors.bd),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: colors.mu, size: 24),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'تمامی نشست‌ها، آدرس‌های IP و فراخوانی‌های مدیریتی مطابق با استانداردهای امنیتی پروژه در جدول audit_logs با امضای هش SHA-256 ثبت می‌گردند.',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 12,
                                    color: colors.mu,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              AppButton(
                                text: 'ورود سریع تست (Super Admin)',
                                size: AppButtonSize.sm,
                                variant: AppButtonVariant.outline,
                                onPressed: () {
                                  ref
                                      .read(authRoleProvider.notifier)
                                      .selectRole(AuthGateRole.admin);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required AppBadgeVariant badgeVariant,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    required bool isFeatured,
  }) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      borderColor: isFeatured ? colors.pr : colors.bd,
      borderWidth: isFeatured ? 2.0 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadius.rLg,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              AppBadge(
                variant: badgeVariant,
                child: Text(badgeText),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.mu,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              height: 1.55,
              color: colors.tx.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: buttonText,
            isFullWidth: true,
            variant:
                isFeatured ? AppButtonVariant.primary : AppButtonVariant.outline,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
