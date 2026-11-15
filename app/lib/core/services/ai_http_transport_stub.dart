import 'ai_http_response.dart';

Future<AiHttpResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  Map<String, String>? headers,
  String? body,
  Duration timeout = const Duration(seconds: 4),
}) async {
  // Non-IO platforms (e.g., Web preview without native sockets) fall back
  // gracefully to the local simulation layer.
  return const AiHttpResponse(statusCode: 0, body: '');
}
