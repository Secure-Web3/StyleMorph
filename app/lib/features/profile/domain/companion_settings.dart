import 'package:flutter/foundation.dart';

/// Settings for AI Companion & Stylist interactions.
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

  Map<String, dynamic> toMap() => {
    'characterId': characterId,
    'customName': customName,
    'tone': tone,
    'critiqueStrictness': critiqueStrictness,
    'voiceEnabled': voiceEnabled,
    'subtitleEnabled': subtitleEnabled,
    'voiceType': voiceType,
    'speechSpeed': speechSpeed,
    'responseLength': responseLength,
    'activeScope': activeScope,
    'saveHistory': saveHistory,
    'dailyTipEnabled': dailyTipEnabled,
  };

  factory CompanionSettings.fromMap(
    Map<String, dynamic> map, [
    CompanionSettings? fallback,
  ]) {
    final def = fallback ?? const CompanionSettings();
    return CompanionSettings(
      characterId: map['characterId']?.toString() ?? def.characterId,
      customName: map['customName']?.toString() ?? def.customName,
      tone: map['tone']?.toString() ?? def.tone,
      critiqueStrictness:
          (map['critiqueStrictness'] as num?)?.toDouble() ??
          def.critiqueStrictness,
      voiceEnabled: map['voiceEnabled'] as bool? ?? def.voiceEnabled,
      subtitleEnabled: map['subtitleEnabled'] as bool? ?? def.subtitleEnabled,
      voiceType: map['voiceType']?.toString() ?? def.voiceType,
      speechSpeed: (map['speechSpeed'] as num?)?.toDouble() ?? def.speechSpeed,
      responseLength: map['responseLength']?.toString() ?? def.responseLength,
      activeScope: map['activeScope']?.toString() ?? def.activeScope,
      saveHistory: map['saveHistory'] as bool? ?? def.saveHistory,
      dailyTipEnabled: map['dailyTipEnabled'] as bool? ?? def.dailyTipEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanionSettings &&
          runtimeType == other.runtimeType &&
          characterId == other.characterId &&
          customName == other.customName &&
          tone == other.tone &&
          critiqueStrictness == other.critiqueStrictness &&
          voiceEnabled == other.voiceEnabled &&
          subtitleEnabled == other.subtitleEnabled &&
          voiceType == other.voiceType &&
          speechSpeed == other.speechSpeed &&
          responseLength == other.responseLength &&
          activeScope == other.activeScope &&
          saveHistory == other.saveHistory &&
          dailyTipEnabled == other.dailyTipEnabled;

  @override
  int get hashCode => Object.hash(
    characterId,
    customName,
    tone,
    critiqueStrictness,
    voiceEnabled,
    subtitleEnabled,
    voiceType,
    speechSpeed,
    responseLength,
    activeScope,
    saveHistory,
    dailyTipEnabled,
  );
}
