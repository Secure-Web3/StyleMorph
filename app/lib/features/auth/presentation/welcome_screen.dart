import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import 'auth_provider.dart';
import 'auth_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final backgroundUrl = ref.watch(welcomeBackgroundUrlProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Dynamic background ───────────────────────────────
          _BackgroundLayer(imageUrl: backgroundUrl, colors: colors),

          // ── Layer 2: Content ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top logo area
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpacing.xxxl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppLogo(
                            size: 72,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'StyleMorph',
                            style: AppTypography.displayLarge(
                              color: backgroundUrl != null
                                  ? Colors.white
                                  : colors.tx,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom content card with gradient overlay
                _BottomContentSection(
                  colors: colors,
                  hasBackground: backgroundUrl != null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background Layer
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  final String? imageUrl;
  final AppColors colors;

  const _BackgroundLayer({required this.imageUrl, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _PlaceholderBackground(colors: colors),
          ),
          // Dark gradient overlay at the bottom for text readability
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.3, 0.7, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x88000000),
                  Color(0xDD000000),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _PlaceholderBackground(colors: colors);
  }
}

class _PlaceholderBackground extends StatelessWidget {
  final AppColors colors;

  const _PlaceholderBackground({required this.colors});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            colors.bg,
            colors.sf,
            colors.bd.withValues(alpha: 0.5),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Content Section
// ─────────────────────────────────────────────────────────────────────────────

class _BottomContentSection extends StatelessWidget {
  final AppColors colors;
  final bool hasBackground;

  const _BottomContentSection({
    required this.colors,
    required this.hasBackground,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = hasBackground ? Colors.white : colors.tx;
    final subtitleColor =
        hasBackground ? Colors.white.withValues(alpha: 0.75) : colors.mu;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.xxxl,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      decoration: hasBackground
          ? null
          : BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.bd, width: 1.0),
              ),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persian tagline
          Text(
            'پرو مجازی لباس • استایل شخصی با هوش مصنوعی',
            style: AppTypography.titleMedium(color: textColor),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'قبل از خرید، لباس را روی تصویر خود امتحان کنید.\n'
            'ست‌های مناسب پیدا کنید و سبک خود را بسازید.',
            style: AppTypography.bodySmall(color: subtitleColor),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Single CTA button
          AppButton(
            isFullWidth: true,
            text: 'شروع  ·  Get Started',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Footer note
          Center(
            child: Text(
              '© 2026 StyleMorph',
              style: AppTypography.caption(color: subtitleColor),
            ),
          ),
        ],
      ),
    );
  }
}
