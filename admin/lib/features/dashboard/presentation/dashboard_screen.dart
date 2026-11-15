import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/state/admin_state.dart';
import '../../finance/domain/transaction_model.dart';
import '../../ai_gateway/domain/ai_gateway_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedTimeframe = '24h';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final transactions = ref.watch(ledgerTransactionsProvider);
    final keys = ref.watch(gcpKeyPoolProvider);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Quick Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'داشبورد کلان مانیتورینگ سیستم',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.tx,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'پایش لحظه‌ای درآمدهای مالی، پردازش‌های هوش مصنوعی و ترافیک کاربران',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: colors.mu,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                      borderRadius: AppRadius.rMd,
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi, size: 14, color: Color(0xFF16A34A)),
                        SizedBox(width: 6),
                        Text(
                          'اتصال زنده به کلاود ران (Cloud Run Live)',
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
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 1. TOP: 4 GLOBAL KPI CARDS
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1000;
              final width = isNarrow
                  ? (constraints.maxWidth - AppSpacing.lg) / 2
                  : (constraints.maxWidth - (AppSpacing.lg * 3)) / 4;

              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  _buildKpiCard(
                    context: context,
                    width: width,
                    title: 'کل درآمد ناخالص (Gross Revenue)',
                    primaryValue: '\$128,450.00',
                    secondaryValue: '۵,۱۳۸,۰۰۰ StyleCoin',
                    trendText: '+۱۴.۸٪ نسبت به ماه قبل',
                    isTrendPositive: true,
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF16A34A),
                  ),
                  _buildKpiCard(
                    context: context,
                    width: width,
                    title: 'هزینه هوش مصنوعی ابری (GCP Cost)',
                    primaryValue: '\$3,420.80',
                    secondaryValue: '۲.۶۶٪ از کل درآمد ناخالص',
                    trendText: '-۴.۲٪ بهینه‌سازی الگوریتم کش',
                    isTrendPositive: true, // green because cost went down
                    icon: Icons.cloud_done_outlined,
                    iconColor: const Color(0xFF2563EB),
                  ),
                  _buildKpiCard(
                    context: context,
                    width: width,
                    title: 'کاربران فعال روزانه (DAU)',
                    primaryValue: '۴۲,۸۵۰',
                    secondaryValue: '۸,۹۴۰ کاربر همزمان در ساعات اوج',
                    trendText: '+۱۸.۵٪ رشد پس از انتشار نسخه ۲',
                    isTrendPositive: true,
                    icon: Icons.people_alt_outlined,
                    iconColor: const Color(0xFF9333EA),
                  ),
                  _buildKpiCard(
                    context: context,
                    width: width,
                    title: 'فروشندگان و بوتیک‌های فعال',
                    primaryValue: '۳۱۸',
                    secondaryValue: '۱,۴۲۰ کالای تبلیغاتی فعال (CPC)',
                    trendText: '+۶.۱٪ افزایش نسبت به هفته قبل',
                    isTrendPositive: true,
                    icon: Icons.store_outlined,
                    iconColor: const Color(0xFFD97706),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 2. 8-SECTION SUMMARY & DIRECT DEEP-LINK GRID
          _buildSectionSummaryGrid(context),
          const SizedBox(height: AppSpacing.xxl),

          // 3. MIDDLE: INTERACTIVE REGIONAL HEATMAP & TRAFFIC ANALYSIS
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.public, color: colors.pr, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'نقشه پراکندگی ترافیک منطقه‌ای و زمان پاسخ‌دهی (Latency Heatmap)',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.tx,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'توزیع جغرافیایی درخواست‌های هوش مصنوعی و میانگین تأخیر سرورهای لبه (Edge CDN)',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: colors.mu,
                          ),
                        ),
                      ],
                    ),
                    // Timeframe filter chips
                    Row(
                      children: [
                        _buildTimeChip('24h', '۲۴ ساعت گذشته'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildTimeChip('7d', '۷ روز گذشته'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildTimeChip('30d', '۳۰ روز گذشته'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Regional grid breakdown
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;
                    final leftCol = Column(
                      children: [
                        _buildRegionRow(
                          name: 'تهران و حومه (Tehran)',
                          users: '۱۸,۴۲۰ کاربر',
                          latency: '۲۲ میلی‌ثانیه',
                          sharePct: 0.38,
                          statusLabel: 'عالی',
                          statusColor: const Color(0xFF16A34A),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildRegionRow(
                          name: 'استانبول (Istanbul Hub)',
                          users: '۹,۱۵۰ کاربر',
                          latency: '۳۸ میلی‌ثانیه',
                          sharePct: 0.21,
                          statusLabel: 'پایدار',
                          statusColor: const Color(0xFF16A34A),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildRegionRow(
                          name: 'دبی و خلیج‌فارس (Dubai Edge)',
                          users: '۵,۳۰۰ کاربر',
                          latency: '۴۵ میلی‌ثانیه',
                          sharePct: 0.12,
                          statusLabel: 'پایدار',
                          statusColor: const Color(0xFF16A34A),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildRegionRow(
                          name: 'اصفهان و شیراز (Central Iran)',
                          users: '۶,۷۳۰ کاربر',
                          latency: '۲۵ میلی‌ثانیه',
                          sharePct: 0.16,
                          statusLabel: 'عالی',
                          statusColor: const Color(0xFF16A34A),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildRegionRow(
                          name: 'فرانکفورت و اروپا (Frankfurt Gen2)',
                          users: '۳,۲۵۰ کاربر',
                          latency: '۴۸ میلی‌ثانیه',
                          sharePct: 0.13,
                          statusLabel: 'طبیعی',
                          statusColor: const Color(0xFF2563EB),
                        ),
                      ],
                    );

                    final rightCol = Container(
                      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: AppRadius.rLg,
                        border: Border.all(color: colors.bd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'وضعیت کلی شبکه ابری',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.tx,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildSummaryMetric(
                            label: 'میانگین جهانی زمان پاسخ:',
                            val: '۳۲.۴ ms',
                            colors: colors,
                          ),
                          const Divider(height: 20),
                          _buildSummaryMetric(
                            label: 'نرخ خطای درخواست‌ها (Error Rate):',
                            val: '۰.۰۲٪',
                            colors: colors,
                            isGood: true,
                          ),
                          const Divider(height: 20),
                          _buildSummaryMetric(
                            label: 'حجم تصاویر پردازش‌شده در کمد:',
                            val: '۱۸۴,۹۲۰ فایل',
                            colors: colors,
                          ),
                          const Divider(height: 20),
                          _buildSummaryMetric(
                            label: 'صرفه‌جویی با کش هش SHA-256:',
                            val: '\$۱,۸۹۰.۰۰ در ماه',
                            colors: colors,
                            isGood: true,
                          ),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          leftCol,
                          const SizedBox(height: AppSpacing.xl),
                          rightCol,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: leftCol),
                        const SizedBox(width: AppSpacing.xxl),
                        Expanded(flex: 4, child: rightCol),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 3. BOTTOM: 3 MINI QUICK-ACTION WIDGETS
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1100;
              final w1 = _buildLatestTransactionsWidget(
                context: context,
                transactions: transactions.take(5).toList(),
              );
              final w2 = _buildAiKeysHealthWidget(
                context: context,
                keys: keys,
              );
              final w3 = _buildSupportTicketsWidget(context: context);

              if (isNarrow) {
                return Column(
                  children: [
                    w1,
                    const SizedBox(height: AppSpacing.lg),
                    w2,
                    const SizedBox(height: AppSpacing.lg),
                    w3,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: w1),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(flex: 4, child: w2),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(flex: 3, child: w3),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSummaryGrid(BuildContext context) {
    final colors = context.colors;

    final sections = [
      {
        'index': 0,
        'title': 'داشبورد کلان',
        'subtitle': 'پایش KPIها، درآمد و ترافیک لبه CDN',
        'badge': 'مرکز فرماندهی',
        'icon': Icons.dashboard_outlined,
        'color': const Color(0xFF2563EB),
      },
      {
        'index': 1,
        'title': 'امور مالی و دفتر کل',
        'subtitle': 'ترازنامه ۵.۱M سکه و لجر تغییرناپذیر',
        'badge': 'تراز متعادل',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFF16A34A),
      },
      {
        'index': 2,
        'title': 'مدیریت ماژولهای اپ',
        'subtitle': '۶ حوزه: کمد، استایلیست، آتلیه، تندرستی...',
        'badge': 'Remote Config',
        'icon': Icons.widgets_outlined,
        'color': const Color(0xFF9333EA),
      },
      {
        'index': 3,
        'title': 'دروازه هوش مصنوعی',
        'subtitle': 'بالانسر چندحسابی، روتینگ و کنترل کیفی',
        'badge': 'تأخیر: ۳۸ms',
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFF0284C7),
      },
      {
        'index': 4,
        'title': 'مدیریت فروشندگان',
        'subtitle': 'صف تایید بوتیک‌ها، کاتالوگ و کمیسیون',
        'badge': '۳۱۸ فروشگاه',
        'icon': Icons.storefront_outlined,
        'color': const Color(0xFFD97706),
      },
      {
        'index': 5,
        'title': 'تنظیمات زیرساختی',
        'subtitle': 'نشست تک‌دستگاهی، RBAC، شیلد و PITR',
        'badge': '۴ زیرماژول',
        'icon': Icons.tune_outlined,
        'color': const Color(0xFF4F46E5),
      },
      {
        'index': 6,
        'title': 'تبلیغات درونبرنامهای',
        'subtitle': 'AdMob SSV، سخاوت تطبیقی و قفل تندرستی',
        'badge': 'SSV Verified',
        'icon': Icons.campaign_outlined,
        'color': const Color(0xFF0D9488),
      },
      {
        'index': 7,
        'title': 'پشتیبانی و تیکتینگ',
        'subtitle': 'میزکار متنی، لاگ خطای AI و استرداد آنی',
        'badge': '1-Click Refund',
        'icon': Icons.confirmation_number_outlined,
        'color': const Color(0xFFE11D48),
      },
    ];

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hub_outlined, color: colors.pr, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'دسترسی مستقیم و ناوبری بخش‌های ۸‌گانه مدیریتی',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.tx,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'روی هر بخش کلیک کنید تا مستقیماً به پنل اختصاصی مربوطه هدایت شوید',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: colors.mu,
                    ),
                  ),
                ],
              ),
              const AppBadge(
                variant: AppBadgeVariant.info,
                child: Text('معماری ۸ بخشی یکپارچه'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 800;
              final isMedium = constraints.maxWidth < 1200;
              final crossAxisCount = isSmall ? 2 : (isMedium ? 4 : 4);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.2,
                ),
                itemCount: sections.length,
                itemBuilder: (context, idx) {
                  final s = sections[idx];
                  final sIndex = s['index'] as int;
                  final sIcon = s['icon'] as IconData;
                  final sColor = s['color'] as Color;

                  return InkWell(
                    onTap: () {
                      ref.read(selectedSectionIndexProvider.notifier).state = sIndex;
                    },
                    borderRadius: AppRadius.rMd,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: AppRadius.rMd,
                        border: Border.all(color: colors.bd),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: sColor.withValues(alpha: 0.12),
                              borderRadius: AppRadius.rSm,
                            ),
                            child: Icon(sIcon, color: sColor, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s['title'] as String,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colors.tx,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s['subtitle'] as String,
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
                          Icon(Icons.arrow_forward_ios, size: 12, color: colors.mu),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required double width,
    required String title,
    required String primaryValue,
    required String secondaryValue,
    required String trendText,
    required bool isTrendPositive,
    required IconData icon,
    required Color iconColor,
  }) {
    final colors = context.colors;

    return Container(
      width: width,
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rCard,
        border: Border.all(color: colors.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.mu,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.rMd,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            primaryValue,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryValue,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: colors.mu,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                isTrendPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isTrendPositive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trendText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isTrendPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String id, String label) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;
    final isSelected = _selectedTimeframe == id;

    return InkWell(
      onTap: () => setState(() => _selectedTimeframe = id),
      borderRadius: AppRadius.rSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.pr : colors.bg,
          borderRadius: AppRadius.rSm,
          border: Border.all(color: isSelected ? colors.pr : colors.bd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.prt : colors.tx,
          ),
        ),
      ),
    );
  }

  Widget _buildRegionRow({
    required String name,
    required String users,
    required String latency,
    required double sharePct,
    required String statusLabel,
    required Color statusColor,
  }) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.tx,
              ),
            ),
            Row(
              children: [
                Text(
                  users,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: colors.mu,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.rSm,
                  ),
                  child: Text(
                    latency,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.rFull,
          child: LinearProgressIndicator(
            value: sharePct,
            backgroundColor: colors.bd.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(colors.pr),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String val,
    required AppColors colors,
    bool isGood = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            color: colors.mu,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isGood ? const Color(0xFF16A34A) : colors.tx,
          ),
        ),
      ],
    );
  }

  Widget _buildLatestTransactionsWidget({
    required BuildContext context,
    required List<TransactionRecord> transactions,
  }) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'آخرین تراکنش‌های دفتر کل',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(selectedSectionIndexProvider.notifier).state = 1;
                },
                child: const Text('مشاهده دفتر کل کامل',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...transactions.map((tx) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.bd, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tx.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.userDisplayName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                        ),
                        Text(
                          tx.txId,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            color: colors.mu,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${tx.amountCoins} سکه',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.tx,
                        ),
                      ),
                      Text(
                        '\$${tx.amountUsd.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiKeysHealthWidget({
    required BuildContext context,
    required List<GcpApiKeyItem> keys,
  }) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'پایش سلامت کلیدهای هوش مصنوعی',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(selectedSectionIndexProvider.notifier).state = 3;
                },
                child: const Text('مدیریت درگاه AI',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...keys.take(4).map((k) {
            final usagePct =
                k.billedLimit > 0 ? (k.officialBilledCost / k.billedLimit) : 0.0;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.bd, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          k.alias,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${k.latencyMs}ms',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(k.status.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سقف: \$${k.officialBilledCost.toStringAsFixed(0)} / \$${k.billedLimit.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                      Text(
                        k.status.label,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          color: Color(k.status.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: AppRadius.rFull,
                    child: LinearProgressIndicator(
                      value: usagePct.clamp(0.0, 1.0),
                      backgroundColor: colors.bd.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePct > 0.8
                            ? const Color(0xFFDC2626)
                            : (usagePct > 0.6
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A)),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSupportTicketsWidget({required BuildContext context}) {
    final colors = context.colors;

    final tickets = [
      {
        'id': 'TCK-401',
        'title': 'تأخیر در تأیید مدارک بوتیک زاگرس',
        'priority': 'فوری',
        'time': '۱۸ دقیقه پیش',
        'variant': AppBadgeVariant.destructive,
      },
      {
        'id': 'TCK-398',
        'title': 'درخواست گزارش ماهانه مالیات ارزش‌افزوده',
        'priority': 'متوسط',
        'time': '۱ ساعت پیش',
        'variant': AppBadgeVariant.warning,
      },
      {
        'id': 'TCK-395',
        'title': 'خطای عدم کسر سکه در حالت آزمایشی',
        'priority': 'عادی',
        'time': '۳ ساعت پیش',
        'variant': AppBadgeVariant.info,
      },
    ];

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'تیکت‌های باز پشتیبانی',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(selectedSectionIndexProvider.notifier).state = 7;
                },
                child: const Text('پورتال تیکت‌ها', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tickets.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.bd, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t['id'] as String,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.mu,
                        ),
                      ),
                      AppBadge(
                        variant: t['variant'] as AppBadgeVariant,
                        size: AppBadgeSize.sm,
                        child: Text(t['priority'] as String),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t['title'] as String,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.tx,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t['time'] as String,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10,
                      color: colors.mu,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
