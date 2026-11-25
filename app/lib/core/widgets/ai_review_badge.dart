import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../ai/ai_verification_models.dart';
import '../localization/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_badge.dart';

/// Reusable `shadcn`-styled verification status badge & compact review feedback
/// widget for KYC documents, Profile Media slots, and Virtual Wardrobe items.
class AiReviewBadge extends StatelessWidget {
  final AiVerificationStatus status;
  final List<AiVerificationIssueCode> issues;
  final bool compact;
  final VoidCallback? onTap;

  const AiReviewBadge({
    super.key,
    required this.status,
    this.issues = const [],
    this.compact = false,
    this.onTap,
  });

  /// Maps an [AiVerificationIssueCode] to a localized human-readable message.
  static String localizeIssue(
    AppStrings strings,
    AiVerificationIssueCode code,
  ) {
    switch (code) {
      case AiVerificationIssueCode.fileTooLarge:
        return strings.aiIssueFileTooLarge;
      case AiVerificationIssueCode.unsupportedFormat:
        return strings.aiIssueUnsupportedFormat;
      case AiVerificationIssueCode.lowResolution:
        return strings.aiIssueLowResolution;
      case AiVerificationIssueCode.blurryOrDark:
        return strings.aiIssueBlurryOrDark;
      case AiVerificationIssueCode.missingSubject:
        return strings.aiIssueMissingSubject;
      case AiVerificationIssueCode.policyViolation:
        return strings.aiIssuePolicyViolation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.colors;

    final AppBadgeVariant variant;
    final FaIconData icon;
    final String label;

    switch (status) {
      case AiVerificationStatus.pending:
      case AiVerificationStatus.reviewing:
        variant = AppBadgeVariant.info;
        icon = FontAwesomeIcons.wandMagicSparkles;
        label = strings.aiStatusReviewing;
        break;
      case AiVerificationStatus.approved:
        variant = AppBadgeVariant.success;
        icon = FontAwesomeIcons.circleCheck;
        label = strings.aiStatusApproved;
        break;
      case AiVerificationStatus.rejected:
        variant = AppBadgeVariant.destructive;
        icon = FontAwesomeIcons.circleExclamation;
        label = strings.aiStatusRejected;
        break;
      case AiVerificationStatus.needsManualReview:
        variant = AppBadgeVariant.warning;
        icon = FontAwesomeIcons.clock;
        label = strings.aiStatusManualReview;
        break;
    }

    final badge = AppBadge(
      variant: variant,
      size: compact ? AppBadgeSize.sm : AppBadgeSize.md,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: compact ? 9 : 11),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (compact || issues.isEmpty) {
      return badge;
    }

    final issueText = localizeIssue(strings, issues.first);
    final issueColor = status == AiVerificationStatus.rejected
        ? colors.orColor
        : colors.wn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: AppSpacing.xs),
        Text(issueText, style: AppTypography.caption(color: issueColor)),
      ],
    );
  }
}
