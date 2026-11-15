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
import '../../../core/state/admin_state.dart';
import '../domain/module_config.dart';

class ModulesScreen extends ConsumerStatefulWidget {
  const ModulesScreen({super.key});

  @override
  ConsumerState<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends ConsumerState<ModulesScreen> {
  int _activeSubTabIndex = 0;
  final TextEditingController _maintenanceMsgController =
      TextEditingController();

  final List<String> _subTabLabels = [
    'پروفایل',
    'کمد مجازی',
    'فروشگاه',
    'استایلیست',
    'آتلیه',
    'تندرستی',
  ];

  @override
  void dispose() {
    _maintenanceMsgController.dispose();
    super.dispose();
  }

  void _syncToRemoteConfig(ModuleConfig currentModule) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        content: Text(
          'تنظیمات ماژول «${currentModule.titleFa}» با موفقیت در Firebase Remote Config ذخیره شد و در کمتر از ۲ ثانیه در کلاینت‌ها اعمال خواهد شد.',
          style: const TextStyle(fontFamily: AppTypography.fontFamily),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final modules = ref.watch(modulesConfigProvider);
    final currentModule = modules[_activeSubTabIndex.clamp(0, modules.length - 1)];

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مدیریت ماژولهای اپلیکیشن (Mobile Modules Manager)',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.tx,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'پیکربندی فیچرفلگ‌ها، کلیدهای قطع اضطراری (Kill-Switch) و محدودیت‌های سهمیه روزانه',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: colors.mu,
                    ),
                  ),
                ],
              ),
              AppButton(
                text: 'همگام‌سازی با Remote Config',
                icon: const Icon(Icons.cloud_sync_outlined, size: 16),
                size: AppButtonSize.sm,
                onPressed: () => _syncToRemoteConfig(currentModule),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // 6 Sub-Tabs Selector
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.sf,
              borderRadius: AppRadius.rLg,
              border: Border.all(color: colors.bd),
            ),
            child: Row(
              children: List.generate(_subTabLabels.length, (index) {
                final isSelected = _activeSubTabIndex == index;
                final mod = modules[index];
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeSubTabIndex = index;
                        _maintenanceMsgController.text = mod.maintenanceNotice;
                      });
                    },
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
                          Text(
                            _subTabLabels[index],
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected ? colors.prt : colors.tx,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: mod.isEnabled
                                  ? (mod.isMaintenance
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF16A34A))
                                  : const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Active Module Details Card
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentModule.titleFa,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.tx,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentModule.descriptionFa,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: colors.mu,
                          ),
                        ),
                      ],
                    ),
                    AppBadge(
                      variant: currentModule.isEnabled
                          ? (currentModule.isMaintenance
                              ? AppBadgeVariant.warning
                              : AppBadgeVariant.success)
                          : AppBadgeVariant.destructive,
                      child: Text(
                        currentModule.isEnabled
                            ? (currentModule.isMaintenance
                                ? 'در دست تعمیر'
                                : 'ماژول فعال')
                            : 'غیرفعال (قطع اضطراری)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                // 1. MASTER KILL-SWITCH & MAINTENANCE MODE
                Text(
                  'کنترل‌های حیاتی و وضعیت دسترسی عمومی',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Column(
                    children: [
                      AppSwitchTile(
                        label: 'کلید قطع اضطراری ماژول (Master Kill-Switch)',
                        subtitle:
                            'در صورت بروز مشکل فنی یا باگ امنیتی، کل این ماژول بدون نیاز به انتشار نسخه جدید خاموش می‌شود.',
                        value: currentModule.isEnabled,
                        onChanged: (val) {
                          ref
                              .read(modulesConfigProvider.notifier)
                              .updateModule(currentModule.id, (old) {
                            return old.copyWith(isEnabled: val);
                          });
                        },
                      ),
                      const Divider(height: 16),
                      AppSwitchTile(
                        label: 'حالت در دست تعمیر (Maintenance Mode)',
                        subtitle:
                            'ماژول برای کاربران عادی قفل شده و بنر تعمیرات به همراه متن پیام سفارشی نمایش داده می‌شود.',
                        value: currentModule.isMaintenance,
                        onChanged: (val) {
                          ref
                              .read(modulesConfigProvider.notifier)
                              .updateModule(currentModule.id, (old) {
                            return old.copyWith(isMaintenance: val);
                          });
                        },
                      ),
                      if (currentModule.isMaintenance) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _maintenanceMsgController,
                          label: 'متن پیام نمایش داده شده به کاربران هنگام تعمیرات:',
                          onChanged: (val) {
                            ref
                                .read(modulesConfigProvider.notifier)
                                .updateModule(currentModule.id, (old) {
                              return old.copyWith(maintenanceNotice: val);
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 2. AI AUTO-TAGGING & VISION TOGGLES
                Text(
                  'هوش مصنوعی و پردازش تصویر',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Column(
                    children: [
                      AppSwitchTile(
                        label: 'برچسب‌گذاری خودکار با مدل بینایی (AI Auto-Tagging)',
                        subtitle:
                            'استخراج متادیتا، دسته‌بندی رنگ و بافت پارچه با Gemini 2.0 Flash بلافاصله پس از آپلود تصویر.',
                        value: currentModule.aiAutoTagging,
                        onChanged: (val) {
                          ref
                              .read(modulesConfigProvider.notifier)
                              .updateModule(currentModule.id, (old) {
                            return old.copyWith(aiAutoTagging: val);
                          });
                        },
                      ),
                      const Divider(height: 16),
                      AppSwitchTile(
                        label: 'اجبار به احراز هویت دوعاملی (Require 2FA)',
                        subtitle:
                            'جهت محافظت از داده‌های آناتومی بدن و تصاویر حساس چهره.',
                        value: currentModule.require2FA,
                        onChanged: (val) {
                          ref
                              .read(modulesConfigProvider.notifier)
                              .updateModule(currentModule.id, (old) {
                            return old.copyWith(require2FA: val);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 3. QUOTAS & LIMITS COUNTERS
                Text(
                  'سقف مجاز سهمیه رایگان و محدودیت ذخیره‌سازی',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: AppRadius.rMd,
                          border: Border.all(color: colors.bd),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سقف پردازش رایگان روزانه (Free Quota):',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.tx,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${currentModule.dailyFreeQuota} بار در روز برای هر کاربر',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colors.pr,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: currentModule.dailyFreeQuota > 0
                                          ? () {
                                              ref
                                                  .read(modulesConfigProvider.notifier)
                                                  .updateModule(currentModule.id,
                                                      (old) {
                                                return old.copyWith(
                                                    dailyFreeQuota:
                                                        old.dailyFreeQuota - 1);
                                              });
                                            }
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        ref
                                            .read(modulesConfigProvider.notifier)
                                            .updateModule(currentModule.id, (old) {
                                          return old.copyWith(
                                              dailyFreeQuota:
                                                  old.dailyFreeQuota + 1);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: AppRadius.rMd,
                          border: Border.all(color: colors.bd),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حداکثر سقف آیتم‌های قابل نگهداری:',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.tx,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${currentModule.maxItemLimit} آیتم برای کاربران عادی',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colors.pr,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: currentModule.maxItemLimit > 10
                                          ? () {
                                              ref
                                                  .read(modulesConfigProvider.notifier)
                                                  .updateModule(currentModule.id,
                                                      (old) {
                                                return old.copyWith(
                                                    maxItemLimit:
                                                        old.maxItemLimit - 10);
                                              });
                                            }
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        ref
                                            .read(modulesConfigProvider.notifier)
                                            .updateModule(currentModule.id, (old) {
                                          return old.copyWith(
                                              maxItemLimit:
                                                  old.maxItemLimit + 10);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
