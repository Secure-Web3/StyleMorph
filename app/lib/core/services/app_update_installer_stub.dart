Future<void> downloadAndInstallApkImpl(
  String url, {
  required void Function(double progress) onProgress,
  String? version,
  int? build,
}) {
  throw UnsupportedError('APK installation is only supported on Android.');
}
