import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/email_verification_gate.dart';
import '../../domain/atelier_models.dart';
import '../atelier_provider.dart';

class TemplateDetailSheet extends ConsumerStatefulWidget {
  const TemplateDetailSheet({super.key, required this.template});

  final AtelierTemplate template;

  @override
  ConsumerState<TemplateDetailSheet> createState() =>
      _TemplateDetailSheetState();
}

class _TemplateDetailSheetState extends ConsumerState<TemplateDetailSheet> {
  bool _acceptedTerms = false;
  String? _error;

  Color _parse(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _generate() {
    if (!checkEmailVerificationGate(context, ref)) return;
    setState(() => _error = null);
    final strings = context.strings;
    try {
      ref.read(atelierProvider.notifier).generateTemplate(widget.template);
      ref.read(atelierProvider.notifier).switchTab('creations');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.tr('سفارش قالب')} «${strings.tr(widget.template.name)}» ${strings.tr('ثبت شد و به صف هوش مصنوعی رفت.')}',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final t = widget.template;
    final appCoins = ref.watch(appStateProvider).coins;
    final primaryColor = _parse(t.colorHexes.first);

    return AppBottomSheetShell(
      title: strings.tr(t.name),
      maxHeightFactor: 0.90,
      bottomBar: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.buildCostText(t.price),
                  style: AppTypography.cardTitle(color: colors.tx),
                ),
                Text(
                  strings.balanceText(appCoins),
                  style: AppTypography.caption(color: colors.mu),
                ),
              ],
            ),
          ),
          AppButton(
            text: strings.atelConfirmStart,
            onPressed: _acceptedTerms ? _generate : null,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual preview
          AppCard(
            height: 170,
            backgroundColor: primaryColor.withValues(alpha: 0.18),
            child: Center(
              child: Icon(t.icons.first, size: 64, color: primaryColor),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            strings.tr(t.description),
            style: AppTypography.bodySmall(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.md),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: strings.atelPopularity,
                  val: strings.formatPercent(t.popularity),
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatBox(
                  label: strings.atelUsage,
                  val: strings.formatPercent(t.usage),
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatBox(
                  label: strings.atelBuildTime,
                  val: strings.tr(t.timeEstimate),
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Output specs
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  t.type == 'v'
                      ? Icons.videocam_rounded
                      : Icons.photo_camera_rounded,
                  size: 16,
                  color: colors.pr,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  strings.atelOutputType,
                  style: AppTypography.caption(color: colors.mu),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    strings.tr(t.outputSpecs),
                    style: AppTypography.cardTitle(color: colors.tx),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Pro Options
          Text(
            strings.atelProOptions,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: t.proOptions.map((opt) {
              return AppBadge(
                size: AppBadgeSize.sm,
                child: Text(strings.tr(opt)),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Anatomical & Privacy Checklist
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReqLine(
                  text: strings.tr('عکس‌های پایه آلبوم پروفایل شما تکمیل است.'),
                  colors: colors,
                ),
                _ReqLine(
                  text: strings.tr('ابعاد و مشخصات AI DNA ثبت شده است.'),
                  colors: colors,
                ),
                _ReqLine(
                  text: strings.tr(
                    'چهره شما توسط سیستم احراز هویت اولیه تایید شد.',
                  ),
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Guarantee note
          AppCard(
            backgroundColor: colors.okb,
            borderColor: colors.ok.withValues(alpha: 0.3),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 15, color: colors.ok),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings.atelGuarantee,
                    style: AppTypography.caption(color: colors.ok),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Confirmation checkbox
          AppCheckboxTile(
            label: strings.atelConfirmTerms,
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v),
          ),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings.tr(_error!),
              style: AppTypography.bodySmall(color: colors.orColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.val,
    required this.colors,
  });

  final String label;
  final String val;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.bd),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 9,
              color: colors.mu,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReqLine extends StatelessWidget {
  const _ReqLine({required this.text, required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: colors.ok),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                color: colors.tx,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
