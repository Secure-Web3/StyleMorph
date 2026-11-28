import 'dart:async';
import 'dart:io';

/// Probes Firebase/Firestore and GitHub Releases endpoints to detect
/// regional filtering or missing VPN when a local network interface is active.
Future<bool> probeServerReachabilityImpl({
  Duration timeout = const Duration(seconds: 4),
}) async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return true;
  }
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
    ).timeout(timeout);
    if (interfaces.isEmpty) {
      return true;
    }
  } catch (_) {
    // If interface enumeration fails, proceed with endpoint probes.
  }

  final endpoints = <Uri>[
    Uri.parse('https://firestore.googleapis.com/'),
    Uri.parse('https://api.github.com/'),
  ];

  final results = await Future.wait(
    endpoints.map((uri) => _probeEndpoint(uri, timeout)),
  );
  // If any critical endpoint is unreachable/timed out, alert the user.
  return results.every((reachable) => reachable);
}

Future<bool> _probeEndpoint(Uri uri, Duration timeout) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.headUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.userAgentHeader, 'StyleMorph-HealthCheck');
    final response = await request.close().timeout(timeout);
    await response.drain<void>().timeout(timeout);
    return response.statusCode > 0;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
