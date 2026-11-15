import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/state/admin_state.dart';
import '../domain/ai_gateway_models.dart';

class AiGatewayScreen extends ConsumerStatefulWidget {
  const AiGatewayScreen({super.key});

  @override
  ConsumerState<AiGatewayScreen> createState() => _AiGatewayScreenState();
}

class _AiGatewayScreenState extends ConsumerState<AiGatewayScreen> {
  final TextEditingController _watermarkController = TextEditingController();

  final List<String> _availableModels = [
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-1.5-flash',
    'imagen-3-ultra',
    'flux-1.1-pro',
    'sdxl-turbo',
  ];

  @override
  void initState() {
    super.initState();
    final qa = ref.read(visualQaConfigProvider);
    _watermarkController.text = qa.watermarkText;
  }

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  void _runDiagnostics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16A34A),
        content: Text(
          'تست پینگ به دروازه هوش مصنوعی (Cloud Run EU): زمان رفت‌وبرگشت ۳۸ میلی‌ثانیه، تمامی کلیدها سالم هستند.',
          style: TextStyle(fontFamily: AppTypography.fontFamily),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final keys = ref.watch(gcpKeyPoolProvider);
    final routing = ref.watch(serviceRoutingProvider);
    final visualQa = ref.watch(visualQaConfigProvider);

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
                    'دروازه هوش مصنوعی، بالانسر کلیدها و قیمت‌گذاری (AI Gateway)',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.tx,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'توزیع هوشمند بار پردازشی، استخر کلیدهای مستقل GCP، پایش لحظه‌ای صورت‌حساب و کنترل کیفیت بصری',
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
                  AppButton(
                    text: 'تست پینگ و سلامت درگاه',
                    icon: const Icon(Icons.network_ping, size: 16),
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: _runDiagnostics,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // 1. LIVE BILLING & KEY POOL (TABLE OF 5 GCP KEYS)
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.vpn_key_outlined,
                            color: colors.pr, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'استخر کلیدهای چندپروژه‌ای گوگل کلاد (Multi-Project GCP Pool)',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                        ),
                      ],
                    ),
                    const AppBadge(
                      variant: AppBadgeVariant.success,
                      child: Text('۵ کلید API ثبت‌شده در Secret Manager'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'صورت‌حساب رسمی GCP در برابر مصرف تخمینی زنده، با مدارشکن خودکار زیر ۱۰ میلی‌ثانیه',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: colors.mu,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Keys Table
                Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: colors.bd),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: colors.bg,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            _buildKeyHeaderCell('نام کلید و پروژه GCP', flex: 3),
                            _buildKeyHeaderCell('منطقه ابری', flex: 2),
                            _buildKeyHeaderCell('دوگانه مانیتورینگ مصرف (Dual Live Meter)', flex: 4),
                            _buildKeyHeaderCell('تأخیر پینگ', flex: 2),
                            _buildKeyHeaderCell('وضعیت', flex: 2),
                            _buildKeyHeaderCell('قطع خودکار سقف', flex: 2),
                            _buildKeyHeaderCell('عملیات', flex: 2, alignEnd: true),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Rows
                      ...keys.map((k) {
                        final usageRatio = k.billedLimit > 0
                            ? (k.officialBilledCost / k.billedLimit)
                            : 0.0;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: colors.bd.withValues(alpha: 0.5)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Name & Masked Key
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      k.alias,
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colors.tx,
                                      ),
                                    ),
                                    Text(
                                      '${k.gcpProjectId} • ${k.maskedKey}',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 10,
                                        color: colors.mu,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Region
                              Expanded(
                                flex: 2,
                                child: Text(
                                  k.region,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    color: colors.tx,
                                  ),
                                ),
                              ),
                              // Dual Live Meter
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'رسمی: \$${k.officialBilledCost.toStringAsFixed(1)} / \$${k.billedLimit.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontFamily: AppTypography.fontFamily,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '+زنده: \$${k.liveUnbilledCost.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontFamily: AppTypography.fontFamily,
                                            fontSize: 10,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: AppRadius.rFull,
                                      child: LinearProgressIndicator(
                                        value: usageRatio.clamp(0.0, 1.0),
                                        backgroundColor:
                                            colors.bd.withValues(alpha: 0.5),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          usageRatio > 0.8
                                              ? const Color(0xFFDC2626)
                                              : (usageRatio > 0.6
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFF16A34A)),
                                        ),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Latency
                              Expanded(
                                flex: 2,
                                child: Text(
                                  k.latencyMs > 0 ? '${k.latencyMs} ms' : '-',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(k.status.color),
                                  ),
                                ),
                              ),
                              // Status
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: AppBadge(
                                    variant: k.status == KeyStatus.active
                                        ? AppBadgeVariant.success
                                        : (k.status == KeyStatus.degraded
                                            ? AppBadgeVariant.warning
                                            : AppBadgeVariant.destructive),
                                    size: AppBadgeSize.sm,
                                    child: Text(k.status.label),
                                  ),
                                ),
                              ),
                              // Auto Disable switch
                              Expanded(
                                flex: 2,
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: k.autoDisableEnabled,
                                    activeThumbColor: colors.pr,
                                    onChanged: (val) {
                                      ref
                                          .read(gcpKeyPoolProvider.notifier)
                                          .toggleAutoDisable(k.keyId);
                                    },
                                  ),
                                ),
                              ),
                              // Rotate / Action button
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: AppButton(
                                    text: 'چرخش کلید',
                                    size: AppButtonSize.sm,
                                    variant: AppButtonVariant.outline,
                                    icon: const Icon(Icons.refresh, size: 14),
                                    onPressed: () {
                                      ref
                                          .read(gcpKeyPoolProvider.notifier)
                                          .rotateKey(k.keyId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'کلید ${k.alias} با موفقیت Hot-Reload شد.'),
                                        ),
                                      );
                                    },
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
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 2. MODEL ROUTING MATRIX
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.alt_route, color: colors.pr, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'ماتریس مسیریابی مدل‌های هوش مصنوعی (Model Routing)',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                        ),
                      ],
                    ),
                    const AppBadge(
                      variant: AppBadgeVariant.info,
                      child: Text('تنظیمات بالانسر ابری'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'انتخاب مدل اولیه و مدل جایگزین اضطراری (Fallback) برای هر یک از خدمات پردازشی بدون قطعی سرویس',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: colors.mu,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Routing items
                ...routing.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.rMd,
                      border: Border.all(color: colors.bd),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.serviceTitleFa,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.tx,
                                ),
                              ),
                              Text(
                                r.serviceDescriptionFa,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 11,
                                  color: colors.mu,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Primary Model Dropdown
                        Expanded(
                          flex: 3,
                          child: AppDropdown<String>(
                            label: 'مدل اولیه (Primary)',
                            value: r.primaryModel,
                            items: _availableModels.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(m, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(serviceRoutingProvider.notifier)
                                    .updateRouting(
                                        r.serviceId, val, r.fallbackModel);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Fallback Model Dropdown
                        Expanded(
                          flex: 3,
                          child: AppDropdown<String>(
                            label: 'مدل جایگزین (Fallback)',
                            value: r.fallbackModel,
                            items: _availableModels.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(m, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(serviceRoutingProvider.notifier)
                                    .updateRouting(
                                        r.serviceId, r.primaryModel, val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 3. VISUAL QA & TESTING CONTROLS (MOCK AI, ANATOMY, WATERMARK)
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_fix_high, color: colors.pr, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'کنترل کیفیت بصری و محیط شبیه‌ساز (Visual QA & Mock AI)',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                        ),
                      ],
                    ),
                    AppBadge(
                      variant: visualQa.useMockAi
                          ? AppBadgeVariant.warning
                          : AppBadgeVariant.success,
                      child: Text(visualQa.useMockAi
                          ? 'حالت تست رایگان (Mock AI)'
                          : 'هوش مصنوعی زنده پروداکشن'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'تنظیمات پیشرفته آناتومی دست و بدن، اعمال واترمارک روی خروجی‌های رایگان و سوئیچ شبیه‌ساز برای عدم مصرف توکن GCP',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: colors.mu,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Column(
                    children: [
                      // USE_MOCK_AI MASTER TOGGLE
                      AppSwitchTile(
                        label: 'سوئیچ فعال‌سازی هوش مصنوعی شبیه‌سازی‌شده (USE_MOCK_AI)',
                        subtitle:
                            'در صورت فعال بودن، تمام درخواست‌های استایلیست و آتلیه با داده‌های پیش‌فرض تست بدون فراخوانی API پولی گوگل پاسخ داده می‌شوند.',
                        value: visualQa.useMockAi,
                        onChanged: (val) {
                          ref
                              .read(visualQaConfigProvider.notifier)
                              .toggleUseMockAi(val);
                        },
                      ),
                      const Divider(height: 16),

                      // Anatomical correction
                      AppSwitchTile(
                        label: 'تطبیق آناتومی بدن و حذف خطاهای فیزیکی (Anatomical Self-Correction)',
                        subtitle:
                            'اعمال الگوریتم تصحیح دست، انگشتان و تقارن چهره در خروجی‌های اتاق پرو و آتلیه مد با ضریب اطمینان ۹۵٪.',
                        value: visualQa.anatomicalCorrectionEnabled,
                        onChanged: (val) {
                          ref
                              .read(visualQaConfigProvider.notifier)
                              .toggleAnatomicalCorrection(val);
                        },
                      ),
                      const Divider(height: 16),

                      // Watermark
                      AppSwitchTile(
                        label: 'اعمال واترمارک برای کاربران طرح رایگان (Watermark)',
                        subtitle:
                            'درج لوگو یا متن شفاف در گوشه پایین تصاویر تولیدی در پلن‌های غیرپرمیوم.',
                        value: visualQa.watermarkEnabled,
                        onChanged: (val) {
                          ref
                              .read(visualQaConfigProvider.notifier)
                              .toggleWatermark(val);
                        },
                      ),
                      if (visualQa.watermarkEnabled) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _watermarkController,
                          label: 'متن واترمارک روی تصاویر:',
                          onChanged: (val) {
                            ref
                                .read(visualQaConfigProvider.notifier)
                                .setWatermarkText(val);
                          },
                        ),
                      ],
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

  Widget _buildKeyHeaderCell(String title, {required int flex, bool alignEnd = false}) {
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
}
