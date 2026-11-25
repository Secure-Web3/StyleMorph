import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@immutable
class WardrobeItem {
  final String id;
  final String title;
  final String
  category; // 'tops','bottoms','outfit','outerwear','underwear','activewear','footwear','bags','jewelry','accessories' or legacy 'cl','sh','bg','jw','ac'
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
  final String
  aiGarmentZone; // e.g. 'upper_body','lower_body','full_body','outerwear','footwear','bag','accessory'
  final String aiVerificationStatus;
  final List<String>
  imageUrls; // Up to 3 frames/angles: primary + optional 2 angles
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
    String? aiGarmentZone,
    this.aiVerificationStatus = 'pending_ai',
    List<String>? imageUrls,
    this.createdAt,
    this.updatedAt,
  }) : title = title ?? name ?? '',
       aiGarmentZone = aiGarmentZone ?? '',
       imageUrls = imageUrls ?? const [];

  /// Backward-compatible alias for [title].
  String get name => title;

  /// Helper to automatically map categories to AI Virtual Try-On zones.
  static String deriveGarmentZone(String cat) {
    switch (cat.toLowerCase()) {
      case 'tops':
      case 'top':
      case 'cl':
        return 'upper_body';
      case 'bottoms':
      case 'bottom':
        return 'lower_body';
      case 'outfit':
      case 'full_outfit':
      case 'dress':
        return 'full_body';
      case 'outerwear':
        return 'outerwear';
      case 'underwear':
      case 'loungewear':
        return 'underwear';
      case 'activewear':
        return 'activewear';
      case 'footwear':
      case 'sh':
      case 'shoes':
        return 'footwear';
      case 'bags':
      case 'bg':
      case 'bag':
        return 'bag';
      case 'jewelry':
      case 'jw':
        return 'jewelry';
      case 'accessories':
      case 'ac':
      case 'accessory':
        return 'accessory';
      default:
        return 'upper_body';
    }
  }

  /// Canonical zone for AI pipelines and styling engines.
  String get canonicalGarmentZone =>
      aiGarmentZone.isNotEmpty ? aiGarmentZone : deriveGarmentZone(category);

  /// Safe list of images for multi-angle carousel display.
  List<String> get effectiveImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (originalUrl.isNotEmpty) return [originalUrl];
    if (thumbUrl.isNotEmpty) return [thumbUrl];
    return const [];
  }

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
    String? aiGarmentZone,
    String? aiVerificationStatus,
    List<String>? imageUrls,
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
      aiGarmentZone: aiGarmentZone ?? this.aiGarmentZone,
      aiVerificationStatus: aiVerificationStatus ?? this.aiVerificationStatus,
      imageUrls: imageUrls ?? this.imageUrls,
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
      'aiGarmentZone': canonicalGarmentZone,
      'aiVerificationStatus': aiVerificationStatus,
      'imageUrls': effectiveImageUrls,
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

    String sanitizeUrl(dynamic raw) {
      if (raw is! String) return '';
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed.startsWith('blob:')) return '';
      return trimmed;
    }

    final itemTitle = (data['title'] ?? data['name'] ?? '') as String;
    final itemCategory = (data['category'] ?? 'tops') as String;
    final zone = (data['aiGarmentZone'] ?? '') as String;
    final rawImages = data['imageUrls'];
    final List<String> images = rawImages is List
        ? rawImages
              .whereType<String>()
              .map(sanitizeUrl)
              .where((u) => u.isNotEmpty)
              .toList()
        : [];
    final thumb = sanitizeUrl(data['thumbUrl']);
    final orig = sanitizeUrl(data['originalUrl']);
    final effectiveImages = images.isNotEmpty
        ? images
        : (orig.isNotEmpty
              ? [orig]
              : (thumb.isNotEmpty ? [thumb] : <String>[]));

    return WardrobeItem(
      id: id,
      title: itemTitle,
      category: itemCategory,
      subCategory: (data['subCategory'] ?? 'عمومی') as String,
      colorName: (data['colorName'] ?? 'نامشخص') as String,
      colorHex: (data['colorHex'] ?? '#888888') as String,
      season: (data['season'] ?? 'همه') as String,
      occasion: (data['occasion'] ?? 'روزمره') as String,
      material: (data['material'] ?? 'پارچه') as String,
      size: (data['size'] ?? 'M') as String,
      isFavorite: (data['isFavorite'] ?? false) as bool,
      isArchived: (data['isArchived'] ?? false) as bool,
      thumbUrl: thumb,
      originalUrl: orig,
      imageHash: (data['imageHash'] ?? '') as String,
      aiGarmentZone: zone.isNotEmpty ? zone : deriveGarmentZone(itemCategory),
      aiVerificationStatus:
          (data['aiVerificationStatus'] as String?)?.isNotEmpty == true
          ? data['aiVerificationStatus'] as String
          : 'pending_ai',
      imageUrls: effectiveImages,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
