import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Domain entity representing an authenticated StyleMorph mobile app user.
@immutable
class AuthUser {
  final String id;
  final String email;
  final String role;
  final String authProvider;
  final DateTime? createdAt;
  final String? displayName;

  const AuthUser({
    required this.id,
    required this.email,
    this.role = 'user',
    this.authProvider = 'email',
    this.createdAt,
    this.displayName,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'email': email,
      'role': role,
      'authProvider': authProvider,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (displayName != null && displayName!.isNotEmpty)
        'displayName': displayName,
    };
  }

  factory AuthUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawCreated = data['createdAt'];
    DateTime? resolvedCreated;
    if (rawCreated is Timestamp) {
      resolvedCreated = rawCreated.toDate();
    }

    return AuthUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      authProvider: data['authProvider'] as String? ?? 'email',
      createdAt: resolvedCreated,
      displayName: data['displayName'] as String?,
    );
  }
}
