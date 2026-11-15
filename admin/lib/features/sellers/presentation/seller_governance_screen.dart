import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/state/admin_state.dart';
import '../domain/seller_models.dart';

class SellerGovernanceScreen extends ConsumerStatefulWidget {
  const SellerGovernanceScreen({super.key});

  @override
  ConsumerState<SellerGovernanceScreen> createState() =>
      _SellerGovernanceScreenState();
}

class _SellerGovernanceScreenState
    extends ConsumerState<SellerGovernanceScreen> {
  int _activeSubTab = 0; // 0: Merchants Queue, 1: Products Queue, 2: Financial Rules
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();

  // Financial rules controllers
  final TextEditingController _cpcController = TextEditingController();
  final TextEditingController _cpmController = TextEditingController();
  final TextEditingController _stdCommController = TextEditingController();
  final TextEditingController _premCommController = TextEditingController();
  final TextEditingController _cptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rules = ref.read(sellerFinancialRulesProvider);
    _cpcController.text = rules.cpcBaseRateToman.toString();
    _cpmController.text = rules.cpmBaseRateToman.toString();
    _stdCommController.text = rules.commissionTierStandard.toString();
    _premCommController.text = rules.commissionTierPremium.toString();
    _cptController.text = rules.costPerTryOnCoins.toString();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rejectReasonController.dispose();
    _cpcController.dispose();
    _cpmController.dispose();
    _stdCommController.dispose();
    _premCommController.dispose();
    _cptController.dispose();
    super.dispose();
  }

  void _showRejectDialog({
    required String title,
    required VoidCallback onConfirm,
  }) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;
    _rejectReasonController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.sf,
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
            const SizedBox(width: AppSpacing.sm),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'علت رد درخواست (پیام جهت اطلاع به فروشنده ارسال خواهد شد):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _rejectReasonController,
              placeholder: 'مثال: نقص در مدارک هویتی / عدم تطابق استاندارد عکس',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('انصراف'),
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            text: 'تأیید و رد درخواست',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final merchants = ref.watch(merchantsQueueProvider);
    final products = ref.watch(productsQueueProvider);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مدیریت فروشندگان و قوانین مالی (Seller Governance)',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.tx,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'صف بررسی مدارک بوتیک‌ها، تأیید کاتالوگ کالاهای اسپانسرشده و تنظیم نرخ‌های CPC/CPM و CPT',
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
                  AppBadge(
                    variant: AppBadgeVariant.warning,
                    child: Text(
                      '${merchants.where((m) => m.status == MerchantStatus.pending).length} فروشگاه در انتظار تأیید',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Sub-Tabs Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.sf,
              borderRadius: AppRadius.rLg,
              border: Border.all(color: colors.bd),
            ),
            child: Row(
              children: [
                _buildSubTabButton(0, 'صف بررسی فروشگاه‌ها (${merchants.length})', Icons.store_outlined),
                _buildSubTabButton(1, 'تأیید کاتالوگ محصولات (${products.length})', Icons.checkroom_outlined),
                _buildSubTabButton(2, 'قوانین مالی و نرخ تبلیغات (CPC/CPM)', Icons.price_change_outlined),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Content Based on Sub-Tab
          if (_activeSubTab == 0)
            _buildMerchantsQueueTab(merchants)
          else if (_activeSubTab == 1)
            _buildProductsQueueTab(products)
          else
            _buildFinancialRulesTab(),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String title, IconData icon) {
    final colors = context.colors;
    final isSelected = _activeSubTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeSubTab = index),
        borderRadius: AppRadius.rMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.pr : Colors.transparent,
            borderRadius: AppRadius.rMd,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? colors.prt : colors.mu),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? colors.prt : colors.tx,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SubTab 0: Merchants Moderation Queue Table
  Widget _buildMerchantsQueueTab(List<MerchantModel> merchants) {
    final colors = context.colors;

    return AppCard(
      padding: EdgeInsetsDirectional.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header Row
          Container(
            color: colors.bg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                _buildHeaderCell('نام فروشگاه و شهر', flex: 3),
                _buildHeaderCell('نام مالک و تلفن', flex: 3),
                _buildHeaderCell('کد ملی', flex: 2),
                _buildHeaderCell('تعداد کالا', flex: 2),
                _buildHeaderCell('موجودی کیف پول', flex: 2),
                _buildHeaderCell('وضعیت', flex: 2),
                _buildHeaderCell('اقدامات نظارتی', flex: 3, alignEnd: true),
              ],
            ),
          ),
          const Divider(height: 1),

          // Rows
          ...merchants.map((m) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.bd.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  // Store & City
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.storeName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                        ),
                        Text(m.city, style: TextStyle(fontSize: 10, color: colors.mu)),
                      ],
                    ),
                  ),
                  // Owner & Phone
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.ownerName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.tx)),
                        Text(m.phone, style: TextStyle(fontSize: 10, color: colors.mu)),
                      ],
                    ),
                  ),
                  // National ID
                  Expanded(
                    flex: 2,
                    child: Text(m.nationalId, style: TextStyle(fontSize: 11, color: colors.tx)),
                  ),
                  // Catalog Count
                  Expanded(
                    flex: 2,
                    child: Text('${m.catalogCount} قلم', style: TextStyle(fontSize: 11, color: colors.tx)),
                  ),
                  // Wallet Balance
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${(m.walletBalanceToman / 1000).toStringAsFixed(0)} هزار تومان',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                  // Status
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppBadge(
                        variant: m.status == MerchantStatus.approved
                            ? AppBadgeVariant.success
                            : (m.status == MerchantStatus.pending
                                ? AppBadgeVariant.warning
                                : AppBadgeVariant.destructive),
                        size: AppBadgeSize.sm,
                        child: Text(m.status.label),
                      ),
                    ),
                  ),
                  // Actions
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (m.status != MerchantStatus.approved)
                          AppButton(
                            text: 'تأیید فروشگاه',
                            size: AppButtonSize.sm,
                            icon: const Icon(Icons.check, size: 14),
                            onPressed: () {
                              ref.read(merchantsQueueProvider.notifier).approveMerchant(m.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فروشگاه ${m.storeName} تأیید شد.')),
                              );
                            },
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        if (m.status != MerchantStatus.rejected)
                          AppButton(
                            text: 'رد',
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.destructive,
                            icon: const Icon(Icons.close, size: 14),
                            onPressed: () {
                              _showRejectDialog(
                                title: 'رد فروشگاه ${m.storeName}',
                                onConfirm: () {
                                  final reason = _rejectReasonController.text.trim();
                                  ref.read(merchantsQueueProvider.notifier).rejectMerchant(
                                        m.id,
                                        reason.isEmpty ? 'نقص در مدارک' : reason,
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
            );
          }),
        ],
      ),
    );
  }

  // SubTab 1: Products Moderation Queue Table
  Widget _buildProductsQueueTab(List<ProductApprovalModel> products) {
    final colors = context.colors;

    return AppCard(
      padding: EdgeInsetsDirectional.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: colors.bg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                _buildHeaderCell('عنوان کالا', flex: 4),
                _buildHeaderCell('فروشگاه', flex: 3),
                _buildHeaderCell('دسته‌بندی', flex: 2),
                _buildHeaderCell('قیمت (تومان)', flex: 2),
                _buildHeaderCell('وضعیت', flex: 2),
                _buildHeaderCell('اقدامات نظارتی', flex: 3, alignEnd: true),
              ],
            ),
          ),
          const Divider(height: 1),

          // Rows
          ...products.map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.bd.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  // Title
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                        ),
                        Text(
                          p.redirectUrl,
                          style: TextStyle(fontSize: 10, color: colors.mu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Merchant
                  Expanded(
                    flex: 3,
                    child: Text(p.merchantName, style: TextStyle(fontSize: 11, color: colors.tx)),
                  ),
                  // Category
                  Expanded(
                    flex: 2,
                    child: Text(p.category, style: TextStyle(fontSize: 11, color: colors.tx)),
                  ),
                  // Price
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${p.priceToman.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} تومان',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Status
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppBadge(
                        variant: p.status == MerchantStatus.approved
                            ? AppBadgeVariant.success
                            : (p.status == MerchantStatus.pending
                                ? AppBadgeVariant.warning
                                : AppBadgeVariant.destructive),
                        size: AppBadgeSize.sm,
                        child: Text(p.status.label),
                      ),
                    ),
                  ),
                  // Actions
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (p.status != MerchantStatus.approved)
                          AppButton(
                            text: 'تأیید کالا',
                            size: AppButtonSize.sm,
                            icon: const Icon(Icons.check, size: 14),
                            onPressed: () {
                              ref.read(productsQueueProvider.notifier).approveProduct(p.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('کالای ${p.title} تأیید شد.')),
                              );
                            },
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        if (p.status != MerchantStatus.rejected)
                          AppButton(
                            text: 'رد',
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.destructive,
                            icon: const Icon(Icons.close, size: 14),
                            onPressed: () {
                              _showRejectDialog(
                                title: 'رد کالای ${p.title}',
                                onConfirm: () {
                                  final reason = _rejectReasonController.text.trim();
                                  ref.read(productsQueueProvider.notifier).rejectProduct(
                                        p.id,
                                        reason.isEmpty ? 'عدم تطابق استاندارد' : reason,
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
            );
          }),
        ],
      ),
    );
  }

  // SubTab 2: Financial Rules & Fees
  Widget _buildFinancialRulesTab() {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تعرفه حراجی تبلیغات و کمیسیون پلتفرم (Pricing & Commission Tiers)',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.tx,
                ),
              ),
              AppButton(
                text: 'ذخیره قوانین مالی',
                icon: const Icon(Icons.save_outlined, size: 16),
                size: AppButtonSize.sm,
                onPressed: () {
                  final cpc = int.tryParse(_cpcController.text) ?? 1500;
                  final cpm = int.tryParse(_cpmController.text) ?? 25000;
                  final std = int.tryParse(_stdCommController.text) ?? 12;
                  final prem = int.tryParse(_premCommController.text) ?? 8;
                  final cpt = int.tryParse(_cptController.text) ?? 40;

                  ref.read(sellerFinancialRulesProvider.notifier).updateRules(
                        cpc: cpc,
                        cpm: cpm,
                        stdCommission: std,
                        premCommission: prem,
                        cpt: cpt,
                      );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF16A34A),
                      content: Text('قوانین مالی فروشندگان با موفقیت ذخیره و در بک‌اند اعمال گردید.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'کف قیمت هر کلیک و نمایش، درصد کارمزد ارجاع خرید و هزینه پرو مجازی البسه برای فروشندگان',
            style: TextStyle(fontSize: 12, color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Form fields grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              return Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.lg,
                children: [
                  SizedBox(
                    width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - AppSpacing.xl) / 2,
                    child: AppTextField(
                      controller: _cpcController,
                      label: 'کف نرخ هر کلیک ارجاعی به سایت فروشنده (CPC Floor - تومان):',
                      suffixText: 'تومان',
                    ),
                  ),
                  SizedBox(
                    width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - AppSpacing.xl) / 2,
                    child: AppTextField(
                      controller: _cpmController,
                      label: 'کف نرخ هر ۱۰۰۰ بازدید پروموت‌شده (CPM Floor - تومان):',
                      suffixText: 'تومان',
                    ),
                  ),
                  SizedBox(
                    width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - AppSpacing.xl) / 2,
                    child: AppTextField(
                      controller: _stdCommController,
                      label: 'درصد کمیسیون فروشگاه‌های استاندارد (Standard Tier):',
                      suffixText: 'درصد (٪)',
                    ),
                  ),
                  SizedBox(
                    width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - AppSpacing.xl) / 2,
                    child: AppTextField(
                      controller: _premCommController,
                      label: 'درصد کمیسیون فروشگاه‌های طلایی و ویژه (Premium Tier):',
                      suffixText: 'درصد (٪)',
                    ),
                  ),
                  SizedBox(
                    width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - AppSpacing.xl) / 2,
                    child: AppTextField(
                      controller: _cptController,
                      label: 'هزینه هر بار پرو مجازی لباس فروشنده (Cost Per Try-on - CPT):',
                      suffixText: 'سکه StyleCoin',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required int flex, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF737373),
          ),
        ),
      ),
    );
  }
}
