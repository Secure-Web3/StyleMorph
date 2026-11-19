import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'turnstile_skeleton.dart';

const String kTurnstileSiteKey = '0x4AAAAAAGILAS7YQZalDE3k';

@JS('setTurnstileHandler')
external void _setTurnstileHandler(
  String callbackId,
  JSFunction onVerified,
  JSFunction onExpired,
  JSFunction onError,
  JSFunction onLoaded,
);

@JS('removeTurnstileHandler')
external void _removeTurnstileHandler(String callbackId);

@JS('renderTurnstileExplicit')
external String? _jsRenderTurnstile(
  String containerId,
  String siteKey,
  String callbackId,
  String theme,
);

@JS('resetTurnstileExplicit')
external void _jsResetTurnstile(String? widgetId);

@JS('isTurnstileLoaded')
external bool _isTurnstileLoaded();

class TurnstileController {
  _TurnstileWidgetState? _state;

  void reset() {
    _state?.reset();
  }
}

class TurnstileWidget extends StatefulWidget {
  final ValueChanged<String> onVerified;
  final VoidCallback? onExpired;
  final VoidCallback? onError;
  final TurnstileController? controller;
  final String siteKey;

  const TurnstileWidget({
    super.key,
    required this.onVerified,
    this.onExpired,
    this.onError,
    this.controller,
    this.siteKey = kTurnstileSiteKey,
  });

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  late final String _uniqueId;
  late final String _viewId;
  late final String _containerId;
  String? _widgetId;
  Timer? _renderTimer;
  bool _isInteractive = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _uniqueId = '${DateTime.now().microsecondsSinceEpoch}';
    _viewId = 'turnstile-view-$_uniqueId';
    _containerId = 'cf-turnstile-container-$_uniqueId';

    // Register platform view for web
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = _containerId;
      div.style.width = '100%';
      div.style.height = '65px';
      div.style.display = 'flex';
      div.style.justifyContent = 'center';
      div.style.alignItems = 'center';
      return div;
    });

    _registerCallbacks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleRender();
    });
  }

  @override
  void didUpdateWidget(covariant TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    _renderTimer?.cancel();
    try {
      _removeTurnstileHandler(_uniqueId);
    } catch (_) {}
    super.dispose();
  }

  void reset() {
    try {
      _jsResetTurnstile(_widgetId);
    } catch (_) {}
  }

  void _registerCallbacks() {
    void onVerifiedDart(JSString token) {
      if (mounted) {
        widget.onVerified(token.toDart);
      }
    }

    void onExpiredDart() {
      if (mounted) {
        widget.onExpired?.call();
      }
    }

    void onErrorDart(JSAny? _) {
      if (mounted) {
        widget.onError?.call();
      }
    }

    void onLoadedDart() {
      if (mounted && !_isInteractive) {
        setState(() {
          _isInteractive = true;
        });
      }
    }

    try {
      _setTurnstileHandler(
        _uniqueId,
        onVerifiedDart.toJS,
        onExpiredDart.toJS,
        onErrorDart.toJS,
        onLoadedDart.toJS,
      );
    } catch (e) {
      debugPrint('[TurnstileWeb] _setTurnstileHandler error: $e');
    }
  }

  void _scheduleRender([int attempt = 0]) {
    if (!mounted) return;
    try {
      final el = web.document.getElementById(_containerId);
      final hasTurnstile = _isTurnstileLoaded();
      if (el != null && hasTurnstile) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final res = _jsRenderTurnstile(
          _containerId,
          widget.siteKey,
          _uniqueId,
          isDark ? 'dark' : 'light',
        );
        if (res != null) {
          _widgetId = res;
          return;
        }
      }
    } catch (e) {
      debugPrint('[TurnstileWeb] Render attempt error: $e');
    }

    if (attempt < 15) {
      _renderTimer = Timer(const Duration(milliseconds: 250), () {
        _scheduleRender(attempt + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Cloudflare Turnstile platform view iframe (renders underneath)
          HtmlElementView(viewType: _viewId),

          // 2. Smooth Shimmer/Pulse Skeleton (Cross-fades out when interactive)
          IgnorePointer(
            ignoring: _isInteractive,
            child: AnimatedOpacity(
              opacity: _isInteractive ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: const TurnstileSkeleton(width: 300, height: 65),
            ),
          ),
        ],
      ),
    );
  }
}
