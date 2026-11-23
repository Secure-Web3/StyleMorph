import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/widgets/legal_doc_modal_sheet.dart';

/// Pinned footer component displaying the official copyright text (`StyleMorph 2026 ©`)
/// and optional legal quick links (`Terms • Privacy • Legal Info`).
/// Pinned to the absolute bottom of Auth and Welcome screens.
class AuthFooter extends StatelessWidget {
  final bool isTransparent;
  final bool showLegalLinks;

  const AuthFooter({
    super.key,
    this.isTransparent = false,
    this.showLegalLinks = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final linkColor = isTransparent
        ? Colors.white.withValues(alpha: 0.85)
        : colors.mu;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
        vertical: showLegalLinks ? AppSpacing.sm : AppSpacing.md,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLegalLinks) ...[
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                _buildLegalLink(
                  context,
                  key: const Key('auth_footer_legal_terms'),
                  label: strings.legalTabTerms,
                  color: linkColor,
                  onTap: () =>
                      LegalDocModalSheet.showTerms(context, previewOnly: true),
                ),
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: 11,
                    color: linkColor.withValues(alpha: 0.5),
                  ),
                ),
                _buildLegalLink(
                  context,
                  key: const Key('auth_footer_legal_privacy'),
                  label: strings.legalTabPrivacy,
                  color: linkColor,
                  onTap: () => LegalDocModalSheet.showPrivacy(
                    context,
                    previewOnly: true,
                  ),
                ),
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: 11,
                    color: linkColor.withValues(alpha: 0.5),
                  ),
                ),
                _buildLegalLink(
                  context,
                  key: const Key('auth_footer_legal_info'),
                  label: strings.legalTabLegalInfo,
                  color: linkColor,
                  onTap: () => LegalDocModalSheet.showLegalInfo(
                    context,
                    previewOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
          Text(
            strings.authCopyrightYear,
            style: AppTypography.caption(
              color: isTransparent
                  ? Colors.white.withValues(alpha: 0.75)
                  : colors.mu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(
    BuildContext context, {
    required Key key,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: 2,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
            decoration: TextDecoration.underline,
            decorationColor: color.withValues(alpha: 0.35),
            decorationThickness: 1.0,
          ),
        ),
      ),
    );
  }
}
