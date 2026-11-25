import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_verification_models.dart';
import '../../../core/ai/ai_verification_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage/media_storage_provider.dart';
import '../../../core/services/storage/media_storage_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/firestore_wardrobe_repository.dart';
import '../data/wardrobe_repository.dart';
import '../domain/wardrobe_item.dart';

class WardrobeFilter {
  final String
  category; // 'all','tops','bottoms','outfit','outerwear','underwear','activewear','footwear','bags','jewelry','accessories'
  final String searchQuery;
  final String colorFilter; // '' = all, else hex
  final String seasonFilter; // '' = all, else season name
  final String occasionFilter; // '' = all, else occasion name
  final bool showArchived;
  final bool multiSelectMode;
  final Set<String> selectedColors;
  final Set<String> selectedSeasons;
  final Set<String> selectedOccasions;
  final Set<String> selectedIds;

  const WardrobeFilter({
    this.category = 'all',
    this.searchQuery = '',
    this.colorFilter = '',
    this.seasonFilter = '',
    this.occasionFilter = '',
    this.showArchived = false,
    this.multiSelectMode = false,
    this.selectedColors = const {},
    this.selectedSeasons = const {},
    this.selectedOccasions = const {},
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
    Set<String>? selectedColors,
    Set<String>? selectedSeasons,
    Set<String>? selectedOccasions,
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
      selectedColors: selectedColors ?? this.selectedColors,
      selectedSeasons: selectedSeasons ?? this.selectedSeasons,
      selectedOccasions: selectedOccasions ?? this.selectedOccasions,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  int get activeFilterCount {
    if (multiSelectMode) {
      return selectedColors.length +
          selectedSeasons.length +
          selectedOccasions.length;
    }
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

  /// Backward-compatible category matching helper across legacy and modern 10 categories.
  static bool matchesCategory(String itemCategory, String selectedCategory) {
    if (selectedCategory == 'all') return true;
    final itemCat = itemCategory.toLowerCase();
    final selCat = selectedCategory.toLowerCase();
    if (itemCat == selCat) return true;

    // Legacy and alias category mapping
    if (selCat == 'tops' && (itemCat == 'cl' || itemCat == 'top')) return true;
    if (selCat == 'bottoms' && (itemCat == 'bottom')) return true;
    if (selCat == 'outfit' &&
        (itemCat == 'full_outfit' || itemCat == 'dress')) {
      return true;
    }
    if (selCat == 'footwear' && (itemCat == 'sh' || itemCat == 'shoes')) {
      return true;
    }
    if (selCat == 'bags' && (itemCat == 'bg' || itemCat == 'bag')) return true;
    if (selCat == 'jewelry' && (itemCat == 'jw' || itemCat == 'jewel')) {
      return true;
    }
    if (selCat == 'accessories' &&
        (itemCat == 'ac' || itemCat == 'accessory')) {
      return true;
    }

    // Inverse mapping for legacy selected filter
    if (selCat == 'cl' && (itemCat == 'tops' || itemCat == 'top')) return true;
    if (selCat == 'sh' && (itemCat == 'footwear' || itemCat == 'shoes')) {
      return true;
    }
    if (selCat == 'bg' && (itemCat == 'bags' || itemCat == 'bag')) return true;
    if (selCat == 'jw' && (itemCat == 'jewelry' || itemCat == 'jewel')) {
      return true;
    }
    if (selCat == 'ac' &&
        (itemCat == 'accessories' || itemCat == 'accessory')) {
      return true;
    }

    return false;
  }

  List<WardrobeItem> get filteredItems {
    return items.where((item) {
      if (!filter.showArchived && item.isArchived) return false;
      if (filter.showArchived && !item.isArchived) return false;
      if (filter.category != 'all' &&
          !matchesCategory(item.category, filter.category)) {
        return false;
      }
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.title.toLowerCase().contains(q) &&
            !item.colorName.toLowerCase().contains(q) &&
            !item.subCategory.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (filter.multiSelectMode) {
        // Multi-Select: OR within attribute group, AND across attribute groups
        if (filter.selectedColors.isNotEmpty &&
            !filter.selectedColors.contains(item.colorHex)) {
          return false;
        }
        if (filter.selectedSeasons.isNotEmpty &&
            !filter.selectedSeasons.contains(item.season)) {
          return false;
        }
        if (filter.selectedOccasions.isNotEmpty &&
            !filter.selectedOccasions.contains(item.occasion)) {
          return false;
        }
      } else {
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
      }
      return true;
    }).toList();
  }

  int countByCategory(String cat) {
    if (cat == 'all') return items.where((e) => !e.isArchived).length;
    return items
        .where((e) => !e.isArchived && matchesCategory(e.category, cat))
        .length;
  }
}

class WardrobeNotifier extends StateNotifier<WardrobeState> {
  final WardrobeRepository _repo;
  final MediaStorageService? _storageService;
  final String? _userId;
  final NotificationService? _notificationService;
  final AiVerificationService? _aiVerificationService;

  WardrobeNotifier(
    this._repo, [
    this._storageService,
    this._userId,
    this._notificationService,
    this._aiVerificationService,
  ]) : super(
         WardrobeState(
           items: _repo is InMemoryWardrobeRepository
               ? _repo.getItems()
               : const [],
           filter: const WardrobeFilter(),
         ),
       ) {
    loadInitial();
  }

  void _notifyWardrobeActivity({
    required String title,
    required String body,
    required String emoji,
    required String eventType,
  }) {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    unawaited(
      (_notificationService ?? NotificationService()).createNotification(
        uid: uid,
        title: title,
        body: body,
        category: 'wardrobe',
        targetRoute: 'wardrobe',
        emoji: emoji,
        sendEmail: false,
        eventType: eventType,
      ),
    );
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _repo.fetchPage(limit: 20);
      if (!mounted) return;
      state = state.copyWith(
        items: page.items,
        lastCursor: page.lastCursor,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        lastCursor: page.lastCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
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

  void setMultiSelectMode(bool enabled) {
    state = state.copyWith(
      filter: state.filter.copyWith(multiSelectMode: enabled),
    );
  }

  void toggleMultiSelectColor(String hex) {
    final next = Set<String>.from(state.filter.selectedColors);
    if (next.contains(hex)) {
      next.remove(hex);
    } else {
      next.add(hex);
    }
    state = state.copyWith(filter: state.filter.copyWith(selectedColors: next));
  }

  void toggleMultiSelectSeason(String season) {
    final next = Set<String>.from(state.filter.selectedSeasons);
    if (next.contains(season)) {
      next.remove(season);
    } else {
      next.add(season);
    }
    state = state.copyWith(
      filter: state.filter.copyWith(selectedSeasons: next),
    );
  }

  void toggleMultiSelectOccasion(String occasion) {
    final next = Set<String>.from(state.filter.selectedOccasions);
    if (next.contains(occasion)) {
      next.remove(occasion);
    } else {
      next.add(occasion);
    }
    state = state.copyWith(
      filter: state.filter.copyWith(selectedOccasions: next),
    );
  }

  void clearFilters() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        colorFilter: '',
        seasonFilter: '',
        occasionFilter: '',
        searchQuery: '',
        selectedColors: const {},
        selectedSeasons: const {},
        selectedOccasions: const {},
      ),
    );
  }

  void applyAdvancedFilters({
    bool multiSelectMode = false,
    String color = '',
    String season = '',
    String occasion = '',
    Set<String> selectedColors = const {},
    Set<String> selectedSeasons = const {},
    Set<String> selectedOccasions = const {},
  }) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        multiSelectMode: multiSelectMode,
        colorFilter: color,
        seasonFilter: season,
        occasionFilter: occasion,
        selectedColors: selectedColors,
        selectedSeasons: selectedSeasons,
        selectedOccasions: selectedOccasions,
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
      _notifyWardrobeActivity(
        title: updated.isArchived
            ? 'Wardrobe Item Archived'
            : 'Wardrobe Item Restored',
        body: updated.isArchived
            ? "'${updated.title}' was moved to archive."
            : "'${updated.title}' was restored to your wardrobe.",
        emoji: updated.isArchived ? '📦' : '👗',
        eventType: updated.isArchived
            ? 'wardrobe_item_archived'
            : 'wardrobe_item_restored',
      );
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
    _notifyWardrobeActivity(
      title: 'Wardrobe Item Updated',
      body: "'${item.title}' details were updated.",
      emoji: '✏️',
      eventType: 'wardrobe_item_updated',
    );
  }

  Future<WardrobeItem> updateItemWithImages({
    required String id,
    List<Uint8List?>? slotBytes,
    List<String?>? slotUrls,
    List<String?>? slotMimes,
    List<Uint8List>? newImages,
    List<String>? newMimeTypes,
    List<String>? existingUrlsToKeep,
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
    final idx = state.items.indexWhere((e) => e.id == id);
    final existing = idx != -1 ? state.items[idx] : null;

    final List<String> finalUrls = [];
    String imageHash = existing?.imageHash ?? '';
    final uid = _userId ?? 'guest';

    if (slotBytes != null || slotUrls != null) {
      const int maxSlots = 3;
      for (int i = 0; i < maxSlots; i++) {
        final bytes = (slotBytes != null && i < slotBytes.length)
            ? slotBytes[i]
            : null;
        final existingUrl = (slotUrls != null && i < slotUrls.length)
            ? slotUrls[i]
            : null;
        final mime =
            (slotMimes != null && i < slotMimes.length && slotMimes[i] != null)
            ? slotMimes[i]!
            : 'image/jpeg';

        if (bytes != null) {
          final hash = sha256.convert(bytes).toString();
          if (i == 0) {
            imageHash = hash;
          }
          final storagePath = 'users/$uid/wardrobe/${id}_angle_$i.jpg';
          if (_storageService != null) {
            final uploaded = await _storageService.uploadImage(
              path: storagePath,
              bytes: bytes,
              mimeType: mime,
            );
            finalUrls.add(uploaded);
          }
        } else if (existingUrl != null && existingUrl.isNotEmpty) {
          finalUrls.add(existingUrl);
        }
      }
    } else {
      if (existingUrlsToKeep != null) {
        finalUrls.addAll(existingUrlsToKeep);
      }
      if (newImages != null && newImages.isNotEmpty) {
        for (int i = 0; i < newImages.length; i++) {
          final bytes = newImages[i];
          final hash = sha256.convert(bytes).toString();
          if (finalUrls.isEmpty) imageHash = hash;
          final mime = (newMimeTypes != null && i < newMimeTypes.length)
              ? newMimeTypes[i]
              : 'image/jpeg';
          final storagePath = 'users/$uid/wardrobe/${id}_angle_$i.jpg';
          if (_storageService != null) {
            final uploaded = await _storageService.uploadImage(
              path: storagePath,
              bytes: bytes,
              mimeType: mime,
            );
            finalUrls.add(uploaded);
          }
        }
      }
    }

    if (finalUrls.isEmpty && existing != null) {
      if (existing.imageUrls.isNotEmpty) {
        finalUrls.addAll(existing.imageUrls);
      } else if (existing.thumbUrl.isNotEmpty) {
        finalUrls.add(existing.thumbUrl);
      }
    }

    final primaryUrl = finalUrls.isNotEmpty
        ? finalUrls.first
        : (existing?.thumbUrl ?? '');
    final now = DateTime.now();
    final zone = WardrobeItem.deriveGarmentZone(category);
    final updated = (existing != null)
        ? existing.copyWith(
            title: title,
            category: category,
            subCategory: subCategory,
            colorName: colorName,
            colorHex: colorHex,
            season: season,
            occasion: occasion,
            material: material,
            size: size,
            thumbUrl: primaryUrl,
            originalUrl: primaryUrl,
            imageHash: imageHash,
            aiGarmentZone: zone,
            imageUrls: finalUrls,
            updatedAt: now,
          )
        : WardrobeItem(
            id: id,
            title: title,
            category: category,
            subCategory: subCategory,
            colorName: colorName,
            colorHex: colorHex,
            season: season,
            occasion: occasion,
            material: material,
            size: size,
            thumbUrl: primaryUrl,
            originalUrl: primaryUrl,
            imageHash: imageHash,
            aiGarmentZone: zone,
            imageUrls: finalUrls,
            updatedAt: now,
          );

    await updateItem(updated);
    return updated;
  }

  Future<WardrobeItem> updateItemWithImage({
    required String id,
    Uint8List? newImageBytes,
    String? mimeType,
    List<Uint8List>? extraNewImages,
    List<String>? extraMimeTypes,
    List<String>? existingUrlsToKeep,
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
    final allNew = [?newImageBytes, ...?extraNewImages];
    final allMimes = [?mimeType, ...?extraMimeTypes];
    return updateItemWithImages(
      id: id,
      newImages: allNew.isNotEmpty ? allNew : null,
      newMimeTypes: allMimes.isNotEmpty ? allMimes : null,
      existingUrlsToKeep: existingUrlsToKeep,
      title: title,
      category: category,
      subCategory: subCategory,
      colorName: colorName,
      colorHex: colorHex,
      season: season,
      occasion: occasion,
      material: material,
      size: size,
    );
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
    final itemName = (target != null && target.title.trim().isNotEmpty)
        ? target.title.trim()
        : 'Item';
    _notifyWardrobeActivity(
      title: 'Wardrobe Item Removed',
      body: "'$itemName' was removed from your wardrobe.",
      emoji: '🗑️',
      eventType: 'wardrobe_item_deleted',
    );

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
    _notifyWardrobeActivity(
      title: 'Wardrobe Item Added',
      body: "'${item.title}' was added to your wardrobe.",
      emoji: '👗',
      eventType: 'wardrobe_item_added',
    );
  }

  Future<WardrobeItem> addItemWithImages({
    required List<Uint8List> images,
    List<String>? mimeTypes,
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
    final uid = _userId ?? 'guest';
    final itemId = 'wardrobe_${DateTime.now().millisecondsSinceEpoch}';
    final List<String> uploadedUrls = [];
    String firstHash = '';

    for (int i = 0; i < images.length; i++) {
      final bytes = images[i];
      final hash = sha256.convert(bytes).toString();
      if (i == 0) firstHash = hash;
      final mime = (mimeTypes != null && i < mimeTypes.length)
          ? mimeTypes[i]
          : 'image/jpeg';
      final storagePath = 'users/$uid/wardrobe/${itemId}_$i.jpg';
      String uploaded = '';
      if (_storageService != null) {
        uploaded = await _storageService.uploadImage(
          path: storagePath,
          bytes: bytes,
          mimeType: mime,
        );
      }
      uploadedUrls.add(uploaded);
    }

    final primaryUrl = uploadedUrls.isNotEmpty ? uploadedUrls.first : '';
    final now = DateTime.now();
    final zone = WardrobeItem.deriveGarmentZone(category);
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
      thumbUrl: primaryUrl,
      originalUrl: primaryUrl,
      imageHash: firstHash,
      aiGarmentZone: zone,
      aiVerificationStatus: images.isNotEmpty
          ? AiVerificationStatus.reviewing.wireValue
          : AiVerificationStatus.pendingAi.wireValue,
      imageUrls: uploadedUrls,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.addItem(item);
    state = state.copyWith(items: [item, ...state.items]);
    _notifyWardrobeActivity(
      title: 'Wardrobe Item Added',
      body: "'${item.title}' was added to your wardrobe.",
      emoji: '👗',
      eventType: 'wardrobe_item_added',
    );
    if (images.isNotEmpty) {
      final firstMime = (mimeTypes != null && mimeTypes.isNotEmpty)
          ? mimeTypes.first
          : 'image/jpeg';
      unawaited(
        _verifyWardrobeGarmentAsync(
          itemId: item.id,
          bytes: images.first,
          mimeType: firstMime,
          title: title,
          category: category,
        ),
      );
    }
    return item;
  }

  Future<void> _verifyWardrobeGarmentAsync({
    required String itemId,
    required Uint8List bytes,
    required String mimeType,
    required String title,
    required String category,
  }) async {
    try {
      final verifier = _aiVerificationService ?? AiVerificationService();
      final result = await verifier.verifyWardrobeGarment(
        bytes: bytes,
        fileNameOrMime: mimeType,
        category: category,
      );
      final idx = state.items.indexWhere((e) => e.id == itemId);
      if (idx != -1) {
        final updated = state.items[idx].copyWith(
          aiVerificationStatus: result.status.wireValue,
          updatedAt: DateTime.now(),
        );
        final nextItems = [...state.items];
        nextItems[idx] = updated;
        state = state.copyWith(items: nextItems);
        await _repo.updateItem(updated);
      }
      if (result.isApproved && _notificationService != null) {
        final uid = (_userId != null && _userId.isNotEmpty) ? _userId : 'guest';
        await _notificationService.notifyWardrobeItemApproved(
          uid: uid,
          itemName: title,
        );
      }
    } catch (_) {
      // Non-blocking AI quality-control hook; never fails item creation.
    }
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
    List<Uint8List>? extraImages,
    List<String>? extraMimeTypes,
  }) async {
    final allImages = [imageBytes, ...?extraImages];
    final allMimes = [mimeType, ...?extraMimeTypes];
    return addItemWithImages(
      images: allImages,
      mimeTypes: allMimes,
      title: title,
      category: category,
      subCategory: subCategory,
      colorName: colorName,
      colorHex: colorHex,
      season: season,
      occasion: occasion,
      material: material,
      size: size,
    );
  }
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid != null && uid.isNotEmpty) {
    try {
      return FirestoreWardrobeRepository(
        firestore: FirebaseFirestore.instance,
        userId: uid,
      );
    } catch (_) {
      // Graceful fallback for widget tests & unauthenticated mode
    }
  }
  return InMemoryWardrobeRepository();
});

final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>(
  (ref) {
    final uid = ref.watch(currentUidProvider);
    final repo = ref.watch(wardrobeRepositoryProvider);
    final storageService = ref.watch(mediaStorageServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final aiVerificationService = ref.read(aiVerificationServiceProvider);
    return WardrobeNotifier(
      repo,
      storageService,
      uid,
      notificationService,
      aiVerificationService,
    );
  },
);
