import 'package:flutter/foundation.dart';

@immutable
class AppNotification {
  final String id;
  final String category; // 'ai', 'shop', 'finance'
  final String emoji;
  final String title;
  final String body;
  final String timestampLabel;
  final String
  targetRoute; // 'atelier_creations', 'shop', 'profile_wallet', 'stylist'
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.category,
    required this.emoji,
    required this.title,
    required this.body,
    required this.timestampLabel,
    required this.targetRoute,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? category,
    String? emoji,
    String? title,
    String? body,
    String? timestampLabel,
    String? targetRoute,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      body: body ?? this.body,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      targetRoute: targetRoute ?? this.targetRoute,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          category == other.category &&
          emoji == other.emoji &&
          title == other.title &&
          body == other.body &&
          timestampLabel == other.timestampLabel &&
          targetRoute == other.targetRoute &&
          isRead == other.isRead;

  @override
  int get hashCode => Object.hash(
    id,
    category,
    emoji,
    title,
    body,
    timestampLabel,
    targetRoute,
    isRead,
  );
}

/// Alias for AppNotification providing clean nomenclature for Shell domain.
typedef NotificationItem = AppNotification;
