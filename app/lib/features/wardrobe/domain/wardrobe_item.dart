import 'package:flutter/material.dart';

@immutable
class WardrobeItem {
  final String id;
  final String name;
  final String category; // 'cl','sh','bg','jw','ac'
  final String subCategory;
  final String colorName;
  final String colorHex;
  final String season; // 'همه','بهار','تابستان','پاییز','زمستان'
  final String occasion; // 'روزمره','رسمی','ورزشی','مجلسی'
  final String material;
  final String size;
  final bool isFavorite;
  final bool isArchived;

  const WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.colorName,
    required this.colorHex,
    required this.season,
    required this.occasion,
    required this.material,
    required this.size,
    required this.isFavorite,
    required this.isArchived,
  });

  WardrobeItem copyWith({
    String? id,
    String? name,
    String? category,
    String? subCategory,
    String? colorName,
    String? colorHex,
    String? season,
    String? occasion,
    String? material,
    String? size,
    bool? isFavorite,
    bool? isArchived,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      colorName: colorName ?? this.colorName,
      colorHex: colorHex ?? this.colorHex,
      season: season ?? this.season,
      occasion: occasion ?? this.occasion,
      material: material ?? this.material,
      size: size ?? this.size,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
