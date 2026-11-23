import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@immutable
class WardrobeItem {
  final String id;
  final String title;
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
  final String thumbUrl;
  final String originalUrl;
  final String imageHash; // 64-character SHA-256
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WardrobeItem({
    required this.id,
    String? title,
    String? name,
    required this.category,
    this.subCategory = 'عمومی',
    this.colorName = 'نامشخص',
    this.colorHex = '#888888',
    this.season = 'همه',
    this.occasion = 'روزمره',
    this.material = 'پارچه',
    this.size = 'M',
    this.isFavorite = false,
    this.isArchived = false,
    this.thumbUrl = '',
    this.originalUrl = '',
    this.imageHash = '',
    this.createdAt,
    this.updatedAt,
  }) : title = title ?? name ?? '';

  /// Backward-compatible alias for [title].
  String get name => title;

  WardrobeItem copyWith({
    String? id,
    String? title,
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
    String? thumbUrl,
    String? originalUrl,
    String? imageHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      title: title ?? name ?? this.title,
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
      thumbUrl: thumbUrl ?? this.thumbUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      imageHash: imageHash ?? this.imageHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'subCategory': subCategory,
      'colorName': colorName,
      'colorHex': colorHex,
      'season': season,
      'occasion': occasion,
      'material': material,
      'size': size,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'thumbUrl': thumbUrl,
      'originalUrl': originalUrl,
      'imageHash': imageHash,
      if (createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!)
      else
        'createdAt': FieldValue.serverTimestamp(),
      if (updatedAt != null)
        'updatedAt': Timestamp.fromDate(updatedAt!)
      else
        'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory WardrobeItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return WardrobeItem.fromMap(data, doc.id);
  }

  factory WardrobeItem.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final itemTitle = (data['title'] ?? data['name'] ?? '') as String;
    return WardrobeItem(
      id: id,
      title: itemTitle,
      category: (data['category'] ?? 'cl') as String,
      subCategory: (data['subCategory'] ?? 'عمومی') as String,
      colorName: (data['colorName'] ?? 'نامشخص') as String,
      colorHex: (data['colorHex'] ?? '#888888') as String,
      season: (data['season'] ?? 'همه') as String,
      occasion: (data['occasion'] ?? 'روزمره') as String,
      material: (data['material'] ?? 'پارچه') as String,
      size: (data['size'] ?? 'M') as String,
      isFavorite: (data['isFavorite'] ?? false) as bool,
      isArchived: (data['isArchived'] ?? false) as bool,
      thumbUrl: (data['thumbUrl'] ?? '') as String,
      originalUrl: (data['originalUrl'] ?? '') as String,
      imageHash: (data['imageHash'] ?? '') as String,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
