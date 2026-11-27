import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/extracted_web_product.dart';
import 'web_product_action_bar.dart';

/// Displays an image-first Google Search WebView on mobile (`!kIsWeb`) with
/// live [AppColors] theme synchronization and header masking, or a sleek
/// external-browser launch card on Flutter Web (`kIsWeb`).
class ShopWebDiscoveryView extends ConsumerStatefulWidget {
  const ShopWebDiscoveryView({
    super.key,
    required this.searchUri,
    required this.searchQuery,
    this.activeFilterLabels = const [],
  });

  final Uri searchUri;
  final String searchQuery;
  final List<String> activeFilterLabels;

  @override
  ConsumerState<ShopWebDiscoveryView> createState() =>
      _ShopWebDiscoveryViewState();
}

class _ShopWebDiscoveryViewState extends ConsumerState<ShopWebDiscoveryView> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _webViewSupported = false;
  bool _canGoBack = false;
  bool _isProductPage = false;
  ExtractedWebProduct? _extractedProduct;
  AppColors? _lastColors;

  @override
  void initState() {
    super.initState();
    _initWebViewIfSupported();
  }

  static bool _isGoogleSearchUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.contains('google.') && uri.path.startsWith('/search');
  }

  void _initWebViewIfSupported() {
    if (kIsWeb) return;
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) => NavigationDecision.navigate,
            onPageStarted: (url) {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _isProductPage = !_isGoogleSearchUrl(url);
                if (!_isProductPage) {
                  _extractedProduct = null;
                }
              });
            },
            onPageFinished: (url) async {
              if (!mounted) return;
              final canBack =
                  await (_controller?.canGoBack() ?? Future.value(false));
              final onProductPage = !_isGoogleSearchUrl(url);
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _canGoBack = canBack;
                _isProductPage = onProductPage;
              });
              if (onProductPage) {
                await _extractProductMetadata();
              } else {
                await _injectHeaderMaskAndTheme(context.colors);
              }
            },
            onWebResourceError: (_) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        )
        ..loadRequest(widget.searchUri);

      _controller = controller;
      _webViewSupported = true;
    } catch (_) {
      // Headless test environments without a registered WebViewPlatform
      // safely fall back to the preview card.
      _controller = null;
      _webViewSupported = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colors = context.colors;
    if (_lastColors != colors) {
      _lastColors = colors;
      _syncThemeToWebView(colors);
    }
  }

  @override
  void didUpdateWidget(covariant ShopWebDiscoveryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchUri != widget.searchUri) {
      if (_webViewSupported && _controller != null) {
        setState(() => _isLoading = true);
        _controller!.loadRequest(widget.searchUri);
      }
    }
  }

  static String _toCssHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  Future<void> _syncThemeToWebView(AppColors colors) async {
    final controller = _controller;
    if (!_webViewSupported || controller == null) return;
    try {
      await controller.setBackgroundColor(colors.bg);
      await controller.runJavaScript(_buildThemeSyncJs(colors));
    } catch (_) {}
  }

  Future<void> _injectHeaderMaskAndTheme(AppColors colors) async {
    final controller = _controller;
    if (!_webViewSupported || controller == null) return;
    try {
      await controller.setBackgroundColor(colors.bg);
      await controller.runJavaScript(
        '${_buildHeaderMaskJs()}\n${_buildThemeSyncJs(colors)}',
      );
    } catch (_) {}
  }

  Future<void> _extractProductMetadata() async {
    final controller = _controller;
    if (!_webViewSupported || controller == null) return;
    try {
      final raw = await controller.runJavaScriptReturningResult(
        _extractPageProductMetadataJs,
      );
      if (!mounted) return;

      dynamic decoded = raw;
      if (decoded is String) {
        decoded = jsonDecode(decoded);
        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }
      }

      if (decoded is Map) {
        final product = ExtractedWebProduct.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (product.isValid) {
          setState(() => _extractedProduct = product);
        }
      }
    } catch (_) {}
  }

  static const String _extractPageProductMetadataJs = '''
(function extractPageProductMetadata() {
  function metaContent(selectors) {
    for (var i = 0; i < selectors.length; i++) {
      var el = document.querySelector(selectors[i]);
      if (el && el.getAttribute('content')) {
        return el.getAttribute('content').trim();
      }
    }
    return '';
  }

  var title = metaContent([
    'meta[property="og:title"]',
    'meta[name="twitter:title"]'
  ]) || (document.title || '').trim();

  var imageUrl = metaContent([
    'meta[property="og:image"]',
    'meta[property="og:image:secure_url"]',
    'meta[name="twitter:image"]'
  ]);

  if (!imageUrl) {
    var imgs = Array.prototype.slice.call(document.querySelectorAll('img'));
    var bestArea = 0;
    for (var j = 0; j < imgs.length; j++) {
      var img = imgs[j];
      var src = img.currentSrc || img.src || '';
      if (!src || src.indexOf('data:') === 0) continue;
      var w = img.naturalWidth || img.width || 0;
      var h = img.naturalHeight || img.height || 0;
      var area = w * h;
      if (area > bestArea && w >= 120 && h >= 120) {
        bestArea = area;
        imageUrl = src;
      }
    }
  }

  var priceText = metaContent([
    'meta[property="product:price:amount"]',
    'meta[property="og:price:amount"]'
  ]);
  var currency = metaContent([
    'meta[property="product:price:currency"]',
    'meta[property="og:price:currency"]'
  ]);

  if (!priceText) {
    var scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (var k = 0; k < scripts.length; k++) {
      try {
        var data = JSON.parse(scripts[k].textContent || '{}');
        var offers = data.offers || (Array.isArray(data['@graph']) ? data['@graph'][0] && data['@graph'][0].offers : null);
        if (Array.isArray(offers)) offers = offers[0];
        if (offers && offers.price) {
          priceText = String(offers.price);
          currency = currency || String(offers.priceCurrency || '');
          break;
        }
      } catch (e) {}
    }
  }

  return JSON.stringify({
    title: title,
    imageUrl: imageUrl,
    pageUrl: window.location.href || '',
    sourceHost: window.location.hostname || '',
    priceText: priceText,
    currency: currency
  });
})();
''';

  static String _buildHeaderMaskJs() {
    return '''
(function() {
  var id = 'stylemorph-header-mask';
  var style = document.getElementById(id);
  if (!style) {
    style = document.createElement('style');
    style.id = id;
    document.head && document.head.appendChild(style);
  }
  style.textContent = [
    'header, form[role="search"], #gb, [role="navigation"], #top_nav, .sfbg, #searchform, #hdtb, .T1diZc, .A8SBwf { display: none !important; }',
    'body { margin-top: 0 !important; padding-top: 4px !important; }'
  ].join(' ');
})();
''';
  }

  static String _buildThemeSyncJs(AppColors colors) {
    final bg = _toCssHex(colors.bg);
    final sf = _toCssHex(colors.sf);
    final tx = _toCssHex(colors.tx);
    final bd = _toCssHex(colors.bd);
    final pr = _toCssHex(colors.pr);

    return '''
(function() {
  if (document.documentElement) {
    document.documentElement.style.backgroundColor = '$bg';
  }
  if (document.body) {
    document.body.style.backgroundColor = '$bg';
    document.body.style.color = '$tx';
  }
  var id = 'stylemorph-theme-sync';
  var style = document.getElementById(id);
  if (!style) {
    style = document.createElement('style');
    style.id = id;
    document.head && document.head.appendChild(style);
  }
  style.textContent = [
    'html, body, #main, #rcnt, #center_col { background-color: $bg !important; color: $tx !important; }',
    'a, span, div, h3 { color: $tx; }',
    'a:link, a:visited { color: $pr !important; }',
    '.isv-r, [data-ri] { background-color: $sf !important; border: 1px solid $bd !important; border-radius: 10px !important; }'
  ].join(' ');
})();
''';
  }

  Future<void> _openExternal() async {
    await launchUrl(widget.searchUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    ref.listen<ThemeState>(themeProvider, (_, _) {
      if (mounted) {
        _syncThemeToWebView(context.colors);
      }
    });

    if (kIsWeb || !_webViewSupported || _controller == null) {
      return _WebFallbackPreview(
        colors: colors,
        strings: strings,
        searchQuery: widget.searchQuery,
        activeFilterLabels: widget.activeFilterLabels,
        onOpenExternal: _openExternal,
      );
    }

    return Container(
      color: colors.bg,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_canGoBack)
            PositionedDirectional(
              top: AppSpacing.sm,
              start: AppSpacing.sm,
              child: Material(
                color: colors.sf.withValues(alpha: 0.94),
                borderRadius: AppRadius.rFull,
                elevation: 2,
                child: InkWell(
                  borderRadius: AppRadius.rFull,
                  onTap: () => _controller?.goBack(),
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.rFull,
                      border: Border.all(color: colors.bd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 15,
                          color: colors.pr,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.shopWebBackToResults,
                          style: AppTypography.cardTitle(color: colors.tx),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isProductPage &&
              _extractedProduct != null &&
              _extractedProduct!.isValid)
            PositionedDirectional(
              bottom: AppSpacing.sm,
              start: AppSpacing.sm,
              end: AppSpacing.sm,
              child: WebProductActionBar(product: _extractedProduct!),
            ),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    color: colors.pr,
                    backgroundColor: colors.bd,
                    minHeight: 2,
                  ),
                  Container(
                    width: double.infinity,
                    color: colors.sf.withValues(alpha: 0.92),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      strings.shopWebLoading,
                      style: AppTypography.caption(color: colors.mu),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WebFallbackPreview extends StatelessWidget {
  const _WebFallbackPreview({
    required this.colors,
    required this.strings,
    required this.searchQuery,
    required this.activeFilterLabels,
    required this.onOpenExternal,
  });

  final AppColors colors;
  final AppStrings strings;
  final String searchQuery;
  final List<String> activeFilterLabels;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.bg,
      alignment: AlignmentDirectional.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: AppCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.pr.withValues(alpha: 0.12),
                      borderRadius: AppRadius.rMd,
                    ),
                    child: Icon(
                      Icons.image_search_rounded,
                      color: colors.pr,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      strings.shopWebPreviewTitle,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.shopWebPreviewDesc,
                style: AppTypography.caption(color: colors.mu),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: AppRadius.rMd,
                  border: Border.all(color: colors.bd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 16, color: colors.pr),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        searchQuery,
                        style: AppTypography.inputLabel(color: colors.tx),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeFilterLabels.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: activeFilterLabels
                      .map(
                        (label) => AppBadge(
                          variant: AppBadgeVariant.standard,
                          size: AppBadgeSize.sm,
                          child: Text(label),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                isFullWidth: true,
                text: strings.shopWebOpenExternal,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                onPressed: onOpenExternal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
