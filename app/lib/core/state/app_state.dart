import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile/data/kyc_model.dart';
import '../../features/profile/data/profile_firestore_mapper.dart';
import '../../features/profile/data/user_preferences.dart';
import '../../features/profile/domain/legal_consent_audit.dart';
import '../../features/profile/domain/profile_progress_calculator.dart';
import '../../features/profile/domain/profile_snapshot.dart';
import '../../features/shell/domain/app_tab.dart';
import '../../features/shell/domain/notification_item.dart';
import '../localization/locale_provider.dart';
import '../services/biometric_service.dart';
import '../services/loyalty_service.dart';
import '../services/referral_service.dart';
import '../services/session_service.dart';
import '../services/web_unload_guard.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

export '../../features/profile/data/profile_firestore_mapper.dart';
export '../../features/profile/domain/companion_settings.dart';
export '../../features/profile/domain/legal_consent_audit.dart';
export '../../features/profile/domain/profile_progress_calculator.dart';
export '../../features/profile/domain/profile_snapshot.dart';
export '../../features/shell/domain/app_tab.dart';
export '../../features/shell/domain/notification_item.dart';

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
  bool get hasUnsavedChanges => hasUnsavedProfileChanges;
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
  final LegalConsentAudit? legalConsent;

  // Snapshot of last-persisted profile data for true discard rollback
  final ProfileSnapshot? savedSnapshot;

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
    this.legalConsent,
    this.savedSnapshot,
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
    LegalConsentAudit? legalConsent,
    bool clearTerms = false,
    ProfileSnapshot? savedSnapshot,
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
      legalConsent: clearTerms ? null : (legalConsent ?? this.legalConsent),
      savedSnapshot: savedSnapshot ?? this.savedSnapshot,
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
    captureSavedSnapshot();
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
  }) => ProfileProgressCalculator.calculate(
    identity: identity,
    aiDna: aiDna,
    personaMode: personaMode,
    mediaSlots: mediaSlots,
  );

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
    setHasUnsavedChanges(dirty);
  }

  void setHasUnsavedChanges(bool value) {
    if (state.hasUnsavedProfileChanges != value) {
      state = state.copyWith(hasUnsavedProfileChanges: value);
      WebUnloadGuard.update(value);
    }
  }

  void markDirty() => setHasUnsavedChanges(true);

  void clearDirty() => setHasUnsavedChanges(false);

  /// Captures a frozen snapshot of the currently saved profile & preferences state.
  void captureSavedSnapshot() {
    state = state.copyWith(
      savedSnapshot: ProfileSnapshot.capture(
        identityValues: state.identityValues,
        aiDnaValues: state.aiDnaValues,
        aiDnaSources: state.aiDnaSources,
        preferences: state.preferences,
        companionSettings: state.companionSettings,
        personaMode: state.personaMode,
      ),
      hasUnsavedProfileChanges: false,
    );
    WebUnloadGuard.update(false);
  }

  /// Discards any unpersisted edits and rolls back all profile state fields
  /// to the exact values from the last-saved snapshot.
  void discardUnsavedChanges() {
    final snapshot = state.savedSnapshot;
    if (snapshot != null) {
      final progress = calculateProfileProgress(
        identity: snapshot.identityValues,
        aiDna: snapshot.aiDnaValues,
        personaMode: snapshot.personaMode,
        mediaSlots: state.mediaSlots,
      );
      final points = _computeCurrentPoints(progress);
      final rank = LoyaltyService.getRank(points).nameCapitalized;

      state = state.copyWith(
        identityValues: Map<String, String>.from(snapshot.identityValues),
        aiDnaValues: Map<String, String>.from(snapshot.aiDnaValues),
        aiDnaSources: Map<String, String>.from(snapshot.aiDnaSources),
        preferences: snapshot.preferences,
        companionSettings: snapshot.companionSettings,
        personaMode: snapshot.personaMode,
        profileProgress: progress,
        stylePoints: points,
        loyaltyRank: rank,
        hasUnsavedProfileChanges: false,
      );
    } else {
      state = state.copyWith(hasUnsavedProfileChanges: false);
    }
    WebUnloadGuard.update(false);
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

      final parsed = ProfileFirestoreMapper.parseDocument(
        data: doc.data(),
        user: user,
        fallbackCompanion: state.companionSettings,
        fallbackPlan: state.currentPlan,
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

      // Apply loaded preferences locally across the app
      try {
        final localPrefs = await SharedPreferences.getInstance();
        await localPrefs.setString(
          ThemeNotifier.keyThemePalette,
          parsed.preferences.fashionThemePalette,
        );
        await localPrefs.setString(
          ThemeNotifier.keyThemeMode,
          parsed.preferences.brightnessMode,
        );
        await localPrefs.setString(
          LocaleNotifier.keyAppLanguage,
          parsed.preferences.appLanguage,
        );
      } catch (_) {}

      if (_ref != null) {
        for (final p in AppPalette.values) {
          if (p.name == parsed.preferences.fashionThemePalette) {
            _ref.read(themeProvider.notifier).setPalette(p);
            break;
          }
        }
        for (final m in ThemeMode.values) {
          if (m.name == parsed.preferences.brightnessMode) {
            _ref.read(themeProvider.notifier).setThemeMode(m);
            break;
          }
        }
        _ref
            .read(localeProvider.notifier)
            .setLanguage(parsed.preferences.appLanguage);
        _ref
            .read(biometricServiceProvider)
            .setBiometricLockEnabled(parsed.preferences.biometricLock);
      }

      if (parsed.backfillData.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(parsed.backfillData, SetOptions(merge: true))
            .catchError((e) {
              debugPrint('[loadProfileFromFirestore] backfill error: $e');
            });
      }

      state = state.copyWith(
        photoUrl: parsed.photoUrl,
        identityValues: parsed.identity,
        aiDnaValues: parsed.aiDna,
        companionSettings: parsed.companion,
        coins: parsed.coins,
        currentPlan: parsed.currentPlan,
        profileProgress: parsed.profileProgress,
        stylePoints: parsed.stylePoints,
        loyaltyRank: parsed.loyaltyRank,
        aiUsageCount: parsed.aiUsageCount,
        kycData: parsed.kyc,
        personaMode: parsed.personaMode,
        mediaSlots: parsed.mediaSlots,
        preferences: parsed.preferences,
        showFloatingSupport: parsed.preferences.showFloatingSupport,
        showHeaderCoins: parsed.preferences.showHeaderCoins,
        referralCode: parsed.referralCode,
        referralCount: parsed.referralCount,
        networkTier: parsed.networkTier,
        referrals: referralEntries,
        userName: parsed.userName,
        userHandle: parsed.userHandle,
        hasUnsavedProfileChanges: false,
        termsAcceptedAt: parsed.termsAcceptedAt,
        termsVersion: parsed.termsVersion,
        legalConsent: parsed.legalConsent,
      );

      if (parsed.referralCode.isEmpty) {
        Future.microtask(() async {
          try {
            final newCode = await ReferralService().ensureUserReferralCode(
              user.uid,
            );
            state = state.copyWith(referralCode: newCode);
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('[loadProfileFromFirestore] Error: $e');
    } finally {
      // Always mark profile as loaded for current user UID so auth gate can proceed
      final currentUid = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser?.uid
          : null;
      state = state.copyWith(isProfileLoaded: true, loadedUid: currentUid);
      captureSavedSnapshot();
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

      final dataToSave = ProfileFirestoreMapper.toFirestorePayload(
        user: user,
        identityValues: state.identityValues,
        aiDnaValues: state.aiDnaValues,
        personaMode: state.personaMode,
        mediaSlots: state.mediaSlots,
        companionSettings: state.companionSettings,
        userPreferences: updatedPreferences,
        currentThemePalette: currentPalette,
        currentThemeMode: currentMode,
        profileProgress: progress,
        stylePoints: points,
        loyaltyRank: rank,
        fallbackHandle: state.userHandle,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(dataToSave, SetOptions(merge: true));

      final first = state.identityValues['firstName']?.trim() ?? '';
      final last = state.identityValues['lastName']?.trim() ?? '';
      final fullName = '$first $last'.trim();
      final nick = state.identityValues['nick']?.trim() ?? state.userHandle;

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
      WebUnloadGuard.update(false);
      captureSavedSnapshot();
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
    WebUnloadGuard.update(false);
    captureSavedSnapshot();
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
    WebUnloadGuard.update(true);
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
    WebUnloadGuard.update(true);
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
    WebUnloadGuard.update(true);
  }

  void resetCompanionSettings() {
    state = state.copyWith(
      companionSettings: const CompanionSettings(),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
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
    WebUnloadGuard.update(true);
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
    WebUnloadGuard.update(true);
  }

  void toggleHeaderCoins(bool show) {
    state = state.copyWith(
      showHeaderCoins: show,
      preferences: state.preferences.copyWith(showHeaderCoins: show),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
  }

  void toggleShowEmailInHeader(bool show) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(showEmailInHeader: show),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
  }

  void setFashionThemePalette(String palette) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(fashionThemePalette: palette),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
  }

  void setBrightnessMode(String mode) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(brightnessMode: mode),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
  }

  void setAppLanguage(String code) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(appLanguage: code),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
  }

  void setAutoDataBackup(String frequency) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(autoDataBackup: frequency),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
  }

  void setBiometricLock(bool enabled) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(biometricLock: enabled),
      hasUnsavedProfileChanges: true,
    );
    WebUnloadGuard.update(true);
  }

  Future<void> setAppMode(
    String mode, {
    bool persistImmediately = false,
  }) async {
    final hadUnsaved = state.hasUnsavedProfileChanges;
    state = state.copyWith(
      preferences: state.preferences.copyWith(appMode: mode),
      hasUnsavedProfileChanges: !persistImmediately && hadUnsaved,
    );
    if (persistImmediately) {
      await saveProfileToFirestore();
      if (!hadUnsaved) {
        captureSavedSnapshot();
      }
    } else {
      WebUnloadGuard.update(true);
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
    final now = DateTime.now().toUtc();
    String uid = state.loadedUid ?? '';
    String name = state.userName;
    String email = state.identityValues['email'] ?? '';

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
    );

    state = state.copyWith(
      termsAcceptedAt: now,
      termsVersion: version,
      legalConsent: audit,
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
      debugPrint('[AppStateNotifier] acceptTerms error: $e');
    }
  }

  /// Resets terms acceptance locally (used for testing or revocation).
  void clearTerms() {
    state = state.copyWith(clearTerms: true);
  }
}
