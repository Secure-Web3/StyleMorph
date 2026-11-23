import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';

/// Gender-aware 3D character avatar widget with fallback silhouette.
///
/// Priority fallback in avatar hierarchy:
/// - Male variants ('male', 'مردانه', 'مرد', etc.) -> [maleAsset]
/// - Female variants ('female', 'زنانه', 'زن', etc.) -> [femaleAsset]
/// - Unselected / null / empty / 'non_binary' -> Subtle editorial silhouette icon
class Gender3dAvatar extends StatelessWidget {
  static const String maleAsset = 'assets/images/avatars/avatar_male_3d.jpg';
  static const String femaleAsset =
      'assets/images/avatars/avatar_female_3d.jpg';

  final String? gender;
  final double? size;
  final BoxFit fit;
  final Alignment alignment;

  const Gender3dAvatar({
    super.key,
    this.gender,
    this.size,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  });

  /// Returns true if [raw] corresponds to a male gender designation across supported locales.
  static bool isMale(String? raw) {
    if (raw == null) return false;
    final val = raw.trim().toLowerCase();
    const maleVariants = {
      'male',
      'm',
      'man',
      'men',
      'boy',
      'مرد',
      'مردانه',
      'آقا',
      'اقا',
      'پسر',
      'ذكر',
      'رجل',
      'erkek',
      'adam',
    };
    return maleVariants.contains(val);
  }

  /// Returns true if [raw] corresponds to a female gender designation across supported locales.
  static bool isFemale(String? raw) {
    if (raw == null) return false;
    final val = raw.trim().toLowerCase();
    const femaleVariants = {
      'female',
      'f',
      'woman',
      'women',
      'girl',
      'w',
      'زن',
      'زنانه',
      'خانم',
      'بانو',
      'دختر',
      'أنثى',
      'انثى',
      'امرأة',
      'امراة',
      'kadin',
      'kadın',
    };
    return femaleVariants.contains(val);
  }

  @override
  Widget build(BuildContext context) {
    if (isMale(gender)) {
      return Image.asset(
        maleAsset,
        width: size,
        height: size,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => _buildSilhouette(context),
      );
    }

    if (isFemale(gender)) {
      return Image.asset(
        femaleAsset,
        width: size,
        height: size,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => _buildSilhouette(context),
      );
    }

    return _buildSilhouette(context);
  }

  Widget _buildSilhouette(BuildContext context) {
    final colors = context.colors;
    final iconSize = (size != null) ? size! * 0.45 : 18.0;

    return Container(
      width: size,
      height: size,
      color: colors.sf,
      alignment: Alignment.center,
      child: FaIcon(
        FontAwesomeIcons.solidUser,
        size: iconSize,
        color: colors.mu.withValues(alpha: 0.6),
      ),
    );
  }
}
