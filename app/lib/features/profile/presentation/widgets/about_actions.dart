import 'about_actions_stub.dart'
    if (dart.library.js_interop) 'about_actions_web.dart'
    as platform;

void reloadAppWindow() => platform.reloadAppWindow();

void openExternalUrl(String url) => platform.openExternalUrl(url);
