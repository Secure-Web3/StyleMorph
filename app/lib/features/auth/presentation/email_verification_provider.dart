import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/state/app_state.dart';
import 'auth_provider.dart';
import 'email_verification_screen.dart';

@immutable
class EmailVerificationState {
  final bool isVerified;
  final bool isChecking;
  final bool isResending;
  final int cooldownSeconds;

  const EmailVerificationState({
    required this.isVerified,
    this.isChecking = false,
    this.isResending = false,
    this.cooldownSeconds = 0,
  });

  EmailVerificationState copyWith({
    bool? isVerified,
    bool? isChecking,
    bool? isResending,
    int? cooldownSeconds,
  }) {
    return EmailVerificationState(
      isVerified: isVerified ?? this.isVerified,
      isChecking: isChecking ?? this.isChecking,
      isResending: isResending ?? this.isResending,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    );
  }
}

class EmailVerificationNotifier extends StateNotifier<EmailVerificationState> {
  final Ref _ref;
  Timer? _cooldownTimer;

  EmailVerificationNotifier(this._ref) : super(_computeInitialState(_ref)) {
    _ref.listen<AsyncValue<User?>>(authStateChangesProvider, (_, next) {
      final user = next.value;
      if (user == null) {
        final isOverride = _ref.read(emailVerifiedOverrideProvider);
        state = EmailVerificationState(isVerified: isOverride);
      } else {
        final isOAuth = user.providerData.any(
          (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
        );
        final isOverride = _ref.read(emailVerifiedOverrideProvider);
        final verified = isOAuth || isOverride || user.emailVerified;
        state = state.copyWith(isVerified: verified);
      }
    });
  }

  static EmailVerificationState _computeInitialState(Ref ref) {
    try {
      if (Firebase.apps.isEmpty) {
        final isOverride = ref.read(emailVerifiedOverrideProvider);
        return EmailVerificationState(isVerified: isOverride);
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const EmailVerificationState(isVerified: false);
      }
      final isOAuth = user.providerData.any(
        (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
      );
      final isOverride = ref.read(emailVerifiedOverrideProvider);
      final verified = isOAuth || isOverride || user.emailVerified;
      return EmailVerificationState(isVerified: verified);
    } catch (_) {
      return const EmailVerificationState(isVerified: false);
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    state = state.copyWith(cooldownSeconds: 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.cooldownSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: state.cooldownSeconds - 1);
      }
    });
  }

  /// Reloads the Firebase user and updates verification state.
  /// If verified, synchronizes session, profile, and sets Firestore flag.
  Future<bool> reloadAndCheckVerification() async {
    try {
      if (Firebase.apps.isEmpty) return false;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      state = state.copyWith(isChecking: true);
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null) {
        try {
          await refreshedUser.getIdToken(true);
        } catch (_) {}
      }

      final isVerified = refreshedUser?.emailVerified ?? false;
      if (isVerified) {
        state = state.copyWith(isVerified: true, isChecking: false);
        _ref.read(emailVerifiedOverrideProvider.notifier).state = true;

        // Persist real verified status in Firestore users collection
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'isEmailVerified': true,
            'emailVerifiedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[EmailVerificationNotifier] Firestore update error: $e');
        }

        // Guarantee session & profile sync
        await _ref.read(sessionServiceProvider).upsertSession();
        await _ref.read(appStateProvider.notifier).loadProfileFromFirestore();
        _ref.invalidate(authStateChangesProvider);
        return true;
      } else {
        state = state.copyWith(isChecking: false);
        return false;
      }
    } catch (e) {
      debugPrint('[EmailVerificationNotifier] reload error: $e');
      state = state.copyWith(isChecking: false);
      return false;
    }
  }

  /// Resends verification email with a 60-second cooldown period.
  Future<bool> resendVerificationEmail() async {
    if (state.cooldownSeconds > 0 || state.isResending) return false;

    try {
      if (Firebase.apps.isEmpty) return false;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      state = state.copyWith(isResending: true);
      await user.sendEmailVerification();
      state = state.copyWith(isResending: false);
      _startCooldown();
      return true;
    } catch (e) {
      debugPrint('[EmailVerificationNotifier] resend error: $e');
      state = state.copyWith(isResending: false);
      return false;
    }
  }
}

final emailVerificationProvider =
    StateNotifierProvider<EmailVerificationNotifier, EmailVerificationState>((ref) {
  return EmailVerificationNotifier(ref);
});
