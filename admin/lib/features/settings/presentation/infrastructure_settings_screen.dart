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
import '../domain/settings_models.dart';

class InfrastructureSettingsScreen extends ConsumerStatefulWidget {
  const InfrastructureSettingsScreen({super.key});

  @override
  ConsumerState<InfrastructureSettingsScreen> createState() =>
      _InfrastructureSettingsScreenState();
}

class _InfrastructureSettingsScreenState
    extends ConsumerState<InfrastructureSettingsScreen> {
  int _activeTab = 0; // 0: Locales & Shield, 1: Users & RBAC, 2: Bots & Webhooks, 3: Audit & Backup

  // Shield & Remote config controllers
  final TextEditingController _buildsController = TextEditingController();
  final TextEditingController _promoTextController = TextEditingController();

  // Search user controller
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final shield = ref.read(storeReviewerShieldProvider);
    _buildsController.text = shield.underReviewBuildNumbers;
    _promoTextController.text = shield.promoBannerText;
  }

  @override
  void dispose() {
    _buildsController.dispose();
    _promoTextController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  void _showAddSubAdminModal() {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.lightWhite;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final permissions = <String>{'READ_LEDGER'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: colors.sf,
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: Color(0xFF2563EB)),
              SizedBox(width: AppSpacing.sm),
              Text('افزودن مدیر فرعی جدید (Sub-Admin RBAC)'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(controller: nameCtrl, label: 'نام و نام خانوادگی:'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: emailCtrl, label: 'آدرس ایمیل سازمانی:'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: roleCtrl, label: 'عنوان شغلی (Role Title):'),
                  const SizedBox(height: AppSpacing.md),
                  const Text('مجوزهای دسترسی تفکیک‌شده (Granular Permissions):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  _buildPermCheckbox('READ_LEDGER', 'مشاهده تراکنش‌ها و دفتر کل', permissions, setModalState),
                  _buildPermCheckbox('REVERSE_TX', 'استرداد و لغو تراکنش مالی', permissions, setModalState),
                  _buildPermCheckbox('APPROVE_SELLER', 'تأیید یا رد فروشندگان', permissions, setModalState),
                  _buildPermCheckbox('UPDATE_CONFIG', 'تغییر پیکربندی Remote Config', permissions, setModalState),
                  _buildPermCheckbox('DEVOPS_KEYS', 'مدیریت کلیدهای هوش مصنوعی', permissions, setModalState),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('انصراف'),
              onPressed: () => Navigator.pop(ctx),
            ),
            AppButton(
              text: 'ایجاد حساب کاربری',
              size: AppButtonSize.sm,
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                  ref.read(subAdminsProvider.notifier).addSubAdmin(
                        SubAdminModel(
                          id: 'adm_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          roleTitle: roleCtrl.text.trim().isEmpty ? 'کارشناس سیستم' : roleCtrl.text.trim(),
                          permissions: permissions.toList(),
                        ),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('مدیر فرعی جدید با موفقیت ایجاد گردید.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermCheckbox(
      String key, String label, Set<String> perms, StateSetter setModalState) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 12)),
      value: perms.contains(key),
      onChanged: (val) {
        setModalState(() {
          if (val == true) {
            perms.add(key);
          } else {
            perms.remove(key);
          }
        });
      },
    );
  }

  void _triggerPitrBackup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Row(
          children: [
            Icon(Icons.cloud_download_outlined, color: Color(0xFF16A34A)),
            SizedBox(width: AppSpacing.sm),
            Text('ایجاد نسخه پشتیبان سرد Point-In-Time (PITR)'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'عملیات اسنپ‌شات کامل پایگاه داده Firestore و تمامی مجموعه‌های ledger، users و jobs آغاز شد.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              '• مخزن ذخیره‌سازی: gs://stylemorph-cold-backups-eu\n• هش ممیزی یکتا با استاندارد SHA-256 ذخیره گردید.\n• زمان بازگشت پذیری: تا ۳۰ روز گذشته ثانیه‌به‌ثانیه.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: 'تأیید و بازگشت',
            size: AppButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF16A34A),
                  content: Text('اسنپ‌شات سرد با موفقیت تولید و در کلاد استوریج ذخیره شد.'),
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

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنظیمات زیرساختی، امنیت و پیکربندی (Infrastructure & Security)',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colors.tx,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مدیریت رشته‌های زنده OTA، شیلد ممیزی کافه‌بازار و اپ‌استور، مدیریت نشست تک‌دستگاهی و لاگ‌های ممیزی',
                      style: TextStyle(fontSize: 13, color: colors.mu),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppButton(
                text: 'پشتیبان‌گیری سرد PITR',
                icon: const Icon(Icons.backup_outlined, size: 16),
                variant: AppButtonVariant.outline,
                size: AppButtonSize.sm,
                onPressed: _triggerPitrBackup,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // 4 Sub-Tabs Navigation
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.sf,
              borderRadius: AppRadius.rLg,
              border: Border.all(color: colors.bd),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'زبان، تم و پیکربندی (Remote Config)', Icons.translate_outlined),
                _buildTabButton(1, 'کاربران و نشست‌ها (Users & RBAC)', Icons.manage_accounts_outlined),
                _buildTabButton(2, 'هاب بات‌ها و وب‌هوک (Bot & API Hub)', Icons.hub_outlined),
                _buildTabButton(3, 'لاگ ممیزی و بکاپ (Audit & Backup)', Icons.security_outlined),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Render active tab
          if (_activeTab == 0)
            _buildRemoteConfigTab()
          else if (_activeTab == 1)
            _buildUsersRbacTab()
          else if (_activeTab == 2)
            _buildBotHubTab()
          else
            _buildAuditLogsTab(),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final colors = context.colors;
    final isSelected = _activeTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
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
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? colors.prt : colors.tx,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SubTab 0: Locales, Themes & Remote Config (with Store Reviewer Shield)
  Widget _buildRemoteConfigTab() {
    final colors = context.colors;
    final otaStrings = ref.watch(otaStringsProvider);
    final shield = ref.watch(storeReviewerShieldProvider);

    return Column(
      children: [
        // Store Reviewer Shield & Promo Banner Card
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
                      Icon(Icons.shield_outlined, color: colors.pr, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'شیلد ممیزی کافه‌بازار و اپ‌استور (Store Reviewer Shield)',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.tx,
                        ),
                      ),
                    ],
                  ),
                  AppBadge(
                    variant: shield.isShieldActive ? AppBadgeVariant.warning : AppBadgeVariant.standard,
                    child: Text(shield.isShieldActive ? 'شیلد بررسی فعال است' : 'حالت عادی پروداکشن'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'هنگام ارسال نسخه جدید به بازار یا اپ‌استور، این سوئیچ را فعال کنید تا صفحات پرداخت و محدودیت‌های سهمیه برای حساب‌های ارزیاب مخفی شود.',
                style: TextStyle(fontSize: 12, color: colors.mu),
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
                    AppSwitchTile(
                      label: 'فعال‌سازی شیلد ممیزی (Reviewer Bypass Mode)',
                      subtitle: 'غیرفعال‌سازی موقت درگاه‌های پرداخت برای بیلدنامبرهای در حال بررسی.',
                      value: shield.isShieldActive,
                      onChanged: (val) {
                        ref.read(storeReviewerShieldProvider.notifier).toggleShield(val);
                      },
                    ),
                    const Divider(height: 16),
                    AppTextField(
                      controller: _buildsController,
                      label: 'شماره بیلد‌های تحت بررسی (Comma-separated build numbers):',
                      onChanged: (val) {
                        ref.read(storeReviewerShieldProvider.notifier).setBuildNumbers(val);
                      },
                    ),
                    const Divider(height: 16),
                    AppSwitchTile(
                      label: 'نمایش بنر جشنواره شارژ کیف پول (Wallet Promo Banner)',
                      subtitle: 'نمایش نوار تخفیف و سکه هدیه در تب پروفایل و فروشگاه کلاینت‌ها.',
                      value: shield.promoBannerEnabled,
                      onChanged: (val) {
                        ref.read(storeReviewerShieldProvider.notifier).togglePromoBanner(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // OTA String Editor Table
        AppCard(
          padding: EdgeInsetsDirectional.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: colors.bg,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    _buildHeaderCell('کلید ترجمه (Key)', flex: 3),
                    _buildHeaderCell('فارسی (پیش‌فرض)', flex: 4),
                    _buildHeaderCell('عربی (العربية)', flex: 3),
                    _buildHeaderCell('انگلیسی (English)', flex: 3),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...otaStrings.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.bd.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          s.key,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.tx,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(s.defaultFa, style: TextStyle(fontSize: 12, color: colors.tx)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(s.ar, style: TextStyle(fontSize: 12, color: colors.tx)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(s.en, style: TextStyle(fontSize: 12, color: colors.tx)),
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

  // SubTab 1: Users, Sessions & Single-Device Revoke
  Widget _buildUsersRbacTab() {
    final colors = context.colors;
    final users = ref.watch(userRbacListProvider);
    final subAdmins = ref.watch(subAdminsProvider);

    return Column(
      children: [
        // Sub-Admins list
        AppCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مدیران فرعی و تفکیک دسترسی (Sub-Admins & Permissions)',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.tx,
                    ),
                  ),
                  AppButton(
                    text: 'افزودن مدیر جدید',
                    icon: const Icon(Icons.add, size: 16),
                    size: AppButtonSize.sm,
                    onPressed: _showAddSubAdminModal,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...subAdmins.map((adm) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.pr.withValues(alpha: 0.1),
                        child: Icon(Icons.admin_panel_settings, size: 18, color: colors.pr),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adm.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.tx)),
                            Text('${adm.email} • ${adm.roleTitle}', style: TextStyle(fontSize: 11, color: colors.mu)),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 4,
                        children: adm.permissions.map((p) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.pr.withValues(alpha: 0.08),
                              borderRadius: AppRadius.rSm,
                            ),
                            child: Text(p, style: TextStyle(fontSize: 10, color: colors.pr)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Device Sessions Table & Revoke Button
        AppCard(
          padding: EdgeInsetsDirectional.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: colors.bg,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    _buildHeaderCell('کاربر (UID / نام)', flex: 3),
                    _buildHeaderCell('دستگاه و نسخه سیستم‌عامل', flex: 3),
                    _buildHeaderCell('آدرس IP', flex: 2),
                    _buildHeaderCell('شناسه نشست فعال (Single-Device)', flex: 3),
                    _buildHeaderCell('عملیات امنیتی', flex: 2, alignEnd: true),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...users.map((u) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.bd.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      // User
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.displayName, style: TextStyle(fontWeight: FontWeight.bold, color: colors.tx)),
                            Text(u.uid, style: TextStyle(fontSize: 10, color: colors.mu)),
                          ],
                        ),
                      ),
                      // Device & OS
                      Expanded(
                        flex: 3,
                        child: Text('${u.deviceModel} (${u.osVersion})', style: TextStyle(fontSize: 11, color: colors.tx)),
                      ),
                      // IP
                      Expanded(
                        flex: 2,
                        child: Text(u.ipAddress, style: TextStyle(fontSize: 11, color: colors.tx)),
                      ),
                      // Session ID
                      Expanded(
                        flex: 3,
                        child: Text(
                          u.isSessionRevoked ? 'نشست لغو شد (Revoked)' : u.activeSessionId,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: u.isSessionRevoked ? const Color(0xFFDC2626) : colors.tx,
                          ),
                        ),
                      ),
                      // Revoke Button
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: u.isSessionRevoked
                              ? const AppBadge(
                                  variant: AppBadgeVariant.destructive,
                                  size: AppBadgeSize.sm,
                                  child: Text('لغو شده'),
                                )
                              : AppButton(
                                  text: 'لغو نشست دستگاه',
                                  size: AppButtonSize.sm,
                                  variant: AppButtonVariant.destructive,
                                  icon: const Icon(Icons.phonelink_erase, size: 14),
                                  onPressed: () {
                                    ref.read(userRbacListProvider.notifier).revokeSession(u.uid);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('نشست فعال کاربر ${u.displayName} لغو گردید و از اپلیکیشن خارج شد.'),
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
    );
  }

  // SubTab 2: Bot & Webhook Hub
  Widget _buildBotHubTab() {
    final colors = context.colors;
    final webhooks = ref.watch(botWebhooksProvider);

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'هاب اعلان‌ها و وب‌هوک‌های تلگرام و دیسکورد (Bot & API Hub)',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.tx,
                ),
              ),
              AppButton(
                text: 'افزودن وب‌هوک جدید',
                icon: const Icon(Icons.add, size: 16),
                size: AppButtonSize.sm,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فرم اتصال وب‌هوک جدید در دسترس است.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ارسال هشدارهای آنی خطا، عبور از سقف هزینه هوش مصنوعی و رویدادهای مدارقطع‌کن به کانال‌های دیسکورد و تلگرام',
            style: TextStyle(fontSize: 12, color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...webhooks.map((wh) {
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.pr.withValues(alpha: 0.1),
                      borderRadius: AppRadius.rMd,
                    ),
                    child: Icon(
                      wh.platform == 'Telegram' ? Icons.send : Icons.chat_bubble_outline,
                      color: colors.pr,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(wh.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.tx)),
                            const SizedBox(width: AppSpacing.sm),
                            AppBadge(
                              variant: wh.isOperational ? AppBadgeVariant.warning : AppBadgeVariant.info,
                              size: AppBadgeSize.sm,
                              child: Text(wh.isOperational ? 'عملیاتی / فرمان از راه دور' : 'فقط خواندنی (Alerts)'),
                            ),
                          ],
                        ),
                        Text(wh.url, style: TextStyle(fontSize: 10, color: colors.mu)),
                      ],
                    ),
                  ),
                  AppButton(
                    text: 'تست پینگ',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('پیام تستی با موفقیت به وب‌هوک ${wh.name} ارسال شد.')),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: wh.isActive,
                      activeThumbColor: colors.pr,
                      onChanged: (val) {
                        ref.read(botWebhooksProvider.notifier).toggleWebhook(wh.id);
                      },
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

  // SubTab 3: Immutable Audit Logs & PITR Backup
  Widget _buildAuditLogsTab() {
    final colors = context.colors;
    final auditLogs = ref.watch(auditLogsProvider);

    return AppCard(
      padding: EdgeInsetsDirectional.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: colors.bg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                _buildHeaderCell('شناسه لاگ و زمان', flex: 3),
                _buildHeaderCell('مجری و اپراتور', flex: 3),
                _buildHeaderCell('نوع عملیات (Action)', flex: 3),
                _buildHeaderCell('موجودیت هدف (Entity)', flex: 4),
                _buildHeaderCell('هش امضای دیجیتال (SHA-256)', flex: 3),
              ],
            ),
          ),
          const Divider(height: 1),
          ...auditLogs.map((log) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.bd.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  // Log ID & Time
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.logId, style: TextStyle(fontWeight: FontWeight.bold, color: colors.tx)),
                        Text(
                          log.timestamp.toIso8601String().split('T').join(' - ').substring(0, 19),
                          style: TextStyle(fontSize: 10, color: colors.mu),
                        ),
                      ],
                    ),
                  ),
                  // Operator
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.adminName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.tx)),
                        Text(log.ipAddress, style: TextStyle(fontSize: 10, color: colors.mu)),
                      ],
                    ),
                  ),
                  // Action Type
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.pr.withValues(alpha: 0.08),
                        borderRadius: AppRadius.rSm,
                      ),
                      child: Text(
                        log.actionType,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.pr),
                      ),
                    ),
                  ),
                  // Target Entity
                  Expanded(
                    flex: 4,
                    child: Text(log.targetEntity, style: TextStyle(fontSize: 11, color: colors.tx)),
                  ),
                  // SHA-256 Hash
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${log.sha256Hash.substring(0, 12)}...${log.sha256Hash.substring(log.sha256Hash.length - 8)}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
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
