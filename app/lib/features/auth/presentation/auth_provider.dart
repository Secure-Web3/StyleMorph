import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/firebase_auth_repository.dart';
import '../../../core/services/session_persistence_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/welcome_persistence_service.dart';
import '../../../core/state/app_state.dart';
import '../domain/auth_repository.dart';

/// Auth UI mode: toggling between Login, Signup, and Forgot Password views.
enum AuthMode { login, signup, forgotPassword }

/// Background image URL — structured for future Remote Config injection.
final welcomeBackgroundUrlProvider = StateProvider<String?>((ref) => null);

/// Clean Architecture provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Real-time stream of the authenticated user's state.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Currently authenticated Firebase [User] or null.
final currentAuthUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value;
});

/// Helper boolean to check whether a session is actively authenticated.
final isUserAuthenticatedProvider = Provider<bool>((ref) {
  final authUser = ref.watch(currentAuthUserProvider);
  return authUser != null;
});

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

@immutable
class AuthFormState {
  final AuthMode mode;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final String email;
  final String password;
  final String confirmPassword;
  final String forgotEmail;
  final PasswordValidationState passwordValidation;
  final bool passwordsMatch;
  final bool isSubmitting;
  final String? errorCode;
  final String? successMessageKey;
  final bool rememberMe;

  const AuthFormState({
    this.mode = AuthMode.login,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.forgotEmail = '',
    this.passwordValidation = const PasswordValidationState(),
    this.passwordsMatch = true,
    this.isSubmitting = false,
    this.errorCode,
    this.successMessageKey,
    this.rememberMe = true,
  });

  AuthFormState copyWith({
    AuthMode? mode,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    String? email,
    String? password,
    String? confirmPassword,
    String? forgotEmail,
    PasswordValidationState? passwordValidation,
    bool? passwordsMatch,
    bool? isSubmitting,
    String? errorCode,
    bool clearError = false,
    String? successMessageKey,
    bool clearSuccess = false,
    bool? rememberMe,
  }) {
    return AuthFormState(
      mode: mode ?? this.mode,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      forgotEmail: forgotEmail ?? this.forgotEmail,
      passwordValidation: passwordValidation ?? this.passwordValidation,
      passwordsMatch: passwordsMatch ?? this.passwordsMatch,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      successMessageKey:
          clearSuccess ? null : (successMessageKey ?? this.successMessageKey),
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class AuthFormNotifier extends StateNotifier<AuthFormState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthFormNotifier(this._repository, this._ref) : super(const AuthFormState());

  void setMode(AuthMode mode) {
    state = state.copyWith(
      mode: mode,
      isPasswordVisible: false,
      isConfirmPasswordVisible: false,
      clearError: true,
      clearSuccess: true,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim(), clearError: true);
  }

  void setPassword(String value) {
    final validation = PasswordValidationState.validate(value);
    final match = state.confirmPassword.isEmpty || value == state.confirmPassword;
    state = state.copyWith(
      password: value,
      passwordValidation: validation,
      passwordsMatch: match,
      clearError: true,
    );
  }

  void setConfirmPassword(String value) {
    final match = value.isEmpty || value == state.password;
    state = state.copyWith(
      confirmPassword: value,
      passwordsMatch: match,
      clearError: true,
    );
  }

  void setForgotEmail(String value) {
    state = state.copyWith(forgotEmail: value.trim(), clearError: true);
  }

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<bool> _isCurrentDeviceBlocked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final sessionService = _ref.read(sessionServiceProvider);
      final deviceId = await sessionService.currentDeviceId();
      final isBlocked = await sessionService.isDeviceBlocked(user.uid, deviceId);
      if (isBlocked) {
        try {
          await _repository.signOut();
        } catch (_) {}
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        _ref.read(appStateProvider.notifier).logout();
        state = state.copyWith(
          isSubmitting: false,
          errorCode: 'device-blocked',
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Submits email and password for login.
  Future<bool> login() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(errorCode: 'invalid-credential');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _ref
          .read(sessionPersistenceServiceProvider)
          .applyPersistence(state.rememberMe);
      await _repository.signInWithEmailAndPassword(
        email: state.email,
        password: state.password,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.reload();
        } catch (_) {}
      }
      if (await _isCurrentDeviceBlocked()) return false;
      if (user != null) {
        await _ref.read(sessionServiceProvider).upsertSession();
        await _ref.read(appStateProvider.notifier).loadProfileFromFirestore();
        _ref.read(hasSeenWelcomeProvider.notifier).markSeen();
      }
      state = state.copyWith(isSubmitting: false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthFormNotifier] login FirebaseAuthException: ${e.code} — ${e.message}');
      state = state.copyWith(isSubmitting: false, errorCode: e.code);
      return false;
    } catch (e) {
      debugPrint('[AuthFormNotifier] login unexpected error: $e');
      state = state.copyWith(isSubmitting: false, errorCode: 'generic:$e');
      return false;
    }
  }

  /// Submits email and password for registration and Firestore provisioning.
  Future<bool> signup() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(errorCode: 'invalid-credential');
      return false;
    }

    if (!state.passwordValidation.isValid) {
      state = state.copyWith(errorCode: 'weak-password');
      return false;
    }

    if (state.password != state.confirmPassword) {
      state = state.copyWith(errorCode: 'password-mismatch');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _ref
          .read(sessionPersistenceServiceProvider)
          .applyPersistence(state.rememberMe);
      final credential = await _repository.createUserWithEmailAndPassword(
        email: state.email,
        password: state.password,
      );
      final user = credential.user ?? FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('[AuthFormNotifier] sendEmailVerification error: $e');
        }
      }
      if (await _isCurrentDeviceBlocked()) return false;
      if (user != null) {
        await _ref.read(sessionServiceProvider).upsertSession();
        await _ref.read(appStateProvider.notifier).loadProfileFromFirestore();
        _ref.read(hasSeenWelcomeProvider.notifier).markSeen();
      }
      state = state.copyWith(isSubmitting: false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthFormNotifier] signup FirebaseAuthException: ${e.code} — ${e.message}');
      state = state.copyWith(isSubmitting: false, errorCode: e.code);
      return false;
    } catch (e) {
      debugPrint('[AuthFormNotifier] signup unexpected error: $e');
      state = state.copyWith(isSubmitting: false, errorCode: 'generic:$e');
      return false;
    }
  }

  /// Authenticates using Google Sign-In and provisions Firestore record.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _ref
          .read(sessionPersistenceServiceProvider)
          .applyPersistence(state.rememberMe);
      final credential = await _repository.signInWithGoogle();
      if (credential == null) {
        state = state.copyWith(isSubmitting: false, errorCode: 'google-cancelled');
        return false;
      }
      if (await _isCurrentDeviceBlocked()) return false;
      await _ref.read(sessionServiceProvider).upsertSession();
      await _ref.read(appStateProvider.notifier).loadProfileFromFirestore();
      _ref.read(hasSeenWelcomeProvider.notifier).markSeen();
      state = state.copyWith(isSubmitting: false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthFormNotifier] signInWithGoogle FirebaseAuthException: ${e.code} — ${e.message}');
      state = state.copyWith(isSubmitting: false, errorCode: e.code);
      return false;
    } catch (e) {
      debugPrint('[AuthFormNotifier] signInWithGoogle unexpected error: $e');
      state = state.copyWith(isSubmitting: false, errorCode: 'generic:$e');
      return false;
    }
  }

  /// Authenticates using Apple Sign-In and provisions Firestore record.
  Future<bool> signInWithApple() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _ref
          .read(sessionPersistenceServiceProvider)
          .applyPersistence(state.rememberMe);
      final credential = await _repository.signInWithApple();
      if (credential == null) {
        state = state.copyWith(isSubmitting: false, errorCode: 'apple-cancelled');
        return false;
      }
      if (await _isCurrentDeviceBlocked()) return false;
      await _ref.read(sessionServiceProvider).upsertSession();
      await _ref.read(appStateProvider.notifier).loadProfileFromFirestore();
      _ref.read(hasSeenWelcomeProvider.notifier).markSeen();
      state = state.copyWith(isSubmitting: false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthFormNotifier] signInWithApple FirebaseAuthException: ${e.code} — ${e.message}');
      state = state.copyWith(isSubmitting: false, errorCode: e.code);
      return false;
    } catch (e) {
      debugPrint('[AuthFormNotifier] signInWithApple unexpected error: $e');
      state = state.copyWith(isSubmitting: false, errorCode: 'generic:$e');
      return false;
    }
  }

  /// Sends a password reset email via Firebase Auth.
  Future<bool> sendPasswordResetEmail() async {
    final email = state.forgotEmail.isNotEmpty ? state.forgotEmail : state.email;
    if (email.isEmpty) {
      state = state.copyWith(errorCode: 'invalid-email');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = state.copyWith(
        isSubmitting: false,
        successMessageKey: 'authResetEmailSent',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthFormNotifier] sendPasswordResetEmail FirebaseAuthException: ${e.code} — ${e.message}');
      state = state.copyWith(isSubmitting: false, errorCode: e.code);
      return false;
    } catch (e) {
      debugPrint('[AuthFormNotifier] sendPasswordResetEmail unexpected error: $e');
      state = state.copyWith(isSubmitting: false, errorCode: 'generic:$e');
      return false;
    }
  }
}

/// Main StateNotifier provider for authentication form state & operations.
final authFormProvider =
    StateNotifierProvider<AuthFormNotifier, AuthFormState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthFormNotifier(repo, ref);
});

/// Granular selectors
final authModeProvider = Provider<AuthMode>((ref) {
  return ref.watch(authFormProvider.select((s) => s.mode));
});

final authPasswordVisibleProvider = Provider<bool>((ref) {
  return ref.watch(authFormProvider.select((s) => s.isPasswordVisible));
});

final authConfirmPasswordVisibleProvider = Provider<bool>((ref) {
  return ref.watch(authFormProvider.select((s) => s.isConfirmPasswordVisible));
});

final authIsSubmittingProvider = Provider<bool>((ref) {
  return ref.watch(authFormProvider.select((s) => s.isSubmitting));
});
