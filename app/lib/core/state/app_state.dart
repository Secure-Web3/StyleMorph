import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/profile/data/kyc_model.dart';
import '../../features/profile/data/user_preferences.dart';
import '../localization/locale_provider.dart';
import '../services/biometric_service.dart';
import '../services/loyalty_service.dart';
import '../services/referral_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

enum AppTab { shop, wardrobe, stylist, atelier, wellness, profile }

@immutable
class SupportMessage {
  final String text;
  final bool isUser;
  final DateTime? timestamp;

  const SupportMessage({
    required this.text,
    required this.isUser,
    this.timestamp,
  });
}

@immutable
class AppNotification {
  final String id;
  final String category; // 'ai', 'shop', 'finance'
  final String emoji;
  final String title;
  final String body;
  final String timestampLabel;
  final String
  targetRoute; // 'atelier_creations', 'shop', 'profile_wallet', 'stylist'
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.category,
    required this.emoji,
    required this.title,
    required this.body,
    required this.timestampLabel,
    required this.targetRoute,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      emoji: emoji,
      title: title,
      body: body,
      timestampLabel: timestampLabel,
      targetRoute: targetRoute,
      isRead: isRead ?? this.isRead,
    );
  }
}

@immutable
class CompanionSettings {
  final String characterId;
  final String customName;
  final String tone;
  final double critiqueStrictness; // 0.0 to 1.0
  final bool voiceEnabled;
  final bool subtitleEnabled;
  final String voiceType;
  final double speechSpeed;
  final String responseLength;
  final String activeScope;
  final bool saveHistory;
  final bool dailyTipEnabled;

  const CompanionSettings({
    this.characterId = 'ramin',
    this.customName = '',
    this.tone = 'صمیمی و دوستانه',
    this.critiqueStrictness = 0.5,
    this.voiceEnabled = true,
    this.subtitleEnabled = true,
    this.voiceType = 'پیش‌فرض شخصیت',
    this.speechSpeed = 1.0,
    this.responseLength = 'متوسط',
    this.activeScope = 'فقط تندرستی و استایلیست',
    this.saveHistory = true,
    this.dailyTipEnabled = false,
  });

  CompanionSettings copyWith({
    String? characterId,
    String? customName,
    String? tone,
    double? critiqueStrictness,
    bool? voiceEnabled,
    bool? subtitleEnabled,
    String? voiceType,
    double? speechSpeed,
    String? responseLength,
    String? activeScope,
    bool? saveHistory,
    bool? dailyTipEnabled,
  }) {
    return CompanionSettings(
      characterId: characterId ?? this.characterId,
      customName: customName ?? this.customName,
      tone: tone ?? this.tone,
      critiqueStrictness: critiqueStrictness ?? this.critiqueStrictness,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      subtitleEnabled: subtitleEnabled ?? this.subtitleEnabled,
      voiceType: voiceType ?? this.voiceType,
      speechSpeed: speechSpeed ?? this.speechSpeed,
      responseLength: responseLength ?? this.responseLength,
      activeScope: activeScope ?? this.activeScope,
      saveHistory: saveHistory ?? this.saveHistory,
      dailyTipEnabled: dailyTipEnabled ?? this.dailyTipEnabled,
    );
  }
}

@immutable
class AppState {
  final bool isLoggedIn;
  final AppTab currentTab;
  final String currentProfileTab;
  final int coins;
  final double profileProgress;
  final int stylePoints;
  final String loyaltyRank;
  final int aiUsageCount;
  final String userName;
  final String userHandle;
  final String photoUrl;
  final int userLevel;
  final bool isSupportOpen;
  final bool showFloatingSupport;
  final bool showHeaderCoins;
  final String currentPlan;
  final List<SupportMessage> supportMessages;
  final UserPreferences preferences;

  // Profile dirty-state & form data
  final bool hasUnsavedProfileChanges;
  final bool isSavingProfile;
  final Map<String, String> identityValues;
  final CompanionSettings companionSettings;

  // Notification Center state
  final List<AppNotification> notifications;

  // AI DNA & Tailoring field source tracking ('AI' or 'USER')
  final Map<String, String> aiDnaSources;
  final Map<String, String> aiDnaValues;
  final KycData kycData;

  // Media persona mode ('full_body' or 'privacy_avatar') & slots (slotKey -> url)
  final String personaMode;
  final Map<String, String> mediaSlots;

  // Referral network & rewards
  final String referralCode;
  final int referralCount;
  final String networkTier;
  final List<ReferralEntry> referrals;

  // Gate-level pre-fetch flag: true once loadProfileFromFirestore() completes
  final bool isProfileLoaded;
  final String? loadedUid;

  // Electronic User Agreement & Terms Consent
  final DateTime? termsAcceptedAt;
  final String? termsVersion;

  const AppState({
    this.isLoggedIn = false,
    this.currentTab = AppTab.profile,
    this.currentProfileTab = 'p-identity',
    this.coins = 0,
    this.profileProgress = 0.10,
    this.stylePoints = 0,
    this.loyaltyRank = 'Bronze',
    this.aiUsageCount = 0,
    this.userName = '',
    this.userHandle = '',
    this.photoUrl = '',
    this.userLevel = 1,
    this.isSupportOpen = false,
    this.showFloatingSupport = false,
    this.showHeaderCoins = false,
    this.preferences = const UserPreferences(),
    this.currentPlan = 'عادی (رایگان)',
    this.hasUnsavedProfileChanges = false,
    this.isSavingProfile = false,
    this.companionSettings = const CompanionSettings(),
    this.identityValues = const {},
    this.notifications = const [],
    this.supportMessages = const [
      SupportMessage(
        text: 'سلام! چطور می‌تونم کمکتون کنم؟',
        isUser: false,
        timestamp: null,
      ),
    ],
    this.aiDnaSources = const {},
    this.aiDnaValues = const {},
    this.kycData = const KycData(),
    this.personaMode = 'full_body',
    this.mediaSlots = const {},
    this.referralCode = '',
    this.referralCount = 0,
    this.networkTier = 'Starter',
    this.referrals = const [],
    this.isProfileLoaded = false,
    this.loadedUid,
    this.termsAcceptedAt,
    this.termsVersion,
  });

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  bool get isSimpleMode => preferences.isSimpleMode;
  bool get isAdvancedMode => preferences.isAdvancedMode;

  AppState copyWith({
    bool? isLoggedIn,
    AppTab? currentTab,
    String? currentProfileTab,
    int? coins,
    double? profileProgress,
    int? stylePoints,
    String? loyaltyRank,
    int? aiUsageCount,
    String? userName,
    String? userHandle,
    String? photoUrl,
    int? userLevel,
    bool? isSupportOpen,
    bool? showFloatingSupport,
    bool? showHeaderCoins,
    UserPreferences? preferences,
    String? currentPlan,
    bool? hasUnsavedProfileChanges,
    bool? isSavingProfile,
    Map<String, String>? identityValues,
    CompanionSettings? companionSettings,
    List<AppNotification>? notifications,
    List<SupportMessage>? supportMessages,
    Map<String, String>? aiDnaSources,
    Map<String, String>? aiDnaValues,
    KycData? kycData,
    String? personaMode,
    Map<String, String>? mediaSlots,
    String? referralCode,
    int? referralCount,
    String? networkTier,
    List<ReferralEntry>? referrals,
    bool? isProfileLoaded,
    String? loadedUid,
    bool clearLoadedUid = false,
    DateTime? termsAcceptedAt,
    String? termsVersion,
    bool clearTerms = false,
  }) {
    return AppState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentTab: currentTab ?? this.currentTab,
      currentProfileTab: currentProfileTab ?? this.currentProfileTab,
      coins: coins ?? this.coins,
      profileProgress: profileProgress ?? this.profileProgress,
      stylePoints: stylePoints ?? this.stylePoints,
      loyaltyRank: loyaltyRank ?? this.loyaltyRank,
      aiUsageCount: aiUsageCount ?? this.aiUsageCount,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      photoUrl: photoUrl ?? this.photoUrl,
      userLevel: userLevel ?? this.userLevel,
      isSupportOpen: isSupportOpen ?? this.isSupportOpen,
      showFloatingSupport: showFloatingSupport ?? this.showFloatingSupport,
      showHeaderCoins: showHeaderCoins ?? this.showHeaderCoins,
      preferences: preferences ?? this.preferences,
      currentPlan: currentPlan ?? this.currentPlan,
      hasUnsavedProfileChanges:
          hasUnsavedProfileChanges ?? this.hasUnsavedProfileChanges,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      identityValues: identityValues ?? this.identityValues,
      companionSettings: companionSettings ?? this.companionSettings,
      notifications: notifications ?? this.notifications,
      supportMessages: supportMessages ?? this.supportMessages,
      aiDnaSources: aiDnaSources ?? this.aiDnaSources,
      aiDnaValues: aiDnaValues ?? this.aiDnaValues,
      kycData: kycData ?? this.kycData,
      personaMode: personaMode ?? this.personaMode,
      mediaSlots: mediaSlots ?? this.mediaSlots,
      referralCode: referralCode ?? this.referralCode,
      referralCount: referralCount ?? this.referralCount,
      networkTier: networkTier ?? this.networkTier,
      referrals: referrals ?? this.referrals,
      isProfileLoaded: isProfileLoaded ?? this.isProfileLoaded,
      loadedUid: clearLoadedUid ? null : (loadedUid ?? this.loadedUid),
      termsAcceptedAt: clearTerms
          ? null
          : (termsAcceptedAt ?? this.termsAcceptedAt),
      termsVersion: clearTerms ? null : (termsVersion ?? this.termsVersion),
    );
  }

  /// Forwarding convenience method to [AppStateNotifier.calculateProfileProgress].
  static double calculateProfileProgress({
    required Map<String, String> identity,
    required Map<String, String> aiDna,
    String personaMode = 'full_body',
    Map<String, String> mediaSlots = const {},
  }) => AppStateNotifier.calculateProfileProgress(
    identity: identity,
    aiDna: aiDna,
    personaMode: personaMode,
    mediaSlots: mediaSlots,
  );
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  return AppStateNotifier(ref);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref? _ref;

  AppStateNotifier([this._ref]) : super(const AppState()) {
    loadProfileFromFirestore();
  }

  /// Calculates profile completion percentage using the exact weighted formula:
  /// - 40% Weight: Anatomy (Anatomy & DNA Specs)
  /// - 35% Weight: Media (Media Album & Reference Photos based on persona mode)
  /// - 25% Weight: Identity (Identity & Personal Information)
  static double calculateProfileProgress({
    required Map<String, String> identity,
    required Map<String, String> aiDna,
    String personaMode = 'full_body',
    Map<String, String> mediaSlots = const {},
  }) {
    // 1. Identity Component (25% Weight = 0.25 total)
    // 9 distinct items: email, first, last, nick, mobile, nid, dob, country/city, address/zip
    int identityFilled = 0;
    if ((identity['email'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['firstName'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['lastName'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['nick'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['mobile'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['nid'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['dob'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['country'] ?? '').trim().isNotEmpty ||
        (identity['city'] ?? '').trim().isNotEmpty) {
      identityFilled++;
    }
    if ((identity['address'] ?? '').trim().isNotEmpty ||
        (identity['zip'] ?? '').trim().isNotEmpty) {
      identityFilled++;
    }
    final identityScore = (identityFilled / 9.0) * 0.25;

    // 2. Anatomy Component (40% Weight = 0.40 total)
    // 3 basic fields + 9 tailoring/SMPL specs = 12 items total
    int anatomyFilled = 0;
    if ((aiDna['gender'] ?? '').trim().isNotEmpty) anatomyFilled++;
    if ((aiDna['height'] ?? '').trim().isNotEmpty) anatomyFilled++;
    if ((aiDna['weight'] ?? '').trim().isNotEmpty) anatomyFilled++;

    const tailoringKeys = [
      'shoulder',
      'chest',
      'waist',
      'belly',
      'hips',
      'skinTone',
      'bodyShape',
      'faceShape',
      'hair',
    ];
    for (final k in tailoringKeys) {
      if ((aiDna[k] ?? '').trim().isNotEmpty ||
          (k == 'belly' && (aiDna['abdomen'] ?? '').trim().isNotEmpty) ||
          (k == 'bodyShape' &&
              (aiDna['bodySilhouette'] ?? '').trim().isNotEmpty) ||
          (k == 'hair' &&
              ((aiDna['hairColor'] ?? '').trim().isNotEmpty ||
                  (aiDna['hairTexture'] ?? '').trim().isNotEmpty))) {
        anatomyFilled++;
      }
    }
    final anatomyScore = (anatomyFilled / 12.0) * 0.40;

    // 3. Media Component (35% Weight = 0.35 total)
    double mediaScore = 0.0;
    if (personaMode == 'privacy_avatar') {
      int filled = 0;
      if ((mediaSlots['front_face'] ?? '').trim().isNotEmpty) filled++;
      if ((mediaSlots['side_face'] ?? '').trim().isNotEmpty) filled++;
      mediaScore = (filled / 2.0) * 0.35;
    } else {
      int reqFilled = 0;
      if ((mediaSlots['front_face'] ?? '').trim().isNotEmpty) reqFilled++;
      if ((mediaSlots['side_face'] ?? '').trim().isNotEmpty) reqFilled++;
      if ((mediaSlots['body_front'] ?? '').trim().isNotEmpty) reqFilled++;
      if ((mediaSlots['body_side'] ?? '').trim().isNotEmpty) reqFilled++;
      final reqScore = (reqFilled / 4.0) * 0.25;

      int optFilled = 0;
      if ((mediaSlots['body_back'] ?? '').trim().isNotEmpty) optFilled++;
      if ((mediaSlots['hand_skin'] ?? '').trim().isNotEmpty) optFilled++;
      if ((mediaSlots['scan_360'] ?? '').trim().isNotEmpty) optFilled++;
      final optScore = (optFilled / 3.0) * 0.10;

      mediaScore = reqScore + optScore;
    }

    final totalScore = identityScore + anatomyScore + mediaScore;
    return totalScore.clamp(0.0, 1.0);
  }

  void switchTab(AppTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void switchProfileTab(String profileTabId) {
    state = state.copyWith(
      currentTab: AppTab.profile,
      currentProfileTab: profileTabId,
    );
  }

  void addCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
  }

  void setPlan(String planName) {
    state = state.copyWith(currentPlan: planName);
  }

  void markProfileDirty([bool dirty = true]) {
    if (state.hasUnsavedProfileChanges != dirty) {
      state = state.copyWith(hasUnsavedProfileChanges: dirty);
    }
  }

  /// Loads real user profile from Firestore `users/{uid}`.
  Future<void> loadProfileFromFirestore() async {
    try {
      if (Firebase.apps.isEmpty) {
        state = state.copyWith(isProfileLoaded: true, clearLoadedUid: true);
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(isProfileLoaded: true, clearLoadedUid: true);
        return;
      }

      // Upsert current device session on profile load
      SessionService().upsertSession().catchError((e) {
        debugPrint('[AppStateNotifier] upsertSession error: $e');
      });

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final Map<String, String> identity = {};
      identity['email'] = user.email ?? '';

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

        CompanionSettings companion = state.companionSettings;
        if (data['companion'] is Map) {
          final cMap = Map<String, dynamic>.from(data['companion'] as Map);
          companion = CompanionSettings(
            characterId:
                cMap['characterId']?.toString() ?? companion.characterId,
            customName: cMap['customName']?.toString() ?? companion.customName,
            tone: cMap['tone']?.toString() ?? companion.tone,
            critiqueStrictness:
                (cMap['critiqueStrictness'] as num?)?.toDouble() ??
                companion.critiqueStrictness,
            voiceEnabled:
                cMap['voiceEnabled'] as bool? ?? companion.voiceEnabled,
            subtitleEnabled:
                cMap['subtitleEnabled'] as bool? ?? companion.subtitleEnabled,
            voiceType: cMap['voiceType']?.toString() ?? companion.voiceType,
            speechSpeed:
                (cMap['speechSpeed'] as num?)?.toDouble() ??
                companion.speechSpeed,
            responseLength:
                cMap['responseLength']?.toString() ?? companion.responseLength,
            activeScope:
                cMap['activeScope']?.toString() ?? companion.activeScope,
            saveHistory: cMap['saveHistory'] as bool? ?? companion.saveHistory,
            dailyTipEnabled:
                cMap['dailyTipEnabled'] as bool? ?? companion.dailyTipEnabled,
          );
        }

        final coins =
            (data['walletBalance'] as num?)?.toInt() ??
            (data['coins'] as num?)?.toInt() ??
            (data['coinBalance'] as num?)?.toInt() ??
            0;
        final currentPlan = data['plan']?.toString() ?? state.currentPlan;

        final isOAuth = user.providerData.any(
          (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
        );

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
        final nick =
            identity['nick']?.trim() ?? data['handle']?.toString() ?? '';

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

        final progress = calculateProfileProgress(
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

        // Apply loaded preferences locally across the app
        try {
          final localPrefs = await SharedPreferences.getInstance();
          await localPrefs.setString(
            ThemeNotifier.keyThemePalette,
            preferences.fashionThemePalette,
          );
          await localPrefs.setString(
            ThemeNotifier.keyThemeMode,
            preferences.brightnessMode,
          );
          await localPrefs.setString(
            LocaleNotifier.keyAppLanguage,
            preferences.appLanguage,
          );
        } catch (_) {}

        if (_ref != null) {
          for (final p in AppPalette.values) {
            if (p.name == preferences.fashionThemePalette) {
              _ref.read(themeProvider.notifier).setPalette(p);
              break;
            }
          }
          for (final m in ThemeMode.values) {
            if (m.name == preferences.brightnessMode) {
              _ref.read(themeProvider.notifier).setThemeMode(m);
              break;
            }
          }
          _ref
              .read(localeProvider.notifier)
              .setLanguage(preferences.appLanguage);
          _ref
              .read(biometricServiceProvider)
              .setBiometricLockEnabled(preferences.biometricLock);
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

        if (backfill.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(backfill, SetOptions(merge: true))
              .catchError((e) {
                debugPrint('[loadProfileFromFirestore] backfill error: $e');
              });
        }

        state = state.copyWith(
          photoUrl: photoUrl,
          identityValues: identity,
          aiDnaValues: aiDna,
          companionSettings: companion,
          coins: coins,
          currentPlan: currentPlan,
          profileProgress: progress,
          stylePoints: finalPoints,
          loyaltyRank: loyaltyRank,
          aiUsageCount: aiUsageCount,
          kycData: kyc,
          personaMode: personaMode,
          mediaSlots: mediaSlots,
          preferences: preferences,
          showFloatingSupport: preferences.showFloatingSupport,
          showHeaderCoins: preferences.showHeaderCoins,
          referralCode: referralCode,
          referralCount: referralCount,
          networkTier: networkTier,
          referrals: referralEntries,
          userName: fullName.isNotEmpty
              ? fullName
              : (user.displayName ?? (user.email?.split('@').first ?? '')),
          userHandle: nick.isNotEmpty ? nick : '',
          hasUnsavedProfileChanges: false,
          termsAcceptedAt: termsAcceptedAt,
          termsVersion: termsVersion,
        );

        if (referralCode.isEmpty) {
          Future.microtask(() async {
            try {
              final newCode = await ReferralService().ensureUserReferralCode(
                user.uid,
              );
              state = state.copyWith(referralCode: newCode);
            } catch (_) {}
          });
        }
      } else {
        final isOAuth = user.providerData.any(
          (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
        );
        final isEmailVerified = isOAuth || user.emailVerified;
        final (extractedFirst, extractedLast) =
            FirebaseAuthRepository.splitDisplayName(user.displayName);
        if (extractedFirst.isNotEmpty) identity['firstName'] = extractedFirst;
        if (extractedLast.isNotEmpty) identity['lastName'] = extractedLast;

        final photoUrl = user.photoURL?.trim() ?? '';

        final progress = calculateProfileProgress(
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
        state = state.copyWith(
          photoUrl: photoUrl,
          identityValues: identity,
          aiDnaValues: const {},
          coins: 0,
          profileProgress: progress,
          stylePoints: points,
          loyaltyRank: rank,
          aiUsageCount: 0,
          personaMode: 'full_body',
          mediaSlots: const {},
          userName: user.displayName ?? (user.email?.split('@').first ?? ''),
          userHandle: '',
          hasUnsavedProfileChanges: false,
        );
      }
    } catch (e) {
      debugPrint('[loadProfileFromFirestore] Error: $e');
    } finally {
      // Always mark profile as loaded for current user UID so auth gate can proceed
      final currentUid = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser?.uid
          : null;
      state = state.copyWith(isProfileLoaded: true, loadedUid: currentUid);
    }
  }

  /// Persists real profile data directly to Firestore `users/{uid}`.
  Future<bool> saveProfileToFirestore() async {
    if (Firebase.apps.isEmpty) {
      saveProfileChanges();
      return true;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      saveProfileChanges();
      return true;
    }

    state = state.copyWith(isSavingProfile: true);
    try {
      final uid = user.uid;
      final progress = calculateProfileProgress(
        identity: state.identityValues,
        aiDna: state.aiDnaValues,
        personaMode: state.personaMode,
        mediaSlots: state.mediaSlots,
      );

      final first = state.identityValues['firstName']?.trim() ?? '';
      final last = state.identityValues['lastName']?.trim() ?? '';
      final fullName = '$first $last'.trim();
      final nick = state.identityValues['nick']?.trim() ?? state.userHandle;

      final isOAuth = user.providerData.any(
        (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
      );
      final isEmailVerified = isOAuth || user.emailVerified;

      final points = LoyaltyService.calculateStylePoints(
        profileProgress: progress,
        isEmailVerified: isEmailVerified,
        referralCount: state.referralCount,
        aiUsageCount: state.aiUsageCount,
        coinActivity: state.coins,
      );
      final rank = LoyaltyService.getRank(points).nameCapitalized;

      final dataToSave = <String, dynamic>{
        'email': user.email ?? (state.identityValues['email'] ?? ''),
        'displayName': fullName.isNotEmpty
            ? fullName
            : (user.displayName ?? ''),
        'firstName': first,
        'lastName': last,
        'handle': nick,
        'identity': state.identityValues,
        'aiDna': state.aiDnaValues,
        'personaMode': state.personaMode,
        'mediaSlots': state.mediaSlots,
        'companion': {
          'characterId': state.companionSettings.characterId,
          'customName': state.companionSettings.customName,
          'tone': state.companionSettings.tone,
          'critiqueStrictness': state.companionSettings.critiqueStrictness,
          'voiceEnabled': state.companionSettings.voiceEnabled,
          'subtitleEnabled': state.companionSettings.subtitleEnabled,
          'voiceType': state.companionSettings.voiceType,
          'speechSpeed': state.companionSettings.speechSpeed,
          'responseLength': state.companionSettings.responseLength,
          'activeScope': state.companionSettings.activeScope,
          'saveHistory': state.companionSettings.saveHistory,
          'dailyTipEnabled': state.companionSettings.dailyTipEnabled,
        },
        'profileProgress': progress,
        'stylePoints': points,
        'loyaltyRank': rank,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String currentPalette = state.preferences.fashionThemePalette;
      String currentMode = state.preferences.brightnessMode;
      String currentLang = state.preferences.appLanguage;
      try {
        final prefs = await SharedPreferences.getInstance();
        final p = prefs.getString(ThemeNotifier.keyThemePalette);
        if (p != null) currentPalette = p;
        final m = prefs.getString(ThemeNotifier.keyThemeMode);
        if (m != null) currentMode = m;
        final l = prefs.getString(LocaleNotifier.keyAppLanguage);
        if (l != null) currentLang = l;
      } catch (_) {}

      final updatedPreferences = state.preferences.copyWith(
        fashionThemePalette: currentPalette,
        brightnessMode: currentMode,
        appLanguage: currentLang,
        showFloatingSupport: state.showFloatingSupport,
        showHeaderCoins: state.showHeaderCoins,
      );

      dataToSave['preferences'] = updatedPreferences.toMap();
      dataToSave['theme'] = {'palette': currentPalette, 'mode': currentMode};

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(dataToSave, SetOptions(merge: true));

      state = state.copyWith(
        isSavingProfile: false,
        hasUnsavedProfileChanges: false,
        preferences: updatedPreferences,
        profileProgress: progress,
        stylePoints: points,
        loyaltyRank: rank,
        userName: fullName.isNotEmpty ? fullName : state.userName,
        userHandle: nick.isNotEmpty ? nick : state.userHandle,
      );
      return true;
    } catch (e) {
      debugPrint('[saveProfileToFirestore] Error: $e');
      state = state.copyWith(isSavingProfile: false);
      return false;
    }
  }

  int _computeCurrentPoints(double progress) {
    bool isEmailVerified = false;
    try {
      if (Firebase.apps.isNotEmpty) {
        isEmailVerified =
            FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      }
    } catch (_) {}
    return LoyaltyService.calculateStylePoints(
      profileProgress: progress,
      isEmailVerified: isEmailVerified,
      referralCount: state.referralCount,
      aiUsageCount: state.aiUsageCount,
      coinActivity: state.coins,
    );
  }

  void saveProfileChanges() {
    final first = state.identityValues['firstName']?.trim() ?? '';
    final last = state.identityValues['lastName']?.trim() ?? '';
    final fullName = '$first $last'.trim();
    final nick = state.identityValues['nick']?.trim() ?? state.userHandle;

    final progress = calculateProfileProgress(
      identity: state.identityValues,
      aiDna: state.aiDnaValues,
      personaMode: state.personaMode,
      mediaSlots: state.mediaSlots,
    );
    final points = _computeCurrentPoints(progress);
    final rank = LoyaltyService.getRank(points).nameCapitalized;

    state = state.copyWith(
      hasUnsavedProfileChanges: false,
      profileProgress: progress,
      stylePoints: points,
      loyaltyRank: rank,
      userName: fullName.isNotEmpty ? fullName : state.userName,
      userHandle: nick.isNotEmpty ? nick : state.userHandle,
    );
  }

  void updateIdentityField(String key, String value) {
    final updated = Map<String, String>.from(state.identityValues)
      ..[key] = value;
    final progress = calculateProfileProgress(
      identity: updated,
      aiDna: state.aiDnaValues,
      personaMode: state.personaMode,
      mediaSlots: state.mediaSlots,
    );
    final points = _computeCurrentPoints(progress);
    final rank = LoyaltyService.getRank(points).nameCapitalized;
    state = state.copyWith(
      identityValues: updated,
      profileProgress: progress,
      stylePoints: points,
      loyaltyRank: rank,
      hasUnsavedProfileChanges: true,
    );
  }

  void updateKycData(KycData kyc) {
    state = state.copyWith(kycData: kyc);
  }

  void setPersonaMode(String mode) {
    final progress = calculateProfileProgress(
      identity: state.identityValues,
      aiDna: state.aiDnaValues,
      personaMode: mode,
      mediaSlots: state.mediaSlots,
    );
    final points = _computeCurrentPoints(progress);
    final rank = LoyaltyService.getRank(points).nameCapitalized;
    state = state.copyWith(
      personaMode: mode,
      profileProgress: progress,
      stylePoints: points,
      loyaltyRank: rank,
      hasUnsavedProfileChanges: true,
    );
  }

  void updateMediaSlot(String slotKey, String url) {
    final updated = Map<String, String>.from(state.mediaSlots)..[slotKey] = url;
    final progress = calculateProfileProgress(
      identity: state.identityValues,
      aiDna: state.aiDnaValues,
      personaMode: state.personaMode,
      mediaSlots: updated,
    );
    final points = _computeCurrentPoints(progress);
    final rank = LoyaltyService.getRank(points).nameCapitalized;
    state = state.copyWith(
      mediaSlots: updated,
      profileProgress: progress,
      stylePoints: points,
      loyaltyRank: rank,
    );
  }

  void deleteMediaSlot(String slotKey) {
    final updated = Map<String, String>.from(state.mediaSlots)..remove(slotKey);
    final progress = calculateProfileProgress(
      identity: state.identityValues,
      aiDna: state.aiDnaValues,
      personaMode: state.personaMode,
      mediaSlots: updated,
    );
    final points = _computeCurrentPoints(progress);
    final rank = LoyaltyService.getRank(points).nameCapitalized;
    state = state.copyWith(
      mediaSlots: updated,
      profileProgress: progress,
      stylePoints: points,
      loyaltyRank: rank,
    );
  }

  void updateCompanionSettings(CompanionSettings settings) {
    state = state.copyWith(
      companionSettings: settings,
      hasUnsavedProfileChanges: true,
    );
  }

  void resetCompanionSettings() {
    state = state.copyWith(
      companionSettings: const CompanionSettings(),
      hasUnsavedProfileChanges: true,
    );
  }

  void updateAiDnaField(String key, String value) {
    final updatedValues = Map<String, String>.from(state.aiDnaValues)
      ..[key] = value;
    final updatedSources = Map<String, String>.from(state.aiDnaSources)
      ..[key] = 'USER';
    final progress = calculateProfileProgress(
      identity: state.identityValues,
      aiDna: updatedValues,
      personaMode: state.personaMode,
      mediaSlots: state.mediaSlots,
    );
    final points = _computeCurrentPoints(progress);
    final rank = LoyaltyService.getRank(points).nameCapitalized;
    state = state.copyWith(
      aiDnaValues: updatedValues,
      aiDnaSources: updatedSources,
      profileProgress: progress,
      stylePoints: points,
      loyaltyRank: rank,
      hasUnsavedProfileChanges: true,
    );
  }

  void toggleSupport([bool? open]) {
    state = state.copyWith(isSupportOpen: open ?? !state.isSupportOpen);
  }

  void toggleFloatingSupport(bool show) {
    state = state.copyWith(
      showFloatingSupport: show,
      preferences: state.preferences.copyWith(showFloatingSupport: show),
      isSupportOpen: show ? state.isSupportOpen : false,
      hasUnsavedProfileChanges: true,
    );
  }

  void toggleHeaderCoins(bool show) {
    state = state.copyWith(
      showHeaderCoins: show,
      preferences: state.preferences.copyWith(showHeaderCoins: show),
      hasUnsavedProfileChanges: true,
    );
  }

  void toggleShowEmailInHeader(bool show) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(showEmailInHeader: show),
      hasUnsavedProfileChanges: true,
    );
  }

  void setFashionThemePalette(String palette) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(fashionThemePalette: palette),
      hasUnsavedProfileChanges: true,
    );
  }

  void setBrightnessMode(String mode) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(brightnessMode: mode),
      hasUnsavedProfileChanges: true,
    );
  }

  void setAppLanguage(String code) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(appLanguage: code),
      hasUnsavedProfileChanges: true,
    );
  }

  void setAutoDataBackup(String frequency) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(autoDataBackup: frequency),
      hasUnsavedProfileChanges: true,
    );
  }

  void setBiometricLock(bool enabled) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(biometricLock: enabled),
      hasUnsavedProfileChanges: true,
    );
  }

  Future<void> setAppMode(
    String mode, {
    bool persistImmediately = false,
  }) async {
    state = state.copyWith(
      preferences: state.preferences.copyWith(appMode: mode),
      hasUnsavedProfileChanges: !persistImmediately,
    );
    if (persistImmediately) {
      await saveProfileToFirestore();
    }
  }

  void markNotificationRead(String id) {
    final updated = state.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllNotificationsRead() {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);
  }

  void sendSupportMessage(String text) {
    if (text.trim().isEmpty) return;
    final updated = List<SupportMessage>.from(state.supportMessages)
      ..add(
        SupportMessage(
          text: text.trim(),
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    state = state.copyWith(supportMessages: updated);
  }

  void login() {
    state = state.copyWith(isLoggedIn: true, currentTab: AppTab.profile);
    loadProfileFromFirestore();
  }

  void setReferralData({
    String? referralCode,
    int? referralCount,
    String? networkTier,
    List<ReferralEntry>? referrals,
  }) {
    state = state.copyWith(
      referralCode: referralCode,
      referralCount: referralCount,
      networkTier: networkTier,
      referrals: referrals,
    );
  }

  void logout() {
    state = state.copyWith(
      isLoggedIn: false,
      identityValues: const {},
      aiDnaValues: const {},
      coins: 0,
      profileProgress: 0.10,
      stylePoints: 0,
      loyaltyRank: 'Bronze',
      aiUsageCount: 0,
      userName: '',
      userHandle: '',
      personaMode: 'full_body',
      mediaSlots: const {},
      referralCode: '',
      referralCount: 0,
      networkTier: 'Starter',
      referrals: const [],
      preferences: const UserPreferences(),
      showFloatingSupport: false,
      showHeaderCoins: false,
      hasUnsavedProfileChanges: false,
      isProfileLoaded: false,
      clearLoadedUid: true,
      clearTerms: true,
    );
  }

  /// Resets profile loaded flag and loaded UID when switching accounts or signing out.
  void resetProfileLoaded() {
    state = state.copyWith(isProfileLoaded: false, clearLoadedUid: true);
  }

  /// Electronically signs and records agreement to Terms of Service & Privacy Policy.
  Future<void> acceptTerms({String version = '1.0'}) async {
    final now = DateTime.now();
    state = state.copyWith(termsAcceptedAt: now, termsVersion: version);
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'termsAcceptedAt': FieldValue.serverTimestamp(),
                'termsVersion': version,
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('[AppStateNotifier] acceptTerms error: $e');
    }
  }

  /// Resets terms acceptance locally (used for testing or revocation).
  void clearTerms() {
    state = state.copyWith(clearTerms: true);
  }
}
