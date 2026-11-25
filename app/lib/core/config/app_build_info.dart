/// Centralized compile-time application build and version metadata.
///
/// Values are injected via `--dart-define` during CI/CD builds and fall back
/// to deterministic defaults matching `app/pubspec.yaml` for local runs.
abstract final class AppBuildInfo {
  /// Semantic version (`MAJOR.MINOR.PATCH`) injected via `APP_VERSION`.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Monotonically increasing integer build number injected via `BUILD_NUMBER`.
  static const int buildNumber = int.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 100,
  );

  /// Release date string (e.g. `YYYY-MM-DD` or `November 2026`) injected via `RELEASE_DATE`.
  static const String releaseDate = String.fromEnvironment(
    'RELEASE_DATE',
    defaultValue: 'November 2026',
  );

  /// Target environment (`preview` | `staging` | `production`) injected via `APP_ENV`.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'preview',
  );

  /// Optional Git commit SHA injected via `GIT_SHA`.
  static const String gitSha = String.fromEnvironment(
    'GIT_SHA',
    defaultValue: '',
  );

  /// Shortened 7-character Git SHA when available, or empty string.
  static String get shortGitSha =>
      gitSha.length > 7 ? gitSha.substring(0, 7) : gitSha;

  static bool get isPreview => environment == 'preview';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  /// Compares two SemVer strings ([current] vs [target]).
  ///
  /// Returns a negative value if [current] < [target], `0` if equal,
  /// and a positive value if [current] > [target].
  static int compareSemVer(String current, String target) {
    final p1 = _parseSemVerParts(current);
    final p2 = _parseSemVerParts(target);
    for (var i = 0; i < 3; i++) {
      if (p1[i] != p2[i]) {
        return p1[i].compareTo(p2[i]);
      }
    }
    return 0;
  }

  /// Returns `true` when [remoteBuild] or [remoteVersion] is newer than the
  /// running build ([currentBuild] / [currentVersion]).
  static bool isUpdateAvailable({
    required String remoteVersion,
    required int remoteBuild,
    String? currentVersion,
    int? currentBuild,
  }) {
    final effectiveBuild = currentBuild ?? buildNumber;
    final effectiveVersion = currentVersion ?? appVersion;

    if (remoteBuild > effectiveBuild) return true;
    final trimmedRemote = remoteVersion.trim();
    if (trimmedRemote.isNotEmpty &&
        compareSemVer(effectiveVersion, trimmedRemote) < 0) {
      return true;
    }
    return false;
  }

  /// Returns `true` when [minRequiredBuild] is positive and greater than
  /// [currentBuild] (defaulting to [buildNumber]).
  static bool isForceUpdateRequired({
    required int minRequiredBuild,
    int? currentBuild,
  }) {
    if (minRequiredBuild <= 0) return false;
    final effectiveBuild = currentBuild ?? buildNumber;
    return effectiveBuild < minRequiredBuild;
  }

  static List<int> _parseSemVerParts(String raw) {
    final cleaned = raw.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final core = cleaned.split(RegExp(r'[-+]')).first;
    if (core.isEmpty) return const [0, 0, 0];

    final segments = core.split('.');
    return List<int>.generate(3, (index) {
      if (index >= segments.length) return 0;
      return int.tryParse(segments[index].trim()) ?? 0;
    });
  }
}
