Future<void> downloadAndInstallApkImpl(
  String url, {
  required void Function(double progress) onProgress,
}) {
  throw UnsupportedError('APK installation is only supported on Android.');
}
