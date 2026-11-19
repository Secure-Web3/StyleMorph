import 'package:flutter/foundation.dart';

/// User preferences model persisted in Firestore under `users/{uid}.preferences`.
@immutable
class UserPreferences {
  final String fashionThemePalette;
  final String brightnessMode;
  final String appLanguage;
  final bool showFloatingSupport;
  final bool showHeaderCoins;
  final bool showEmailInHeader;
  final bool biometricLock;
  final String autoDataBackup;

  const UserPreferences({
    this.fashionThemePalette = 'editorial',
    this.brightnessMode = 'light',
    this.appLanguage = 'en',
    this.showFloatingSupport = false,
    this.showHeaderCoins = false,
    this.showEmailInHeader = false,
    this.biometricLock = false,
    this.autoDataBackup = 'weekly',
  });

  Map<String, dynamic> toMap() {
    return {
      'fashionThemePalette': fashionThemePalette,
      'brightnessMode': brightnessMode,
      'appLanguage': appLanguage,
      'showFloatingSupport': showFloatingSupport,
      'showHeaderCoins': showHeaderCoins,
      'showEmailInHeader': showEmailInHeader,
      'biometricLock': biometricLock,
      'autoDataBackup': autoDataBackup,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPreferences();
    return UserPreferences(
      fashionThemePalette: map['fashionThemePalette']?.toString() ??
          map['palette']?.toString() ??
          'editorial',
      brightnessMode: map['brightnessMode']?.toString() ??
          map['mode']?.toString() ??
          'light',
      appLanguage: map['appLanguage']?.toString() ??
          map['language']?.toString() ??
          'en',
      showFloatingSupport: map['showFloatingSupport'] as bool? ??
          map['floatingSupport'] as bool? ??
          false,
      showHeaderCoins: map['showHeaderCoins'] as bool? ??
          map['headerCoins'] as bool? ??
          false,
      showEmailInHeader: map['showEmailInHeader'] as bool? ?? false,
      biometricLock: map['biometricLock'] as bool? ??
          map['biometricEnabled'] as bool? ??
          false,
      autoDataBackup: map['autoDataBackup']?.toString() ??
          map['backupFrequency']?.toString() ??
          'weekly',
    );
  }

  UserPreferences copyWith({
    String? fashionThemePalette,
    String? brightnessMode,
    String? appLanguage,
    bool? showFloatingSupport,
    bool? showHeaderCoins,
    bool? showEmailInHeader,
    bool? biometricLock,
    String? autoDataBackup,
  }) {
    return UserPreferences(
      fashionThemePalette: fashionThemePalette ?? this.fashionThemePalette,
      brightnessMode: brightnessMode ?? this.brightnessMode,
      appLanguage: appLanguage ?? this.appLanguage,
      showFloatingSupport: showFloatingSupport ?? this.showFloatingSupport,
      showHeaderCoins: showHeaderCoins ?? this.showHeaderCoins,
      showEmailInHeader: showEmailInHeader ?? this.showEmailInHeader,
      biometricLock: biometricLock ?? this.biometricLock,
      autoDataBackup: autoDataBackup ?? this.autoDataBackup,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          fashionThemePalette == other.fashionThemePalette &&
          brightnessMode == other.brightnessMode &&
          appLanguage == other.appLanguage &&
          showFloatingSupport == other.showFloatingSupport &&
          showHeaderCoins == other.showHeaderCoins &&
          showEmailInHeader == other.showEmailInHeader &&
          biometricLock == other.biometricLock &&
          autoDataBackup == other.autoDataBackup;

  @override
  int get hashCode =>
      fashionThemePalette.hashCode ^
      brightnessMode.hashCode ^
      appLanguage.hashCode ^
      showFloatingSupport.hashCode ^
      showHeaderCoins.hashCode ^
      showEmailInHeader.hashCode ^
      biometricLock.hashCode ^
      autoDataBackup.hashCode;
}
