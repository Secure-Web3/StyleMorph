import 'package:flutter/foundation.dart';
import '../data/user_preferences.dart';
import 'companion_settings.dart';

export 'companion_settings.dart';

/// Immutable snapshot of profile state used for dirty checks and rollbacks.
@immutable
class ProfileSnapshot {
  final Map<String, String> identityValues;
  final Map<String, String> aiDnaValues;
  final Map<String, String> aiDnaSources;
  final UserPreferences preferences;
  final CompanionSettings companionSettings;
  final String personaMode;

  const ProfileSnapshot({
    required this.identityValues,
    required this.aiDnaValues,
    required this.aiDnaSources,
    required this.preferences,
    required this.companionSettings,
    required this.personaMode,
  });

  /// Captures an unmodifiable snapshot from the provided state parameters.
  factory ProfileSnapshot.capture({
    required Map<String, String> identityValues,
    required Map<String, String> aiDnaValues,
    required Map<String, String> aiDnaSources,
    required UserPreferences preferences,
    required CompanionSettings companionSettings,
    required String personaMode,
  }) {
    return ProfileSnapshot(
      identityValues: Map.unmodifiable(identityValues),
      aiDnaValues: Map.unmodifiable(aiDnaValues),
      aiDnaSources: Map.unmodifiable(aiDnaSources),
      preferences: preferences,
      companionSettings: companionSettings,
      personaMode: personaMode,
    );
  }

  /// Checks if the provided current values differ from this snapshot.
  bool hasDifferences({
    required Map<String, String> currentIdentity,
    required Map<String, String> currentAiDna,
    required Map<String, String> currentAiDnaSources,
    required UserPreferences currentPreferences,
    required CompanionSettings currentCompanionSettings,
    required String currentPersonaMode,
  }) {
    if (personaMode != currentPersonaMode) return true;
    if (preferences != currentPreferences) return true;
    if (companionSettings != currentCompanionSettings) return true;
    if (!_mapEquals(identityValues, currentIdentity)) return true;
    if (!_mapEquals(aiDnaValues, currentAiDna)) return true;
    if (!_mapEquals(aiDnaSources, currentAiDnaSources)) return true;
    return false;
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileSnapshot &&
          runtimeType == other.runtimeType &&
          personaMode == other.personaMode &&
          preferences == other.preferences &&
          companionSettings == other.companionSettings &&
          _mapEquals(identityValues, other.identityValues) &&
          _mapEquals(aiDnaValues, other.aiDnaValues) &&
          _mapEquals(aiDnaSources, other.aiDnaSources);

  @override
  int get hashCode => Object.hash(
    personaMode,
    preferences,
    companionSettings,
    Object.hashAll(identityValues.entries),
    Object.hashAll(aiDnaValues.entries),
    Object.hashAll(aiDnaSources.entries),
  );
}
