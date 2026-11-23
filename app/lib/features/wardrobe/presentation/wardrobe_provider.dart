import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage/media_storage_provider.dart';
import '../../../core/services/storage/media_storage_service.dart';
import '../data/firestore_wardrobe_repository.dart';
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

  int get activeFilterCount {
    int count = 0;
    if (colorFilter.isNotEmpty) count++;
    if (seasonFilter.isNotEmpty) count++;
    if (occasionFilter.isNotEmpty) count++;
    return count;
  }
}

class WardrobeState {
  static const Object _unset = Object();

  final List<WardrobeItem> items;
  final WardrobeFilter filter;
  final bool filterPanelOpen;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? lastCursor;
  final String? errorMessage;

  const WardrobeState({
    required this.items,
    required this.filter,
    this.filterPanelOpen = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.lastCursor,
    this.errorMessage,
  });

  WardrobeState copyWith({
    List<WardrobeItem>? items,
    WardrobeFilter? filter,
    bool? filterPanelOpen,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? lastCursor = _unset,
    String? errorMessage,
  }) {
    return WardrobeState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      filterPanelOpen: filterPanelOpen ?? this.filterPanelOpen,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastCursor: identical(lastCursor, _unset) ? this.lastCursor : lastCursor,
      errorMessage: errorMessage,
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
  final MediaStorageService? _storageService;
  final String? _userId;

  WardrobeNotifier(this._repo, [this._storageService, this._userId])
    : super(
        WardrobeState(
          items: _repo is InMemoryWardrobeRepository
              ? _repo.getItems()
              : const [],
          filter: const WardrobeFilter(),
        ),
      ) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _repo.fetchPage(limit: 20);
      state = state.copyWith(
        items: page.items,
        lastCursor: page.lastCursor,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.fetchPage(
        startAfter: state.lastCursor,
        limit: 20,
      );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        lastCursor: page.lastCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

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

  void applyAdvancedFilters({
    required String color,
    required String season,
    required String occasion,
  }) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        colorFilter: color,
        seasonFilter: season,
        occasionFilter: occasion,
      ),
    );
  }

  Future<void> toggleFavorite(String id) async {
    final idx = state.items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final current = state.items[idx];
    final updated = current.copyWith(isFavorite: !current.isFavorite);

    // Optimistic UI update
    final newItems = List<WardrobeItem>.from(state.items);
    newItems[idx] = updated;
    state = state.copyWith(items: newItems);

    try {
      await _repo.toggleFavorite(id, updated.isFavorite);
    } catch (_) {
      // Rollback on failure
      final rollback = List<WardrobeItem>.from(state.items);
      rollback[idx] = current;
      state = state.copyWith(items: rollback);
    }
  }

  Future<void> toggleArchive(String id) async {
    final idx = state.items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final current = state.items[idx];
    final updated = current.copyWith(isArchived: !current.isArchived);

    // Optimistic UI update
    final newItems = List<WardrobeItem>.from(state.items);
    newItems[idx] = updated;
    state = state.copyWith(items: newItems);

    try {
      await _repo.toggleArchive(id, updated.isArchived);
    } catch (_) {
      // Rollback on failure
      final rollback = List<WardrobeItem>.from(state.items);
      rollback[idx] = current;
      state = state.copyWith(items: rollback);
    }
  }

  Future<void> updateItem(WardrobeItem item) async {
    final idx = state.items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      final newItems = List<WardrobeItem>.from(state.items);
      newItems[idx] = item;
      state = state.copyWith(items: newItems);
    }
    await _repo.updateItem(item);
  }

  Future<void> deleteItem(String id) async {
    final target = state.items.cast<WardrobeItem?>().firstWhere(
      (e) => e?.id == id,
      orElse: () => null,
    );

    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
    );

    await _repo.deleteItem(id);

    if (target != null &&
        target.thumbUrl.isNotEmpty &&
        _storageService != null) {
      try {
        await _storageService.deleteMedia(target.thumbUrl);
      } catch (_) {}
    }
  }

  Future<void> addItem(WardrobeItem item) async {
    await _repo.addItem(item);
    state = state.copyWith(items: [item, ...state.items]);
  }

  Future<WardrobeItem> addItemWithImage({
    required Uint8List imageBytes,
    required String mimeType,
    required String title,
    required String category,
    String subCategory = 'عمومی',
    String colorName = 'نامشخص',
    String colorHex = '#888888',
    String season = 'همه',
    String occasion = 'روزمره',
    String material = 'پارچه',
    String size = 'M',
  }) async {
    // 1. Compute real 64-character SHA-256 digest of imageBytes
    final hashDigest = sha256.convert(imageBytes).toString();

    // 2. Upload image via mediaStorageService
    final uid = _userId ?? 'guest';
    final itemId = 'wardrobe_${DateTime.now().millisecondsSinceEpoch}';
    final storagePath = 'users/$uid/wardrobe/$itemId.jpg';

    String uploadedUrl = '';
    if (_storageService != null) {
      uploadedUrl = await _storageService.uploadImage(
        path: storagePath,
        bytes: imageBytes,
        mimeType: mimeType,
      );
    }

    // 3. Save complete WardrobeItem to repository
    final now = DateTime.now();
    final item = WardrobeItem(
      id: itemId,
      title: title,
      category: category,
      subCategory: subCategory,
      colorName: colorName,
      colorHex: colorHex,
      season: season,
      occasion: occasion,
      material: material,
      size: size,
      isFavorite: false,
      isArchived: false,
      thumbUrl: uploadedUrl,
      originalUrl: uploadedUrl,
      imageHash: hashDigest,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.addItem(item);
    state = state.copyWith(items: [item, ...state.items]);
    return item;
  }
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirestoreWardrobeRepository(
        firestore: FirebaseFirestore.instance,
        userId: user.uid,
      );
    }
  } catch (_) {
    // Graceful fallback for widget tests & unauthenticated mode
  }
  return InMemoryWardrobeRepository();
});

final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>(
  (ref) {
    final repo = ref.watch(wardrobeRepositoryProvider);
    final storageService = ref.watch(mediaStorageServiceProvider);
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    return WardrobeNotifier(repo, storageService, uid);
  },
);
