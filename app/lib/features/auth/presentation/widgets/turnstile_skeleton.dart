import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Luxury Editorial styled shimmer/pulse loading skeleton box for the
/// Cloudflare Turnstile anti-bot verification widget.
///
/// Displays a subtle shield icon and localized security check text with smooth
/// pulsing opacity while the Turnstile script and iframe load.
class TurnstileSkeleton extends StatefulWidget {
  final double width;
  final double height;

  const TurnstileSkeleton({super.key, this.width = 300, this.height = 65});

  @override
  State<TurnstileSkeleton> createState() => _TurnstileSkeletonState();
}

class _TurnstileSkeletonState extends State<TurnstileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.45, end: 0.90).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final pulse = _pulseAnim.value;
        return Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.sf.withValues(alpha: pulse),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colors.bd.withValues(alpha: pulse),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: colors.mu.withValues(alpha: pulse),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  strings.authTurnstileChecking,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.mu.withValues(alpha: pulse),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
