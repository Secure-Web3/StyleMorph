import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/loyalty_service.dart';
import '../../../core/services/referral_service.dart';
import '../../auth/data/firebase_auth_repository.dart';
import '../domain/companion_settings.dart';
import '../domain/legal_consent_audit.dart';
import '../domain/profile_progress_calculator.dart';
import 'kyc_model.dart';
import 'user_preferences.dart';

/// Container for profile fields parsed from Firestore `users/{uid}` document.
@immutable
class ParsedProfileData {
  final String photoUrl;
  final Map<String, String> identity;
  final Map<String, String> aiDna;
  final CompanionSettings companion;
  final int coins;
  final String currentPlan;
  final double profileProgress;
  final int stylePoints;
  final String loyaltyRank;
  final int aiUsageCount;
  final KycData kyc;
  final String personaMode;
  final Map<String, String> mediaSlots;
  final UserPreferences preferences;
  final String referralCode;
  final int referralCount;
  final String networkTier;
  final String userName;
  final String userHandle;
  final DateTime? termsAcceptedAt;
  final String? termsVersion;
  final LegalConsentAudit? legalConsent;
  final Map<String, dynamic> backfillData;

  const ParsedProfileData({
    required this.photoUrl,
    required this.identity,
    required this.aiDna,
    required this.companion,
    required this.coins,
    required this.currentPlan,
    required this.profileProgress,
    required this.stylePoints,
    required this.loyaltyRank,
    required this.aiUsageCount,
    required this.kyc,
    required this.personaMode,
    required this.mediaSlots,
    required this.preferences,
    required this.referralCode,
    required this.referralCount,
    required this.networkTier,
    required this.userName,
    required this.userHandle,
    this.termsAcceptedAt,
    this.termsVersion,
    this.legalConsent,
    this.backfillData = const {},
  });
}

/// Helper for Firestore document parsing, payload serialization, and backfill detection.
class ProfileFirestoreMapper {
  const ProfileFirestoreMapper._();

  /// Parses Firestore `users/{uid}` document snapshot data into [ParsedProfileData].
  static ParsedProfileData parseDocument({
    required Map<String, dynamic>? data,
    required User user,
    required CompanionSettings fallbackCompanion,
    required String fallbackPlan,
  }) {
    final Map<String, String> identity = {};
    identity['email'] = user.email ?? '';

    final isOAuth = user.providerData.any(
      (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
    );

    if (data != null) {
      if (data['identity'] is Map) {
        final idMap = Map<String, dynamic>.from(data['identity'] as Map);
        idMap.forEach((k, v) {
          if (v != null && v.toString().isNotEmpty) {
            identity[k] = v.toString();
          }
        });
      }
      if (!identity.containsKey('email') || identity['email']!.isEmpty) {
        identity['email'] = user.email ?? (data['email']?.toString() ?? '');
      }

      final Map<String, String> aiDna = {};
      if (data['aiDna'] is Map) {
        final aiMap = Map<String, dynamic>.from(data['aiDna'] as Map);
        aiMap.forEach((k, v) {
          if (v != null && v.toString().isNotEmpty) {
            aiDna[k] = v.toString();
          }
        });
      }

      CompanionSettings companion = fallbackCompanion;
      if (data['companion'] is Map) {
        final cMap = Map<String, dynamic>.from(data['companion'] as Map);
        companion = CompanionSettings.fromMap(cMap, fallbackCompanion);
      }

      final coins =
          (data['walletBalance'] as num?)?.toInt() ??
          (data['coins'] as num?)?.toInt() ??
          (data['coinBalance'] as num?)?.toInt() ??
          0;
      final currentPlan = data['plan']?.toString() ?? fallbackPlan;

      String first = identity['firstName']?.trim() ?? '';
      String last = identity['lastName']?.trim() ?? '';

      if (first.isEmpty &&
          data['firstName'] != null &&
          data['firstName'].toString().trim().isNotEmpty) {
        first = data['firstName'].toString().trim();
        identity['firstName'] = first;
      }
      if (last.isEmpty &&
          data['lastName'] != null &&
          data['lastName'].toString().trim().isNotEmpty) {
        last = data['lastName'].toString().trim();
        identity['lastName'] = last;
      }

      if (first.isEmpty &&
          last.isEmpty &&
          (user.displayName?.trim().isNotEmpty ?? false)) {
        final (extractedFirst, extractedLast) =
            FirebaseAuthRepository.splitDisplayName(user.displayName);
        if (extractedFirst.isNotEmpty) {
          first = extractedFirst;
          identity['firstName'] = first;
        }
        if (extractedLast.isNotEmpty) {
          last = extractedLast;
          identity['lastName'] = last;
        }
      }

      final String photoUrl =
          (data['photoURL'] != null &&
              data['photoURL'].toString().trim().isNotEmpty)
          ? data['photoURL'].toString().trim()
          : (user.photoURL?.trim() ?? '');

      final bool isEmailVerified =
          isOAuth || user.emailVerified || (data['emailVerified'] == true);

      final fullName = '$first $last'.trim();
      final nick = identity['nick']?.trim() ?? data['handle']?.toString() ?? '';

      final personaMode = data['personaMode']?.toString() ?? 'full_body';
      final Map<String, String> mediaSlots = {};
      if (data['mediaSlots'] is Map) {
        final mMap = Map<String, dynamic>.from(data['mediaSlots'] as Map);
        mMap.forEach((k, v) {
          if (v != null && v.toString().isNotEmpty) {
            mediaSlots[k] = v.toString();
          }
        });
      }

      final progress = ProfileProgressCalculator.calculate(
        identity: identity,
        aiDna: aiDna,
        personaMode: personaMode,
        mediaSlots: mediaSlots,
      );

      KycData kyc = const KycData();
      if (data['kyc'] is Map) {
        kyc = KycData.fromMap(Map<String, dynamic>.from(data['kyc'] as Map));
      }

      final referralCode = data['referralCode']?.toString() ?? '';
      final referralCount = (data['referralCount'] as num?)?.toInt() ?? 0;
      final networkTier =
          data['networkTier']?.toString() ??
          ReferralService.calculateTier(referralCount);

      DateTime? termsAcceptedAt;
      if (data['termsAcceptedAt'] != null) {
        if (data['termsAcceptedAt'] is Timestamp) {
          termsAcceptedAt = (data['termsAcceptedAt'] as Timestamp).toDate();
        } else if (data['termsAcceptedAt'] is String) {
          termsAcceptedAt = DateTime.tryParse(
            data['termsAcceptedAt'] as String,
          );
        }
      }
      final String? termsVersion = data['termsVersion']?.toString();

      LegalConsentAudit? legalConsent;
      if (data['legalConsent'] is Map) {
        legalConsent = LegalConsentAudit.fromMap(
          Map<String, dynamic>.from(data['legalConsent'] as Map),
        );
      } else if (termsAcceptedAt != null) {
        legalConsent = LegalConsentAudit(
          acceptedAt: termsAcceptedAt,
          contractVersion: termsVersion ?? '1.0',
          signerUid: user.uid,
          signerName: fullName.isNotEmpty
              ? fullName
              : (user.displayName ?? (user.email?.split('@').first ?? '')),
          signerEmail: user.email ?? (data['email']?.toString() ?? ''),
          ipAddress: null,
          ipLocation: null,
          deviceInfo: null,
        );
      }

      UserPreferences preferences = const UserPreferences();
      if (data['preferences'] is Map) {
        preferences = UserPreferences.fromMap(
          Map<String, dynamic>.from(data['preferences'] as Map),
        );
      } else if (data['theme'] is Map) {
        final tMap = Map<String, dynamic>.from(data['theme'] as Map);
        preferences = UserPreferences(
          fashionThemePalette: tMap['palette']?.toString() ?? 'editorial',
          brightnessMode: tMap['mode']?.toString() ?? 'light',
        );
      }

      final int aiUsageCount = (data['aiUsageCount'] as num?)?.toInt() ?? 0;
      final int calculatedPoints = LoyaltyService.calculateStylePoints(
        profileProgress: progress,
        isEmailVerified: isEmailVerified,
        referralCount: referralCount,
        aiUsageCount: aiUsageCount,
        coinActivity: coins,
      );
      final int stylePoints =
          (data['stylePoints'] as num?)?.toInt() ?? calculatedPoints;
      final int finalPoints =
          (stylePoints == 0 ||
              (isEmailVerified && stylePoints < calculatedPoints))
          ? calculatedPoints
          : stylePoints;
      final String loyaltyRank = LoyaltyService.getRank(
        finalPoints,
      ).nameCapitalized;

      final Map<String, dynamic> backfill = {};
      if (isOAuth && data['emailVerified'] != true) {
        backfill['emailVerified'] = true;
      }
      if (photoUrl.isNotEmpty &&
          (data['photoURL'] == null ||
              data['photoURL'].toString().trim().isEmpty)) {
        backfill['photoURL'] = photoUrl;
      }
      if (first.isNotEmpty &&
          (data['firstName'] == null ||
              data['firstName'].toString().trim().isEmpty)) {
        backfill['firstName'] = first;
      }
      if (last.isNotEmpty &&
          (data['lastName'] == null ||
              data['lastName'].toString().trim().isEmpty)) {
        backfill['lastName'] = last;
      }
      if (identity.isNotEmpty) {
        final currentId = data['identity'] is Map
            ? Map<String, dynamic>.from(data['identity'] as Map)
            : <String, dynamic>{};
        bool idChanged = false;
        if (first.isNotEmpty &&
            (currentId['firstName'] == null ||
                currentId['firstName'].toString().trim().isEmpty)) {
          currentId['firstName'] = first;
          idChanged = true;
        }
        if (last.isNotEmpty &&
            (currentId['lastName'] == null ||
                currentId['lastName'].toString().trim().isEmpty)) {
          currentId['lastName'] = last;
          idChanged = true;
        }
        if (idChanged) {
          backfill['identity'] = currentId;
        }
      }
      if (finalPoints != (data['stylePoints'] as num?)?.toInt()) {
        backfill['stylePoints'] = finalPoints;
        backfill['loyaltyRank'] = loyaltyRank;
      }

      return ParsedProfileData(
        photoUrl: photoUrl,
        identity: identity,
        aiDna: aiDna,
        companion: companion,
        coins: coins,
        currentPlan: currentPlan,
        profileProgress: progress,
        stylePoints: finalPoints,
        loyaltyRank: loyaltyRank,
        aiUsageCount: aiUsageCount,
        kyc: kyc,
        personaMode: personaMode,
        mediaSlots: mediaSlots,
        preferences: preferences,
        referralCode: referralCode,
        referralCount: referralCount,
        networkTier: networkTier,
        userName: fullName.isNotEmpty
            ? fullName
            : (user.displayName ?? (user.email?.split('@').first ?? '')),
        userHandle: nick.isNotEmpty ? nick : '',
        termsAcceptedAt: termsAcceptedAt,
        termsVersion: termsVersion,
        legalConsent: legalConsent,
        backfillData: backfill,
      );
    } else {
      final isEmailVerified = isOAuth || user.emailVerified;
      final (extractedFirst, extractedLast) =
          FirebaseAuthRepository.splitDisplayName(user.displayName);
      if (extractedFirst.isNotEmpty) identity['firstName'] = extractedFirst;
      if (extractedLast.isNotEmpty) identity['lastName'] = extractedLast;

      final photoUrl = user.photoURL?.trim() ?? '';
      final progress = ProfileProgressCalculator.calculate(
        identity: identity,
        aiDna: const {},
        personaMode: 'full_body',
        mediaSlots: const {},
      );
      final points = LoyaltyService.calculateStylePoints(
        profileProgress: progress,
        isEmailVerified: isEmailVerified,
        referralCount: 0,
        aiUsageCount: 0,
        coinActivity: 0,
      );
      final rank = LoyaltyService.getRank(points).nameCapitalized;

      return ParsedProfileData(
        photoUrl: photoUrl,
        identity: identity,
        aiDna: const {},
        companion: fallbackCompanion,
        coins: 0,
        currentPlan: fallbackPlan,
        profileProgress: progress,
        stylePoints: points,
        loyaltyRank: rank,
        aiUsageCount: 0,
        kyc: const KycData(),
        personaMode: 'full_body',
        mediaSlots: const {},
        preferences: const UserPreferences(),
        referralCode: '',
        referralCount: 0,
        networkTier: ReferralService.calculateTier(0),
        userName: user.displayName ?? (user.email?.split('@').first ?? ''),
        userHandle: '',
        termsAcceptedAt: null,
        termsVersion: null,
        legalConsent: null,
        backfillData: const {},
      );
    }
  }

  /// Builds the Firestore document payload map for `users/{uid}` persistence.
  static Map<String, dynamic> toFirestorePayload({
    required User user,
    required Map<String, String> identityValues,
    required Map<String, String> aiDnaValues,
    required String personaMode,
    required Map<String, String> mediaSlots,
    required CompanionSettings companionSettings,
    required UserPreferences userPreferences,
    required String currentThemePalette,
    required String currentThemeMode,
    required double profileProgress,
    required int stylePoints,
    required String loyaltyRank,
    required String fallbackHandle,
  }) {
    final first = identityValues['firstName']?.trim() ?? '';
    final last = identityValues['lastName']?.trim() ?? '';
    final fullName = '$first $last'.trim();
    final nick = identityValues['nick']?.trim() ?? fallbackHandle;

    return <String, dynamic>{
      'email': user.email ?? (identityValues['email'] ?? ''),
      'displayName': fullName.isNotEmpty ? fullName : (user.displayName ?? ''),
      'firstName': first,
      'lastName': last,
      'handle': nick,
      'identity': identityValues,
      'aiDna': aiDnaValues,
      'personaMode': personaMode,
      'mediaSlots': mediaSlots,
      'companion': companionSettings.toMap(),
      'profileProgress': profileProgress,
      'stylePoints': stylePoints,
      'loyaltyRank': loyaltyRank,
      'updatedAt': FieldValue.serverTimestamp(),
      'preferences': userPreferences.toMap(),
      'theme': {'palette': currentThemePalette, 'mode': currentThemeMode},
    };
  }
}
