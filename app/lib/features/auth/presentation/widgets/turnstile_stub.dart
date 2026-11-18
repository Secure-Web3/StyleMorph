import 'package:flutter/material.dart';

const String kTurnstileSiteKey = '1x00000000000000000000AA';

class TurnstileController {
  void reset() {}
}

class TurnstileWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
