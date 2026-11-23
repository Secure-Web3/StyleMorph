import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/loyalty_service.dart';
import '../../../core/services/referral_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../domain/companion_settings.dart';
import '../domain/legal_consent_audit.dart';
import '../domain/profile_progress_calculator.dart';
import 'profile_firestore_mapper.dart';
import 'user_preferences.dart';

@immutable
class ProfileLoadResult {
  final ParsedProfileData parsed;
  final List<ReferralEntry> referrals;
  final String? currentUid;

  const ProfileLoadResult({
    required this.parsed,
    required this.referrals,
    this.currentUid,
  });
}

@immutable
class ProfileSaveResult {
  final bool success;
  final UserPreferences preferences;
  final double profileProgress;
  final int stylePoints;
  final String loyaltyRank;
  final String userName;
  final String userHandle;

  const ProfileSaveResult({
    required this.success,
    required this.preferences,
    required this.profileProgress,
    required this.stylePoints,
    required this.loyaltyRank,
    required this.userName,
    required this.userHandle,
  });
}

class ProfileSyncService {
  const ProfileSyncService();

  /// Loads profile from Firestore, fetches referrals, updates backfill,
  /// and applies user preferences locally.
  Future<ProfileLoadResult?> loadProfile({
    required CompanionSettings fallbackCompanion,
    required String fallbackPlan,
    Ref? ref,
  }) async {
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Upsert current device session on profile load
    SessionService().upsertSession().catchError((e) {
      debugPrint('[ProfileSyncService] upsertSession error: $e');
    });

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final parsed = ProfileFirestoreMapper.parseDocument(
      data: doc.data(),
      user: user,
      fallbackCompanion: fallbackCompanion,
      fallbackPlan: fallbackPlan,
    );

    List<ReferralEntry> referralEntries = [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('referrals')
          .orderBy('createdAt', descending: true)
          .get();
      referralEntries = snap.docs.map(ReferralEntry.fromFirestore).toList();
    } catch (_) {}

    await syncPreferencesLocally(parsed.preferences);

    if (ref != null) {
      applyPreferencesToRef(ref, parsed.preferences);
    }

    if (parsed.backfillData.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(parsed.backfillData, SetOptions(merge: true))
          .catchError((e) {
            debugPrint('[ProfileSyncService] backfill error: $e');
          });
    }

    return ProfileLoadResult(
      parsed: parsed,
      referrals: referralEntries,
      currentUid: user.uid,
    );
  }

  /// Persists full profile data, recalculating progress and loyalty points,
  /// and updates Firestore users/{uid}.
  Future<ProfileSaveResult?> saveProfile({
    required Map<String, String> identityValues,
    required Map<String, String> aiDnaValues,
    required String personaMode,
    required Map<String, String> mediaSlots,
    required CompanionSettings companionSettings,
    required UserPreferences currentPreferences,
    required bool showFloatingSupport,
    required bool showHeaderCoins,
    required int referralCount,
    required int aiUsageCount,
    required int coins,
    required String currentUserName,
    required String currentUserHandle,
  }) async {
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final progress = ProfileProgressCalculator.calculate(
      identity: identityValues,
      aiDna: aiDnaValues,
      personaMode: personaMode,
      mediaSlots: mediaSlots,
    );

    final isOAuth = user.providerData.any(
      (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
    );
    final isEmailVerified = isOAuth || user.emailVerified;

    final loyalty = LoyaltyService.evaluate(
      profileProgress: progress,
      isEmailVerified: isEmailVerified,
      referralCount: referralCount,
      aiUsageCount: aiUsageCount,
      coinActivity: coins,
    );

    String currentPalette = currentPreferences.fashionThemePalette;
    String currentMode = currentPreferences.brightnessMode;
    String currentLang = currentPreferences.appLanguage;
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getString(ThemeNotifier.keyThemePalette);
      if (p != null) currentPalette = p;
      final m = prefs.getString(ThemeNotifier.keyThemeMode);
      if (m != null) currentMode = m;
      final l = prefs.getString(LocaleNotifier.keyAppLanguage);
      if (l != null) currentLang = l;
    } catch (_) {}

    final updatedPreferences = currentPreferences.copyWith(
      fashionThemePalette: currentPalette,
      brightnessMode: currentMode,
      appLanguage: currentLang,
      showFloatingSupport: showFloatingSupport,
      showHeaderCoins: showHeaderCoins,
    );

    final dataToSave = ProfileFirestoreMapper.toFirestorePayload(
      user: user,
      identityValues: identityValues,
      aiDnaValues: aiDnaValues,
      personaMode: personaMode,
      mediaSlots: mediaSlots,
      companionSettings: companionSettings,
      userPreferences: updatedPreferences,
      currentThemePalette: currentPalette,
      currentThemeMode: currentMode,
      profileProgress: progress,
      stylePoints: loyalty.points,
      loyaltyRank: loyalty.rank,
      fallbackHandle: currentUserHandle,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(dataToSave, SetOptions(merge: true));

    final first = identityValues['firstName']?.trim() ?? '';
    final last = identityValues['lastName']?.trim() ?? '';
    final fullName = '$first $last'.trim();
    final nick = identityValues['nick']?.trim() ?? currentUserHandle;

    return ProfileSaveResult(
      success: true,
      preferences: updatedPreferences,
      profileProgress: progress,
      stylePoints: loyalty.points,
      loyaltyRank: loyalty.rank,
      userName: fullName.isNotEmpty ? fullName : currentUserName,
      userHandle: nick.isNotEmpty ? nick : currentUserHandle,
    );
  }

  /// Records legal agreement terms in Firestore and returns the created audit record.
  Future<LegalConsentAudit> recordLegalConsent({
    required String version,
    String? documentHash,
    String? loadedUid,
    String? currentName,
    String? currentEmail,
  }) async {
    final now = DateTime.now().toUtc();
    String uid = loadedUid ?? '';
    String name = currentName ?? '';
    String email = currentEmail ?? '';

    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (uid.isEmpty) uid = user.uid;
          if (email.isEmpty && user.email != null) email = user.email!;
          if (name.isEmpty && user.displayName != null) {
            name = user.displayName!;
          }
        }
      }
    } catch (_) {}

    String? ip;
    String? location;
    try {
      final ipRes = await SessionService.detectIpAndLocation().timeout(
        const Duration(seconds: 3),
      );
      ip = ipRes.ip;
      location = ipRes.location;
    } catch (_) {}

    String deviceInfo = 'Unknown Device';
    try {
      deviceInfo = SessionService.resolveDeviceDescriptor();
    } catch (_) {}

    final audit = LegalConsentAudit(
      acceptedAt: now,
      contractVersion: version,
      signerUid: uid,
      signerName: name,
      signerEmail: email,
      ipAddress: ip,
      ipLocation: location,
      deviceInfo: deviceInfo,
      documentHash: documentHash,
    );

    try {
      if (Firebase.apps.isNotEmpty && uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'termsAcceptedAt': FieldValue.serverTimestamp(),
          'termsVersion': version,
          'legalConsent': audit.toMap(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[ProfileSyncService] recordLegalConsent error: $e');
    }

    return audit;
  }

  /// Ensures user has a referral code created if missing.
  Future<String?> ensureReferralCode(String uid) async {
    try {
      return await ReferralService().ensureUserReferralCode(uid);
    } catch (e) {
      debugPrint('[ProfileSyncService] ensureReferralCode error: $e');
      return null;
    }
  }

  /// Persists theme palette, brightness mode, and language code into SharedPreferences.
  static Future<void> syncPreferencesLocally(UserPreferences prefs) async {
    try {
      final localPrefs = await SharedPreferences.getInstance();
      await localPrefs.setString(
        ThemeNotifier.keyThemePalette,
        prefs.fashionThemePalette,
      );
      await localPrefs.setString(
        ThemeNotifier.keyThemeMode,
        prefs.brightnessMode,
      );
      await localPrefs.setString(
        LocaleNotifier.keyAppLanguage,
        prefs.appLanguage,
      );
    } catch (e) {
      debugPrint('[ProfileSyncService] syncPreferencesLocally error: $e');
    }
  }

  /// Propagates theme, language, and biometric preferences to Riverpod state.
  static void applyPreferencesToRef(Ref ref, UserPreferences prefs) {
    for (final p in AppPalette.values) {
      if (p.name == prefs.fashionThemePalette) {
        ref.read(themeProvider.notifier).setPalette(p);
        break;
      }
    }
    for (final m in ThemeMode.values) {
      if (m.name == prefs.brightnessMode) {
        ref.read(themeProvider.notifier).setThemeMode(m);
        break;
      }
    }
    ref.read(localeProvider.notifier).setLanguage(prefs.appLanguage);
    ref
        .read(biometricServiceProvider)
        .setBiometricLockEnabled(prefs.biometricLock);
  }
}

final profileSyncServiceProvider = Provider<ProfileSyncService>((ref) {
  return const ProfileSyncService();
});
