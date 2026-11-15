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

class ConsumerWebPortalScreen extends ConsumerStatefulWidget {
  const ConsumerWebPortalScreen({super.key});

  @override
  ConsumerState<ConsumerWebPortalScreen> createState() =>
      _ConsumerWebPortalScreenState();
}

class _ConsumerWebPortalScreenState
    extends ConsumerState<ConsumerWebPortalScreen> {
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'کمد مجازی',
      'icon': Icons.checkroom_outlined,
      'description': 'مشاهده و سازماندهی البسه، کفش و اکسسوری‌های دیجیتال شده',
      'itemsCount': '۳۴ قلم کالا',
    },
    {
      'title': 'استایلیست شخصی',
      'icon': Icons.chat_bubble_outline,
      'description': 'مشاوره مد و استایلینگ هوشمند مبتنی بر کمد و سلیقه کاربر',
      'itemsCount': '۱۲ گفتگو فعال',
    },
    {
      'title': 'آتلیه و پرو مجازی',
      'icon': Icons.auto_fix_high_outlined,
      'description': 'تولید پرتره مدلینگ و پرو لباس‌ها با هوش مصنوعی',
      'itemsCount': '۸ پرتره نهایی',
    },
    {
      'title': 'تندرستی و زیبایی',
      'icon': Icons.spa_outlined,
      'description': 'تحلیل سلامت پوست، مو، اندام و روتین‌های روزانه',
      'itemsCount': 'امتیاز: ۸۶/۱۰۰',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(adminLanguageProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
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
                  // Logo & Brand
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          borderRadius: AppRadius.rMd,
                        ),
                        child: const Center(
                          child: Icon(Icons.devices, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'StyleMorph Consumer Web',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.tx,
                            ),
                          ),
                          Text(
                            'نسخه وب کلاینت کاربران نهایی (app.stylemorph.com)',
                            style: AppTypography.caption(color: colors.mu),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Coin Balance Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.pr.withValues(alpha: 0.1),
                      borderRadius: AppRadius.rFull,
                      border: Border.all(
                        color: colors.pr.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: colors.pr, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '۴۵۰ StyleCoin',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.pr,
                          ),
                        ),
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
                    tooltip: 'تغییر تم',
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
                    onPressed: () => ref
                        .read(adminLanguageProvider.notifier)
                        .cycleLanguage(),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Back to Auth Gate
                  AppButton(
                    text: 'خروج به درگاه اصلی',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.outline,
                    icon: const Icon(Icons.logout, size: 16),
                    onPressed: () {
                      ref.read(authRoleProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),

            // Main Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Consumer Banner
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.pr.withValues(alpha: 0.12),
                                colors.sf,
                              ],
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                            ),
                            borderRadius: AppRadius.rCard,
                            border: Border.all(color: colors.bd),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colors.pr.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.rLg,
                                ),
                                child: Icon(
                                  Icons.phone_iphone_outlined,
                                  color: colors.pr,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'پیش‌نمایش وب کلاینت کاربران StyleMorph',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colors.tx,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'کاربران نهایی می‌توانند از طریق این پورتال کمد لباس، گفتگو با استایلیست شخصی، آتلیه پرتره و وضعیت تندرستی خود را مشاهده و مدیریت نمایند. دسترسی کامل با سنسورهای بیومتریک و اپل واچ روی اپلیکیشن‌های موبایل فعال است.',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 13,
                                        color: colors.mu,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Tab Selection
                        Row(
                          children: List.generate(_tabs.length, (index) {
                            final tab = _tabs[index];
                            final isSelected = _selectedTabIndex == index;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  end: index < _tabs.length - 1
                                      ? AppSpacing.md
                                      : 0,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedTabIndex = index);
                                  },
                                  borderRadius: AppRadius.rCard,
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: isSelected ? colors.sf : colors.bg,
                                      borderRadius: AppRadius.rCard,
                                      border: Border.all(
                                        color: isSelected
                                            ? colors.pr
                                            : colors.bd,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(
                                              tab['icon'] as IconData,
                                              color: isSelected
                                                  ? colors.pr
                                                  : colors.mu,
                                              size: 24,
                                            ),
                                            AppBadge(
                                              variant: isSelected
                                                  ? AppBadgeVariant.active
                                                  : AppBadgeVariant.standard,
                                              size: AppBadgeSize.sm,
                                              child: Text(
                                                tab['itemsCount'] as String,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          tab['title'] as String,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? colors.pr
                                                : colors.tx,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tab['description'] as String,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 11,
                                            color: colors.mu,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Tab Details Panel
                        AppCard(
                          padding: const EdgeInsetsDirectional.all(
                            AppSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _tabs[_selectedTabIndex]['icon']
                                            as IconData,
                                        color: colors.pr,
                                        size: 22,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'محتوای فعال: ${_tabs[_selectedTabIndex]['title']}',
                                        style: TextStyle(
                                          fontFamily:
                                              AppTypography.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colors.tx,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const AppBadge(
                                    variant: AppBadgeVariant.success,
                                    child: Text('همگام با سرور ابری'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Divider(),
                              const SizedBox(height: AppSpacing.lg),

                              // Interactive simulated items grid
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 700;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isNarrow ? 2 : 4,
                                      crossAxisSpacing: AppSpacing.md,
                                      mainAxisSpacing: AppSpacing.md,
                                      childAspectRatio: 0.9,
                                    ),
                                    itemCount: 4,
                                    itemBuilder: (context, idx) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: colors.bg,
                                          borderRadius: AppRadius.rMd,
                                          border: Border.all(color: colors.bd),
                                        ),
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _tabs[_selectedTabIndex]['icon']
                                                  as IconData,
                                              size: 36,
                                              color: colors.pr.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                            Text(
                                              'آیتم شماره ${idx + 1}',
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTypography.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: colors.tx,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'وضعیت: فعال و تحلیل‌شده',
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTypography.fontFamily,
                                                fontSize: 11,
                                                color: colors.mu,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
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
}
