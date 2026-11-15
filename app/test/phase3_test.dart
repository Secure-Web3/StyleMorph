import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/features/stylist/domain/stylist_models.dart';
import 'package:stylemorph/features/stylist/data/stylist_repository.dart';
import 'package:stylemorph/features/stylist/presentation/stylist_provider.dart';
import 'package:stylemorph/features/stylist/presentation/stylist_tab.dart';
import 'package:stylemorph/features/atelier/domain/atelier_models.dart';
import 'package:stylemorph/features/atelier/data/atelier_repository.dart';
import 'package:stylemorph/features/atelier/presentation/atelier_provider.dart';
import 'package:stylemorph/features/atelier/presentation/atelier_tab.dart';
import 'package:stylemorph/features/wellness/data/wellness_repository.dart';
import 'package:stylemorph/features/wellness/presentation/wellness_provider.dart';
import 'package:stylemorph/features/wellness/presentation/wellness_tab.dart';

void main() {
  group('Phase 3: Stylist & Virtual Try-On Tests', () {
    test('StylistRepository returns initial outfits and chat messages', () {
      final repo = StylistRepository();
      final outfits = repo.getOutfits();
      final messages = repo.getInitialMessages();

      expect(outfits.isNotEmpty, true);
      expect(messages.isNotEmpty, true);
      expect(outfits.first.title, 'ست راحت شهری');
    });

    test('TryOnTier coin costs match strict architecture rules', () {
      expect(TryOnTier.fast.coinCost, 5);
      expect(TryOnTier.standard.coinCost, 10);
      expect(TryOnTier.cinematic.coinCost, 20);
    });

    test('StylistNotifier filters by occasion and toggles lock/save', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stylistProvider.notifier);
      final initialCount =
          container.read(stylistProvider).filteredOutfits.length;

      // Filter by 'کار'
      notifier.setOccasion('کار');
      expect(container.read(stylistProvider).activeOccasion, 'کار');

      // Reset to 'روزمره'
      notifier.setOccasion('روزمره');
      expect(
        container.read(stylistProvider).filteredOutfits.length,
        initialCount,
      );

      // Lock toggle
      notifier.toggleLock('outfit_1');
      expect(
        container
            .read(stylistProvider)
            .outfits
            .firstWhere((o) => o.id == 'outfit_1')
            .isLocked,
        true,
      );

      // Save toggle
      notifier.toggleSave('outfit_1');
      expect(
        container
            .read(stylistProvider)
            .outfits
            .firstWhere((o) => o.id == 'outfit_1')
            .isSaved,
        true,
      );
    });

    testWidgets('StylistTab renders properly with occasion pills and actions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fa'),
            supportedLocales:
                AppLanguage.supportedLanguages.map((l) => l.locale).toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              extensions: const [AppColors.lightWhite],
            ),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: StylistTab(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('۱۸° آفتابی'), findsOneWidget);
      expect(find.text('روزمره'), findsOneWidget);
      expect(find.text('کار'), findsOneWidget);
      expect(find.text('پرو'), findsWidgets);
      expect(find.text('رامین (استایلیست)'), findsOneWidget);
    });
  });

  group('Phase 3: Virtual Atelier Tests', () {
    test('AtelierRepository loads 10 templates and creations', () {
      final repo = AtelierRepository();
      final templates = repo.getTemplates();
      final creations = repo.getCreations();

      expect(templates.length, 10);
      expect(creations.length, 4);
    });

    test('AtelierNotifier switches tabs and filters creations by status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(atelierProvider.notifier);
      expect(container.read(atelierProvider).activeTab, 'showcase');

      notifier.switchTab('creations');
      expect(container.read(atelierProvider).activeTab, 'creations');

      notifier.setCreationsFilter('p');
      expect(container.read(atelierProvider).creationsFilter, 'p');
      expect(
        container.read(atelierProvider).filteredCreations.every((c) =>
            c.status == CreationStatus.queue ||
            c.status == CreationStatus.processing),
        true,
      );
    });

    testWidgets('AtelierTab renders showcase grid and template cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fa'),
            supportedLocales:
                AppLanguage.supportedLanguages.map((l) => l.locale).toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              extensions: const [AppColors.lightWhite],
            ),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: AtelierTab(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ویترین'), findsOneWidget);
      expect(find.text('ساخته‌های من'), findsOneWidget);
      expect(find.text('پرتره استودیویی کلاسیک'), findsOneWidget);
    });
  });

  group('Phase 3: Wellness & Beauty Tests', () {
    test('WellnessRepository returns 3 scores and tasks', () {
      final repo = WellnessRepository();
      final beauty = repo.getBeautyScore();
      final health = repo.getHealthScore();
      final mind = repo.getMindScore();
      final tasks = repo.getTasks();

      expect(beauty.total, 80);
      expect(health.total, 85);
      expect(mind.total, 70);
      expect(tasks.length, 3);
    });

    test('WellnessNotifier toggles task completion and private mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(wellnessProvider.notifier);
      expect(container.read(wellnessProvider).isPrivateMode, false);

      notifier.togglePrivateMode();
      expect(container.read(wellnessProvider).isPrivateMode, true);

      final task = container.read(wellnessProvider).tasks.first;
      final initialDone = task.isDone;

      notifier.toggleTask(task.id);
      expect(
        container
            .read(wellnessProvider)
            .tasks
            .firstWhere((t) => t.id == task.id)
            .isDone,
        !initialDone,
      );
    });

    test('Future Self Simulation deducts 10 coins as per architecture', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCoins = container.read(appStateProvider).coins;
      final notifier = container.read(wellnessProvider.notifier);

      notifier.runFutureSelfSimulation();
      expect(container.read(appStateProvider).coins, initialCoins - 10);
    });

    testWidgets(
        'WellnessTab renders 3 score rings and routine items with zero ads',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fa'),
            supportedLocales:
                AppLanguage.supportedLanguages.map((l) => l.locale).toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              extensions: const [AppColors.lightWhite],
            ),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: WellnessTab(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('زیبایی'), findsWidgets);
      expect(find.text('تندرستی'), findsWidgets);
      expect(find.text('روان'), findsWidgets);
      expect(find.text('بینش امروز هوش مصنوعی'), findsOneWidget);
      expect(find.text('مشاهده روتین پوستی'), findsOneWidget);

      // Verify ZERO ads are displayed
      expect(find.text('تبلیغ'), findsNothing);
      expect(find.text('اسپانسر'), findsNothing);
    });
  });
}
