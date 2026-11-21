import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';

class WeeklyPlannerSheet extends StatelessWidget {
  const WeeklyPlannerSheet({super.key});

  static const _days = [
    ('شنبه', 'ست راحت شهری', '#3b6ea5'),
    ('یکشنبه', 'ست بهاره روشن', '#c0392b'),
    ('دوشنبه', 'ست ساده و گرم', '#222222'),
    ('سه‌شنبه', 'ست راحت شهری', '#3b6ea5'),
    ('چهارشنبه', 'ست بهاره روشن', '#c0392b'),
    ('پنجشنبه', 'هنوز انتخاب نشده', '#8a8f94'),
    ('جمعه', 'هنوز انتخاب نشده', '#8a8f94'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _BaseSheetWrapper(
      title: strings.styWeeklyPlanner,
      actionLabel: strings.styAddCalEvent,
      onAction: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.tr('مناسبت جدید با تقویم گوشی همگام‌سازی شد.'),
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        );
      },
      child: Column(
        children: _days.map((d) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.bd),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  child: Text(
                    strings.tr(d.$1),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(d.$3.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    strings.tr(d.$2),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      color: d.$2 == 'هنوز انتخاب نشده' ? colors.mu : colors.tx,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: colors.mu,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StyleAndColorSheet extends StatelessWidget {
  const StyleAndColorSheet({super.key});

  static const _palette = [
    '#c9a227',
    '#7a5230',
    '#4f7a5a',
    '#d6bf9b',
    '#c0392b',
    '#1f2f56',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _BaseSheetWrapper(
      title: strings.styStylePaletteTitle,
      actionLabel: strings.styUpdatePhotoBtn,
      onAction: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.bd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tr('پالت رنگ سازگار (زیرتن گرم)'),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _palette.map((hex) {
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.bd),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FeatureTile(
            icon: Icons.checkroom_rounded,
            title: strings.tr('فرم لباس مناسب'),
            subtitle: strings.tr('بر اساس تیپ اندام و AI DNA'),
            colors: colors,
          ),
          _FeatureTile(
            icon: Icons.visibility_outlined,
            title: strings.tr('عینک و اکسسوری'),
            subtitle: strings.tr('متناسب با فرم بیضی چهره'),
            colors: colors,
          ),
          _FeatureTile(
            icon: Icons.content_cut_rounded,
            title: strings.tr('مدل مو و ریش'),
            subtitle: strings.tr('هماهنگ با سبک کژوال و رسمی'),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class SmartShoppingSheet extends StatelessWidget {
  const SmartShoppingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _BaseSheetWrapper(
      title: strings.stySmartShoppingTitle,
      actionLabel: strings.styViewInShop,
      onAction: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr(
              'آیتم‌هایی که کمد شما را کامل‌تر می‌کنند (بر اساس ست‌های فعلی):',
            ),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: colors.mu,
            ),
          ),
          const SizedBox(height: 10),
          _ShoppingItemTile(
            title: strings.tr('کت خنثی طوسی'),
            subtitle: strings.tr('با ۶ لباس شما ست می‌شود'),
            colorHex: '#8a8f94',
            icon: Icons.person_pin_rounded,
            colors: colors,
          ),
          _ShoppingItemTile(
            title: strings.tr('کفش رسمی مشکی'),
            subtitle: strings.tr('برای ۴ ست رسمی کمد خالی است'),
            colorHex: '#222222',
            icon: Icons.snowshoeing_rounded,
            colors: colors,
          ),
          _ShoppingItemTile(
            title: strings.tr('شال سبز نخی'),
            subtitle: strings.tr('لایه تکمیلی پالت گرم شما'),
            colorHex: '#4f7a5a',
            icon: Icons.style_outlined,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class StyleStatsSheet extends StatelessWidget {
  const StyleStatsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _BaseSheetWrapper(
      title: strings.styStatsTitle,
      actionLabel: strings.styGetReport,
      onAction: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.bd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tr('پرپوش‌ترین رنگ‌های کمد شما'),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
                const SizedBox(height: 8),
                _StatBar(label: strings.tr('آبی'), pct: 0.80, colors: colors),
                _StatBar(label: strings.tr('مشکی'), pct: 0.65, colors: colors),
                _StatBar(label: strings.tr('بژ'), pct: 0.40, colors: colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.tr('آیتم‌های فراموش‌شده در کمد:'),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: 6),
          _ForgottenItemTile(
            title: strings.tr('مانتو بژ کتان'),
            days: strings.tr('۶۵ روز بدون استفاده'),
            colors: colors,
          ),
          _ForgottenItemTile(
            title: strings.tr('کیف مجلسی نقره‌ای'),
            days: strings.tr('۴۸ روز بدون استفاده'),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _BaseSheetWrapper extends StatelessWidget {
  const _BaseSheetWrapper({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetShell(
      title: title,
      bottomBar: AppButton(
        isFullWidth: true,
        text: actionLabel,
        onPressed: onAction,
      ),
      child: child,
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.subtle,
      borderRadius: AppRadius.rLg,
      margin: const EdgeInsetsDirectional.only(bottom: 6),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.pr),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    color: colors.mu,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, size: 16, color: colors.mu),
        ],
      ),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  const _ShoppingItemTile({
    required this.title,
    required this.subtitle,
    required this.colorHex,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final String colorHex;
  final IconData icon;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.subtle,
      borderRadius: AppRadius.rLg,
      margin: const EdgeInsetsDirectional.only(bottom: 6),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(
                int.parse(colorHex.replaceFirst('#', '0xFF')),
              ).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    color: colors.mu,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_outward_rounded, size: 14, color: colors.mu),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.pct,
    required this.colors,
  });

  final String label;
  final double pct;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                color: colors.mu,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: colors.bd,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2B7A78),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.strings.formatPercent((pct * 100).toInt()),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgottenItemTile extends StatelessWidget {
  const _ForgottenItemTile({
    required this.title,
    required this.days,
    required this.colors,
  });

  final String title;
  final String days;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.bd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.tx,
            ),
          ),
          Text(
            days,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              color: colors.orColor,
            ),
          ),
        ],
      ),
    );
  }
}
