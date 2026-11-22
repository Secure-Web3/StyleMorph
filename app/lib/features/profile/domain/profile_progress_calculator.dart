/// Pure calculation logic for weighted profile completion percentage.
///
/// Weight Breakdown (Canonical Formula: 40% Anatomy / 35% Media / 25% Identity):
/// - 40% Weight: Anatomy (3 basic fields + 9 tailoring/SMPL specs = 12 items total)
/// - 35% Weight: Media (Full Body: 4 required + 3 optional; Privacy: 2 required)
/// - 25% Weight: Identity (9 personal info fields)
class ProfileProgressCalculator {
  const ProfileProgressCalculator._();

  /// Calculates profile completion percentage as a normalized double in [0.0, 1.0].
  static double calculate({
    required Map<String, String> identity,
    required Map<String, String> aiDna,
    String personaMode = 'full_body',
    Map<String, String> mediaSlots = const {},
  }) {
    // 1. Identity Component (25% Weight = 0.25 total)
    // 9 distinct items: email, first, last, nick, mobile, nid, dob, country/city, address/zip
    int identityFilled = 0;
    if ((identity['email'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['firstName'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['lastName'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['nick'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['mobile'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['nid'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['dob'] ?? '').trim().isNotEmpty) identityFilled++;
    if ((identity['country'] ?? '').trim().isNotEmpty ||
        (identity['city'] ?? '').trim().isNotEmpty) {
      identityFilled++;
    }
    if ((identity['address'] ?? '').trim().isNotEmpty ||
        (identity['zip'] ?? '').trim().isNotEmpty) {
      identityFilled++;
    }
    final identityScore = (identityFilled / 9.0) * 0.25;

    // 2. Anatomy Component (40% Weight = 0.40 total)
    // 3 basic fields + 9 tailoring/SMPL specs = 12 items total
    int anatomyFilled = 0;
    if ((aiDna['gender'] ?? '').trim().isNotEmpty) anatomyFilled++;
    if ((aiDna['height'] ?? '').trim().isNotEmpty) anatomyFilled++;
    if ((aiDna['weight'] ?? '').trim().isNotEmpty) anatomyFilled++;

    const tailoringKeys = [
      'shoulder',
      'chest',
      'waist',
      'belly',
      'hips',
      'skinTone',
      'bodyShape',
      'faceShape',
      'hair',
    ];
    for (final k in tailoringKeys) {
      if ((aiDna[k] ?? '').trim().isNotEmpty ||
          (k == 'belly' && (aiDna['abdomen'] ?? '').trim().isNotEmpty) ||
          (k == 'bodyShape' &&
              (aiDna['bodySilhouette'] ?? '').trim().isNotEmpty) ||
          (k == 'hair' &&
              ((aiDna['hairColor'] ?? '').trim().isNotEmpty ||
                  (aiDna['hairTexture'] ?? '').trim().isNotEmpty))) {
        anatomyFilled++;
      }
    }
    final anatomyScore = (anatomyFilled / 12.0) * 0.40;

    // 3. Media Component (35% Weight = 0.35 total)
    double mediaScore = 0.0;
    if (personaMode == 'privacy_avatar') {
      int filled = 0;
      if ((mediaSlots['front_face'] ?? '').trim().isNotEmpty) filled++;
      if ((mediaSlots['side_face'] ?? '').trim().isNotEmpty) filled++;
      mediaScore = (filled / 2.0) * 0.35;
    } else {
      int reqFilled = 0;
      if ((mediaSlots['front_face'] ?? '').trim().isNotEmpty) reqFilled++;
      if ((mediaSlots['side_face'] ?? '').trim().isNotEmpty) reqFilled++;
      if ((mediaSlots['body_front'] ?? '').trim().isNotEmpty) reqFilled++;
      if ((mediaSlots['body_side'] ?? '').trim().isNotEmpty) reqFilled++;
      final reqScore = (reqFilled / 4.0) * 0.25;

      int optFilled = 0;
      if ((mediaSlots['body_back'] ?? '').trim().isNotEmpty) optFilled++;
      if ((mediaSlots['hand_skin'] ?? '').trim().isNotEmpty) optFilled++;
      if ((mediaSlots['scan_360'] ?? '').trim().isNotEmpty) optFilled++;
      final optScore = (optFilled / 3.0) * 0.10;

      mediaScore = reqScore + optScore;
    }

    final totalScore = identityScore + anatomyScore + mediaScore;
    return totalScore.clamp(0.0, 1.0);
  }
}
