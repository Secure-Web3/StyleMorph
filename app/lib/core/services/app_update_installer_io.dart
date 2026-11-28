import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _appUpdaterChannel = MethodChannel(
  'com.stylemorph.stylemorph/app_updater',
);

/// Minimum expected size for a valid StyleMorph APK (5 MB).
const int kMinValidApkBytes = 5 * 1024 * 1024;

/// ZIP/APK magic header (`PK\x03\x04`).
const List<int> kApkMagicHeader = [0x50, 0x4B, 0x03, 0x04];

/// Exception thrown when a downloaded APK fails size or ZIP header validation.
class InvalidApkPackageException implements Exception {
  final String message;

  const InvalidApkPackageException(this.message);

  @override
  String toString() => 'InvalidApkPackageException: $message';
}

/// Builds a deterministic cached APK filename for [version] and [build].
@visibleForTesting
String buildCachedApkFileName({String? version, int? build}) {
  final cleanVersion = (version ?? '').trim().replaceAll(
    RegExp(r'[^0-9A-Za-z._-]'),
    '_',
  );
  final resolvedBuild = build ?? 0;
  if (cleanVersion.isNotEmpty || resolvedBuild > 0) {
    final verPart = cleanVersion.isNotEmpty ? cleanVersion : 'unknown';
    return 'StyleMorph-V$verPart-B$resolvedBuild.apk';
  }
  return 'StyleMorph-update.apk';
}

/// Validates that [file] exists, meets [minBytes], and starts with the
/// ZIP/APK magic header (`0x50, 0x4B, 0x03, 0x04`).
@visibleForTesting
Future<bool> isValidApkFile(
  File file, {
  int minBytes = kMinValidApkBytes,
}) async {
  try {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < minBytes) return false;

    final raf = await file.open(mode: FileMode.read);
    try {
      final header = await raf.read(4);
      if (header.length < 4) return false;
      for (var i = 0; i < 4; i++) {
        if (header[i] != kApkMagicHeader[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  } catch (_) {
    return false;
  }
}

/// Downloads an APK from [url] (following redirects) into the persistent
/// Android updates directory, validates its size and ZIP header, and launches
/// the native package installer. Valid cached APKs for the same version/build
/// are reused without re-downloading.
Future<void> downloadAndInstallApkImpl(
  String url, {
  required void Function(double progress) onProgress,
  String? version,
  int? build,
  @visibleForTesting Directory? updatesDirOverride,
  @visibleForTesting Future<void> Function(String filePath)? installApkOverride,
  @visibleForTesting Future<List<int>> Function(Uri uri)? downloadBytesOverride,
  @visibleForTesting int minValidBytes = kMinValidApkBytes,
}) async {
  if (!Platform.isAndroid && updatesDirOverride == null) {
    throw UnsupportedError('APK installation is only supported on Android.');
  }

  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    throw ArgumentError.value(url, 'url', 'Invalid APK download URL');
  }

  Directory targetDir;
  if (updatesDirOverride != null) {
    targetDir = updatesDirOverride;
  } else {
    String? cacheDirPath;
    try {
      cacheDirPath = await _appUpdaterChannel.invokeMethod<String>(
        'getUpdatesCacheDir',
      );
    } catch (_) {
      cacheDirPath = null;
    }
    targetDir = Directory(
      (cacheDirPath != null && cacheDirPath.isNotEmpty)
          ? cacheDirPath
          : '${Directory.systemTemp.path}${Platform.pathSeparator}updates',
    );
  }

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final fileName = buildCachedApkFileName(version: version, build: build);
  final apkFile = File('${targetDir.path}${Platform.pathSeparator}$fileName');

  Future<void> triggerInstall() async {
    if (installApkOverride != null) {
      await installApkOverride(apkFile.path);
    } else {
      await _appUpdaterChannel.invokeMethod<bool>('installApk', {
        'filePath': apkFile.path,
      });
    }
  }

  // Reuse an already-downloaded valid APK without re-downloading.
  if (await isValidApkFile(apkFile, minBytes: minValidBytes)) {
    onProgress(1.0);
    await triggerInstall();
    return;
  }

  if (await apkFile.exists()) {
    await apkFile.delete();
  }

  if (downloadBytesOverride != null) {
    onProgress(0.0);
    final bytes = await downloadBytesOverride(uri);
    await apkFile.writeAsBytes(bytes, flush: true);
  } else {
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
    } finally {
      await sink?.close();
      client.close(force: true);
    }
  }

  if (!await isValidApkFile(apkFile, minBytes: minValidBytes)) {
    if (await apkFile.exists()) {
      await apkFile.delete();
    }
    throw const InvalidApkPackageException(
      'Downloaded APK failed size or ZIP/APK header validation.',
    );
  }

  onProgress(1.0);
  await triggerInstall();
}
