import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Electronic User Agreement & Terms Consent Audit Trail record.
@immutable
class LegalConsentAudit {
  final DateTime acceptedAt;
  final String contractVersion;
  final String signerUid;
  final String signerName;
  final String signerEmail;
  final String? ipAddress;
  final String? ipLocation;
  final String? deviceInfo;

  const LegalConsentAudit({
    required this.acceptedAt,
    required this.contractVersion,
    required this.signerUid,
    required this.signerName,
    required this.signerEmail,
    this.ipAddress,
    this.ipLocation,
    this.deviceInfo,
  });

  Map<String, dynamic> toMap() => {
    'acceptedAt': acceptedAt.toIso8601String(),
    'contractVersion': contractVersion,
    'signerUid': signerUid,
    'signerName': signerName,
    'signerEmail': signerEmail,
    if (ipAddress != null) 'ipAddress': ipAddress,
    if (ipLocation != null) 'ipLocation': ipLocation,
    if (deviceInfo != null) 'deviceInfo': deviceInfo,
  };

  factory LegalConsentAudit.fromMap(Map<String, dynamic> map) {
    DateTime dt = DateTime.now();
    if (map['acceptedAt'] != null) {
      if (map['acceptedAt'] is Timestamp) {
        dt = (map['acceptedAt'] as Timestamp).toDate();
      } else if (map['acceptedAt'] is String) {
        dt = DateTime.tryParse(map['acceptedAt'] as String) ?? dt;
      }
    }
    return LegalConsentAudit(
      acceptedAt: dt,
      contractVersion: map['contractVersion']?.toString() ?? '1.0',
      signerUid: map['signerUid']?.toString() ?? '',
      signerName: map['signerName']?.toString() ?? '',
      signerEmail: map['signerEmail']?.toString() ?? '',
      ipAddress: map['ipAddress']?.toString(),
      ipLocation: map['ipLocation']?.toString(),
      deviceInfo: map['deviceInfo']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalConsentAudit &&
          runtimeType == other.runtimeType &&
          acceptedAt == other.acceptedAt &&
          contractVersion == other.contractVersion &&
          signerUid == other.signerUid &&
          signerName == other.signerName &&
          signerEmail == other.signerEmail &&
          ipAddress == other.ipAddress &&
          ipLocation == other.ipLocation &&
          deviceInfo == other.deviceInfo;

  @override
  int get hashCode => Object.hash(
    acceptedAt,
    contractVersion,
    signerUid,
    signerName,
    signerEmail,
    ipAddress,
    ipLocation,
    deviceInfo,
  );
}
