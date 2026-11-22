import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/utils/password_generator.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';

void main() {
  group('Password Generator & 8-Character Minimum Tests', () {
    test(
      'generateStrongPassword produces valid 12-char cryptographically strong password',
      () {
        final hasUpper = RegExp(r'[A-Z]');
        final hasLower = RegExp(r'[a-z]');
        final hasDigit = RegExp(r'[0-9]');
        final hasSpecial = RegExp(r'[!@#\$%^&*()_\-+=\[\]{}|;:,.<>?]');

        for (var i = 0; i < 50; i++) {
          final password = generateStrongPassword(12);

          expect(password.length, 12);
          expect(
            hasUpper.hasMatch(password),
            isTrue,
            reason: 'Must contain uppercase',
          );
          expect(
            hasLower.hasMatch(password),
            isTrue,
            reason: 'Must contain lowercase',
          );
          expect(
            hasDigit.hasMatch(password),
            isTrue,
            reason: 'Must contain digit',
          );
          expect(
            hasSpecial.hasMatch(password),
            isTrue,
            reason: 'Must contain special char',
          );

          final validation = PasswordValidationState.validate(password);
          expect(validation.hasMinLength, isTrue);
          expect(validation.hasUppercase, isTrue);
          expect(validation.hasLowercase, isTrue);
          expect(validation.hasDigit, isTrue);
          expect(validation.hasSpecialChar, isTrue);
          expect(validation.isValid, isTrue);
          expect(validation.metRulesCount, 5);
        }
      },
    );

    test(
      'Strict 8-character minimum enforcement in PasswordValidationState',
      () {
        // Less than 8 characters must fail length check
        expect(PasswordValidationState.validate('').hasMinLength, isFalse);
        expect(
          PasswordValidationState.validate('1234567').hasMinLength,
          isFalse,
        );
        expect(PasswordValidationState.validate('Aa1!').hasMinLength, isFalse);
        expect(
          PasswordValidationState.validate('Aa1!567').hasMinLength,
          isFalse,
        );

        // 8 or more characters must pass length check
        expect(
          PasswordValidationState.validate('12345678').hasMinLength,
          isTrue,
        );
        expect(
          PasswordValidationState.validate('Pass123!').hasMinLength,
          isTrue,
        );
        expect(
          PasswordValidationState.validate('LongerPassword123!').hasMinLength,
          isTrue,
        );
      },
    );
  });

  group('Simple vs. Advanced App Mode State & Model Tests', () {
    test('UserPreferences defaults to simple mode', () {
      const prefs = UserPreferences();
      expect(prefs.appMode, 'simple');
      expect(prefs.isSimpleMode, isTrue);
      expect(prefs.isAdvancedMode, isFalse);
    });

    test('UserPreferences serialization preserves appMode', () {
      const advancedPrefs = UserPreferences(appMode: 'advanced');
      expect(advancedPrefs.isAdvancedMode, isTrue);
      expect(advancedPrefs.isSimpleMode, isFalse);

      final map = advancedPrefs.toMap();
      expect(map['appMode'], 'advanced');

      final restored = UserPreferences.fromMap(map);
      expect(restored.appMode, 'advanced');
      expect(restored.isAdvancedMode, isTrue);
      expect(restored.isSimpleMode, isFalse);
    });

    test('AppState reflects appMode correctly and defaults to simple', () {
      const defaultState = AppState();
      expect(defaultState.preferences.appMode, 'simple');
      expect(defaultState.isSimpleMode, isTrue);
      expect(defaultState.isAdvancedMode, isFalse);

      final advancedState = defaultState.copyWith(
        preferences: defaultState.preferences.copyWith(appMode: 'advanced'),
      );
      expect(advancedState.isSimpleMode, isFalse);
      expect(advancedState.isAdvancedMode, isTrue);
    });

    test('AppStateNotifier toggles appMode between simple and advanced', () {
      final notifier = AppStateNotifier();
      expect(notifier.state.isSimpleMode, isTrue);

      notifier.setAppMode('advanced');
      expect(notifier.state.preferences.appMode, 'advanced');
      expect(notifier.state.isAdvancedMode, isTrue);
      expect(notifier.state.isSimpleMode, isFalse);

      notifier.setAppMode('simple');
      expect(notifier.state.preferences.appMode, 'simple');
      expect(notifier.state.isSimpleMode, isTrue);
      expect(notifier.state.isAdvancedMode, isFalse);
    });
  });
}
