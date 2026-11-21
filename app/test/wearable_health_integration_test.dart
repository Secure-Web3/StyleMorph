import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/services/health_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/features/stylist/presentation/stylist_tab.dart';
import 'package:stylemorph/features/wellness/presentation/wellness_provider.dart';
import 'package:stylemorph/features/wellness/presentation/wellness_tab.dart';
import 'package:stylemorph/features/wellness/presentation/widgets/wearable_consent_sheet.dart';

Widget createTestWidget({
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = const Locale('fa'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLanguage.supportedLanguages
          .map((l) => l.locale)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(extensions: const [AppColors.lightWhite]),
      home: Directionality(
        textDirection:
            locale.languageCode == 'fa' || locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('Wearable & Smart Health Integration Unit Tests', () {
    test(
      '1. HealthService default state, device switching, and readiness',
      () async {
        final container = ProviderContainer();
        final healthService = container.read(healthServiceProvider.notifier);

        var state = container.read(healthServiceProvider);
        expect(state.isConnected, true);
        expect(state.sourceDevice, WearableDeviceType.galaxyWatch);
        expect(
          state.consentedScopes.contains(HealthPermissionScope.steps),
          true,
        );
        expect(
          state.consentedScopes.contains(HealthPermissionScope.sleep),
          true,
        );

        // Switch wearable device to Apple HealthKit
        healthService.setSourceDevice(WearableDeviceType.appleHealth);
        await Future<void>.delayed(const Duration(milliseconds: 350));
        state = container.read(healthServiceProvider);
        expect(state.sourceDevice, WearableDeviceType.appleHealth);
        expect(state.lastSyncedAt, isNotNull);

        container.dispose();
      },
    );

    test('2. Granular Privacy Consent filtering (Privacy by Design)', () async {
      final container = ProviderContainer();
      final healthService = container.read(healthServiceProvider.notifier);

      // Initially all 5 scopes consented
      var contextMap = container.read(healthServiceProvider).toGatewayContext();
      expect(contextMap.containsKey('sleepHours'), true);
      expect(contextMap.containsKey('steps'), true);
      expect(contextMap.containsKey('heartRateBpm'), true);

      // Revoke sleep and heart rate consent individually
      healthService.setScopeConsent(HealthPermissionScope.sleep, false);
      healthService.setScopeConsent(HealthPermissionScope.heartRate, false);

      final updatedState = container.read(healthServiceProvider);
      expect(
        updatedState.consentedScopes.contains(HealthPermissionScope.sleep),
        false,
      );
      expect(
        updatedState.consentedScopes.contains(HealthPermissionScope.heartRate),
        false,
      );

      contextMap = updatedState.toGatewayContext();
      // Omitted from AI context
      expect(contextMap.containsKey('sleepHours'), false);
      expect(contextMap.containsKey('heartRateBpm'), false);
      // Still present
      expect(contextMap.containsKey('steps'), true);

      container.dispose();
    });

    test('3. Wearable biometric sync updates WellnessScore ring', () async {
      final container = ProviderContainer();
      final wellnessNotifier = container.read(wellnessProvider.notifier);
      final healthState = container.read(healthServiceProvider);

      // Initial wellness health score
      final initialScore = container.read(wellnessProvider).healthScore.total;
      expect(initialScore, isPositive);

      // Apply wearable telemetry sync
      wellnessNotifier.applyWearableHealthSync(healthState);
      final updatedScore = container.read(wellnessProvider).healthScore;
      expect(updatedScore.total, healthState.energyReadinessScore);

      container.dispose();
    });
  });

  group('Wearable Wellness & Stylist UI Widget Tests', () {
    testWidgets(
      '4. WellnessTab displays WearableSyncCard with connected badge',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));

        await tester.pumpWidget(createTestWidget(child: const WellnessTab()));
        await tester.pumpAndSettle();

        // Verify presence of wearable card and title
        expect(
          find.text('اتصال ساعت هوشمند و سلامت'),
          findsNothing,
        ); // Inside card or sheet
        expect(find.text('همگام‌سازی فوری'), findsOneWidget);
        expect(find.text('مدیریت مجوزها'), findsOneWidget);
        expect(find.text('متصل'), findsOneWidget);
      },
    );

    testWidgets(
      '5. HealthConsentSheet opens and allows toggling granular permissions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));

        await tester.pumpWidget(
          createTestWidget(child: const HealthConsentSheet()),
        );
        await tester.pumpAndSettle();

        // Verify title & device options
        expect(find.text('تنظیمات حریم خصوصی و اتصال گجت'), findsOneWidget);
        expect(find.text('Samsung Health'), findsOneWidget);
        expect(find.text('Apple HealthKit'), findsOneWidget);
        expect(find.text('Google Health Connect'), findsOneWidget);

        // Verify 5 granular permission labels
        expect(find.text('گام‌ها و مسافت پیاده‌روی'), findsOneWidget);
        expect(find.text('خواب شبانه و کیفیت خواب عمیق'), findsOneWidget);
        expect(find.text('ضربان قلب لحظه‌ای و استراحت'), findsOneWidget);
        expect(find.text('ثبت وزن ترازوی هوشمند'), findsOneWidget);
        expect(find.text('کالری فعال روزانه'), findsOneWidget);
      },
    );

    testWidgets(
      '6. StylistTab renders Biometric Health Context Insight Banner',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));

        await tester.pumpWidget(createTestWidget(child: const StylistTab()));
        await tester.pumpAndSettle();

        // Verify biometric insight banner
        expect(find.text('پیشنهاد هوشمند بر اساس سلامت شما'), findsOneWidget);
        expect(find.text('Galaxy Watch 6 / 7'), findsOneWidget);
      },
    );
  });
}
