import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wardrobe_repository.dart';
import '../domain/wardrobe_item.dart';

class WardrobeFilter {
  final String category; // 'all','cl','sh','bg','jw','ac'
  final String searchQuery;
  final String colorFilter; // '' = all, else hex
  final String seasonFilter; // '' = all, else season name
  final String occasionFilter; // '' = all, else occasion name
  final bool showArchived;
  final bool multiSelectMode;
  final Set<String> selectedIds;

  const WardrobeFilter({
    this.category = 'all',
    this.searchQuery = '',
    this.colorFilter = '',
    this.seasonFilter = '',
    this.occasionFilter = '',
    this.showArchived = false,
    this.multiSelectMode = false,
    this.selectedIds = const {},
  });

  WardrobeFilter copyWith({
    String? category,
    String? searchQuery,
    String? colorFilter,
    String? seasonFilter,
    String? occasionFilter,
    bool? showArchived,
    bool? multiSelectMode,
    Set<String>? selectedIds,
  }) {
    return WardrobeFilter(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      colorFilter: colorFilter ?? this.colorFilter,
      seasonFilter: seasonFilter ?? this.seasonFilter,
      occasionFilter: occasionFilter ?? this.occasionFilter,
      showArchived: showArchived ?? this.showArchived,
      multiSelectMode: multiSelectMode ?? this.multiSelectMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class WardrobeState {
  final List<WardrobeItem> items;
  final WardrobeFilter filter;
  final bool filterPanelOpen;

  const WardrobeState({
    required this.items,
    required this.filter,
    this.filterPanelOpen = false,
  });

  WardrobeState copyWith({
    List<WardrobeItem>? items,
    WardrobeFilter? filter,
    bool? filterPanelOpen,
  }) {
    return WardrobeState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      filterPanelOpen: filterPanelOpen ?? this.filterPanelOpen,
    );
  }

  List<WardrobeItem> get filteredItems {
    return items.where((item) {
      if (!filter.showArchived && item.isArchived) return false;
      if (filter.showArchived && !item.isArchived) return false;
      if (filter.category != 'all' && item.category != filter.category) {
        return false;
      }
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.colorName.toLowerCase().contains(q) &&
            !item.subCategory.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (filter.colorFilter.isNotEmpty &&
          item.colorHex != filter.colorFilter) {
        return false;
      }
      if (filter.seasonFilter.isNotEmpty &&
          item.season != 'همه' &&
          item.season != filter.seasonFilter) {
        return false;
      }
      if (filter.occasionFilter.isNotEmpty &&
          item.occasion != filter.occasionFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  int countByCategory(String cat) {
    if (cat == 'all') return items.where((e) => !e.isArchived).length;
    return items.where((e) => e.category == cat && !e.isArchived).length;
  }
}

class WardrobeNotifier extends StateNotifier<WardrobeState> {
  final WardrobeRepository _repo;

  WardrobeNotifier(this._repo)
    : super(
        WardrobeState(items: _repo.getItems(), filter: const WardrobeFilter()),
      );

  void setCategory(String cat) {
    state = state.copyWith(filter: state.filter.copyWith(category: cat));
  }

  void setSearch(String query) {
    state = state.copyWith(filter: state.filter.copyWith(searchQuery: query));
  }

  void setColorFilter(String hex) {
    final newHex = state.filter.colorFilter == hex ? '' : hex;
    state = state.copyWith(filter: state.filter.copyWith(colorFilter: newHex));
  }

  void setSeasonFilter(String season) {
    final newSeason = state.filter.seasonFilter == season ? '' : season;
    state = state.copyWith(
      filter: state.filter.copyWith(seasonFilter: newSeason),
    );
  }

  void setOccasionFilter(String occ) {
    final newOcc = state.filter.occasionFilter == occ ? '' : occ;
    state = state.copyWith(
      filter: state.filter.copyWith(occasionFilter: newOcc),
    );
  }

  void toggleArchiveView() {
    state = state.copyWith(
      filter: state.filter.copyWith(showArchived: !state.filter.showArchived),
    );
  }

  void toggleFilterPanel() {
    state = state.copyWith(filterPanelOpen: !state.filterPanelOpen);
  }

  void clearFilters() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        colorFilter: '',
        seasonFilter: '',
        occasionFilter: '',
        searchQuery: '',
      ),
    );
  }

  void toggleFavorite(String id) {
    _repo.toggleFavorite(id);
    state = state.copyWith(items: _repo.getItems());
  }

  void toggleArchive(String id) {
    _repo.toggleArchive(id);
    state = state.copyWith(items: _repo.getItems());
  }

  void deleteItem(String id) {
    _repo.deleteItem(id);
    state = state.copyWith(items: _repo.getItems());
  }

  void addItem(WardrobeItem item) {
    _repo.addItem(item);
    state = state.copyWith(items: _repo.getItems());
  }
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>(
  (_) => WardrobeRepository(),
);

final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>(
  (ref) => WardrobeNotifier(ref.read(wardrobeRepositoryProvider)),
);
