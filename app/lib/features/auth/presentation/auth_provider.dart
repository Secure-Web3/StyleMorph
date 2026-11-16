import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth UI mode: toggling between Login and Signup.
/// This is a purely local UI state provider — no Firebase connection yet.
enum AuthMode { login, signup }

final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.login);

/// Password visibility toggle for the auth form.
final authPasswordVisibleProvider = StateProvider<bool>((ref) => false);

/// Background image URL — structured for future Remote Config injection.
/// When null, the WelcomeScreen renders a gradient placeholder.
final welcomeBackgroundUrlProvider = StateProvider<String?>((ref) => null);
