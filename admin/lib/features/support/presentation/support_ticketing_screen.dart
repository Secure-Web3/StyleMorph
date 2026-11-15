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
import '../domain/support_models.dart';

class SupportTicketingScreen extends ConsumerStatefulWidget {
  const SupportTicketingScreen({super.key});

  @override
  ConsumerState<SupportTicketingScreen> createState() =>
      _SupportTicketingScreenState();
}

class _SupportTicketingScreenState
    extends ConsumerState<SupportTicketingScreen> {
  String? _selectedTicketId;
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _refundReasonController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    _refundReasonController.dispose();
    super.dispose();
  }

  void _trigger1ClickRefund(SupportTicketItem ticket) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;
    _refundReasonController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.sf,
        title: const Row(
          children: [
            Icon(Icons.undo, color: Color(0xFFDC2626)),
            SizedBox(width: AppSpacing.sm),
            Text('موتور استرداد آنی وجه (1-Click Refund Engine)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آیا مایل به بازگرداندن ۱۵۰ سکه به حساب کاربر ${ticket.userName} (${ticket.userId}) هستید؟',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'این عملیات مستقیماً در دفتر کل غیرقابل تغییر (Immutable Ledger) با شناسه یکتا ثبت شده و وضعیت تیکت به حل‌شده تغییر خواهد یافت.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _refundReasonController,
              label: 'علت ممیزی استرداد (Audit Reason):',
              placeholder: 'مثال: نقص در فراخوانی مدل Imagen-3 و کسر ناعادلانه سکه',
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('انصراف'),
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            text: 'اجرای استرداد و ثبت در لجر',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () {
              final reason = _refundReasonController.text.trim().isEmpty
                  ? 'بررسی تیکت پشتیبانی و تایید نقص هوش مصنوعی'
                  : _refundReasonController.text.trim();

              Navigator.pop(ctx);

              ref.read(supportTicketsProvider.notifier).refundAndResolveTicket(
                    ticketId: ticket.ticketId,
                    reason: reason,
                  );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF16A34A),
                  content: Text(
                    'مبلغ ۱۵۰ سکه با موفقیت به حساب ${ticket.userName} مسترد گردید و سند لجر تولید شد.',
                    style: const TextStyle(fontFamily: AppTypography.fontFamily),
                  ),
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
    final tickets = ref.watch(supportTicketsProvider);

    final selectedTicket = tickets.firstWhere(
      (t) => t.ticketId == (_selectedTicketId ?? tickets.first.ticketId),
      orElse: () => tickets.first,
    );

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
                    'میز پشتیبانی هوشمند و داوری مغایرت‌ها (Smart Support Desk)',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.tx,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'میزکار آگاه به بستر (Context-Aware) با لاگ‌های خطای هوش مصنوعی، اطلاعات دستگاه و موتور استرداد آنی وجه',
                    style: TextStyle(fontSize: 13, color: colors.mu),
                  ),
                ],
              ),
              Row(
                children: [
                  AppBadge(
                    variant: AppBadgeVariant.destructive,
                    child: Text(
                      '${tickets.where((t) => t.status == TicketStatus.open).length} تیکت باز در صف بررسی',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // SPLIT-VIEW LAYOUT
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1100;
              final leftColumn = Column(
                children: [
                  // Tickets Horizontal / Grid selector
                  AppCard(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صندوق تیکت‌های پشتیبانی:',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.mu,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...tickets.map((t) {
                          final isSelected = selectedTicket.ticketId == t.ticketId;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedTicketId = t.ticketId);
                            },
                            borderRadius: AppRadius.rMd,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.pr.withValues(alpha: 0.08)
                                    : colors.bg,
                                borderRadius: AppRadius.rMd,
                                border: Border.all(
                                  color: isSelected ? colors.pr : colors.bd,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AppBadge(
                                    variant: t.priority == TicketPriority.critical
                                        ? AppBadgeVariant.destructive
                                        : (t.priority == TicketPriority.high
                                            ? AppBadgeVariant.warning
                                            : AppBadgeVariant.info),
                                    size: AppBadgeSize.sm,
                                    child: Text(t.priority.label),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.subject,
                                          style: TextStyle(
                                            fontFamily: AppTypography.fontFamily,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: colors.tx,
                                          ),
                                        ),
                                        Text(
                                          '${t.userName} (${t.userId}) • ${t.category}',
                                          style: TextStyle(fontSize: 11, color: colors.mu),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppBadge(
                                    variant: t.status == TicketStatus.resolved
                                        ? AppBadgeVariant.success
                                        : (t.status == TicketStatus.open
                                            ? AppBadgeVariant.warning
                                            : AppBadgeVariant.info),
                                    size: AppBadgeSize.sm,
                                    child: Text(t.status.label),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Active Conversation Thread
                  AppCard(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedTicket.subject,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: colors.tx,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'شناسه تیکت: ${selectedTicket.ticketId} • فرستنده: ${selectedTicket.userName}',
                                    style: TextStyle(fontSize: 11, color: colors.mu),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Prominent 1-Click Refund Button
                            if (selectedTicket.status != TicketStatus.resolved)
                              AppButton(
                                text: 'بازگشت وجه و حل تیکت (1-Click Refund)',
                                variant: AppButtonVariant.destructive,
                                size: AppButtonSize.sm,
                                icon: const Icon(Icons.undo, size: 16),
                                onPressed: () => _trigger1ClickRefund(selectedTicket),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),

                        // Chat messages
                        Column(
                          children: selectedTicket.messages.map((msg) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Align(
                                alignment: msg.isFromAdmin
                                    ? AlignmentDirectional.centerStart
                                    : AlignmentDirectional.centerEnd,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: msg.isFromAdmin
                                        ? colors.pr.withValues(alpha: 0.08)
                                        : colors.bg,
                                    borderRadius: AppRadius.rCard,
                                    border: Border.all(color: colors.bd),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: msg.isFromAdmin
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        msg.sender,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: msg.isFromAdmin ? colors.pr : colors.tx,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.message,
                                        style: TextStyle(fontSize: 12, color: colors.tx, height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Reply Input
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _replyController,
                                placeholder: 'پاسخ رسمی پشتیبانی به کاربر...',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppButton(
                              text: 'ارسال پاسخ',
                              size: AppButtonSize.sm,
                              icon: const Icon(Icons.send, size: 14),
                              onPressed: () {
                                if (_replyController.text.trim().isNotEmpty) {
                                  ref.read(supportTicketsProvider.notifier).replyTicket(
                                        selectedTicket.ticketId,
                                        _replyController.text.trim(),
                                      );
                                  _replyController.clear();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final rightColumn = Column(
                children: [
                  // User & Device Info Card
                  AppCard(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.perm_device_information, color: colors.pr, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'اطلاعات دستگاه و کلاینت کاربر',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.tx,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildContextRow('کاربر:', '${selectedTicket.userName} (${selectedTicket.userEmail})', colors),
                        _buildContextRow('موجودی کیف پول:', '${selectedTicket.userCoinBalance} سکه StyleCoin', colors),
                        _buildContextRow('مدل دستگاه:', selectedTicket.deviceModel, colors),
                        _buildContextRow('نسخه اپلیکیشن:', selectedTicket.appVersion, colors),
                        _buildContextRow('آخرین آدرس IP:', selectedTicket.ipAddress, colors),
                        if (selectedTicket.relatedTxId != null)
                          _buildContextRow('شناسه تراکنش لجر:', selectedTicket.relatedTxId!, colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // AI Error Logs Card
                  AppCard(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                    borderColor: selectedTicket.recentAiErrorLog != null ? const Color(0xFFDC2626) : colors.bd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report_outlined, color: Color(0xFFDC2626), size: 18),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'لاگ خطای هوش مصنوعی (AI Error Log)',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (selectedTicket.recentAiErrorLog != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                              borderRadius: AppRadius.rMd,
                              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedTicket.recentAiErrorLog!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            '• علت خطا: عبور از سقف مجاز توکن در ثانیه (TPM) در کلاود ران اروپا\n• راهکار خودکار: سوییچ به کلید جایگزین و امکان بازگشت وجه ۱-کلیک.',
                            style: TextStyle(fontSize: 11, height: 1.5, color: Colors.grey),
                          ),
                        ] else ...[
                          Text(
                            'هیچ خطایی در گزارش‌های هوش مصنوعی برای این کاربر ثبت نشده است.',
                            style: TextStyle(fontSize: 12, color: colors.mu),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: AppSpacing.xl),
                    rightColumn,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: leftColumn),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(flex: 5, child: rightColumn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContextRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: colors.mu)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.tx),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
