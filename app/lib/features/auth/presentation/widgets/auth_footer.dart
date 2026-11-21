import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Pinned footer component displaying the official copyright text (`StyleMorph 2026 ©`).
/// Pinned to the absolute bottom of Auth and Welcome screens.
class AuthFooter extends StatelessWidget {
  final bool isTransparent;

  const AuthFooter({super.key, this.isTransparent = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : colors.bg,
        border: isTransparent
            ? null
            : Border(
                top: BorderSide(
                  color: colors.bd.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
      ),
      child: Center(
        child: Text(
          strings.authCopyrightYear,
          style: AppTypography.caption(
            color: isTransparent
                ? Colors.white.withValues(alpha: 0.75)
                : colors.mu,
          ),
        ),
      ),
    );
  }
}
