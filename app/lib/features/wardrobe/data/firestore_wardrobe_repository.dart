import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/wardrobe_item.dart';
import 'wardrobe_repository.dart';

/// Live Firestore implementation of [WardrobeRepository] targeting `users/{uid}/wardrobe/{itemId}`.
class FirestoreWardrobeRepository implements WardrobeRepository {
  final FirebaseFirestore firestore;
  final String userId;

  FirestoreWardrobeRepository({required this.firestore, required this.userId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('users').doc(userId).collection('wardrobe');

  @override
  List<WardrobeItem> getItems() => const [];

  @override
  Future<WardrobePage> fetchPage({Object? startAfter, int limit = 20}) async {
    Query<Map<String, dynamic>> query = _collection
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => WardrobeItem.fromFirestore(doc))
        .toList();
    final lastCursor = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length == limit;

    return WardrobePage(items: items, lastCursor: lastCursor, hasMore: hasMore);
  }

  @override
  Future<void> addItem(WardrobeItem item) async {
    await _collection.doc(item.id).set(item.toFirestore());
  }

  @override
  Future<void> updateItem(WardrobeItem item) async {
    await _collection.doc(item.id).update(item.toFirestore());
  }

  @override
  Future<void> toggleFavorite(String id, [bool? isFavorite]) async {
    if (isFavorite != null) {
      await _collection.doc(id).update({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final doc = await _collection.doc(id).get();
      final current = (doc.data()?['isFavorite'] ?? false) as bool;
      await _collection.doc(id).update({
        'isFavorite': !current,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> toggleArchive(String id, [bool? isArchived]) async {
    if (isArchived != null) {
      await _collection.doc(id).update({
        'isArchived': isArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final doc = await _collection.doc(id).get();
      final current = (doc.data()?['isArchived'] ?? false) as bool;
      await _collection.doc(id).update({
        'isArchived': !current,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    await _collection.doc(id).delete();
  }
}
