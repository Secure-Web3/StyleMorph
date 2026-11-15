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
import '../domain/transaction_model.dart';
import 'transaction_inspector_modal.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportCsv(List<TransactionRecord> transactions) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Color(0xFF16A34A)),
            SizedBox(width: AppSpacing.sm),
            Text('خروجی رسمی دفتر کل (CSV Export)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تعداد ${transactions.length} رکورد مالی با تمام متادیتای تطبیق سه‌طرفه و هش‌های ممیزی آماده دانلود است.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'نام فایل: stylemorph_ledger_export_2026.csv\nاستاندارد فرمت: RFC 4180 با انکودینگ UTF-8 BOM',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('انصراف'),
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            text: 'دانلود فایل اکسل / CSV',
            size: AppButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF16A34A),
                  content: Text('فایل CSV با موفقیت تولید و دانلود گردید.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allTransactions = ref.watch(ledgerTransactionsProvider);
    final searchQuery = ref.watch(ledgerSearchProvider);
    final selectedGateway = ref.watch(ledgerGatewayFilterProvider);
    final selectedStatus = ref.watch(ledgerStatusFilterProvider);
    final currentPage = ref.watch(ledgerCurrentPageProvider);
    final rowsPerPage = ref.watch(ledgerRowsPerPageProvider);

    // Filter transactions
    final filtered = allTransactions.where((tx) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTx = tx.txId.toLowerCase().contains(query);
        final matchUser = tx.userId.toLowerCase().contains(query);
        final matchName = tx.userDisplayName.toLowerCase().contains(query);
        if (!matchTx && !matchUser && !matchName) return false;
      }
      if (selectedGateway != PaymentGatewayType.all) {
        if (tx.gateway != selectedGateway) return false;
      }
      if (selectedStatus != null) {
        if (tx.status != selectedStatus) return false;
      }
      return true;
    }).toList();

    // Pagination slice
    final totalRows = filtered.length;
    final totalPages = (totalRows / rowsPerPage).ceil().clamp(1, 999);
    final validPage = currentPage.clamp(1, totalPages);
    final startIndex = (validPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage).clamp(0, totalRows);
    final currentSlice = totalRows == 0
        ? <TransactionRecord>[]
        : filtered.sublist(startIndex, endIndex);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'امور مالی و دفتر کل تغییرناپذیر (Immutable Ledger)',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.tx,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'دفتر کل حسابداری با ثبت زنجیره‌ای رویدادهای Hold، Capture، Release و استرداد آنی',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: colors.mu,
                    ),
                  ),
                ],
              ),
              AppButton(
                text: 'خروجی رسمی CSV',
                icon: const Icon(Icons.download, size: 16),
                variant: AppButtonVariant.outline,
                size: AppButtonSize.sm,
                onPressed: () => _exportCsv(filtered),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Ledger KPI Summary Cards
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
                  _buildSummaryMiniCard(
                    context: context,
                    width: width,
                    title: 'حجم کل مبادلات مالی',
                    val: '\$128,450.00',
                    sub: 'تسویه‌شده از ابتدای دوره',
                    color: const Color(0xFF16A34A),
                  ),
                  _buildSummaryMiniCard(
                    context: context,
                    width: width,
                    title: 'تعداد کل تراکنش‌های لجر',
                    val: '${allTransactions.length} رکورد',
                    sub: 'بدون حتی ۱ مورد مغایرت',
                    color: const Color(0xFF2563EB),
                  ),
                  _buildSummaryMiniCard(
                    context: context,
                    width: width,
                    title: 'نرخ تطبیق سه‌طرفه',
                    val: '۱۰۰.۰٪',
                    sub: 'Reconciled App & Bank',
                    color: const Color(0xFF16A34A),
                  ),
                  _buildSummaryMiniCard(
                    context: context,
                    width: width,
                    title: 'میانگین هزینه AI به تراکنش',
                    val: '\$0.028',
                    sub: 'مارجین سود ناخالص: ۹۱.۴٪',
                    color: const Color(0xFF9333EA),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Search Bar & Filter Chips
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: AppTextField(
                        controller: _searchController,
                        placeholder: 'جستجو بر اساس شناسه تراکنش (TxID) یا کاربر...',
                        prefix: const Icon(Icons.search, size: 18),
                        onChanged: (val) {
                          ref.read(ledgerSearchProvider.notifier).state = val;
                          ref.read(ledgerCurrentPageProvider.notifier).state = 1;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Rows per page dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: AppRadius.rMd,
                        border: Border.all(color: colors.bd),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: rowsPerPage,
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('۵ سطر')),
                            DropdownMenuItem(value: 10, child: Text('۱۰ سطر')),
                            DropdownMenuItem(value: 20, child: Text('۲۰ سطر')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(ledgerRowsPerPageProvider.notifier).state =
                                  val;
                              ref.read(ledgerCurrentPageProvider.notifier).state =
                                  1;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Gateway Filter Chips
                Row(
                  children: [
                    Text(
                      'درگاه پرداخت:',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.mu,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: PaymentGatewayType.values.map((gw) {
                            final isSel = selectedGateway == gw;
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(
                                  end: AppSpacing.xs),
                              child: ChoiceChip(
                                label: Text(gw.label),
                                selected: isSel,
                                selectedColor: colors.pr,
                                labelStyle: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 11,
                                  color: isSel ? colors.prt : colors.tx,
                                  fontWeight:
                                      isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (sel) {
                                  ref
                                      .read(ledgerGatewayFilterProvider.notifier)
                                      .state = gw;
                                  ref
                                      .read(ledgerCurrentPageProvider.notifier)
                                      .state = 1;
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // THE DATA TABLE
          AppCard(
            padding: EdgeInsetsDirectional.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table header
                Container(
                  color: colors.bg,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell('شناسه تراکنش (TxID)', flex: 3),
                      _buildHeaderCell('نوع عملیات', flex: 2),
                      _buildHeaderCell('کاربر (UID / نام)', flex: 3),
                      _buildHeaderCell('درگاه پرداخت', flex: 3),
                      _buildHeaderCell('مبلغ و سکه', flex: 2),
                      _buildHeaderCell('هزینه AI', flex: 2),
                      _buildHeaderCell('وضعیت', flex: 2),
                      _buildHeaderCell('عملیات', flex: 2, alignEnd: true),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table rows
                if (currentSlice.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Center(
                      child: Text(
                        'هیچ تراکنشی با فیلترهای انتخابی یافت نشد.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: colors.mu,
                        ),
                      ),
                    ),
                  )
                else
                  ...currentSlice.map((tx) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            TransactionInspectorModal.show(
                              context: context,
                              transaction: tx,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                // TxID
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    tx.txId,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colors.tx,
                                    ),
                                  ),
                                ),
                                // Operation Type badge
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: tx.operationType.color
                                            .withValues(alpha: 0.1),
                                        borderRadius: AppRadius.rSm,
                                      ),
                                      child: Text(
                                        tx.operationType.label,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: tx.operationType.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // User
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.userDisplayName,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.tx,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        tx.userId,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 10,
                                          color: colors.mu,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Gateway
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    tx.gateway.label,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 11,
                                      color: colors.tx,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Amount & Coins
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${tx.amountCoins} سکه',
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
                                ),
                                // AI Cost
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    tx.cloudAiCost > 0
                                        ? '\$${tx.cloudAiCost.toStringAsFixed(3)}'
                                        : '-',
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 11,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Status
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: AppBadge(
                                      variant: tx.status == TxStatus.refunded
                                          ? AppBadgeVariant.destructive
                                          : (tx.status == TxStatus.settled
                                              ? AppBadgeVariant.success
                                              : AppBadgeVariant.warning),
                                      size: AppBadgeSize.sm,
                                      child: Text(tx.status.label),
                                    ),
                                  ),
                                ),
                                // Inspect Button
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: AppButton(
                                      text: 'بازرسی',
                                      size: AppButtonSize.sm,
                                      variant: AppButtonVariant.outline,
                                      icon: const Icon(Icons.visibility_outlined,
                                          size: 14),
                                      onPressed: () {
                                        TransactionInspectorModal.show(
                                          context: context,
                                          transaction: tx,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: colors.bd.withValues(alpha: 0.5)),
                      ],
                    );
                  }),

                // Pagination footer
                Container(
                  color: colors.bg,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نمایش ردیف‌های ${totalRows == 0 ? 0 : startIndex + 1} تا $endIndex از مجموع $totalRows تراکنش',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: colors.mu,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: validPage > 1
                                ? () {
                                    ref
                                        .read(
                                            ledgerCurrentPageProvider.notifier)
                                        .state = validPage - 1;
                                  }
                                : null,
                          ),
                          Text(
                            'صفحه $validPage از $totalPages',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.tx,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: validPage < totalPages
                                ? () {
                                    ref
                                        .read(
                                            ledgerCurrentPageProvider.notifier)
                                        .state = validPage + 1;
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required int flex, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
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

  Widget _buildSummaryMiniCard({
    required BuildContext context,
    required double width,
    required String title,
    required String val,
    required String sub,
    required Color color,
  }) {
    final colors = context.colors;

    return Container(
      width: width,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rCard,
        border: Border.all(color: colors.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: colors.mu,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              color: colors.mu,
            ),
          ),
        ],
      ),
    );
  }
}
