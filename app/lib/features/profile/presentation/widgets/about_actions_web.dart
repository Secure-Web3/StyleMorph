import 'package:web/web.dart' as web;

void reloadAppWindow() {
  web.window.location.reload();
}

void openExternalUrl(String url) {
  web.window.open(url, '_blank');
}
