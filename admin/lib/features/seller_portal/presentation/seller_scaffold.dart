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
import '../../../core/widgets/app_text_field.dart';
import '../../../core/state/admin_state.dart';
import '../domain/seller_portal_models.dart';

class SellerScaffold extends ConsumerStatefulWidget {
  const SellerScaffold({super.key});

  @override
  ConsumerState<SellerScaffold> createState() => _SellerScaffoldState();
}

class _SellerScaffoldState extends ConsumerState<SellerScaffold> {
  int _activeNavIndex = 0; // 0: Overview, 1: Products, 2: Campaigns, 3: Wallet

  final List<String> _navTitles = [
    'داشبورد فروشگاه',
    'کاتالوگ محصولات',
    'کمپین‌های تبلیغاتی',
    'کیف پول و واریزی‌ها',
  ];

  final List<IconData> _navIcons = [
    Icons.dashboard_outlined,
    Icons.checkroom_outlined,
    Icons.campaign_outlined,
    Icons.account_balance_wallet_outlined,
  ];

  void _showAddProductModal() {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;
    final titleCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.sf,
        title: const Row(
          children: [
            Icon(Icons.add_shopping_cart, color: Color(0xFF2563EB)),
            SizedBox(width: AppSpacing.sm),
            Text('افزودن کالای جدید به کاتالوگ فروشگاه'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: titleCtrl, label: 'عنوان لباس / اکسسوری:'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: catCtrl, label: 'دسته‌بندی (مانند: پالتو، شلوار، شومیز):'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: priceCtrl, label: 'قیمت فروش (تومان):'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: urlCtrl, label: 'لینک خرید مستقیم در سایت فروشنده:'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('انصراف'),
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            text: 'ثبت و ارسال به صف بررسی',
            size: AppButtonSize.sm,
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                final price = int.tryParse(priceCtrl.text) ?? 2500000;
                ref.read(sellerProductsProvider.notifier).addProduct(
                      SellerProductItem(
                        id: 'sp_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        title: titleCtrl.text.trim(),
                        category: catCtrl.text.trim().isEmpty ? 'عمومی' : catCtrl.text.trim(),
                        priceToman: price,
                        redirectUrl: urlCtrl.text.trim().isEmpty
                            ? 'https://zagros-boutique.ir/item'
                            : urlCtrl.text.trim(),
                        isActive: true,
                        viewsCount: 0,
                        clicksCount: 0,
                        tryOnCount: 0,
                        approvalStatus: 'PENDING',
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('کالای جدید ثبت شد و در صف ممیزی ادمین قرار گرفت.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(adminLanguageProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Seller Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: colors.sf,
              border: Border(left: BorderSide(color: colors.bd)),
            ),
            child: Column(
              children: [
                // Store branding
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.bd)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          borderRadius: AppRadius.rMd,
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'بوتیک زاگرس',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.tx,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'پورتال همکاران تجاری B2B',
                              style: TextStyle(fontSize: 10, color: colors.mu),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Nav Items
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: _navTitles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 3),
                    itemBuilder: (context, index) {
                      final isSelected = _activeNavIndex == index;
                      return InkWell(
                        onTap: () => setState(() => _activeNavIndex = index),
                        borderRadius: AppRadius.rMd,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: AppRadius.rMd,
                            border: isSelected
                                ? Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _navIcons[index],
                                size: 18,
                                color: isSelected ? const Color(0xFF2563EB) : colors.mu,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  _navTitles[index],
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF2563EB) : colors.tx,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Wallet & Return to Unified Gate
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.bd)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: AppRadius.rMd,
                          border: Border.all(color: colors.bd),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'موجودی کیف پول:',
                                style: TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '۲,۵۰۰,۰۰۰ تومان',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        text: 'خروج به درگاه اصلی',
                        isFullWidth: true,
                        size: AppButtonSize.sm,
                        variant: AppButtonVariant.outline,
                        icon: const Icon(Icons.arrow_back, size: 14),
                        onPressed: () {
                          ref.read(authRoleProvider.notifier).logout();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: colors.sf,
                    border: Border(bottom: BorderSide(color: colors.bd)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'پورتال فروشندگان / ${_navTitles[_activeNavIndex]}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.tx,
                        ),
                      ),
                      const Spacer(),
                      // Theme Toggle
                      IconButton(
                        icon: Icon(
                          themeState.isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 18,
                          color: colors.tx,
                        ),
                        onPressed: () => ref.read(themeProvider.notifier).cycleThemeMode(),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.language, size: 16),
                        label: Text(currentLang.label),
                        onPressed: () => ref.read(adminLanguageProvider.notifier).cycleLanguage(),
                      ),
                    ],
                  ),
                ),

                // Active Tab Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
                    child: _buildActiveTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeNavIndex) {
      case 0:
        return _buildSellerDashboard();
      case 1:
        return _buildProductCatalog();
      case 2:
        return _buildAdCampaigns();
      case 3:
        return _buildWalletPayouts();
      default:
        return _buildSellerDashboard();
    }
  }

  // Tab 0: Seller Dashboard
  Widget _buildSellerDashboard() {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خلاصه عملکرد بوتیک در اپلیکیشن StyleMorph',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: 4),
        Text('آمار لحظه‌ای بازدیدها، کلیک‌های هدایت به سایت و پرو مجازی البسه شما توسط کاربران',
            style: TextStyle(fontSize: 12, color: colors.mu)),
        const SizedBox(height: AppSpacing.xl),

        // 4 KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            final width = isNarrow
                ? (constraints.maxWidth - AppSpacing.md) / 2
                : (constraints.maxWidth - (AppSpacing.md * 3)) / 4;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _buildSellerKpiCard(
                  title: 'کل بازدید البسه (Views)',
                  val: '۵,۲۱۰ بار',
                  sub: '+۱۲.۴٪ نسبت به هفته قبل',
                  icon: Icons.visibility_outlined,
                  color: const Color(0xFF2563EB),
                  width: width,
                ),
                _buildSellerKpiCard(
                  title: 'کلیک به وبسایت شما (CPC)',
                  val: '۸۴۲ کلیک',
                  sub: 'نرخ تبدیل کلیک: ۱۶.۱٪',
                  icon: Icons.touch_app_outlined,
                  color: const Color(0xFF16A34A),
                  width: width,
                ),
                _buildSellerKpiCard(
                  title: 'پرو مجازی با لباس شما (CPT)',
                  val: '۴۵۳ بار',
                  sub: 'انطباق هوشمند در اتاق پرو AI',
                  icon: Icons.checkroom_outlined,
                  color: const Color(0xFF9333EA),
                  width: width,
                ),
                _buildSellerKpiCard(
                  title: 'بودجه مصرفی تبلیغات',
                  val: '۴۶۵,۰۰۰ تومان',
                  sub: 'از محل کیف پول اعتباری',
                  icon: Icons.price_check,
                  color: const Color(0xFFD97706),
                  width: width,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        // Conversion rate summary banner
        AppCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'کیفیت نمایش و بنچمارک هوش مصنوعی',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.tx,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لباس‌های شما با امتیاز ۹۴٪ تطابق رنگی و بافت در پیشنهادات دستیار استایلیست شخصی قرار می‌گیرند. بیشترین بازدید مربوط به «ست کت‌وشلوار کرپ مازراتی» با ۴۲۰ کلیک مستقیم بوده است.',
                style: TextStyle(fontSize: 13, height: 1.6, color: colors.tx),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellerKpiCard({
    required String title,
    required String val,
    required String sub,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    final colors = context.colors;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
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
              Text(title, style: TextStyle(fontSize: 11, color: colors.mu)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.tx),
          ),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  // Tab 1: Product Catalog Manager
  Widget _buildProductCatalog() {
    final colors = context.colors;
    final products = ref.watch(sellerProductsProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'کاتالوگ کالاهای فعال در استایل‌مورف',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                ),
                Text('مدیریت لینک‌های خرید مستقیم و بررسی وضعیت تایید ممیزی',
                    style: TextStyle(fontSize: 12, color: colors.mu)),
              ],
            ),
            AppButton(
              text: 'افزودن کالای جدید',
              icon: const Icon(Icons.add, size: 16),
              size: AppButtonSize.sm,
              onPressed: _showAddProductModal,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        AppCard(
          padding: EdgeInsetsDirectional.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: colors.bg,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('عنوان کالا', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('دسته‌بندی', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('قیمت (تومان)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('کلیک / پرو', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('وضعیت ممیزی', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Align(alignment: AlignmentDirectional.centerEnd, child: Text('فعال در اپ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...products.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.bd.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      // Title & URL
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.tx)),
                            Text(p.redirectUrl, style: TextStyle(fontSize: 10, color: colors.mu), maxLines: 1),
                          ],
                        ),
                      ),
                      // Category
                      Expanded(flex: 2, child: Text(p.category, style: TextStyle(fontSize: 11, color: colors.tx))),
                      // Price
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${(p.priceToman / 1000).toStringAsFixed(0)} هزار تومان',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Stats
                      Expanded(
                        flex: 2,
                        child: Text('${p.clicksCount} کلیک / ${p.tryOnCount} پرو', style: TextStyle(fontSize: 11, color: colors.tx)),
                      ),
                      // Status
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppBadge(
                            variant: p.approvalStatus == 'APPROVED'
                                ? AppBadgeVariant.success
                                : AppBadgeVariant.warning,
                            size: AppBadgeSize.sm,
                            child: Text(p.approvalStatus == 'APPROVED' ? 'تأیید شده' : 'در انتظار بررسی'),
                          ),
                        ),
                      ),
                      // Toggle
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: p.isActive,
                              activeThumbColor: const Color(0xFF2563EB),
                              onChanged: (val) {
                                ref.read(sellerProductsProvider.notifier).toggleProductActive(p.id);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Tab 2: Ad Campaigns Manager
  Widget _buildAdCampaigns() {
    final colors = context.colors;
    final campaigns = ref.watch(sellerCampaignsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'کمپین‌های تبلیغات کلیکی و حراجی (CPC / CPM)',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                ),
                Text('تعیین سقف بودجه روزانه برای تزریق اولویت‌دار کالا در استایلیست شخصی',
                    style: TextStyle(fontSize: 12, color: colors.mu)),
              ],
            ),
            AppButton(
              text: 'ایجاد کمپین جدید',
              icon: const Icon(Icons.add, size: 16),
              size: AppButtonSize.sm,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('فرم ایجاد کمپین جدید در دسترس است.')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        ...campaigns.map((c) {
          final progress = c.dailyBudgetToman > 0 ? (c.spentBudgetToman / c.dailyBudgetToman) : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Text(c.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.tx)),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: c.isActive,
                        activeThumbColor: const Color(0xFF2563EB),
                        onChanged: (val) {
                          ref.read(sellerCampaignsProvider.notifier).toggleCampaign(c.id);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('محل نمایش: ${c.targetModule} • پیشنهاد هر کلیک: ${c.cpcBidToman} تومان',
                    style: TextStyle(fontSize: 11, color: colors.mu)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('مصرف بودجه: ${c.spentBudgetToman} از ${c.dailyBudgetToman} تومان',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('${(progress * 100).toStringAsFixed(0)}٪',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: AppRadius.rFull,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: colors.bd.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Tab 3: Wallet & Payouts
  Widget _buildWalletPayouts() {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'کیف پول تبلیغاتی و گزارش تسویه‌حساب (Wallet & Payouts)',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: 4),
          Text('مدیریت اعتبار مصرفی تبلیغات و مشاهده شماره شبا جهت تسویه‌حساب فروشگاه',
              style: TextStyle(fontSize: 12, color: colors.mu)),
          const SizedBox(height: AppSpacing.xl),

          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: colors.bd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('موجودی شارژ تبلیغاتی فعال:', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('۲,۵۰۰,۰۰۰ تومان',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
                AppButton(
                  text: 'افزایش موجودی کیف پول',
                  icon: const Icon(Icons.add, size: 16),
                  size: AppButtonSize.sm,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('هدایت به درگاه بانکی شاپرک جهت شارژ کیف پول تبلیغاتی.')),
                    );
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
