import 'iso_location_data.dart';

class IdentityValidator {
  // ── Iranian National ID (کد ملی) ──────────────────────────────────────────
  /// Validates a 10-digit Iranian National ID using the official Modulo-11
  /// check-digit algorithm, rejecting fake repeated numbers (e.g. 1111111111).
  static bool isValidIranianNationalId(String? input) {
    if (input == null) return false;
    final nid = input.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(nid)) return false;

    // Reject repeated digits (e.g., 0000000000, 1111111111, ..., 9999999999)
    final firstChar = nid[0];
    if (nid.split('').every((ch) => ch == firstChar)) return false;

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(nid[i]) * (10 - i);
    }

    final remainder = sum % 11;
    final checkDigit = int.parse(nid[9]);

    if (remainder < 2) {
      return checkDigit == remainder;
    } else {
      return checkDigit == (11 - remainder);
    }
  }

  // ── Turkish Kimlik (T.C. Kimlik No) ───────────────────────────────────────
  /// Validates an 11-digit Turkish Kimlik number according to the official
  /// algorithm:
  /// - 11 numeric digits, cannot start with 0.
  /// - 10th digit = ((Odd digits sum * 7) - Even digits sum) % 10.
  /// - 11th digit = (Sum of first 10 digits) % 10.
  static bool isValidTurkishKimlik(String? input) {
    if (input == null) return false;
    final tc = input.trim();
    if (!RegExp(r'^[1-9]\d{10}$').hasMatch(tc)) return false;

    final d = tc.split('').map(int.parse).toList();

    // Odd digits: index 0, 2, 4, 6, 8 (1st, 3rd, 5th, 7th, 9th)
    final oddSum = d[0] + d[2] + d[4] + d[6] + d[8];
    // Even digits: index 1, 3, 5, 7 (2nd, 4th, 6th, 8th)
    final evenSum = d[1] + d[3] + d[5] + d[7];

    final digit10 = ((oddSum * 7) - evenSum) % 10;
    if (digit10 != d[9]) return false;

    int first10Sum = 0;
    for (int i = 0; i < 10; i++) {
      first10Sum += d[i];
    }
    final digit11 = first10Sum % 10;
    return digit11 == d[10];
  }

  // ── International National ID Fallback ────────────────────────────────────
  /// For all other countries: accepts 5 to 25 alphanumeric or hyphen characters.
  static bool isValidInternationalNationalId(String? input) {
    if (input == null) return false;
    final id = input.trim();
    return RegExp(r'^[A-Za-z0-9\-]{5,25}$').hasMatch(id);
  }

  /// Country-aware National ID validator dispatcher
  static bool isValidNationalId(String? input, String countryCode) {
    if (input == null || input.trim().isEmpty) return false;
    switch (countryCode.toUpperCase()) {
      case 'IR':
        return isValidIranianNationalId(input);
      case 'TR':
        return isValidTurkishKimlik(input);
      default:
        return isValidInternationalNationalId(input);
    }
  }

  // ── Iranian Postal Code (کد پستی) ─────────────────────────────────────────
  /// 10 numeric digits, doesn't start with 0 or 2, and not repeated digits.
  static bool isValidIranianPostalCode(String? input) {
    if (input == null) return false;
    final zip = input.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(zip)) return false;
    if (zip.startsWith('0') || zip.startsWith('2')) return false;

    final firstChar = zip[0];
    if (zip.split('').every((ch) => ch == firstChar)) return false;
    return true;
  }

  // ── Turkish Postal Code ───────────────────────────────────────────────────
  /// Exactly 5 numeric digits.
  static bool isValidTurkishPostalCode(String? input) {
    if (input == null) return false;
    final zip = input.trim();
    return RegExp(r'^\d{5}$').hasMatch(zip);
  }

  // ── International Postal / ZIP Code ───────────────────────────────────────
  /// 3 to 12 alphanumeric, spaces, or hyphen characters.
  static bool isValidInternationalPostalCode(String? input) {
    if (input == null) return false;
    final zip = input.trim();
    return RegExp(r'^[A-Za-z0-9\s\-]{3,12}$').hasMatch(zip);
  }

  /// Country-aware Postal / ZIP Code validator dispatcher
  static bool isValidPostalCode(String? input, String countryCode) {
    if (input == null || input.trim().isEmpty) return false;
    switch (countryCode.toUpperCase()) {
      case 'IR':
        return isValidIranianPostalCode(input);
      case 'TR':
        return isValidTurkishPostalCode(input);
      default:
        return isValidInternationalPostalCode(input);
    }
  }

  // ── Mobile Number & E.164 Utilities ───────────────────────────────────────
  /// Strips any non-digit characters and any country-specific leading zeros
  /// (such as 0912 -> 912 in Iran or 0532 -> 532 in Turkey).
  static String normalizeSubscriber(String subscriber) {
    String clean = subscriber.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return clean;
  }

  /// Builds a canonical E.164 string like `+989123456789`.
  static String formatE164({
    required String dialCode,
    required String subscriber,
  }) {
    String cleanDial = dialCode.trim();
    if (!cleanDial.startsWith('+')) cleanDial = '+$cleanDial';
    final cleanSub = normalizeSubscriber(subscriber);
    if (cleanSub.isEmpty) return '';
    return '$cleanDial$cleanSub';
  }

  /// Validates subscriber digit count according to the selected country.
  static bool isValidSubscriber(String subscriber, IsoCountry country) {
    final clean = normalizeSubscriber(subscriber);
    if (clean.isEmpty) return false;

    switch (country.code.toUpperCase()) {
      case 'IR':
        // Iran: 10 digits, starts with 9 (e.g. 9123456789)
        return clean.length == 10 && clean.startsWith('9');
      case 'TR':
        // Turkey: 10 digits, starts with 5 (e.g. 5321234567)
        return clean.length == 10 && clean.startsWith('5');
      case 'AE':
        // UAE: 9 digits, typically starts with 5 (e.g. 501234567)
        return clean.length == 9 && clean.startsWith('5');
      case 'US':
      case 'CA':
        // US / Canada: 10 digits
        return clean.length == 10;
      default:
        // International fallback: between 7 and 15 digits
        return clean.length >= 7 && clean.length <= 15;
    }
  }

  /// Parses an existing canonical E.164 or plain mobile string into a dial code
  /// and subscriber number, matching against known ISO country dial codes.
  static ({IsoCountry country, String subscriber}) parseE164(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return (country: IsoLocationData.defaultCountry, subscriber: '');
    }

    String input = raw.trim();
    if (input.startsWith('00')) {
      input = '+${input.substring(2)}';
    }

    // Match dial code from longest to shortest (e.g. +971 before +98)
    final sortedCountries = List<IsoCountry>.from(IsoLocationData.countries)
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

    for (final c in sortedCountries) {
      if (input.startsWith(c.dialCode)) {
        final sub = input.substring(c.dialCode.length);
        return (country: c, subscriber: normalizeSubscriber(sub));
      }
    }

    // If starts with 09... (Iran domestic)
    if (input.startsWith('09') && input.length == 11) {
      return (
        country: IsoLocationData.defaultCountry,
        subscriber: input.substring(1),
      );
    }

    // Fallback: return default country with normalized digits
    return (
      country: IsoLocationData.defaultCountry,
      subscriber: normalizeSubscriber(input),
    );
  }
}
