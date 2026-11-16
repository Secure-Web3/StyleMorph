import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth UI mode: toggling between Login, Signup, and Forgot Password views.
/// Purely local UI state provider — no Firebase connection yet.
enum AuthMode { login, signup, forgotPassword }

final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.login);

/// Password visibility toggle for the auth form.
final authPasswordVisibleProvider = StateProvider<bool>((ref) => false);

/// Confirm password visibility toggle.
final authConfirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);

/// Background image URL — structured for future Remote Config injection.
/// When null, the WelcomeScreen renders a gradient placeholder.
final welcomeBackgroundUrlProvider = StateProvider<String?>((ref) => null);

@immutable
class PasswordValidationState {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordValidationState({
    this.hasMinLength = false,
    this.hasUppercase = false,
    this.hasLowercase = false,
    this.hasDigit = false,
    this.hasSpecialChar = false,
  });

  factory PasswordValidationState.validate(String password) {
    return PasswordValidationState(
      hasMinLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasDigit: RegExp(r'[0-9]').hasMatch(password),
      hasSpecialChar: RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_=+]').hasMatch(password),
    );
  }

  int get metRulesCount {
    var count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigit) count++;
    if (hasSpecialChar) count++;
    return count;
  }

  double get strengthFraction => metRulesCount / 5.0;

  bool get isValid => metRulesCount == 5;
}
