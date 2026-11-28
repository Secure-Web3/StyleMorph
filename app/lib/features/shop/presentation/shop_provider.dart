import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shop_repository.dart';
import '../domain/extracted_web_product.dart';
import '../domain/shop_product.dart';

class ShopFilter {
  final String
  category; // 'all', 'cloth', 'shoe', 'bag', 'acc', 'beauty', 'fav'
  final String searchQuery;
  final int maxPrice; // 0 = no limit
  final List<String> brands;
  final List<String> sizes;
  final List<String> colors;
  final String gender; // 'all', 'w', 'm', 'u'
  final bool availableOnly;
  final bool discountOnly;
  final bool verifiedOnly;
  final String saleType; // 'all', 'app', 'site'
  final bool fitFilter;
  final String sortOption; // 'rel', 'lo', 'hi', 'rt', 'dc'

  const ShopFilter({
    this.category = 'all',
    this.searchQuery = '',
    this.maxPrice = 0,
    this.brands = const [],
    this.sizes = const [],
    this.colors = const [],
    this.gender = 'all',
    this.availableOnly = false,
    this.discountOnly = false,
    this.verifiedOnly = false,
    this.saleType = 'all',
    this.fitFilter = false,
    this.sortOption = 'rel',
  });

  ShopFilter copyWith({
    String? category,
    String? searchQuery,
    int? maxPrice,
    List<String>? brands,
    List<String>? sizes,
    List<String>? colors,
    String? gender,
    bool? availableOnly,
    bool? discountOnly,
    bool? verifiedOnly,
    String? saleType,
    bool? fitFilter,
    String? sortOption,
  }) {
    return ShopFilter(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      maxPrice: maxPrice ?? this.maxPrice,
      brands: brands ?? this.brands,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      gender: gender ?? this.gender,
      availableOnly: availableOnly ?? this.availableOnly,
      discountOnly: discountOnly ?? this.discountOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      saleType: saleType ?? this.saleType,
      fitFilter: fitFilter ?? this.fitFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  int get activeFilterCount {
    int cnt = 0;
    if (maxPrice > 0) cnt++;
    cnt += brands.length;
    cnt += sizes.length;
    cnt += colors.length;
    if (gender != 'all') cnt++;
    if (availableOnly) cnt++;
    if (discountOnly) cnt++;
    if (verifiedOnly) cnt++;
    if (saleType != 'all') cnt++;
    return cnt;
  }
}

class ShopState {
  final List<ShopProduct> products;
  final ShopFilter filter;
  final Set<int> wishlist;
  final List<ExtractedWebProduct> webWishlist;
  final Uri? browserReopenUri;
  final List<int> compareList;
  final Map<int, int> priceAlerts; // productId -> alert discount pct
  final List<int> recentlyViewed;

  const ShopState({
    required this.products,
    required this.filter,
    this.wishlist = const {},
    this.webWishlist = const [],
    this.browserReopenUri,
    this.compareList = const [],
    this.priceAlerts = const {},
    this.recentlyViewed = const [2, 4],
  });

  int get totalWishlistCount => wishlist.length + webWishlist.length;

  ShopState copyWith({
    List<ShopProduct>? products,
    ShopFilter? filter,
    Set<int>? wishlist,
    List<ExtractedWebProduct>? webWishlist,
    Uri? browserReopenUri,
    bool clearBrowserReopenUri = false,
    List<int>? compareList,
    Map<int, int>? priceAlerts,
    List<int>? recentlyViewed,
  }) {
    return ShopState(
      products: products ?? this.products,
      filter: filter ?? this.filter,
      wishlist: wishlist ?? this.wishlist,
      webWishlist: webWishlist ?? this.webWishlist,
      browserReopenUri: clearBrowserReopenUri
          ? null
          : (browserReopenUri ?? this.browserReopenUri),
      compareList: compareList ?? this.compareList,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
    );
  }

  bool _isSizeFit(ShopProduct p) {
    if (p.sizes.isEmpty) return true;
    if (p.category == 'shoe') return p.sizes.contains('42');
    if (p.category == 'cloth') return p.sizes.contains('M');
    return true;
  }

  List<ShopProduct> get filteredProducts {
    var list = products.where((p) {
      if (filter.category == 'fav' && !wishlist.contains(p.id)) {
        return false;
      }
      if (filter.category != 'all' &&
          filter.category != 'fav' &&
          p.category != filter.category) {
        return false;
      }
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.brand.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (filter.maxPrice > 0 && p.lowestPrice > filter.maxPrice) {
        return false;
      }
      if (filter.brands.isNotEmpty && !filter.brands.contains(p.brand)) {
        return false;
      }
      if (filter.sizes.isNotEmpty &&
          !p.sizes.any((s) => filter.sizes.contains(s))) {
        return false;
      }
      if (filter.colors.isNotEmpty &&
          !p.colors.any((c) => filter.colors.contains(c))) {
        return false;
      }
      if (filter.gender != 'all' &&
          p.gender != filter.gender &&
          p.gender != 'u') {
        return false;
      }
      if (filter.availableOnly && !p.isAvailable) {
        return false;
      }
      if (filter.discountOnly && p.discountPercent <= 0) {
        return false;
      }
      if (filter.verifiedOnly &&
          !p.sellers.any((s) => s.type == 'app' || s.type == 'agent')) {
        return false;
      }
      if (filter.saleType != 'all' &&
          !p.sellers.any((s) => s.purchaseMethod == filter.saleType)) {
        return false;
      }
      if (filter.fitFilter && !_isSizeFit(p)) {
        return false;
      }
      return true;
    }).toList();

    switch (filter.sortOption) {
      case 'lo':
        list.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
        break;
      case 'hi':
        list.sort((a, b) => b.lowestPrice.compareTo(a.lowestPrice));
        break;
      case 'rt':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'dc':
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      default:
        break;
    }

    return list;
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  final ShopRepository _repo;

  ShopNotifier(this._repo)
    : super(
        ShopState(
          products: _repo.getProducts(),
          filter: const ShopFilter(),
          webWishlist: _repo.getSavedWebWishlist(),
        ),
      );

  void refresh() {
    state = state.copyWith(
      products: _repo.getProducts(),
      webWishlist: _repo.getSavedWebWishlist(),
    );
  }

  void setCategory(String cat) {
    state = state.copyWith(filter: state.filter.copyWith(category: cat));
  }

  void setSearchQuery(String q) {
    state = state.copyWith(filter: state.filter.copyWith(searchQuery: q));
  }

  void toggleFitFilter() {
    state = state.copyWith(
      filter: state.filter.copyWith(fitFilter: !state.filter.fitFilter),
    );
  }

  void setSortOption(String sort) {
    state = state.copyWith(filter: state.filter.copyWith(sortOption: sort));
  }

  void updateFilter(ShopFilter newFilter) {
    state = state.copyWith(filter: newFilter);
  }

  void resetFilters() {
    state = state.copyWith(filter: const ShopFilter());
  }

  void toggleWishlist(int id) {
    final next = Set<int>.from(state.wishlist);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(wishlist: next);
  }

  void saveWebProductToWishlist(ExtractedWebProduct product) {
    if (!product.isValid) return;
    _repo.saveWebWishlistItem(product);
    state = state.copyWith(webWishlist: _repo.getSavedWebWishlist());
  }

  void removeWebProductFromWishlist(String wishlistKey) {
    _repo.removeWebWishlistItem(wishlistKey);
    state = state.copyWith(webWishlist: _repo.getSavedWebWishlist());
  }

  bool isWebProductSaved(ExtractedWebProduct product) {
    return state.webWishlist.any((p) => p.wishlistKey == product.wishlistKey);
  }

  void reopenInBrowser(Uri uri) {
    state = state.copyWith(
      filter: state.filter.copyWith(category: 'all'),
      browserReopenUri: uri,
    );
  }

  void clearBrowserReopenUri() {
    state = state.copyWith(clearBrowserReopenUri: true);
  }

  void toggleCompare(int id) {
    final next = List<int>.from(state.compareList);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (next.length < 3) {
        next.add(id);
      }
    }
    state = state.copyWith(compareList: next);
  }

  void clearCompare() {
    state = state.copyWith(compareList: []);
  }

  void setPriceAlert(int id, int pct) {
    final next = Map<int, int>.from(state.priceAlerts);
    if (next.containsKey(id)) {
      next.remove(id);
    } else {
      next[id] = pct;
    }
    state = state.copyWith(priceAlerts: next);
  }

  void addRecentlyViewed(int id) {
    final next = List<int>.from(state.recentlyViewed);
    next.remove(id);
    next.insert(0, id);
    if (next.length > 8) {
      next.removeLast();
    }
    state = state.copyWith(recentlyViewed: next);
  }
}

final shopRepositoryProvider = Provider<ShopRepository>(
  (_) => ShopRepository(),
);

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>(
  (ref) => ShopNotifier(ref.read(shopRepositoryProvider)),
);

/// Holds the latest Shop product payload handed off to Stylist or Atelier.
class ShopHandoffState {
  final ExtractedWebProduct? stylistProduct;
  final ExtractedWebProduct? atelierProduct;

  const ShopHandoffState({this.stylistProduct, this.atelierProduct});

  ShopHandoffState copyWith({
    ExtractedWebProduct? stylistProduct,
    ExtractedWebProduct? atelierProduct,
    bool clearStylist = false,
    bool clearAtelier = false,
  }) {
    return ShopHandoffState(
      stylistProduct: clearStylist
          ? null
          : (stylistProduct ?? this.stylistProduct),
      atelierProduct: clearAtelier
          ? null
          : (atelierProduct ?? this.atelierProduct),
    );
  }
}

class ShopHandoffNotifier extends StateNotifier<ShopHandoffState> {
  ShopHandoffNotifier() : super(const ShopHandoffState());

  void sendToStylist(ExtractedWebProduct product) {
    state = state.copyWith(stylistProduct: product);
  }

  void sendToAtelier(ExtractedWebProduct product) {
    state = state.copyWith(atelierProduct: product);
  }

  void clearStylist() {
    state = state.copyWith(clearStylist: true);
  }

  void clearAtelier() {
    state = state.copyWith(clearAtelier: true);
  }
}

final shopHandoffProvider =
    StateNotifierProvider<ShopHandoffNotifier, ShopHandoffState>(
      (_) => ShopHandoffNotifier(),
    );
