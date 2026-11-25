/// Target domain for automated AI quality-control and verification.
enum AiVerificationTarget {
  kycDocument('kyc_document'),
  profileMedia('profile_media'),
  wardrobeGarment('wardrobe_garment');

  final String wireValue;
  const AiVerificationTarget(this.wireValue);
}

/// Lifecycle status of an automated AI media verification check.
enum AiVerificationStatus {
  pending('pending'),
  reviewing('reviewing'),
  approved('approved'),
  rejected('rejected'),
  needsManualReview('needs_manual_review');

  final String wireValue;
  const AiVerificationStatus(this.wireValue);

  static AiVerificationStatus fromWireValue(String? raw) {
    switch (raw) {
      case 'pending':
        return AiVerificationStatus.pending;
      case 'reviewing':
        return AiVerificationStatus.reviewing;
      case 'approved':
        return AiVerificationStatus.approved;
      case 'rejected':
        return AiVerificationStatus.rejected;
      case 'needs_manual_review':
      case 'needsManualReview':
        return AiVerificationStatus.needsManualReview;
      default:
        return AiVerificationStatus.needsManualReview;
    }
  }
}

/// Standardized machine-readable issue codes returned by pre-flight or AI QA.
enum AiVerificationIssueCode {
  fileTooLarge('file_too_large'),
  unsupportedFormat('unsupported_format'),
  lowResolution('low_resolution'),
  blurryOrDark('blurry_or_dark'),
  missingSubject('missing_subject'),
  policyViolation('policy_violation');

  final String wireValue;
  const AiVerificationIssueCode(this.wireValue);

  static AiVerificationIssueCode? fromWireValue(String? raw) {
    switch (raw) {
      case 'file_too_large':
      case 'fileTooLarge':
        return AiVerificationIssueCode.fileTooLarge;
      case 'unsupported_format':
      case 'unsupportedFormat':
        return AiVerificationIssueCode.unsupportedFormat;
      case 'low_resolution':
      case 'lowResolution':
        return AiVerificationIssueCode.lowResolution;
      case 'blurry_or_dark':
      case 'blurryOrDark':
        return AiVerificationIssueCode.blurryOrDark;
      case 'missing_subject':
      case 'missingSubject':
        return AiVerificationIssueCode.missingSubject;
      case 'policy_violation':
      case 'policyViolation':
        return AiVerificationIssueCode.policyViolation;
      default:
        return null;
    }
  }
}

/// Immutable result of an automated AI media verification pass.
class AiVerificationResult {
  final AiVerificationStatus status;
  final double confidenceScore;
  final String sha256Hash;
  final List<AiVerificationIssueCode> issues;
  final List<String> suggestedTags;
  final DateTime checkedAt;
  final bool isSimulated;

  const AiVerificationResult({
    required this.status,
    required this.confidenceScore,
    required this.sha256Hash,
    this.issues = const [],
    this.suggestedTags = const [],
    required this.checkedAt,
    this.isSimulated = false,
  });

  bool get isApproved => status == AiVerificationStatus.approved;
  bool get isRejected => status == AiVerificationStatus.rejected;
  bool get needsManualReview =>
      status == AiVerificationStatus.needsManualReview;

  factory AiVerificationResult.fromJson(
    Map<String, dynamic> json, {
    required String fallbackHash,
  }) {
    final rawIssues = json['issues'];
    final parsedIssues = <AiVerificationIssueCode>[];
    if (rawIssues is List) {
      for (final item in rawIssues) {
        final code = AiVerificationIssueCode.fromWireValue(item?.toString());
        if (code != null) {
          parsedIssues.add(code);
        }
      }
    }

    final rawTags = json['suggestedTags'];
    final parsedTags = rawTags is List
        ? rawTags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];

    final rawScore = json['confidenceScore'];
    final score = rawScore is num ? rawScore.toDouble().clamp(0.0, 1.0) : 0.0;

    return AiVerificationResult(
      status: AiVerificationStatus.fromWireValue(json['status']?.toString()),
      confidenceScore: score,
      sha256Hash: (json['sha256Hash']?.toString().isNotEmpty ?? false)
          ? json['sha256Hash'].toString()
          : fallbackHash,
      issues: List.unmodifiable(parsedIssues),
      suggestedTags: List.unmodifiable(parsedTags),
      checkedAt:
          DateTime.tryParse(json['checkedAt']?.toString() ?? '') ??
          DateTime.now(),
      isSimulated: json['isSimulated'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.wireValue,
    'confidenceScore': confidenceScore,
    'sha256Hash': sha256Hash,
    'issues': issues.map((e) => e.wireValue).toList(),
    'suggestedTags': suggestedTags,
    'checkedAt': checkedAt.toIso8601String(),
    'isSimulated': isSimulated,
  };
}
