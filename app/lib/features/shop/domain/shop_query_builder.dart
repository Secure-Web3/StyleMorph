import '../presentation/shop_provider.dart';

/// Normalized user gender and anatomy sizing resolved from `AppState.aiDnaValues`
/// for strict `Fit For Me` personalization.
class ShopProfileFitSpec {
  final String? normalizedGenderCode; // 'm', 'w', or null
  final String? genderSearchKeyword; // "Men's", "Women's", or null
  final String clothingSize;
  final String shoeSize;
  final String? fitPreference;

  const ShopProfileFitSpec({
    this.normalizedGenderCode,
    this.genderSearchKeyword,
    this.clothingSize = 'M',
    this.shoeSize = '42',
    this.fitPreference,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopProfileFitSpec &&
          normalizedGenderCode == other.normalizedGenderCode &&
          genderSearchKeyword == other.genderSearchKeyword &&
          clothingSize == other.clothingSize &&
          shoeSize == other.shoeSize &&
          fitPreference == other.fitPreference;

  @override
  int get hashCode => Object.hash(
    normalizedGenderCode,
    genderSearchKeyword,
    clothingSize,
    shoeSize,
    fitPreference,
  );
}

/// Pure, deterministic builder that converts [ShopFilter] state and user
/// sizing into an image-first Google Search URL (`tbm=isch&udm=2`).
class ShopSearchQueryBuilder {
  const ShopSearchQueryBuilder._();

  static String? normalizeGenderCode(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;
    const maleTokens = {
      'male',
      'm',
      'man',
      'men',
      "men's",
      'مرد',
      'مردانه',
      'erkek',
      'ذكر',
      'رجالي',
    };
    const femaleTokens = {
      'female',
      'f',
      'woman',
      'women',
      "women's",
      'زن',
      'زنانه',
      'kadın',
      'kadin',
      'أنثى',
      'انثى',
      'نسائي',
    };
    if (maleTokens.contains(normalized)) return 'm';
    if (femaleTokens.contains(normalized)) return 'w';
    return null;
  }

  static String? genderSearchKeywordFor(String? raw) {
    switch (normalizeGenderCode(raw)) {
      case 'm':
        return "Men's";
      case 'w':
        return "Women's";
      default:
        return null;
    }
  }

  static ShopProfileFitSpec resolveProfileFitSpec(
    Map<String, String> aiDnaValues,
  ) {
    final genderCode = normalizeGenderCode(aiDnaValues['gender']);
    final genderKeyword = genderSearchKeywordFor(aiDnaValues['gender']);
    final rawShoe = (aiDnaValues['shoeSize'] ?? '').trim();
    final shoeSize = rawShoe.isNotEmpty ? rawShoe : '42';

    final rawShirt = (aiDnaValues['shirtSize'] ?? '').trim();
    String clothingSize = rawShirt;
    if (clothingSize.isEmpty) {
      final chest = double.tryParse((aiDnaValues['chest'] ?? '').trim());
      final weight = double.tryParse((aiDnaValues['weight'] ?? '').trim());
      if (chest != null && chest > 0) {
        if (chest < 90) {
          clothingSize = 'S';
        } else if (chest < 98) {
          clothingSize = 'M';
        } else if (chest < 106) {
          clothingSize = 'L';
        } else {
          clothingSize = 'XL';
        }
      } else if (weight != null && weight > 0) {
        if (weight < 60) {
          clothingSize = 'S';
        } else if (weight < 74) {
          clothingSize = 'M';
        } else if (weight < 88) {
          clothingSize = 'L';
        } else {
          clothingSize = 'XL';
        }
      } else {
        clothingSize = 'M';
      }
    }

    final rawFit = (aiDnaValues['fitPreference'] ?? '').trim();
    return ShopProfileFitSpec(
      normalizedGenderCode: genderCode,
      genderSearchKeyword: genderKeyword,
      clothingSize: clothingSize,
      shoeSize: shoeSize,
      fitPreference: rawFit.isNotEmpty ? rawFit : null,
    );
  }

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
    String? profileGender,
    String? fitPreference,
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
      final explicitGender = genderSearchKeywordFor(
        profileGender ??
            (filter.gender == 'm'
                ? 'male'
                : filter.gender == 'w'
                ? 'female'
                : null),
      );
      if (explicitGender != null) {
        parts.insert(0, explicitGender);
      }
      if (filter.category == 'shoe') {
        parts.add('Shoe $shoeSize');
      } else if (filter.category == 'cloth') {
        parts.add('Size $clothingSize');
        if (fitPreference != null && fitPreference.trim().isNotEmpty) {
          parts.add('${fitPreference.trim()} fit');
        }
      } else if (filter.category == 'all') {
        if (trimmedSearch.isEmpty) {
          parts.add('fashion outfits clothing');
        }
        parts.add('Size $clothingSize');
        if (fitPreference != null && fitPreference.trim().isNotEmpty) {
          parts.add('${fitPreference.trim()} fit');
        }
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
    String? profileGender,
    String? fitPreference,
  }) {
    final query = buildQuery(
      filter: filter,
      localeCode: localeCode,
      clothingSize: clothingSize,
      shoeSize: shoeSize,
      profileGender: profileGender,
      fitPreference: fitPreference,
    );
    return Uri.https('www.google.com', '/search', {
      'tbm': 'isch',
      'udm': '2',
      'q': query,
    });
  }
}
