import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _appUpdaterChannel = MethodChannel(
  'com.stylemorph.stylemorph/app_updater',
);

/// Downloads an APK from [url] (following redirects) into the Android
/// FileProvider cache directory and launches the native package installer.
Future<void> downloadAndInstallApkImpl(
  String url, {
  required void Function(double progress) onProgress,
}) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError('APK installation is only supported on Android.');
  }

  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    throw ArgumentError.value(url, 'url', 'Invalid APK download URL');
  }

  String? cacheDirPath;
  try {
    cacheDirPath = await _appUpdaterChannel.invokeMethod<String>(
      'getUpdatesCacheDir',
    );
  } catch (_) {
    cacheDirPath = null;
  }

  final targetDir = Directory(
    (cacheDirPath != null && cacheDirPath.isNotEmpty)
        ? cacheDirPath
        : '${Directory.systemTemp.path}${Platform.pathSeparator}updates',
  );
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final apkFile = File(
    '${targetDir.path}${Platform.pathSeparator}StyleMorph-update.apk',
  );
  if (await apkFile.exists()) {
    await apkFile.delete();
  }

  final client = HttpClient();
  IOSink? sink;
  try {
    final request = await client.getUrl(uri);
    request.followRedirects = true;
    request.maxRedirects = 8;
    final response = await request.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'APK download failed with HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    onProgress(0.0);

    sink = apkFile.openWrite();
    await for (final chunk in response) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
      }
    }
    await sink.flush();
    await sink.close();
    sink = null;
    onProgress(1.0);
  } finally {
    await sink?.close();
    client.close(force: true);
  }

  await _appUpdaterChannel.invokeMethod<bool>('installApk', {
    'filePath': apkFile.path,
  });
}
