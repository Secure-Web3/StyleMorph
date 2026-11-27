import 'package:flutter/foundation.dart';

/// Feedback categories for web discovery product pages.
enum WebProductFeedbackType { accurate, outOfStock, brokenLink, wrongItem }

/// Lightweight product metadata extracted from an external merchant page
/// inside the Shop WebView.
@immutable
class ExtractedWebProduct {
  final String title;
  final String imageUrl;
  final String pageUrl;
  final String sourceHost;
  final String? priceText;
  final String? currency;

  const ExtractedWebProduct({
    required this.title,
    required this.imageUrl,
    required this.pageUrl,
    required this.sourceHost,
    this.priceText,
    this.currency,
  });

  /// Returns true when the extracted payload has a valid URL and at least
  /// an image or title to display in the floating action bar.
  bool get isValid =>
      pageUrl.isNotEmpty && (imageUrl.isNotEmpty || title.isNotEmpty);

  /// Safely parses a JSON map returned by the WebView metadata extractor,
  /// handling missing or non-string fields gracefully.
  factory ExtractedWebProduct.fromJson(Map<String, dynamic> json) {
    final pageUrl = (json['pageUrl'] ?? json['url'] ?? '').toString().trim();
    final rawHost = (json['sourceHost'] ?? json['host'] ?? '')
        .toString()
        .trim();
    final derivedHost = rawHost.isNotEmpty
        ? rawHost
        : (Uri.tryParse(pageUrl)?.host ?? '');

    final rawTitle = (json['title'] ?? '').toString().trim();
    final rawImage = (json['imageUrl'] ?? json['image'] ?? '')
        .toString()
        .trim();
    final rawPrice = json['priceText'] ?? json['price'];
    final rawCurrency = json['currency'];

    final priceStr = rawPrice?.toString().trim();
    final currencyStr = rawCurrency?.toString().trim();

    return ExtractedWebProduct(
      title: rawTitle.isNotEmpty ? rawTitle : derivedHost,
      imageUrl: rawImage,
      pageUrl: pageUrl,
      sourceHost: derivedHost,
      priceText: (priceStr != null && priceStr.isNotEmpty) ? priceStr : null,
      currency: (currencyStr != null && currencyStr.isNotEmpty)
          ? currencyStr
          : null,
    );
  }
}
