import 'share_actions_stub.dart'
    if (dart.library.js_interop) 'share_actions_web.dart'
    as platform;

/// Attempts to trigger native OS/browser sharing.
/// Returns true if native share succeeded, or false if not supported/cancelled.
Future<bool> shareLink(String link, String title) =>
    platform.shareLink(link, title);
