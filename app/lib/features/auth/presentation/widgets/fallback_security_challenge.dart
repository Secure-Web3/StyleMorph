import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Controller to trigger programmatic resets of [FallbackSecurityChallenge].
class FallbackChallengeController {
  _FallbackSecurityChallengeState? _state;

  void reset() {
    _state?.reset();
  }
}

/// A lightweight, interactive local security challenge (Smart Fallback Verification)
/// that replaces Cloudflare Turnstile when Turnstile fails to load or times out.
///
/// Presents a randomized simple arithmetic check (e.g. `4 + 3 = ?`) in a luxury
/// 65px editorial box matching Turnstile's exact footprint.
class FallbackSecurityChallenge extends StatefulWidget {
  final ValueChanged<String> onVerified;
  final FallbackChallengeController? controller;
  final double width;
  final double height;

  const FallbackSecurityChallenge({
    super.key,
    required this.onVerified,
    this.controller,
    this.width = 300,
    this.height = 65,
  });

  @override
  State<FallbackSecurityChallenge> createState() =>
      _FallbackSecurityChallengeState();
}

class _FallbackSecurityChallengeState extends State<FallbackSecurityChallenge> {
  late final TextEditingController _answerController;
  late int _a;
  late int _b;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _answerController = TextEditingController();
    _generatePuzzle();
  }

  @override
  void didUpdateWidget(covariant FallbackSecurityChallenge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    _answerController.dispose();
    super.dispose();
  }

  void reset() {
    if (mounted) {
      setState(() {
        _isVerified = false;
        _answerController.clear();
        _generatePuzzle();
      });
    }
  }

  void _generatePuzzle() {
    final rand = Random();
    _a = 2 + rand.nextInt(7); // 2 to 8
    _b = 1 + rand.nextInt(8); // 1 to 8
  }

  void _checkAnswer(String input) {
    if (_isVerified) return;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    final normalized = _normalizeDigits(trimmed);
    final val = int.tryParse(normalized);
    if (val != null && val == (_a + _b)) {
      setState(() {
        _isVerified = true;
      });
      final token =
          'local_fallback_challenge_${DateTime.now().millisecondsSinceEpoch}';
      widget.onVerified(token);
    }
  }

  static String _normalizeDigits(String input) {
    const faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var res = input;
    for (var i = 0; i < 10; i++) {
      res = res.replaceAll(faDigits[i], '$i').replaceAll(arDigits[i], '$i');
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (_isVerified) {
      return Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.ok.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colors.ok.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: colors.ok, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              strings.authFallbackVerified,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ok,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.bd, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_rounded, size: 16, color: colors.mu),
          const SizedBox(width: AppSpacing.xs),
          Text(
            strings.authFallbackMathQuestion(_a, _b),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.tx,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 52,
            height: 36,
            child: TextField(
              controller: _answerController,
              onChanged: _checkAnswer,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.tx,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                hintText: strings.authFallbackAnswerHint,
                hintStyle: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10,
                  color: colors.mu,
                ),
                filled: true,
                fillColor: colors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colors.bd),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colors.bd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colors.pr, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 16, color: colors.mu),
            tooltip: 'Refresh puzzle',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              setState(() {
                _answerController.clear();
                _generatePuzzle();
              });
            },
          ),
        ],
      ),
    );
  }
}
