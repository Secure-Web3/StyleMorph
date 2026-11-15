import 'package:flutter/material.dart';

@immutable
class AtelierTemplate {
  final int id;
  final String name;
  final String category; // 'portrait', 'fashion', 'seasonal', 'travel'
  final String type; // 'p' for photo, 'v' for video
  final int framesCount;
  final int price; // coins
  final int popularity; // %
  final int usage; // %
  final List<String> colorHexes;
  final List<IconData> icons;
  final String description;
  final List<String> proOptions;
  final String outputSpecs;
  final String timeEstimate;

  const AtelierTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.framesCount,
    required this.price,
    required this.popularity,
    required this.usage,
    required this.colorHexes,
    required this.icons,
    required this.description,
    required this.proOptions,
    required this.outputSpecs,
    required this.timeEstimate,
  });
}

enum CreationStatus {
  queue('در صف', Color(0xFF8A8F94)),
  processing('در حال ساخت', Color(0xFF3B6EA5)),
  ready('آماده', Color(0xFF2E6B47)),
  failed('ناموفق', Color(0xFFDC2626));

  final String label;
  final Color color;

  const CreationStatus(this.label, this.color);
}

@immutable
class AtelierCreation {
  final int id;
  final int templateId;
  final String templateTitle;
  final String type;
  final CreationStatus status;
  final int progress; // 0..100
  final String date;
  final bool isPrivate;
  final bool isFreeRetryUsed;
  final double? anatomicalScore;
  final String? watermarkText;
  final String? mediaUrl;
  final bool? cacheHit;

  const AtelierCreation({
    required this.id,
    required this.templateId,
    required this.templateTitle,
    required this.type,
    required this.status,
    required this.progress,
    required this.date,
    this.isPrivate = true,
    this.isFreeRetryUsed = false,
    this.anatomicalScore,
    this.watermarkText,
    this.mediaUrl,
    this.cacheHit,
  });

  AtelierCreation copyWith({
    int? id,
    int? templateId,
    String? templateTitle,
    String? type,
    CreationStatus? status,
    int? progress,
    String? date,
    bool? isPrivate,
    bool? isFreeRetryUsed,
    double? anatomicalScore,
    String? watermarkText,
    String? mediaUrl,
    bool? cacheHit,
  }) {
    return AtelierCreation(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateTitle: templateTitle ?? this.templateTitle,
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      date: date ?? this.date,
      isPrivate: isPrivate ?? this.isPrivate,
      isFreeRetryUsed: isFreeRetryUsed ?? this.isFreeRetryUsed,
      anatomicalScore: anatomicalScore ?? this.anatomicalScore,
      watermarkText: watermarkText ?? this.watermarkText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      cacheHit: cacheHit ?? this.cacheHit,
    );
  }
}
