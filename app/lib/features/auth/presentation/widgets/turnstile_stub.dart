import 'package:flutter/material.dart';

export 'turnstile_skeleton.dart';

const String kTurnstileSiteKey = '0x4AAAAAAGILAS7YQZalDE3k';

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
