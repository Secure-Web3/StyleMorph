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

class AdMobSponsoringScreen extends ConsumerStatefulWidget {
  const AdMobSponsoringScreen({super.key});

  @override
  ConsumerState<AdMobSponsoringScreen> createState() =>
      _AdMobSponsoringScreenState();
}

class _AdMobSponsoringScreenState
    extends ConsumerState<AdMobSponsoringScreen> {
  final TextEditingController _watermarkTextController =
      TextEditingController();
  final TextEditingController _ssvUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sponsoring = ref.read(aiSponsoringConfigProvider);
    final admob = ref.read(adMobConfigProvider);
    _watermarkTextController.text = sponsoring.brandWatermarkText;
    _ssvUrlController.text = admob.rewardedSsvUrl;
  }

  @override
  void dispose() {
    _watermarkTextController.dispose();
    _ssvUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final admob = ref.watch(adMobConfigProvider);
    final sponsoring = ref.watch(aiSponsoringConfigProvider);
    final generosity = ref.watch(adaptiveGenerosityConfigProvider);

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
                      'تبلیغات درون‌برنامه‌ای و اسپانسرینگ مد (AdMob & AI Sponsoring)',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colors.tx,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تنظیمات تبلیغات ویدیویی جایزه‌دار (Rewarded SSV)، بنرهای بینابینی، واترمارک برندها و وزن تزریق کالا در هوش مصنوعی',
                      style: TextStyle(fontSize: 13, color: colors.mu),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppButton(
                text: 'ذخیره تنظیمات AdMob و حراجی',
                icon: const Icon(Icons.cloud_done_outlined, size: 16),
                size: AppButtonSize.sm,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF16A34A),
                      content: Text('پیکربندی تبلیغات و ضرایب اسپانسرینگ با موفقیت ذخیره شد.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // 1. ADMOB CONFIGURATION & SSV
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
                        Icon(Icons.monetization_on_outlined, color: colors.pr, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'پیکربندی شبکه تبلیغاتی گوگل ادموب (Google AdMob Network)',
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
                      variant: admob.isAdMobEnabled ? AppBadgeVariant.success : AppBadgeVariant.destructive,
                      child: Text(admob.isAdMobEnabled ? 'تبلیغات فعال است' : 'تبلیغات خاموش'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'تأیید سمت سرور (SSV) جهت اعطای امن سکه StyleCoin پس از تماشای کامل ویدیوی تبلیغاتی',
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
                      // Master AdMob Toggle
                      AppSwitchTile(
                        label: 'فعال‌سازی سراسری تبلیغات AdMob در اپلیکیشن (Master Switch)',
                        subtitle: 'در صورت غیرفعال بودن، هیچ تبلیغاتی به کاربران نمایش داده نمی‌شود.',
                        value: admob.isAdMobEnabled,
                        onChanged: (val) {
                          ref.read(adMobConfigProvider.notifier).toggleAdMob(val);
                        },
                      ),
                      const Divider(height: 16),

                      // Rewarded Video Settings
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تعداد سکه پاداش به ازای هر ویدیو:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.tx),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: admob.rewardedCoinsPerVideo > 5
                                          ? () {
                                              ref.read(adMobConfigProvider.notifier).updateRewarded(
                                                    coins: admob.rewardedCoinsPerVideo - 5,
                                                  );
                                            }
                                          : null,
                                    ),
                                    Text(
                                      '+${admob.rewardedCoinsPerVideo} سکه',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.pr),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        ref.read(adMobConfigProvider.notifier).updateRewarded(
                                              coins: admob.rewardedCoinsPerVideo + 5,
                                            );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'حداکثر سقف تماشای روزانه:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.tx),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: admob.rewardedDailyCap > 1
                                          ? () {
                                              ref.read(adMobConfigProvider.notifier).updateRewarded(
                                                    cap: admob.rewardedDailyCap - 1,
                                                  );
                                            }
                                          : null,
                                    ),
                                    Text(
                                      '${admob.rewardedDailyCap} ویدیو در روز',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.pr),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        ref.read(adMobConfigProvider.notifier).updateRewarded(
                                              cap: admob.rewardedDailyCap + 1,
                                            );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      // SSV Callback URL
                      AppTextField(
                        controller: _ssvUrlController,
                        label: 'آدرس کال‌بک سرور اختصاصی AdMob Server-Side Verification (SSV):',
                        onChanged: (val) {
                          ref.read(adMobConfigProvider.notifier).updateRewarded(ssvUrl: val);
                        },
                      ),
                      const Divider(height: 16),

                      // Interstitial Ads
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تکرار تبلیغات بینابینی (Interstitial Frequency Cap):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.tx),
                              ),
                              Text(
                                'هر ${admob.interstitialFrequency} بار تعویض صفحه اصلی، حداکثر یک بار در هر ۳ دقیقه',
                                style: TextStyle(fontSize: 11, color: colors.mu),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: admob.interstitialFrequency > 1
                                    ? () {
                                        ref.read(adMobConfigProvider.notifier).updateInterstitial(
                                              freq: admob.interstitialFrequency - 1,
                                            );
                                      }
                                    : null,
                              ),
                              Text(
                                '${admob.interstitialFrequency} صفحه',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.tx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  ref.read(adMobConfigProvider.notifier).updateInterstitial(
                                        freq: admob.interstitialFrequency + 1,
                                      );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 2. AI SPONSORING & PROMOTED PLACEMENT
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
                        Icon(Icons.auto_awesome_outlined, color: colors.pr, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'تزریق هوشمند کالاهای اسپانسرشده در هوش مصنوعی (AI Stylist Sponsoring)',
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
                      variant: AppBadgeVariant.active,
                      child: Text('ضریب تزریق: ${sponsoring.stylistRecommendationWeightPct}٪'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'تنظیم میزان اولویت پیشنهاد لباس‌های فروشندگان در پاسخ‌های استایلیست شخصی و آتلیه مد',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sponsoring Weight Slider
                      Text(
                        'وزن و احتمال پیشنهاد کالای فروشنده در پیشنهادات استایلیست (Stylist Weight):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.tx),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: sponsoring.stylistRecommendationWeightPct.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: colors.pr,
                              label: '${sponsoring.stylistRecommendationWeightPct}٪',
                              onChanged: (val) {
                                ref.read(aiSponsoringConfigProvider.notifier).setWeight(val.toInt());
                              },
                            ),
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              '${sponsoring.stylistRecommendationWeightPct}٪',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.pr),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Brand Watermark in Atelier Renders
                      AppSwitchTile(
                        label: 'درج واترمارک برند اسپانسر در رندرهای آتلیه (Sponsored Brand Watermark)',
                        subtitle: 'در پرتره‌های با تخفیف، لوگو و امضای برند شریک در تصویر ثبت می‌شود.',
                        value: sponsoring.sponsoredWatermarkEnabled,
                        onChanged: (val) {
                          ref.read(aiSponsoringConfigProvider.notifier).toggleWatermark(val);
                        },
                      ),
                      if (sponsoring.sponsoredWatermarkEnabled) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _watermarkTextController,
                          label: 'متن امضای برند و نشان تجاری اسپانسر:',
                          onChanged: (val) {
                            ref.read(aiSponsoringConfigProvider.notifier).setWatermarkText(val);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 3. ADAPTIVE GENEROSITY ENGINE
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
                        Icon(Icons.auto_graph_outlined, color: colors.pr, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'موتور سخاوت تطبیقی سکه (Adaptive Generosity Engine)',
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
                      variant: generosity.isEnabled
                          ? AppBadgeVariant.success
                          : AppBadgeVariant.warning,
                      child: Text(
                        generosity.isEnabled
                            ? 'سخاوت فعال (${generosity.currentMultiplier}x)'
                            : 'سخاوت غیرفعال',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'محاسبه خودکار نسبت درآمد تبلیغات به هزینه خدمات ابری هوش مصنوعی و تنظیم پویای سقف سکه رایگان روزانه',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSwitchTile(
                        label: 'فعال‌سازی الگوریتم سخاوت تطبیقی (Dynamic Daily Coin Cap)',
                        subtitle: 'تنظیم هوشمند سقف روزانه سکه بدون نیاز به مداخله دستی ادمین بر اساس سود خالص تبلیغات',
                        value: generosity.isEnabled,
                        onChanged: (val) {
                          ref.read(adaptiveGenerosityConfigProvider.notifier).toggleEnabled(val);
                        },
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نسبت هدف درآمد تبلیغات به هزینه AI (Target Ad/AI Ratio):',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.tx),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${generosity.targetAdToAiRatio.toStringAsFixed(1)}x (حاشیه سود ایمن)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.pr),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سقف سکه روزانه رایگان جاری:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.tx),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${generosity.dynamicDailyFreeCoins} سکه در روز',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 4. PERMANENT WELLNESS AD LOCK
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            borderColor: const Color(0xFF16A34A).withValues(alpha: 0.5),
            borderWidth: 1.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                            borderRadius: AppRadius.rSm,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'قفل دائمی حریم خصوصی بخش تندرستی (Permanent Wellness Ad Lock)',
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
                      child: Text('قفل غیرقابل تغییر (Hardcoded Guard)'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'به موجب منشور اخلاقی و پروتکل حفظ تمرکز و حریم خصوصی داده‌های سلامت کاربران در StyleMorph، کلیه جایگاه‌های تبلیغاتی (بنری، بینابینی، ویدیویی و اسپانسری) در ماژول تندرستی و زیبایی (Wellness & Beauty) و برای کلیه کاربران دارای اشتراک، به صورت قطعی و همیشگی در هر دو سطح کلاینت و سرور مسدود و قفل هستند.',
                  style: TextStyle(fontSize: 12, color: colors.mu, height: 1.6),
                ),
                const SizedBox(height: AppSpacing.lg),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.05),
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مسدودسازی کامل تبلیغات در ماژول تندرستی و زیبایی',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.tx,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'وضعیت: قفل شده در سطح هسته بیزینس، فایربیس ریموت کانفیگ و کلاینت فلاتر (Non-overridable)',
                              style: TextStyle(fontSize: 11, color: colors.mu),
                            ),
                          ],
                        ),
                      ),
                      const AppBadge(
                        variant: AppBadgeVariant.active,
                        child: Text('فعال و محافظت‌شده'),
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
}
