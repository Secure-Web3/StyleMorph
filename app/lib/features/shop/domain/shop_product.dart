import 'package:flutter/material.dart';

@immutable
class ShopSeller {
  final String storeName;
  final String type; // 'app', 'agent', 'ind'
  final int price;
  final String purchaseMethod; // 'app', 'site'
  final double rating;
  final String deliveryTime;
  final bool inStock;
  final int? originalPrice;

  const ShopSeller({
    required this.storeName,
    required this.type,
    required this.price,
    required this.purchaseMethod,
    required this.rating,
    required this.deliveryTime,
    required this.inStock,
    this.originalPrice,
  });

  int get cashReward {
    if (purchaseMethod != 'app') return 0;
    final rate = type == 'app' ? 0.03 : 0.02;
    return (price * rate / 1000).round().clamp(1, 9999);
  }
}

@immutable
class ShopProduct {
  final int id;
  final String name;
  final String category; // 'cloth', 'shoe', 'bag', 'acc', 'beauty'
  final String gender; // 'w', 'm', 'u'
  final String brand;
  final String iconName;
  final String colorHex;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviewCount;
  final String material;
  final String season;
  final List<String> wardrobeFit;
  final List<ShopSeller> sellers;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.gender,
    required this.brand,
    required this.iconName,
    required this.colorHex,
    required this.sizes,
    required this.colors,
    required this.rating,
    required this.reviewCount,
    required this.material,
    required this.season,
    required this.wardrobeFit,
    required this.sellers,
  });

  int get lowestPrice {
    final available = sellers.where((s) => s.inStock).toList();
    final list = available.isNotEmpty ? available : sellers;
    if (list.isEmpty) return 0;
    return list.map((s) => s.price).reduce((a, b) => a < b ? a : b);
  }

  int get discountPercent {
    int maxDisc = 0;
    for (final s in sellers) {
      if (s.originalPrice != null && s.originalPrice! > s.price) {
        final d = ((s.originalPrice! - s.price) / s.originalPrice! * 100)
            .round();
        if (d > maxDisc) maxDisc = d;
      }
    }
    return maxDisc;
  }

  bool get isAvailable => sellers.any((s) => s.inStock);

  bool get isOwn => sellers.length == 1 && sellers.first.type == 'app';
}
