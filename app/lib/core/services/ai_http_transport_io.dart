import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'ai_http_response.dart';

Future<AiHttpResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  Map<String, String>? headers,
  String? body,
  Duration timeout = const Duration(seconds: 4),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.openUrl(method, uri).timeout(timeout);
    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(body));
    }
    final response = await request.close().timeout(timeout);
    final responseBody =
        await response.transform(utf8.decoder).join().timeout(timeout);
    return AiHttpResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  } finally {
    client.close(force: true);
  }
}
