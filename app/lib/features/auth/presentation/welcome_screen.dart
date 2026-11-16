import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import 'auth_provider.dart';
import 'auth_screen.dart';
import 'widgets/auth_top_bar.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = context.strings;
    final backgroundUrl = ref.watch(welcomeBackgroundUrlProvider);
    final hasBackground = backgroundUrl != null;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Dynamic background ───────────────────────────────
          _BackgroundLayer(imageUrl: backgroundUrl, colors: colors),

          // ── Layer 2: Main Layout ──────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Universal Top Header (Theme, Palette, Language) ──────
                AuthTopBar(isTransparent: hasBackground),

                // ── Central branding & Logo ─────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogo(size: 80),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            strings.appName,
                            style: AppTypography.displayLarge(
                              color: hasBackground ? Colors.white : colors.tx,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom Content Card ─────────────────────────────────
                _BottomContentSection(
                  colors: colors,
                  strings: strings,
                  hasBackground: hasBackground,
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
                stops: [0.15, 0.65, 1.0],
                colors: [
                  Color(0x33000000),
                  Color(0x88000000),
                  Color(0xEE000000),
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
  final AppStrings strings;
  final bool hasBackground;

  const _BottomContentSection({
    required this.colors,
    required this.strings,
    required this.hasBackground,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = hasBackground ? Colors.white : colors.tx;
    final subtitleColor =
        hasBackground ? Colors.white.withValues(alpha: 0.8) : colors.mu;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Localized tagline
          Text(
            strings.authWelcomeTagline,
            style: AppTypography.titleMedium(color: textColor),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.authWelcomeDesc,
            style: AppTypography.bodySmall(color: subtitleColor),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Single dynamic localized CTA button
          AppButton(
            isFullWidth: true,
            text: strings.authGetStarted,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Pinned Footer
          Center(
            child: Text(
              strings.authCopyrightYear,
              style: AppTypography.caption(color: subtitleColor),
            ),
          ),
        ],
      ),
    );
  }
}
