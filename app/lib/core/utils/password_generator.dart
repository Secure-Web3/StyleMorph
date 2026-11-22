import 'dart:math';

/// Generates a cryptographically strong random password guaranteed to meet all
/// StyleMorph security requirements:
/// - Length >= 8 (default: 12)
/// - Contains at least 1 uppercase letter
/// - Contains at least 1 lowercase letter
/// - Contains at least 1 number
/// - Contains at least 1 special character
String generateStrongPassword([int length = 12]) {
  assert(length >= 8, 'Password length must be at least 8 characters');

  // Exclude easily confused characters (I, O, l, 0, 1) for executive legibility
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lower = 'abcdefghijkmnopqrstuvwxyz';
  const digits = '23456789';
  const symbols = '!@#\$%^&*()-_=+';
  const allChars = '$upper$lower$digits$symbols';

  final random = Random.secure();
  final chars = <String>[
    upper[random.nextInt(upper.length)],
    lower[random.nextInt(lower.length)],
    digits[random.nextInt(digits.length)],
    symbols[random.nextInt(symbols.length)],
  ];

  for (int i = chars.length; i < length; i++) {
    chars.add(allChars[random.nextInt(allChars.length)]);
  }

  chars.shuffle(random);
  return chars.join();
}
