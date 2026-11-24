import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/domain/kyc_model.dart';
import '../../features/profile/data/profile_sync_service.dart';
import '../../features/profile/domain/user_preferences.dart';
import '../../features/profile/domain/legal_consent_audit.dart';
import '../../features/profile/domain/legal_document_v2.dart';
import '../../features/profile/domain/profile_progress_calculator.dart';
import '../../features/profile/domain/profile_snapshot.dart';
import '../../features/shell/domain/app_tab.dart';
import '../../features/shell/domain/notification_item.dart';
import '../services/loyalty_service.dart';
import '../services/referral_service.dart';
import '../services/web_unload_guard.dart';

export '../../features/profile/data/profile_firestore_mapper.dart';
export '../../features/profile/data/profile_sync_service.dart';
export '../../features/profile/domain/companion_settings.dart';
export '../../features/profile/domain/legal_consent_audit.dart';
export '../../features/profile/domain/legal_document_v2.dart';
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

  /// Effective avatar image URL following priority hierarchy:
  /// 1. Media slot `front_face` (when non-null and non-empty).
  /// 2. Returns null (triggering Gender-Aware 3D Avatar fallback).
  String? get effectiveAvatarUrl {
    final frontFace = mediaSlots['front_face']?.trim();
    if (frontFace != null && frontFace.isNotEmpty) {
      return frontFace;
    }
    return null;
  }

  /// Gender string extracted from AI DNA values (e.g. 'male', 'female', 'non_binary').
  String? get gender => aiDnaValues['gender'];

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
  final ProfileSyncService _profileSyncService;

  AppStateNotifier([this._ref, ProfileSyncService? profileSyncService])
    : _profileSyncService = profileSyncService ?? const ProfileSyncService(),
      super(const AppState()) {
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

  LoyaltyEvaluation _evaluateLoyalty(double progress) {
    bool isEmailVerified = false;
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final isOAuth = user.providerData.any(
            (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
          );
          isEmailVerified = isOAuth || user.emailVerified;
        }
      }
    } catch (_) {}
    return LoyaltyService.evaluate(
      profileProgress: progress,
      isEmailVerified: isEmailVerified,
      referralCount: state.referralCount,
      aiUsageCount: state.aiUsageCount,
      coinActivity: state.coins,
    );
  }

  void _updateProfileProgressAndLoyalty({
    Map<String, String>? identity,
    Map<String, String>? aiDna,
    String? personaMode,
    Map<String, String>? mediaSlots,
    bool markDirty = false,
    Map<String, String>? aiDnaSources,
  }) {
    final newIdentity = identity ?? state.identityValues;
    final newAiDna = aiDna ?? state.aiDnaValues;
    final newPersonaMode = personaMode ?? state.personaMode;
    final newMediaSlots = mediaSlots ?? state.mediaSlots;

    final progress = calculateProfileProgress(
      identity: newIdentity,
      aiDna: newAiDna,
      personaMode: newPersonaMode,
      mediaSlots: newMediaSlots,
    );
    final loyalty = _evaluateLoyalty(progress);

    state = state.copyWith(
      identityValues: newIdentity,
      aiDnaValues: newAiDna,
      personaMode: newPersonaMode,
      mediaSlots: newMediaSlots,
      aiDnaSources: aiDnaSources ?? state.aiDnaSources,
      profileProgress: progress,
      stylePoints: loyalty.points,
      loyaltyRank: loyalty.rank,
      hasUnsavedProfileChanges: markDirty
          ? true
          : state.hasUnsavedProfileChanges,
    );
    if (markDirty) {
      WebUnloadGuard.update(true);
    }
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
      final loyalty = _evaluateLoyalty(progress);

      state = state.copyWith(
        identityValues: Map<String, String>.from(snapshot.identityValues),
        aiDnaValues: Map<String, String>.from(snapshot.aiDnaValues),
        aiDnaSources: Map<String, String>.from(snapshot.aiDnaSources),
        preferences: snapshot.preferences,
        companionSettings: snapshot.companionSettings,
        personaMode: snapshot.personaMode,
        profileProgress: progress,
        stylePoints: loyalty.points,
        loyaltyRank: loyalty.rank,
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
      if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
        state = state.copyWith(isProfileLoaded: true, clearLoadedUid: true);
        return;
      }

      final result = await _profileSyncService.loadProfile(
        fallbackCompanion: state.companionSettings,
        fallbackPlan: state.currentPlan,
        ref: _ref,
      );

      if (result != null) {
        final parsed = result.parsed;
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
          referralCount: result.referrals.isNotEmpty
              ? result.referrals.length
              : parsed.referralCount,
          networkTier: result.referrals.isNotEmpty
              ? ReferralService.calculateTier(result.referrals.length)
              : (parsed.networkTier.isNotEmpty
                    ? parsed.networkTier
                    : ReferralService.calculateTier(parsed.referralCount)),
          referrals: result.referrals,
          userName: parsed.userName,
          userHandle: parsed.userHandle,
          hasUnsavedProfileChanges: false,
          termsAcceptedAt: parsed.termsAcceptedAt,
          termsVersion: parsed.termsVersion,
          legalConsent: parsed.legalConsent,
        );

        if (parsed.referralCode.isEmpty) {
          _profileSyncService
              .ensureReferralCode(FirebaseAuth.instance.currentUser!.uid)
              .then((newCode) {
                if (newCode != null && mounted) {
                  state = state.copyWith(referralCode: newCode);
                }
              });
        }
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
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      saveProfileChanges();
      return true;
    }

    state = state.copyWith(isSavingProfile: true);
    try {
      final result = await _profileSyncService.saveProfile(
        identityValues: state.identityValues,
        aiDnaValues: state.aiDnaValues,
        personaMode: state.personaMode,
        mediaSlots: state.mediaSlots,
        companionSettings: state.companionSettings,
        currentPreferences: state.preferences,
        showFloatingSupport: state.showFloatingSupport,
        showHeaderCoins: state.showHeaderCoins,
        referralCount: state.referralCount,
        aiUsageCount: state.aiUsageCount,
        coins: state.coins,
        currentUserName: state.userName,
        currentUserHandle: state.userHandle,
      );

      if (result != null && result.success) {
        state = state.copyWith(
          isSavingProfile: false,
          hasUnsavedProfileChanges: false,
          preferences: result.preferences,
          profileProgress: result.profileProgress,
          stylePoints: result.stylePoints,
          loyaltyRank: result.loyaltyRank,
          userName: result.userName,
          userHandle: result.userHandle,
        );
        WebUnloadGuard.update(false);
        captureSavedSnapshot();
        return true;
      } else {
        state = state.copyWith(isSavingProfile: false);
        return false;
      }
    } catch (e) {
      debugPrint('[saveProfileToFirestore] Error: $e');
      state = state.copyWith(isSavingProfile: false);
      return false;
    }
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
    final loyalty = _evaluateLoyalty(progress);

    state = state.copyWith(
      hasUnsavedProfileChanges: false,
      profileProgress: progress,
      stylePoints: loyalty.points,
      loyaltyRank: loyalty.rank,
      userName: fullName.isNotEmpty ? fullName : state.userName,
      userHandle: nick.isNotEmpty ? nick : state.userHandle,
    );
    WebUnloadGuard.update(false);
    captureSavedSnapshot();
  }

  void updateIdentityField(String key, String value) {
    final updated = Map<String, String>.from(state.identityValues)
      ..[key] = value;
    _updateProfileProgressAndLoyalty(identity: updated, markDirty: true);
  }

  void updateKycData(KycData kyc) {
    state = state.copyWith(kycData: kyc);
  }

  void setPersonaMode(String mode) {
    _updateProfileProgressAndLoyalty(personaMode: mode, markDirty: true);
  }

  void updateMediaSlot(String slotKey, String url) {
    final updated = Map<String, String>.from(state.mediaSlots)..[slotKey] = url;
    _updateProfileProgressAndLoyalty(mediaSlots: updated);
  }

  void deleteMediaSlot(String slotKey) {
    final updated = Map<String, String>.from(state.mediaSlots)..remove(slotKey);
    _updateProfileProgressAndLoyalty(mediaSlots: updated);
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
    _updateProfileProgressAndLoyalty(
      aiDna: updatedValues,
      aiDnaSources: updatedSources,
      markDirty: true,
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
    final list = referrals ?? state.referrals;
    final derivedCount = referralCount ?? list.length;
    final derivedTier =
        networkTier ?? ReferralService.calculateTier(derivedCount);
    state = state.copyWith(
      referralCode: referralCode,
      referralCount: derivedCount,
      networkTier: derivedTier,
      referrals: referrals,
    );
  }

  /// Completely resets 100% of user-scoped profile and session data to clean defaults,
  /// preserving only device-level preferences (such as locale and theme).
  void resetUserSession() {
    state = AppState(
      preferences: state.preferences,
      isLoggedIn: false,
      currentTab: AppTab.profile,
      currentProfileTab: 'p-identity',
      coins: 0,
      profileProgress: 0.10,
      stylePoints: 0,
      loyaltyRank: 'Bronze',
      aiUsageCount: 0,
      userName: '',
      userHandle: '',
      photoUrl: '',
      userLevel: 1,
      isSupportOpen: false,
      showFloatingSupport: state.preferences.showFloatingSupport,
      showHeaderCoins: state.preferences.showHeaderCoins,
      currentPlan: 'عادی (رایگان)',
      supportMessages: const [],
      hasUnsavedProfileChanges: false,
      isSavingProfile: false,
      companionSettings: const CompanionSettings(),
      identityValues: const {},
      notifications: const [],
      aiDnaSources: const {},
      aiDnaValues: const {},
      kycData: const KycData(),
      personaMode: 'full_body',
      mediaSlots: const {},
      referralCode: '',
      referralCount: 0,
      networkTier: 'Starter',
      referrals: const [],
      isProfileLoaded: false,
      loadedUid: null,
      termsAcceptedAt: null,
      termsVersion: null,
      legalConsent: null,
      savedSnapshot: null,
    );
  }

  /// Resets user state when switching accounts or signing out.
  void resetForAccountSwitch() {
    resetUserSession();
  }

  void logout() {
    resetUserSession();
  }

  /// Resets profile loaded flag and loaded UID when switching accounts or signing out.
  void resetProfileLoaded() {
    resetUserSession();
  }

  /// Electronically signs and records agreement to Terms of Service & Privacy Policy.
  Future<void> acceptTerms({String version = 'v2.0'}) async {
    final audit = await _profileSyncService.recordLegalConsent(
      version: version,
      documentHash: LegalDocumentV2.sha256Hash,
      loadedUid: state.loadedUid,
      currentName: state.userName,
      currentEmail: state.identityValues['email'],
    );

    state = state.copyWith(
      termsAcceptedAt: audit.acceptedAt,
      termsVersion: version,
      legalConsent: audit,
    );
  }

  /// Resets terms acceptance locally (used for testing or revocation).
  void clearTerms() {
    state = state.copyWith(clearTerms: true);
  }
}
