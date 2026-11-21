import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/email_verification_gate.dart';
import '../wellness_provider.dart';

// ─────────────────────────────────────────────
// 1. Beauty Detail Sheet
// ─────────────────────────────────────────────
class BeautyDetailSheet extends StatelessWidget {
  const BeautyDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _WellnessSheetBase(
      title: strings.wellBeautySheetTitle,
      actionLabel: strings.tr('به‌روزرسانی تحلیل از عکس'),
      onAction: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.bd),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _ScoreCircle(
                      score: 80,
                      color: const Color(0xFFC2547A),
                      colors: colors,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${strings.tasksProgress(80, 100)} · ${strings.tr('وضعیت خوب')}',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.tx,
                            ),
                          ),
                          Text(
                            strings.tr(
                              'بر اساس روتین مراقبت و عکس‌های پروفایل شما؛ قضاوتی درباره چهره نیست.',
                            ),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              color: colors.mu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SubScoreBar(
                  label: strings.tr('مراقبت منظم'),
                  score: 75,
                  color: const Color(0xFFC2547A),
                  colors: colors,
                ),
                _SubScoreBar(
                  label: strings.tr('وضعیت پوست'),
                  score: 82,
                  color: const Color(0xFFC2547A),
                  colors: colors,
                ),
                _SubScoreBar(
                  label: strings.tr('وضعیت مو'),
                  score: 84,
                  color: const Color(0xFFC2547A),
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            strings.tr('روتین‌های امروز شما'),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppBadge(
                size: AppBadgeSize.sm,
                child: Text(strings.tr('صبح: شست‌وشو و آبرسان')),
              ),
              AppBadge(
                size: AppBadgeSize.sm,
                child: Text(strings.tr('شب: پاک‌کننده ملایم و کرم شب')),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ActionTileItem(
            icon: Icons.water_drop_rounded,
            title: strings.tr('تحلیل عمیق پوست و مو'),
            subtitle: strings.tr('نوع پوست، رطوبت و نیازهای فصلی'),
            colors: colors,
          ),
          _ActionTileItem(
            icon: Icons.spa_rounded,
            title: strings.tr('مشاوره زیبایی هوشمند'),
            subtitle: strings.tr('راهکارهای مراقبت غیرتهاجمی'),
            colors: colors,
          ),
          _ActionTileItem(
            icon: Icons.calendar_month_rounded,
            title: strings.tr('تقویم مراقبت و روتین‌ها'),
            subtitle: strings.tr('یادآوری‌های هوشمند روزانه'),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. Health & Fitness Detail Sheet
// ─────────────────────────────────────────────
class HealthDetailSheet extends StatefulWidget {
  const HealthDetailSheet({super.key});

  @override
  State<HealthDetailSheet> createState() => _HealthDetailSheetState();
}

class _HealthDetailSheetState extends State<HealthDetailSheet> {
  String _activeTab = 'diet'; // 'diet', 'sleep', 'workout'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _WellnessSheetBase(
      title: strings.wellHealthSheetTitle,
      actionLabel: strings.tr('ثبت اطلاعات امروز'),
      onAction: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.bd),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _ScoreCircle(
                      score: 85,
                      color: const Color(0xFF4F7A5A),
                      colors: colors,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${strings.tasksProgress(85, 100)} · ${strings.tr('وضعیت عالی')}',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.tx,
                            ),
                          ),
                          Text(
                            strings.tr(
                              'بر اساس خواب، تغذیه و فعالیت‌های هفته اخیر شما.',
                            ),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              color: colors.mu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SubScoreBar(
                  label: strings.tr('کیفیت خواب'),
                  score: 88,
                  color: const Color(0xFF4F7A5A),
                  colors: colors,
                ),
                _SubScoreBar(
                  label: strings.tr('تغذیه'),
                  score: 80,
                  color: const Color(0xFF4F7A5A),
                  colors: colors,
                ),
                _SubScoreBar(
                  label: strings.tr('فعالیت بدنی'),
                  score: 82,
                  color: const Color(0xFF4F7A5A),
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sub-tabs segmented switcher
          AppSegmentedControl<String>(
            expand: true,
            value: _activeTab,
            onChanged: (val) => setState(() => _activeTab = val),
            items: [
              AppSegmentItem(value: 'diet', label: strings.tr('تغذیه')),
              AppSegmentItem(value: 'sleep', label: strings.tr('خواب')),
              AppSegmentItem(value: 'workout', label: strings.tr('ورزش')),
            ],
          ),
          const SizedBox(height: 12),

          if (_activeTab == 'diet') ...[
            _ActionTileItem(
              icon: Icons.restaurant_rounded,
              title: strings.tr('پیشنهاد وعده غذایی سالم'),
              subtitle: strings.tr('بر اساس هدف تناسب اندام و کالری مناسب'),
              colors: colors,
            ),
            _ActionTileItem(
              icon: Icons.add_circle_outline_rounded,
              title: strings.tr('ثبت سریع وعده روزانه'),
              subtitle: strings.tr('عکس یا متن برای بررسی خودکار هوش مصنوعی'),
              colors: colors,
            ),
          ] else if (_activeTab == 'sleep') ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.bd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        strings.tr('کیفیت خواب'),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                      Text(
                        strings.tasksProgress(88, 100),
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        strings.tr('مدت خواب دیشب'),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                      Text(
                        strings.tr('۷ ساعت'),
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ActionTileItem(
              icon: Icons.bed_rounded,
              title: strings.tr('ساعت پیشنهادی خواب'),
              subtitle: strings.tr('۲۳:۰۰ برای هماهنگی ریتم شبانه‌روزی'),
              colors: colors,
            ),
          ] else ...[
            // Workout week row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'].map((day) {
                final isPassed = day == 'ش' || day == 'ی' || day == 'د';
                return Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isPassed ? colors.pr : colors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.bd),
                  ),
                  child: Center(
                    child: Text(
                      strings.tr(day),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: isPassed ? colors.prt : colors.tx,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            _ActionTileItem(
              icon: Icons.fitness_center_rounded,
              title: strings.tr('برنامه تمرین هفتگی'),
              subtitle: strings.tr('۴ روز در هفته تمرینات فانکشنال'),
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 3. Mind & Calm Detail Sheet
// ─────────────────────────────────────────────
class MindDetailSheet extends StatelessWidget {
  const MindDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _WellnessSheetBase(
      title: strings.wellMindSheetTitle,
      actionLabel: strings.tr('ثبت حال امروز'),
      onAction: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.bd),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _ScoreCircle(
                      score: 70,
                      color: const Color(0xFF6B5FB5),
                      colors: colors,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${strings.tasksProgress(70, 100)} · ${strings.tr('وضعیت متعادل')}',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.tx,
                            ),
                          ),
                          Text(
                            strings.tr(
                              'بر اساس ثبت خلق‌وخو، خواب و استرس روزانه؛ تشخیص پزشکی نیست.',
                            ),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              color: colors.mu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SubScoreBar(
                  label: strings.tr('خلق‌وخو'),
                  score: 72,
                  color: const Color(0xFF6B5FB5),
                  colors: colors,
                ),
                _SubScoreBar(
                  label: strings.tr('کنترل استرس'),
                  score: 65,
                  color: const Color(0xFF6B5FB5),
                  colors: colors,
                ),
                _SubScoreBar(
                  label: strings.tr('کیفیت استراحت'),
                  score: 74,
                  color: const Color(0xFF6B5FB5),
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _ActionTileItem(
            icon: Icons.air_rounded,
            title: strings.tr('تمرین تنفس ۳ دقیقه‌ای'),
            subtitle: strings.tr('آرام‌سازی فوری ذهن با ضرباهنگ ۴-۴-۴'),
            colors: colors,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    strings.tr(
                      'تمرین تنفس آرام‌بخش شروع شد. ۴ ثانیه دم، ۴ ثانیه حبس، ۴ ثانیه بازدم.',
                    ),
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                ),
              );
            },
          ),
          _ActionTileItem(
            icon: Icons.self_improvement_rounded,
            title: strings.tr('مدیتیشن و مایندفولنس'),
            subtitle: strings.tr('جلسات ۵ و ۱۰ دقیقه‌ای صوتی'),
            colors: colors,
          ),
          _ActionTileItem(
            icon: Icons.chat_bubble_outline_rounded,
            title: strings.tr('گفتگو با همراه هوش مصنوعی'),
            subtitle: strings.tr('تخلیه ذهن در محیطی کاملاً خصوصی و امن'),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 4. Future Self Simulation Sheet
// ─────────────────────────────────────────────
class FutureSelfSheet extends ConsumerStatefulWidget {
  const FutureSelfSheet({super.key});

  @override
  ConsumerState<FutureSelfSheet> createState() => _FutureSelfSheetState();
}

class _FutureSelfSheetState extends ConsumerState<FutureSelfSheet> {
  String _timeframe = '۶ ماه';
  bool _accepted = false;
  bool _simulated = false;
  bool _inProgress = false;
  String? _error;

  Future<void> _runSimulation() async {
    if (!checkEmailVerificationGate(context, ref)) return;
    setState(() {
      _error = null;
      _inProgress = true;
    });
    try {
      await ref
          .read(wellnessProvider.notifier)
          .runFutureSelfSimulation(timeframe: _timeframe);
      if (mounted) {
        setState(() => _simulated = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _inProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final coins = ref.watch(appStateProvider).coins;
    final futureResult = ref.watch(wellnessProvider).lastFutureSelfResult;

    return _WellnessSheetBase(
      title: strings.wellFutureSheetTitle,
      actionLabel: _simulated
          ? strings.wellClose
          : _inProgress
          ? strings.tr('در حال پردازش...')
          : '${strings.tr('تأیید و اجرای شبیه‌ساز')} (${strings.coinsText(10)})',
      onAction: () {
        if (_simulated) {
          Navigator.pop(context);
        } else if (_accepted && !_inProgress) {
          _runSimulation();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.tr(
              'اگر به اهداف ورزشی و روتین‌های مراقبتی خود متعهد بمانید، چهره و اندام شما چه تغییری می‌کند؟',
            ),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: colors.tx,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Timeframe chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['۳ ماه', '۶ ماه', '۱ سال'].map((t) {
              return AppChip(
                label: strings.tr(t),
                isSelected: _timeframe == t,
                onTap: () => setState(() => _timeframe = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Visual Simulation Box
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.bd),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 40,
                        color: colors.mu,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.tr('وضعیت فعلی'),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: _simulated
                        ? colors.pr.withValues(alpha: 0.08)
                        : colors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _simulated ? colors.pr : colors.bd,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _simulated
                                ? Icons.auto_awesome_rounded
                                : Icons.lock_outline_rounded,
                            size: 40,
                            color: _simulated ? colors.pr : colors.mu,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _simulated
                                ? '${strings.tr('خودِ آینده')} (${strings.tr(_timeframe)})'
                                : strings.tr('پیش‌نمایش آینده'),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _simulated ? colors.tx : colors.mu,
                            ),
                          ),
                        ],
                      ),
                      if (_simulated)
                        PositionedDirectional(
                          bottom: 6,
                          start: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              futureResult != null
                                  ? '${futureResult.watermarkText} · ${strings.formatPercent(futureResult.anatomicalScorePercent)}'
                                  : strings.aiWatermarkBadge,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 7,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Realism and Ethics notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.tr(
                      'تغییرات پیش‌بینی‌شده کاملاً فیزیولوژیک و واقع‌بینانه هستند و هرگز چهره غیرواقعی تولید نمی‌کنند. این تحلیل جایگزین مشاوره پزشکی نیست.',
                    ),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (!_simulated)
            AppCheckboxTile(
              label:
                  '${strings.tr('می‌پذیرم که ۱۰ سکه کسر شود و نتیجه یک شبیه‌سازی آماری است.')} (${strings.balanceText(coins)})',
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v),
            ),

          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              strings.tr(_error!),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: colors.orColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 5. Daily Check-in Sheet
// ─────────────────────────────────────────────
class DailyCheckInSheet extends StatefulWidget {
  const DailyCheckInSheet({super.key});

  @override
  State<DailyCheckInSheet> createState() => _DailyCheckInSheetState();
}

class _DailyCheckInSheetState extends State<DailyCheckInSheet> {
  int _selectedMood = 4;
  String _energy = 'متوسط';
  String _sleep = '۶ تا ۸ ساعت';
  final _weightCtrl = TextEditingController();
  bool _weightInit = false;

  static const _moods = [
    (1, Icons.sentiment_very_dissatisfied_rounded),
    (2, Icons.sentiment_dissatisfied_rounded),
    (3, Icons.sentiment_neutral_rounded),
    (4, Icons.sentiment_satisfied_rounded),
    (5, Icons.sentiment_very_satisfied_rounded),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_weightInit) {
      _weightInit = true;
      _weightCtrl.text = context.strings.formatNumber('60.4');
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return _WellnessSheetBase(
      title: strings.wellCheckinSheetTitle,
      actionLabel: strings.tr('ذخیره در پرونده سلامت'),
      onAction: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.tr('اطلاعات روزانه با موفقیت در داشبورد ثبت شد.'),
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr('امروز چه حالی دارید؟'),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moods.map((m) {
              final isSel = _selectedMood == m.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = m.$1),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSel
                        ? colors.pr.withValues(alpha: 0.12)
                        : colors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? colors.pr : colors.bd,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    m.$2,
                    color: isSel ? colors.pr : colors.mu,
                    size: 24,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          Text(
            strings.tr('سطح انرژی امروز'),
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['کم', 'متوسط', 'زیاد'].map((e) {
              return AppChip(
                label: strings.tr(e),
                isSelected: _energy == e,
                onTap: () => setState(() => _energy = e),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          AppDropdown<String>(
            label: strings.tr('میزان خواب دیشب'),
            value: _sleep,
            items: ['کمتر از ۶ ساعت', '۶ تا ۸ ساعت', 'بیشتر از ۸ ساعت'].map((
              s,
            ) {
              return DropdownMenuItem(value: s, child: Text(strings.tr(s)));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _sleep = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            label: strings.tr('وزن امروز (کیلوگرم - اختیاری)'),
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Common Sheet Wrapper & Widgets
// ─────────────────────────────────────────────
class _WellnessSheetBase extends StatelessWidget {
  const _WellnessSheetBase({
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

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({
    required this.score,
    required this.color,
    required this.colors,
  });

  final int score;
  final Color color;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4.5,
            backgroundColor: colors.bd,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            context.strings.formatNumber(score),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubScoreBar extends StatelessWidget {
  const _SubScoreBar({
    required this.label,
    required this.score,
    required this.color,
    required this.colors,
  });

  final String label;
  final int score;
  final Color color;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 75,
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
                value: score / 100,
                minHeight: 5,
                backgroundColor: colors.bd,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.strings.formatNumber(score),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTileItem extends StatelessWidget {
  const _ActionTileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      variant: AppCardVariant.subtle,
      borderRadius: AppRadius.rLg,
      margin: const EdgeInsetsDirectional.only(bottom: 6),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.pr),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle(color: colors.tx)),
                Text(subtitle, style: AppTypography.caption(color: colors.mu)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: colors.mu),
        ],
      ),
    );
  }
}
