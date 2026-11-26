import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Pure-Dart RFC 6238 TOTP generator/verifier & RFC 4648 Base32 utility.
/// Compatible with Google Authenticator, Apple Passwords, Microsoft Authenticator, and Authy.
class TotpHelper {
  TotpHelper._();

  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const int defaultPeriodSeconds = 30;
  static const int defaultDigits = 6;

  /// Generates a cryptographically secure 20-byte (160-bit) Base32 secret.
  static String generateSecret({int byteLength = 20, Random? random}) {
    final rng = random ?? Random.secure();
    final bytes = Uint8List(byteLength);
    for (var i = 0; i < byteLength; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return base32Encode(bytes);
  }

  /// Encodes raw bytes to unpadded uppercase RFC 4648 Base32.
  static String base32Encode(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    final buffer = StringBuffer();
    var bits = 0;
    var value = 0;

    for (final byte in bytes) {
      value = (value << 8) | (byte & 0xff);
      bits += 8;
      while (bits >= 5) {
        buffer.write(_base32Alphabet[(value >> (bits - 5)) & 0x1f]);
        bits -= 5;
      }
    }
    if (bits > 0) {
      buffer.write(_base32Alphabet[(value << (5 - bits)) & 0x1f]);
    }
    return buffer.toString();
  }

  /// Decodes a Base32 string (ignoring spaces, hyphens, and case) into bytes.
  static Uint8List base32Decode(String input) {
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[\s\-=]'), '');
    if (cleaned.isEmpty) return Uint8List(0);

    final out = <int>[];
    var bits = 0;
    var value = 0;

    for (var i = 0; i < cleaned.length; i++) {
      final idx = _base32Alphabet.indexOf(cleaned[i]);
      if (idx < 0) {
        throw FormatException('Invalid Base32 character: ${cleaned[i]}');
      }
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        out.add((value >> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    return Uint8List.fromList(out);
  }

  /// Builds a standard `otpauth://totp/...` URI for QR code scanning.
  static String buildOtpAuthUri({
    required String accountLabel,
    required String secret,
    String issuer = 'StyleMorph',
    int digits = defaultDigits,
    int period = defaultPeriodSeconds,
  }) {
    final cleanLabel = accountLabel.trim().isEmpty
        ? 'user'
        : accountLabel.trim();
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedLabel = Uri.encodeComponent('$issuer:$cleanLabel');
    final cleanSecret = secret.toUpperCase().replaceAll(RegExp(r'[\s\-=]'), '');
    return 'otpauth://totp/$encodedLabel'
        '?secret=$cleanSecret'
        '&issuer=$encodedIssuer'
        '&algorithm=SHA1'
        '&digits=$digits'
        '&period=$period';
  }

  /// Generates a 6-digit RFC 6238 TOTP code for [secret] at [timestamp].
  static String generateCode(
    String secret, {
    DateTime? timestamp,
    int periodSeconds = defaultPeriodSeconds,
    int digits = defaultDigits,
  }) {
    final now = timestamp ?? DateTime.now().toUtc();
    final counter = now.millisecondsSinceEpoch ~/ 1000 ~/ periodSeconds;
    return generateHotp(secret, counter, digits: digits);
  }

  /// Generates an RFC 4226 HOTP code for [secret] and [counter].
  static String generateHotp(
    String secret,
    int counter, {
    int digits = defaultDigits,
  }) {
    final key = base32Decode(secret);
    final counterBytes = Uint8List(8);
    var c = counter;
    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = c & 0xff;
      c = c >> 8;
    }

    final hmac = Hmac(sha1, key);
    final hash = hmac.convert(counterBytes).bytes;
    final offset = hash[hash.length - 1] & 0x0f;
    final binary =
        ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final mod = pow(10, digits).toInt();
    final otp = binary % mod;
    return otp.toString().padLeft(digits, '0');
  }

  /// Verifies a user-entered [code] against [secret] allowing ±[windowSteps]
  /// (default `1`, i.e. previous, current, and next 30-second window).
  static bool verifyCode(
    String secret,
    String code, {
    DateTime? timestamp,
    int periodSeconds = defaultPeriodSeconds,
    int digits = defaultDigits,
    int windowSteps = 1,
  }) {
    final normalizedCode = code.trim();
    if (normalizedCode.length != digits ||
        !RegExp(r'^\d+$').hasMatch(normalizedCode)) {
      return false;
    }

    try {
      final now = timestamp ?? DateTime.now().toUtc();
      final baseCounter = now.millisecondsSinceEpoch ~/ 1000 ~/ periodSeconds;
      for (var step = -windowSteps; step <= windowSteps; step++) {
        final expected = generateHotp(
          secret,
          baseCounter + step,
          digits: digits,
        );
        if (_constantTimeEquals(expected, normalizedCode)) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
