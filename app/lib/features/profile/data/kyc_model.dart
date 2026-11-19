import 'package:cloud_firestore/cloud_firestore.dart';

enum KycStatus {
  notSubmitted,
  pending,
  verified,
  rejected;

  static KycStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'pending':
        return KycStatus.pending;
      case 'verified':
        return KycStatus.verified;
      case 'rejected':
        return KycStatus.rejected;
      default:
        return KycStatus.notSubmitted;
    }
  }

  String toDbString() {
    switch (this) {
      case KycStatus.pending:
        return 'pending';
      case KycStatus.verified:
        return 'verified';
      case KycStatus.rejected:
        return 'rejected';
      case KycStatus.notSubmitted:
        return 'not_submitted';
    }
  }
}

enum KycDocType {
  nationalId,
  passport,
  driversLicense;

  static KycDocType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'passport':
        return KycDocType.passport;
      case 'drivers_license':
      case 'driverslicense':
        return KycDocType.driversLicense;
      default:
        return KycDocType.nationalId;
    }
  }

  String toDbString() {
    switch (this) {
      case KycDocType.passport:
        return 'passport';
      case KycDocType.driversLicense:
        return 'drivers_license';
      case KycDocType.nationalId:
        return 'national_id';
    }
  }
}

class KycData {
  final KycStatus status;
  final KycDocType docType;
  final String frontUrl;
  final String? backUrl;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  const KycData({
    this.status = KycStatus.notSubmitted,
    this.docType = KycDocType.nationalId,
    this.frontUrl = '',
    this.backUrl,
    this.rejectionReason,
    this.submittedAt,
    this.updatedAt,
  });

  bool get isSubmitted =>
      status != KycStatus.notSubmitted && frontUrl.isNotEmpty;
  bool get isVerified => status == KycStatus.verified;
  bool get isPending => status == KycStatus.pending;
  bool get isRejected => status == KycStatus.rejected;

  factory KycData.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const KycData();

    DateTime? parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d);
      return null;
    }

    return KycData(
      status: KycStatus.fromString(map['status']?.toString()),
      docType: KycDocType.fromString(map['docType']?.toString()),
      frontUrl: map['frontUrl']?.toString() ?? '',
      backUrl: map['backUrl']?.toString(),
      rejectionReason: map['rejectionReason']?.toString(),
      submittedAt: parseDate(map['submittedAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toDbString(),
      'docType': docType.toDbString(),
      'frontUrl': frontUrl,
      'backUrl': backUrl,
      'rejectionReason': rejectionReason ?? '',
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  KycData copyWith({
    KycStatus? status,
    KycDocType? docType,
    String? frontUrl,
    String? backUrl,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return KycData(
      status: status ?? this.status,
      docType: docType ?? this.docType,
      frontUrl: frontUrl ?? this.frontUrl,
      backUrl: backUrl ?? this.backUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
