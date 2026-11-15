import 'package:flutter/material.dart';

@immutable
class StylistOutfitItem {
  final String title;
  final String category;
  final String colorHex;
  final IconData icon;

  const StylistOutfitItem({
    required this.title,
    required this.category,
    required this.colorHex,
    required this.icon,
  });
}

@immutable
class StylistOutfit {
  final String id;
  final String title;
  final String occasion;
  final List<String> tags;
  final List<StylistOutfitItem> items;
  final bool isLocked;
  final bool isSaved;

  const StylistOutfit({
    required this.id,
    required this.title,
    required this.occasion,
    required this.tags,
    required this.items,
    this.isLocked = false,
    this.isSaved = false,
  });

  StylistOutfit copyWith({
    String? id,
    String? title,
    String? occasion,
    List<String>? tags,
    List<StylistOutfitItem>? items,
    bool? isLocked,
    bool? isSaved,
  }) {
    return StylistOutfit(
      id: id ?? this.id,
      title: title ?? this.title,
      occasion: occasion ?? this.occasion,
      tags: tags ?? this.tags,
      items: items ?? this.items,
      isLocked: isLocked ?? this.isLocked,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

@immutable
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final StylistOutfit? outfitAttachment;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.outfitAttachment,
  });
}

enum TryOnTier {
  fast('سریع', 5, 'وضوح استاندارد، پردازش سریع در ۵ ثانیه'),
  standard('استاندارد', 10, 'وضوح بالا با هماهنگی دقیق چین‌وچروک و بافت پارچه'),
  cinematic('سینمایی (۴K)', 20, 'پردازش فوق‌العاده جزئیات و نورپردازی استودیویی');

  final String label;
  final int coinCost;
  final String description;

  const TryOnTier(this.label, this.coinCost, this.description);
}
