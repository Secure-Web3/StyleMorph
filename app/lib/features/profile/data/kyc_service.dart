import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage/firebase_cloud_media_storage.dart';
import '../../../core/services/storage/firestore_inline_media_storage.dart';
import '../../../core/services/storage/media_storage_provider.dart';
import '../../../core/services/storage/media_storage_service.dart';
import 'kyc_model.dart';

final kycServiceProvider = Provider<KycService>((ref) {
  final mediaStorage = ref.watch(mediaStorageServiceProvider);
  return KycService(mediaStorage: mediaStorage);
});

class KycService {
  final FirebaseFirestore? _firestore;
  final MediaStorageService _mediaStorage;

  KycService({
    FirebaseFirestore? firestore,
    MediaStorageService? mediaStorage,
    FirebaseStorage? storage,
  }) : _firestore =
           firestore ??
           (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
       _mediaStorage =
           mediaStorage ??
           (storage != null
               ? FirebaseCloudMediaStorage(storage: storage)
               : const FirestoreInlineMediaStorage());

  /// Uploads KYC document photo under `users/{uid}/kyc/{filename}`.
  Future<String> uploadKycImage({
    required String uid,
    required XFile file,
    required String tag,
  }) async {
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$tag.$ext';
    final path = 'users/$uid/kyc/$filename';

    final bytes = await file.readAsBytes();
    return await _mediaStorage.uploadImage(
      path: path,
      bytes: bytes,
      mimeType: 'image/jpeg',
    );
  }

  /// Submits KYC document for review, storing metadata in Firestore root & subcollection.
  Future<KycData> submitKyc({
    required String uid,
    required KycDocType docType,
    required String frontUrl,
    String? backUrl,
  }) async {
    final kycData = KycData(
      status: KycStatus.pending,
      docType: docType,
      frontUrl: frontUrl,
      backUrl: backUrl,
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (Firebase.apps.isNotEmpty && _firestore != null) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.set({
        'kyc': kycData.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await userDoc.collection('kyc').doc('main').set(kycData.toMap());
    }

    return kycData;
  }

  /// Deletes KYC document and resets verification status in Firestore.
  Future<void> deleteKyc(
    String uid, {
    String? frontUrl,
    String? backUrl,
  }) async {
    if (Firebase.apps.isNotEmpty && _firestore != null) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.update({
        'kyc': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await userDoc.collection('kyc').doc('main').delete();
      } catch (_) {}
    }

    if (frontUrl != null && frontUrl.isNotEmpty) {
      try {
        await _mediaStorage.deleteMedia(frontUrl);
      } catch (_) {}
    }
    if (backUrl != null && backUrl.isNotEmpty) {
      try {
        await _mediaStorage.deleteMedia(backUrl);
      } catch (_) {}
    }
  }
}
