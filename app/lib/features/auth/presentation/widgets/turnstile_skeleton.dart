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
  final bool isFailed;
  final VoidCallback? onRetry;

  const TurnstileSkeleton({
    super.key,
    this.width = 300,
    this.height = 65,
    this.isFailed = false,
    this.onRetry,
  });

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
          child: widget.isFailed
              ? InkWell(
                  onTap: widget.onRetry,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: colors.wn),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          strings.authTurnstileUnavailable,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamilyFor(
                              strings.localeCode,
                            ),
                            fontFamilyFallback:
                                AppTypography.fontFamilyFallbackFor(
                                  strings.localeCode,
                                ),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.mu,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.mu.withValues(alpha: pulse),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        strings.authTurnstileChecking,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamilyFor(
                            strings.localeCode,
                          ),
                          fontFamilyFallback:
                              AppTypography.fontFamilyFallbackFor(
                                strings.localeCode,
                              ),
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
