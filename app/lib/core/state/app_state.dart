import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  shop,
  wardrobe,
  stylist,
  atelier,
  wellness,
  profile,
}

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
  final String targetRoute; // 'atelier_creations', 'shop', 'profile_wallet', 'stylist'
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
  final String userName;
  final String userHandle;
  final int userLevel;
  final bool isSupportOpen;
  final bool showFloatingSupport;
  final bool showHeaderCoins;
  final String currentPlan;
  final List<SupportMessage> supportMessages;

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

  // Gate-level pre-fetch flag: true once loadProfileFromFirestore() completes
  final bool isProfileLoaded;

  const AppState({
    this.isLoggedIn = false,
    this.currentTab = AppTab.profile,
    this.currentProfileTab = 'p-identity',
    this.coins = 0,
    this.profileProgress = 0.10,
    this.userName = '',
    this.userHandle = '',
    this.userLevel = 1,
    this.isSupportOpen = false,
    this.showFloatingSupport = true,
    this.showHeaderCoins = true,
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
    this.isProfileLoaded = false,
  });

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  AppState copyWith({
    bool? isLoggedIn,
    AppTab? currentTab,
    String? currentProfileTab,
    int? coins,
    double? profileProgress,
    String? userName,
    String? userHandle,
    int? userLevel,
    bool? isSupportOpen,
    bool? showFloatingSupport,
    bool? showHeaderCoins,
    String? currentPlan,
    bool? hasUnsavedProfileChanges,
    bool? isSavingProfile,
    Map<String, String>? identityValues,
    CompanionSettings? companionSettings,
    List<AppNotification>? notifications,
    List<SupportMessage>? supportMessages,
    Map<String, String>? aiDnaSources,
    Map<String, String>? aiDnaValues,
    bool? isProfileLoaded,
  }) {
    return AppState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentTab: currentTab ?? this.currentTab,
      currentProfileTab: currentProfileTab ?? this.currentProfileTab,
      coins: coins ?? this.coins,
      profileProgress: profileProgress ?? this.profileProgress,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      userLevel: userLevel ?? this.userLevel,
      isSupportOpen: isSupportOpen ?? this.isSupportOpen,
      showFloatingSupport: showFloatingSupport ?? this.showFloatingSupport,
      showHeaderCoins: showHeaderCoins ?? this.showHeaderCoins,
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
      isProfileLoaded: isProfileLoaded ?? this.isProfileLoaded,
    );
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    loadProfileFromFirestore();
  }

  /// Calculates profile completion percentage based on real filled fields.
  /// Starts near 10% (when only email is present) and increases dynamically.
  static double calculateProfileProgress({
    required Map<String, String> identity,
    required Map<String, String> aiDna,
  }) {
    double score = 0.0;
    if ((identity['email'] ?? '').trim().isNotEmpty) score += 0.10;
    if ((identity['firstName'] ?? '').trim().isNotEmpty) score += 0.10;
    if ((identity['lastName'] ?? '').trim().isNotEmpty) score += 0.10;
    if ((identity['nick'] ?? '').trim().isNotEmpty) score += 0.10;
    if ((identity['mobile'] ?? '').trim().isNotEmpty) score += 0.10;
    if ((identity['nid'] ?? '').trim().isNotEmpty) score += 0.10;
    if ((identity['country'] ?? '').trim().isNotEmpty ||
        (identity['city'] ?? '').trim().isNotEmpty) {
      score += 0.10;
    }
    if ((identity['address'] ?? '').trim().isNotEmpty ||
        (identity['zip'] ?? '').trim().isNotEmpty) {
      score += 0.10;
    }

    // Anatomy basics (Gender, Height, Weight)
    int anatomyBasics = 0;
    if ((aiDna['gender'] ?? '').trim().isNotEmpty) anatomyBasics++;
    if ((aiDna['height'] ?? '').trim().isNotEmpty) anatomyBasics++;
    if ((aiDna['weight'] ?? '').trim().isNotEmpty) anatomyBasics++;
    score += (anatomyBasics / 3.0) * 0.10;

    // Tailoring measurements
    int tailoringCount = 0;
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
      if ((aiDna[k] ?? '').trim().isNotEmpty) tailoringCount++;
    }
    score += (tailoringCount / tailoringKeys.length) * 0.10;

    return score.clamp(0.0, 1.0);
  }

  /// Only allow staying on Profile module while other modules are disabled.
  void switchTab(AppTab tab) {
    if (tab != AppTab.profile) return;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
            speechSpeed: (cMap['speechSpeed'] as num?)?.toDouble() ??
                companion.speechSpeed,
            responseLength:
                cMap['responseLength']?.toString() ?? companion.responseLength,
            activeScope:
                cMap['activeScope']?.toString() ?? companion.activeScope,
            saveHistory:
                cMap['saveHistory'] as bool? ?? companion.saveHistory,
            dailyTipEnabled:
                cMap['dailyTipEnabled'] as bool? ?? companion.dailyTipEnabled,
          );
        }

        final coins = (data['coins'] as num?)?.toInt() ??
            (data['coinBalance'] as num?)?.toInt() ??
            0;
        final currentPlan = data['plan']?.toString() ?? state.currentPlan;

        final first = identity['firstName']?.trim() ?? '';
        final last = identity['lastName']?.trim() ?? '';
        final fullName = '$first $last'.trim();
        final nick =
            identity['nick']?.trim() ?? data['handle']?.toString() ?? '';

        final progress = calculateProfileProgress(
          identity: identity,
          aiDna: aiDna,
        );

        state = state.copyWith(
          identityValues: identity,
          aiDnaValues: aiDna,
          companionSettings: companion,
          coins: coins,
          currentPlan: currentPlan,
          profileProgress: progress,
          userName: fullName.isNotEmpty
              ? fullName
              : (user.displayName ?? (user.email?.split('@').first ?? '')),
          userHandle: nick.isNotEmpty ? nick : '',
          hasUnsavedProfileChanges: false,
        );
      } else {
        final progress = calculateProfileProgress(
          identity: identity,
          aiDna: const {},
        );
        state = state.copyWith(
          identityValues: identity,
          aiDnaValues: const {},
          coins: 0,
          profileProgress: progress,
          userName: user.displayName ?? (user.email?.split('@').first ?? ''),
          userHandle: '',
          hasUnsavedProfileChanges: false,
        );
      }
    } catch (e) {
      debugPrint('[loadProfileFromFirestore] Error: $e');
    } finally {
      // Always mark profile as loaded so the auth gate can proceed
      state = state.copyWith(isProfileLoaded: true);
    }
  }

  /// Persists real profile data directly to Firestore `users/{uid}`.
  Future<bool> saveProfileToFirestore() async {
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
      );

      final first = state.identityValues['firstName']?.trim() ?? '';
      final last = state.identityValues['lastName']?.trim() ?? '';
      final fullName = '$first $last'.trim();
      final nick = state.identityValues['nick']?.trim() ?? state.userHandle;

      final dataToSave = <String, dynamic>{
        'email': user.email ?? (state.identityValues['email'] ?? ''),
        'displayName':
            fullName.isNotEmpty ? fullName : (user.displayName ?? ''),
        'handle': nick,
        'identity': state.identityValues,
        'aiDna': state.aiDnaValues,
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(dataToSave, SetOptions(merge: true));

      state = state.copyWith(
        isSavingProfile: false,
        hasUnsavedProfileChanges: false,
        profileProgress: progress,
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

  void saveProfileChanges() {
    final first = state.identityValues['firstName']?.trim() ?? '';
    final last = state.identityValues['lastName']?.trim() ?? '';
    final fullName = '$first $last'.trim();
    final nick = state.identityValues['nick']?.trim() ?? state.userHandle;

    final progress = calculateProfileProgress(
      identity: state.identityValues,
      aiDna: state.aiDnaValues,
    );

    state = state.copyWith(
      hasUnsavedProfileChanges: false,
      profileProgress: progress,
      userName: fullName.isNotEmpty ? fullName : state.userName,
      userHandle: nick.isNotEmpty ? nick : state.userHandle,
    );
  }

  void updateIdentityField(String key, String value) {
    final updated = Map<String, String>.from(state.identityValues)..[key] = value;
    final progress = calculateProfileProgress(
      identity: updated,
      aiDna: state.aiDnaValues,
    );
    state = state.copyWith(
      identityValues: updated,
      profileProgress: progress,
      hasUnsavedProfileChanges: true,
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
    final updatedValues = Map<String, String>.from(state.aiDnaValues)..[key] = value;
    final updatedSources = Map<String, String>.from(state.aiDnaSources)..[key] = 'USER';
    final progress = calculateProfileProgress(
      identity: state.identityValues,
      aiDna: updatedValues,
    );
    state = state.copyWith(
      aiDnaValues: updatedValues,
      aiDnaSources: updatedSources,
      profileProgress: progress,
      hasUnsavedProfileChanges: true,
    );
  }

  void toggleSupport([bool? open]) {
    state = state.copyWith(isSupportOpen: open ?? !state.isSupportOpen);
  }

  void toggleFloatingSupport(bool show) {
    state = state.copyWith(
      showFloatingSupport: show,
      isSupportOpen: show ? state.isSupportOpen : false,
    );
  }

  void toggleHeaderCoins(bool show) {
    state = state.copyWith(showHeaderCoins: show);
  }

  void markNotificationRead(String id) {
    final updated = state.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllNotificationsRead() {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
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

  void logout() {
    state = state.copyWith(
      isLoggedIn: false,
      identityValues: const {},
      aiDnaValues: const {},
      coins: 0,
      profileProgress: 0.10,
      userName: '',
      userHandle: '',
      hasUnsavedProfileChanges: false,
      isProfileLoaded: false,
    );
  }
}
