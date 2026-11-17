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
  final Map<String, String> identityValues;
  final CompanionSettings companionSettings;

  // Notification Center state
  final List<AppNotification> notifications;

  // AI DNA & Tailoring field source tracking ('AI' or 'USER')
  final Map<String, String> aiDnaSources;
  final Map<String, String> aiDnaValues;

  const AppState({
    this.isLoggedIn = false,
    this.currentTab = AppTab.wardrobe,
    this.currentProfileTab = 'p-identity',
    this.coins = 0,
    this.profileProgress = 0.0,
    this.userName = '',
    this.userHandle = '',
    this.userLevel = 1,
    this.isSupportOpen = false,
    this.showFloatingSupport = true,
    this.showHeaderCoins = true,
    this.currentPlan = 'عادی (رایگان)',
    this.hasUnsavedProfileChanges = false,
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
    Map<String, String>? identityValues,
    CompanionSettings? companionSettings,
    List<AppNotification>? notifications,
    List<SupportMessage>? supportMessages,
    Map<String, String>? aiDnaSources,
    Map<String, String>? aiDnaValues,
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
      identityValues: identityValues ?? this.identityValues,
      companionSettings: companionSettings ?? this.companionSettings,
      notifications: notifications ?? this.notifications,
      supportMessages: supportMessages ?? this.supportMessages,
      aiDnaSources: aiDnaSources ?? this.aiDnaSources,
      aiDnaValues: aiDnaValues ?? this.aiDnaValues,
    );
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

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

  void saveProfileChanges() {
    final first = state.identityValues['firstName']?.trim() ?? '';
    final last = state.identityValues['lastName']?.trim() ?? '';
    final fullName = '$first $last'.trim();
    final nick = state.identityValues['nick']?.trim() ?? state.userHandle;

    state = state.copyWith(
      hasUnsavedProfileChanges: false,
      userName: fullName.isNotEmpty ? fullName : state.userName,
      userHandle: nick.isNotEmpty ? nick : state.userHandle,
    );
  }

  void updateIdentityField(String key, String value) {
    final updated = Map<String, String>.from(state.identityValues)..[key] = value;
    state = state.copyWith(
      identityValues: updated,
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
    state = state.copyWith(
      aiDnaValues: updatedValues,
      aiDnaSources: updatedSources,
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
  }

  void logout() {
    state = state.copyWith(isLoggedIn: false);
  }
}
