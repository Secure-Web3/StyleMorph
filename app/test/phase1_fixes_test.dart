import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/domain/iso_location_data.dart';
import 'package:stylemorph/features/profile/presentation/widgets/searchable_location_picker_sheet.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  group('Always-Latin Geo Normalization & Picker Tests', () {
    test(
      'IsoLocationData normalizes localized country, province, and city to Latin',
      () {
        expect(
          IsoLocationData.normalizeCountryName('ایران', code: 'IR'),
          'Iran',
        );
        expect(IsoLocationData.normalizeCountryName('ترکیه'), 'Turkey');

        final iran = IsoLocationData.findByCode('IR')!;
        expect(IsoLocationData.normalizeProvinceName(iran, 'تهران'), 'Tehran');

        final tehranProv = IsoLocationData.findProvince(iran, name: 'تهران')!;
        expect(
          IsoLocationData.normalizeCityName(
            'تهران',
            country: iran,
            province: tehranProv,
          ),
          'Tehran',
        );
        expect(
          IsoLocationData.normalizeCityName('شیراز', country: iran),
          'Shiraz',
        );
      },
    );

    testWidgets(
      'Country picker displays Latin names even when app locale is Persian',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            locale: const Locale('fa'),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        SearchableLocationPickerSheet.showCountryPicker(
                          context,
                        ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Iran'), findsOneWidget);
        expect(find.text('ایران'), findsNothing);
      },
    );
  });
}
