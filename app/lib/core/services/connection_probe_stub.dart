/// Stub reachability probe used on Web or unsupported platforms.
Future<bool> probeServerReachabilityImpl({
  Duration timeout = const Duration(seconds: 4),
}) async {
  return true;
}
