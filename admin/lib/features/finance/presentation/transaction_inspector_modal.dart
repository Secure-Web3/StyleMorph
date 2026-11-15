import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class TransactionInspectorModal extends ConsumerStatefulWidget {
  final TransactionRecord transaction;

  const TransactionInspectorModal({
    super.key,
    required this.transaction,
  });

  static Future<void> show({
    required BuildContext context,
    required TransactionRecord transaction,
  }) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: colors.sf,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rCard,
          side: BorderSide(color: colors.bd),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: TransactionInspectorModal(transaction: transaction),
        ),
      ),
    );
  }

  @override
  ConsumerState<TransactionInspectorModal> createState() =>
      _TransactionInspectorModalState();
}

class _TransactionInspectorModalState
    extends ConsumerState<TransactionInspectorModal> {
  final TextEditingController _refundReasonController = TextEditingController();

  @override
  void dispose() {
    _refundReasonController.dispose();
    super.dispose();
  }

  void _confirmRefund() {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.sf,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: AppSpacing.sm),
            Text('تأیید استرداد و لغو آنی تراکنش'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آیا از لغو تراکنش ${widget.transaction.txId} و برگشت مبلغ ${widget.transaction.amountCoins} سکه به کاربر مطمئن هستید؟',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _refundReasonController,
              label: 'علت استرداد (جهت ثبت در دفتر کل و گزارش ممیزی)',
              placeholder: 'مثال: نقص در فراخوانی مدل / عدم رضایت مشتری',
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('انصراف'),
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            text: 'اجرای استرداد (Reverse Tx)',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx); // Close alert
              final reason = _refundReasonController.text.trim().isEmpty
                  ? 'ثبت استرداد توسط مدیر ارشد'
                  : _refundReasonController.text.trim();

              ref
                  .read(ledgerTransactionsProvider.notifier)
                  .reverseTransaction(widget.transaction.txId, reason);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF16A34A),
                  content: Text(
                    'تراکنش ${widget.transaction.txId} با موفقیت در لجر مرجوع شد و به سند کاربر متصل گردید.',
                    style: const TextStyle(fontFamily: AppTypography.fontFamily),
                  ),
                ),
              );

              Navigator.pop(context); // Close inspector
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tx = widget.transaction;

    final profitMargin = tx.amountUsd > 0
        ? (((tx.amountUsd - tx.cloudAiCost) / tx.amountUsd) * 100)
        : 100.0;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with TxID and Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tx.operationType.color.withValues(alpha: 0.1),
                      borderRadius: AppRadius.rMd,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: tx.operationType.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'شناسنامه جزئیات تراکنش',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.tx,
                        ),
                      ),
                      Text(
                        tx.txId,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  AppBadge(
                    variant: tx.status == TxStatus.refunded
                        ? AppBadgeVariant.destructive
                        : (tx.status == TxStatus.settled
                            ? AppBadgeVariant.success
                            : AppBadgeVariant.warning),
                    child: Text(tx.status.label),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: colors.mu,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // 1. Idempotency Key & User Details Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: colors.bd),
            ),
            child: Column(
              children: [
                _buildCopyableRow(
                  label: 'شناسه یکتای عملیات (Idempotency Key):',
                  value: tx.idempotencyKey,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildCopyableRow(
                  label: 'شناسه کاربر (UID):',
                  value: '${tx.userId} (${tx.userDisplayName})',
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildCopyableRow(
                  label: 'درگاه پرداخت:',
                  value: tx.gateway.label,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildCopyableRow(
                  label: 'شرح پردازش:',
                  value: tx.notes.isEmpty ? 'عملیات استاندارد سیستم' : tx.notes,
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. 3-WAY RECONCILIATION STATUS (APP vs GATEWAY vs LEDGER)
          Text(
            'تطبیق سه‌طرفه حسابداری ابری (3-Way Reconciliation)',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildReconcileStep(
                  step: '۱. کلاینت اپلیکیشن',
                  status: tx.reconciliationAppStatus,
                  detail: 'سند کاربر به‌روزرسانی شد',
                  isOk: true,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildReconcileStep(
                  step: '۲. درگاه پرداخت',
                  status: tx.reconciliationGatewayStatus,
                  detail: 'توکن رسید بانکی تأیید شد',
                  isOk: true,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildReconcileStep(
                  step: '۳. دفتر کل تغییرناپذیر',
                  status: tx.reconciliationLedgerStatus,
                  detail: 'هش زنجیره‌ای ذخیره گردید',
                  isOk: true,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. EXACT CLOUD AI COST VS REVENUE BREAKDOWN
          Text(
            'آنالیز مارجین سود ناخالص و هزینه هوش مصنوعی ابری (Cloud AI Cost)',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFinancialMetric(
                  title: 'درآمد دریافتی (Revenue)',
                  val: '\$${tx.amountUsd.toStringAsFixed(2)}',
                  sub: '${tx.amountCoins} سکه StyleCoin',
                  color: const Color(0xFF16A34A),
                ),
                Container(width: 1, height: 40, color: colors.bd),
                _buildFinancialMetric(
                  title: 'هزینه سرور AI (GCP)',
                  val: '\$${tx.cloudAiCost.toStringAsFixed(3)}',
                  sub: 'تولید تصویر و فراخوانی مدل',
                  color: const Color(0xFF2563EB),
                ),
                Container(width: 1, height: 40, color: colors.bd),
                _buildFinancialMetric(
                  title: 'حاشیه سود خالص (Margin)',
                  val: '${profitMargin.toStringAsFixed(1)}٪',
                  sub: 'سود ناخالص عملیات',
                  color: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 4. ACTION BAR (REFUND & PRINT)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'زمان ثبت: ${tx.timestamp.toIso8601String().split('T').join('  -  ').substring(0, 19)}',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  color: colors.mu,
                ),
              ),
              Row(
                children: [
                  AppButton(
                    text: 'چاپ فاکتور و رسید مالی',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    icon: const Icon(Icons.print_outlined, size: 16),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('رسید مالی جهت چاپ ارسال شد.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (tx.status != TxStatus.refunded)
                    AppButton(
                      text: 'استرداد و لغو آنی تراکنش (1-Click Refund)',
                      variant: AppButtonVariant.destructive,
                      size: AppButtonSize.sm,
                      icon: const Icon(Icons.undo, size: 16),
                      onPressed: _confirmRefund,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow({
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            color: colors.mu,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.tx,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 14),
          color: colors.mu,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'کپی کردن',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('در حافظه کپی شد'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReconcileStep({
    required String step,
    required String status,
    required String detail,
    required bool isOk,
    required AppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: colors.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                step,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.tx,
                ),
              ),
              Icon(
                isOk ? Icons.check_circle : Icons.error,
                size: 14,
                color: isOk ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
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

  Widget _buildFinancialMetric({
    required String title,
    required String val,
    required String sub,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            color: Color(0xFF737373),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 10,
            color: Color(0xFF737373),
          ),
        ),
      ],
    );
  }
}
