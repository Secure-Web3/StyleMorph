import '../domain/wardrobe_item.dart';

class WardrobeRepository {
  final List<WardrobeItem> _items;

  WardrobeRepository([List<WardrobeItem>? initialItems])
    : _items = initialItems != null ? List.from(initialItems) : [];

  List<WardrobeItem> getItems() => List.unmodifiable(_items);

  void addItem(WardrobeItem item) {
    _items.add(item);
  }

  void toggleFavorite(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isFavorite: !_items[index].isFavorite,
      );
    }
  }

  void toggleArchive(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isArchived: !_items[index].isArchived,
      );
    }
  }

  void deleteItem(String id) {
    _items.removeWhere((e) => e.id == id);
  }
}
