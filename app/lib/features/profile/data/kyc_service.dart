import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'kyc_model.dart';

final kycServiceProvider = Provider<KycService>((ref) {
  return KycService();
});

class KycService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage? _storage;

  KycService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null as dynamic),
        _storage = storage ??
            (Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null);

  /// Uploads KYC document photo to Firebase Storage under `users/{uid}/kyc/{filename}`.
  Future<String> uploadKycImage({
    required String uid,
    required XFile file,
    required String tag,
  }) async {
    if (Firebase.apps.isEmpty || _storage == null) {
      return 'https://firebasestorage.googleapis.com/v0/b/mock/o/users%2F$uid%2Fkyc%2F${file.name}';
    }

    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$tag.$ext';
    final ref = _storage.ref().child('users').child(uid).child('kyc').child(filename);

    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uid': uid, 'tag': tag},
    );

    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
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

    if (Firebase.apps.isNotEmpty) {
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
  Future<void> deleteKyc(String uid, {String? frontUrl, String? backUrl}) async {
    if (Firebase.apps.isNotEmpty) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.update({
        'kyc': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await userDoc.collection('kyc').doc('main').delete();
      } catch (_) {}

      if (_storage != null) {
        if (frontUrl != null && frontUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(frontUrl).delete();
          } catch (_) {}
        }
        if (backUrl != null && backUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(backUrl).delete();
          } catch (_) {}
        }
      }
    }
  }
}
