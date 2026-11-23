import '../domain/wardrobe_item.dart';

/// Cursor-based pagination envelope for wardrobe items.
class WardrobePage {
  final List<WardrobeItem> items;
  final Object? lastCursor;
  final bool hasMore;

  const WardrobePage({
    required this.items,
    this.lastCursor,
    required this.hasMore,
  });
}

/// Abstract contract for wardrobe storage operations.
abstract class WardrobeRepository {
  List<WardrobeItem> getItems() => const [];
  Future<WardrobePage> fetchPage({Object? startAfter, int limit = 20});
  Future<void> addItem(WardrobeItem item);
  Future<void> updateItem(WardrobeItem item);
  Future<void> toggleFavorite(String id, [bool? isFavorite]);
  Future<void> toggleArchive(String id, [bool? isArchived]);
  Future<void> deleteItem(String id);
}

/// In-memory implementation used for unit/widget tests and unauthenticated fallback.
class InMemoryWardrobeRepository implements WardrobeRepository {
  final List<WardrobeItem> _items;

  InMemoryWardrobeRepository([List<WardrobeItem>? initialItems])
    : _items = initialItems != null ? List.from(initialItems) : [];

  @override
  List<WardrobeItem> getItems() => List.unmodifiable(_items);

  @override
  Future<WardrobePage> fetchPage({Object? startAfter, int limit = 20}) async {
    int startIndex = 0;
    if (startAfter != null) {
      if (startAfter is int) {
        startIndex = startAfter;
      } else if (startAfter is String) {
        final idx = _items.indexWhere((e) => e.id == startAfter);
        if (idx != -1) startIndex = idx + 1;
      }
    }

    if (startIndex >= _items.length) {
      return const WardrobePage(items: [], lastCursor: null, hasMore: false);
    }

    final endIndex = (startIndex + limit).clamp(0, _items.length);
    final pageItems = _items.sublist(startIndex, endIndex);
    final nextCursor = endIndex < _items.length ? endIndex : null;
    final hasMore = endIndex < _items.length;

    return WardrobePage(
      items: pageItems,
      lastCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  @override
  Future<void> addItem(WardrobeItem item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> updateItem(WardrobeItem item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  @override
  Future<void> toggleFavorite(String id, [bool? isFavorite]) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final next = isFavorite ?? !_items[index].isFavorite;
      _items[index] = _items[index].copyWith(isFavorite: next);
    }
  }

  @override
  Future<void> toggleArchive(String id, [bool? isArchived]) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final next = isArchived ?? !_items[index].isArchived;
      _items[index] = _items[index].copyWith(isArchived: next);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}
