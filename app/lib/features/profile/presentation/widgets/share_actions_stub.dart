import 'package:share_plus/share_plus.dart';

Future<bool> shareLink(String link, String title) async {
  try {
    final result = await SharePlus.instance.share(
      ShareParams(text: link, title: title),
    );
    return result.status != ShareResultStatus.unavailable;
  } catch (_) {
    return false;
  }
}
