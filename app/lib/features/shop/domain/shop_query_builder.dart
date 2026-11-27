import '../presentation/shop_provider.dart';

/// Pure, deterministic builder that converts [ShopFilter] state and user
/// sizing into an image-first Google Search URL (`tbm=isch&udm=2`).
class ShopSearchQueryBuilder {
  const ShopSearchQueryBuilder._();

  static const Map<String, Map<String, String>> _categoryKeywords = {
    'en': {
      'cloth': 'clothing',
      'shoe': 'shoes',
      'bag': 'handbag',
      'acc': 'fashion accessories',
      'beauty': 'beauty cosmetics',
      'fav': 'trending fashion',
    },
    'fa': {
      'cloth': 'لباس پوشاک',
      'shoe': 'کفش',
      'bag': 'کیف',
      'acc': 'اکسسوری مد',
      'beauty': 'لوازم آرایشی زیبایی',
      'fav': 'مد محبوب',
    },
    'ar': {
      'cloth': 'ملابس أزياء',
      'shoe': 'أحذية',
      'bag': 'حقائب',
      'acc': 'إكسسوارات',
      'beauty': 'تجميل وعناية',
      'fav': 'أزياء رائجة',
    },
    'tr': {
      'cloth': 'giyim kıyafet',
      'shoe': 'ayakkabı',
      'bag': 'çanta',
      'acc': 'aksesuar',
      'beauty': 'güzellik kozmetik',
      'fav': 'trend moda',
    },
  };

  static const Map<String, Map<String, String>> _genderKeywords = {
    'en': {'w': 'women', 'm': 'men', 'u': 'unisex'},
    'fa': {'w': 'زنانه', 'm': 'مردانه', 'u': 'یونیسکس'},
    'ar': {'w': 'نسائي', 'm': 'رجالي', 'u': 'للجنسين'},
    'tr': {'w': 'kadın', 'm': 'erkek', 'u': 'unisex'},
  };

  static const Map<String, Map<String, String>> _sortKeywords = {
    'en': {
      'lo': 'affordable',
      'hi': 'luxury',
      'rt': 'best rated',
      'dc': 'sale discount',
    },
    'fa': {
      'lo': 'ارزان قیمت مناسب',
      'hi': 'لوکس',
      'rt': 'پرفروش محبوب',
      'dc': 'تخفیف حراج',
    },
    'ar': {
      'lo': 'بسعر مناسب',
      'hi': 'فاخر',
      'rt': 'الأعلى تقييما',
      'dc': 'تخفيضات',
    },
    'tr': {'lo': 'uygun fiyat', 'hi': 'lüks', 'rt': 'en iyi', 'dc': 'indirim'},
  };

  static const Map<String, String> _contextKeywords = {
    'en': 'outfit buy',
    'fa': 'استایل خرید',
    'ar': 'إطلالة تسوق',
    'tr': 'kombin satın al',
  };

  static const Map<String, String> _defaultQueries = {
    'en': 'luxury fashion outfit lookbook',
    'fa': 'استایل مد لوکس لباس',
    'ar': 'أزياء فاخرة إطلالة',
    'tr': 'lüks moda kombin lookbook',
  };

  static String _normalizeLocale(String localeCode) {
    final code = localeCode.toLowerCase().split('_').first.split('-').first;
    if (_defaultQueries.containsKey(code)) return code;
    return 'en';
  }

  /// Builds the deterministic search query string from [filter] and user sizes.
  static String buildQuery({
    required ShopFilter filter,
    String localeCode = 'en',
    String clothingSize = 'M',
    String shoeSize = '42',
  }) {
    final lang = _normalizeLocale(localeCode);
    final parts = <String>[];

    final trimmedSearch = filter.searchQuery.trim();
    if (trimmedSearch.isNotEmpty) {
      parts.add(trimmedSearch);
    }

    if (filter.category != 'all') {
      final catKeyword = _categoryKeywords[lang]?[filter.category];
      if (catKeyword != null && catKeyword.isNotEmpty) {
        parts.add(catKeyword);
      }
    }

    if (filter.gender != 'all') {
      final genderKeyword = _genderKeywords[lang]?[filter.gender];
      if (genderKeyword != null && genderKeyword.isNotEmpty) {
        parts.add(genderKeyword);
      }
    }

    for (final brand in filter.brands) {
      final b = brand.trim();
      if (b.isNotEmpty) parts.add(b);
    }

    for (final color in filter.colors) {
      final c = color.trim();
      if (c.isNotEmpty) parts.add(c);
    }

    for (final size in filter.sizes) {
      final s = size.trim();
      if (s.isNotEmpty) parts.add('Size $s');
    }

    if (filter.fitFilter) {
      if (filter.category == 'shoe') {
        parts.add('Shoe $shoeSize');
      } else if (filter.category == 'cloth') {
        parts.add('Size $clothingSize');
      } else {
        parts.add('Size $clothingSize');
        parts.add('Shoe $shoeSize');
      }
    }

    if (filter.discountOnly) {
      final disc = _sortKeywords[lang]?['dc'];
      if (disc != null) parts.add(disc);
    }

    if (filter.sortOption != 'rel') {
      final sortKw = _sortKeywords[lang]?[filter.sortOption];
      if (sortKw != null && !parts.contains(sortKw)) {
        parts.add(sortKw);
      }
    }

    if (parts.isEmpty) {
      return _defaultQueries[lang]!;
    }

    final contextKw = _contextKeywords[lang];
    if (contextKw != null && contextKw.isNotEmpty) {
      parts.add(contextKw);
    }

    return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Builds the image-first Google Search [Uri] (`tbm=isch&udm=2`).
  static Uri buildSearchUri({
    required ShopFilter filter,
    String localeCode = 'en',
    String clothingSize = 'M',
    String shoeSize = '42',
  }) {
    final query = buildQuery(
      filter: filter,
      localeCode: localeCode,
      clothingSize: clothingSize,
      shoeSize: shoeSize,
    );
    return Uri.https('www.google.com', '/search', {
      'tbm': 'isch',
      'udm': '2',
      'q': query,
    });
  }
}
