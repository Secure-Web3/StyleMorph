import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/extracted_web_product.dart';
import '../shop_provider.dart';

/// Displays an image-first Google Search WebView on mobile (`!kIsWeb`) with
/// live [AppColors] theme synchronization and header masking, or a sleek
/// external-browser launch card on Flutter Web (`kIsWeb`).
class ShopWebDiscoveryView extends ConsumerStatefulWidget {
  const ShopWebDiscoveryView({
    super.key,
    required this.searchUri,
    required this.searchQuery,
    this.activeFilterLabels = const [],
    @visibleForTesting this.onTestProductChannelReady,
  });

  final Uri searchUri;
  final String searchQuery;
  final List<String> activeFilterLabels;
  final void Function(void Function(String) onMessage)?
  onTestProductChannelReady;

  @visibleForTesting
  static Color resolveWebViewBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Injected CSS/JS rule that guarantees sharp, unblurred, full-opacity
  /// rendering for search-grid thumbnails and opened product images.
  @visibleForTesting
  static String buildCrispImagesJs() {
    return '''
(function() {
  var id = 'stylemorph-crisp-images';
  var style = document.getElementById(id);
  if (!style) {
    style = document.createElement('style');
    style.id = id;
    document.head && document.head.appendChild(style);
  }
  style.textContent = 'img, picture, video, [style*="background-image"] { filter: none !important; -webkit-filter: none !important; backdrop-filter: none !important; -webkit-backdrop-filter: none !important; opacity: 1 !important; }';
})();
''';
  }

  /// Capturing JS long-press bridge on `document` that resolves elements under
  /// transparent product-card overlays (`elementFromPoint`), suppresses the
  /// native context menu, and posts product metadata to `StyleMorphProductChannel`.
  @visibleForTesting
  static String buildImageLongPressBridgeJs() {
    return '''
(function() {
  if (window.__styleMorphLongPressInstalled) return;
  window.__styleMorphLongPressInstalled = true;

  var holdTimer = null;
  var startX = 0;
  var startY = 0;
  var longPressFired = false;
  var gestureActive = false;
  var prevUserSelect = '';
  var prevTouchCallout = '';

  function applyTouchSuppression() {
    var root = document.documentElement;
    if (!root) return;
    prevUserSelect = root.style.userSelect || '';
    prevTouchCallout = root.style.webkitTouchCallout || '';
    root.style.userSelect = 'none';
    root.style.webkitUserSelect = 'none';
    root.style.webkitTouchCallout = 'none';
  }

  function restoreTouchSuppression() {
    var root = document.documentElement;
    if (!root) return;
    root.style.userSelect = prevUserSelect;
    root.style.webkitUserSelect = prevUserSelect;
    root.style.webkitTouchCallout = prevTouchCallout;
  }

  function startHold(target, x, y) {
    if (gestureActive) return;
    gestureActive = true;
    longPressFired = false;
    startX = x;
    startY = y;
    applyTouchSuppression();
    clearTimeout(holdTimer);
    holdTimer = setTimeout(function() {
      var payload = findProductPayload(target, startX, startY);
      if (payload) {
        longPressFired = true;
        postPayload(payload);
      }
    }, 320);
  }

  function moveHold(x, y) {
    if (!holdTimer) return;
    var dx = Math.abs(x - startX);
    var dy = Math.abs(y - startY);
    if (dx > 12 || dy > 12) {
      clearTimeout(holdTimer);
      holdTimer = null;
      gestureActive = false;
      restoreTouchSuppression();
    }
  }

  function endHold(e) {
    clearTimeout(holdTimer);
    holdTimer = null;
    gestureActive = false;
    restoreTouchSuppression();
    if (longPressFired) {
      e.preventDefault();
      e.stopPropagation();
      longPressFired = false;
    }
  }

  function cancelHold() {
    clearTimeout(holdTimer);
    holdTimer = null;
    gestureActive = false;
    longPressFired = false;
    restoreTouchSuppression();
  }

  function extractBgImageUrl(el) {
    if (!el || !window.getComputedStyle) return '';
    var bg = window.getComputedStyle(el).backgroundImage || '';
    var match = bg.match(/url\\(["']?([^"')]+)["']?\\)/i);
    return (match && match[1]) ? match[1] : '';
  }

  function findProductPayload(rawTarget, x, y) {
    var pointTarget = (typeof x === 'number' && typeof y === 'number' && document.elementFromPoint)
      ? (document.elementFromPoint(x, y) || rawTarget)
      : rawTarget;
    if (!pointTarget || !pointTarget.closest) return null;

    var tile = pointTarget.closest('a, [data-docid], [data-ved], article, li, [data-ri], .isv-r') ||
      pointTarget.closest('div');
    var anchor = pointTarget.closest('a') || (tile && tile.querySelector ? tile.querySelector('a') : null);
    var img = pointTarget.tagName === 'IMG' ? pointTarget : pointTarget.closest('img');
    if (!img && tile && tile.querySelector) {
      img = tile.querySelector('img');
    }

    var imageUrl = '';
    if (img) {
      imageUrl = img.currentSrc || img.src || img.getAttribute('data-src') || '';
    }
    if (!imageUrl) {
      imageUrl = extractBgImageUrl(pointTarget) || extractBgImageUrl(tile);
    }
    if (!imageUrl || imageUrl.indexOf('data:') === 0) return null;

    var pageUrl = (anchor && anchor.href) ? anchor.href : (window.location.href || '');
    var rawTitle = (
      (img && img.getAttribute('alt')) ||
      pointTarget.getAttribute('aria-label') ||
      pointTarget.getAttribute('title') ||
      (anchor && (anchor.getAttribute('aria-label') || anchor.getAttribute('title'))) ||
      ''
    ).trim();
    if (!rawTitle && tile && tile.querySelector) {
      var heading = tile.querySelector('h1, h2, h3, h4, [role="heading"], span, div');
      if (heading && heading.textContent) {
        rawTitle = heading.textContent.trim().slice(0, 120);
      }
    }
    if (!rawTitle) {
      rawTitle = (document.title || '').trim();
    }
    var host = '';
    try { host = new URL(pageUrl).hostname || ''; } catch (e) { host = window.location.hostname || ''; }
    return {
      imageUrl: imageUrl,
      title: rawTitle,
      pageUrl: pageUrl,
      sourceHost: host
    };
  }

  function postPayload(payload) {
    if (!payload) return;
    if (window.StyleMorphProductChannel && window.StyleMorphProductChannel.postMessage) {
      window.StyleMorphProductChannel.postMessage(JSON.stringify(payload));
    }
  }

  document.addEventListener('contextmenu', function(e) {
    var payload = findProductPayload(e.target, e.clientX, e.clientY);
    if (payload) {
      e.preventDefault();
      e.stopPropagation();
      postPayload(payload);
    }
  }, { capture: true, passive: false });

  document.addEventListener('pointerdown', function(e) {
    if (e.isPrimary === false) return;
    startHold(e.target, e.clientX, e.clientY);
  }, { capture: true, passive: false });

  document.addEventListener('pointermove', function(e) {
    if (e.isPrimary === false) return;
    moveHold(e.clientX, e.clientY);
  }, { capture: true, passive: false });

  document.addEventListener('pointerup', endHold, { capture: true, passive: false });
  document.addEventListener('pointercancel', cancelHold, { capture: true, passive: false });

  document.addEventListener('touchstart', function(e) {
    if (!e.touches || e.touches.length !== 1) return;
    startHold(e.target, e.touches[0].clientX, e.touches[0].clientY);
  }, { capture: true, passive: false });

  document.addEventListener('touchmove', function(e) {
    if (!e.touches || e.touches.length !== 1) return;
    moveHold(e.touches[0].clientX, e.touches[0].clientY);
  }, { capture: true, passive: false });

  document.addEventListener('touchend', endHold, { capture: true, passive: false });
  document.addEventListener('touchcancel', cancelHold, { capture: true, passive: false });
})();
''';
  }

  @override
  ConsumerState<ShopWebDiscoveryView> createState() =>
      _ShopWebDiscoveryViewState();
}

class _ShopWebDiscoveryViewState extends ConsumerState<ShopWebDiscoveryView>
    with AutomaticKeepAliveClientMixin {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _webViewSupported = false;
  bool _canGoBack = false;
  bool _isProductPage = false;
  ExtractedWebProduct? _extractedProduct;
  ExtractedWebProduct? _longPressedProduct;
  AppColors? _lastColors;
  ThemeData? _lastTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.onTestProductChannelReady?.call((rawJson) {
      _handleProductChannelMessage(JavaScriptMessage(message: rawJson));
    });
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
        ..addJavaScriptChannel(
          'StyleMorphProductChannel',
          onMessageReceived: _handleProductChannelMessage,
        )
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
              final colors = context.colors;
              setState(() {
                _isLoading = false;
                _canGoBack = canBack;
                _isProductPage = onProductPage;
              });
              await _injectLongPressBridge();
              if (!mounted) return;
              if (onProductPage) {
                await _injectCrispImages();
                await _extractProductMetadata();
              } else {
                await _injectHeaderMaskAndTheme(colors);
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
    final theme = Theme.of(context);
    final colors = context.colors;
    if (_lastTheme != theme || _lastColors != colors) {
      _lastTheme = theme;
      _lastColors = colors;
      _syncThemeToWebView(
        colors,
        surfaceColor: ShopWebDiscoveryView.resolveWebViewBackgroundColor(
          context,
        ),
      );
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

  Future<void> _syncThemeToWebView(
    AppColors colors, {
    Color? surfaceColor,
  }) async {
    final controller = _controller;
    if (!_webViewSupported || controller == null) return;
    try {
      await controller.setBackgroundColor(surfaceColor ?? colors.bg);
      await controller.runJavaScript(_buildThemeSyncJs(colors));
    } catch (_) {}
  }

  Future<void> _injectCrispImages() async {
    final controller = _controller;
    if (!_webViewSupported || controller == null) return;
    try {
      await controller.runJavaScript(ShopWebDiscoveryView.buildCrispImagesJs());
    } catch (_) {}
  }

  Future<void> _injectLongPressBridge() async {
    final controller = _controller;
    if (!_webViewSupported || controller == null) return;
    try {
      await controller.runJavaScript(
        ShopWebDiscoveryView.buildImageLongPressBridgeJs(),
      );
    } catch (_) {}
  }

  void _handleProductChannelMessage(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map) return;
      final product = ExtractedWebProduct.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!product.isValid) return;
      setState(() => _longPressedProduct = product);
      AppModal.showSheet(
        context: context,
        child: DiscoveryProductActionSheet(product: product),
      );
    } catch (_) {}
  }

  Future<void> _injectHeaderMaskAndTheme(AppColors colors) async {
    final controller = _controller;
    if (!_webViewSupported || controller == null) return;
    try {
      final surfaceColor = ShopWebDiscoveryView.resolveWebViewBackgroundColor(
        context,
      );
      await controller.setBackgroundColor(surfaceColor);
      await controller.runJavaScript(
        '${_buildHeaderMaskJs()}\n${_buildThemeSyncJs(colors)}\n${ShopWebDiscoveryView.buildCrispImagesJs()}',
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
    super.build(context);
    final colors = context.colors;
    final strings = context.strings;

    ref.listen<ThemeState>(themeProvider, (_, _) {
      if (mounted) {
        _syncThemeToWebView(context.colors);
      }
    });

    ref.listen<Uri?>(shopProvider.select((s) => s.browserReopenUri), (_, uri) {
      if (uri != null && mounted) {
        if (_webViewSupported && _controller != null) {
          setState(() => _isLoading = true);
          _controller!.loadRequest(uri);
        }
        ref.read(shopProvider.notifier).clearBrowserReopenUri();
      }
    });

    final activeProduct = _longPressedProduct ?? _extractedProduct;

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
          WebViewWidget(
            controller: _controller!,
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
              ),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            },
          ),
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
          if ((_isProductPage || _longPressedProduct != null) &&
              activeProduct != null &&
              activeProduct.isValid)
            PositionedDirectional(
              bottom: AppSpacing.sm,
              start: AppSpacing.sm,
              end: AppSpacing.sm,
              child: DiscoveryProductActionBar(product: activeProduct),
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
      alignment: AlignmentDirectional.center,
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              size: 40,
              color: colors.pr.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              strings.shopWebPreviewTitle,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle(color: colors.tx),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              searchQuery,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(color: colors.mu),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              size: AppButtonSize.md,
              text: strings.shopSearchOnGoogle,
              onPressed: onOpenExternal,
            ),
          ],
        ),
      ),
    );
  }
}

void _performSendToStylist(
  BuildContext context,
  WidgetRef ref,
  ExtractedWebProduct product,
) {
  ref.read(shopHandoffProvider.notifier).sendToStylist(product);
  ref.read(appStateProvider.notifier).switchTab(AppTab.stylist);
  AppToast.showSuccess(context, context.strings.shopWebSentToStylistMsg);
}

void _performSendToAtelier(
  BuildContext context,
  WidgetRef ref,
  ExtractedWebProduct product,
) {
  ref.read(shopHandoffProvider.notifier).sendToAtelier(product);
  ref.read(appStateProvider.notifier).switchTab(AppTab.atelier);
  AppToast.showSuccess(context, context.strings.shopWebSentToAtelierMsg);
}

void _performSaveToWishlist(
  BuildContext context,
  WidgetRef ref,
  ExtractedWebProduct product,
) {
  ref.read(shopProvider.notifier).saveWebProductToWishlist(product);
  AppToast.showSuccess(context, context.strings.shopWebSavedWishlistSuccess);
}

/// Sleek glassmorphic bottom action pill displaying strictly the 3 target
/// product actions (`Send to Stylist`, `Send to Atelier`, `Save to Wishlist`).
class DiscoveryProductActionBar extends ConsumerWidget {
  const DiscoveryProductActionBar({super.key, required this.product});

  final ExtractedWebProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final isSaved = ref.watch(
      shopProvider.select(
        (s) => s.webWishlist.any((p) => p.wishlistKey == product.wishlistKey),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.sf.withValues(alpha: 0.94),
        borderRadius: AppRadius.rXl,
        border: Border.all(color: colors.bd),
        boxShadow: [
          BoxShadow(
            color: colors.tx.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiscoveryProductHeader(product: product, thumbSize: 36),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  onPressed: () => _performSendToStylist(context, ref, product),
                  child: _ActionPillLabel(
                    icon: Icons.checkroom_rounded,
                    label: strings.shopWebSendToStylistBtn,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  onPressed: () => _performSendToAtelier(context, ref, product),
                  child: _ActionPillLabel(
                    icon: Icons.auto_awesome_rounded,
                    label: strings.shopWebSendToAtelierBtn,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  onPressed: () =>
                      _performSaveToWishlist(context, ref, product),
                  child: _ActionPillLabel(
                    icon: isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: strings.shopWebSaveWishlistBtn,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet triggered when long-pressing any product image or card inside
/// the Shop WebView, offering preview thumbnail + the 3 target actions.
class DiscoveryProductActionSheet extends ConsumerWidget {
  const DiscoveryProductActionSheet({super.key, required this.product});

  final ExtractedWebProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final isSaved = ref.watch(
      shopProvider.select(
        (s) => s.webWishlist.any((p) => p.wishlistKey == product.wishlistKey),
      ),
    );

    return AppBottomSheetShell(
      title: product.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: _DiscoveryProductHeader(product: product, thumbSize: 64),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            isFullWidth: true,
            icon: const Icon(Icons.checkroom_rounded, size: 16),
            text: strings.shopWebSendToStylistBtn,
            onPressed: () {
              Navigator.pop(context);
              _performSendToStylist(context, ref, product);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            text: strings.shopWebSendToAtelierBtn,
            onPressed: () {
              Navigator.pop(context);
              _performSendToAtelier(context, ref, product);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.outline,
            isFullWidth: true,
            icon: Icon(
              isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
            ),
            text: strings.shopWebSaveWishlistBtn,
            onPressed: () {
              Navigator.pop(context);
              _performSaveToWishlist(context, ref, product);
            },
          ),
        ],
      ),
    );
  }
}

class _DiscoveryProductHeader extends StatelessWidget {
  const _DiscoveryProductHeader({
    required this.product,
    required this.thumbSize,
  });

  final ExtractedWebProduct product;
  final double thumbSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = [
      product.sourceHost,
      if (product.priceText != null)
        '${product.priceText} ${product.currency ?? ''}'.trim(),
    ].where((e) => e.isNotEmpty).join(' · ');

    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadius.rMd,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            color: colors.bg,
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.shopping_bag_outlined,
                      color: colors.pr,
                      size: 18,
                    ),
                  )
                : Icon(Icons.shopping_bag_outlined, color: colors.pr, size: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.title,
                style: AppTypography.cardTitle(color: colors.tx),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: AppTypography.caption(color: colors.mu),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionPillLabel extends StatelessWidget {
  const _ActionPillLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, maxLines: 1),
        ],
      ),
    );
  }
}
