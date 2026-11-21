import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<bool> shareLink(String link, String title) async {
  try {
    final nav = web.window.navigator;
    final shareData = web.ShareData(title: title, url: link);
    if (nav.canShare(shareData)) {
      await nav.share(shareData).toDart;
      return true;
    }
  } catch (_) {}
  return false;
}
