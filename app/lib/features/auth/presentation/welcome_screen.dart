import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/welcome_persistence_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import 'auth_provider.dart';
import 'auth_screen.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_top_bar.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const String defaultAssetBackground = 'assets/images/welcome_bg.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    ref.watch(localeProvider);
    final strings = context.strings;
    final remoteUrl = ref.watch(welcomeBackgroundUrlProvider);

    final ImageProvider backgroundImage = remoteUrl != null
        ? NetworkImage(remoteUrl)
        : const AssetImage(defaultAssetBackground);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: backgroundImage,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Dark vertical gradient overlay at the bottom to ensure text readability
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.68, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.70),
                Colors.black.withValues(alpha: 0.92),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── 1. Universal Top Header (Pinned at top) ─────────────
                const AuthTopBar(isTransparent: true),

                // ── 2. Branding (Logo & App Title) below top bar ─────────
                _WelcomeBranding(strings: strings),

                // ── 3. Spacer to push bottom content down ────────────────
                const Spacer(),

                // ── 4. Bottom Content Section ────────────────────────────
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Localized tagline
                      Text(
                        strings.authWelcomeTagline,
                        style: AppTypography.titleMedium(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings.authWelcomeDesc,
                        style: AppTypography.bodySmall(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Localized CTA Button
                      AppButton(
                        isFullWidth: true,
                        text: strings.authGetStarted,
                        onPressed: () {
                          ref.read(hasSeenWelcomeProvider.notifier).markSeen();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── 5. Universal Footer (Pinned at bottom) ───────────────
                const AuthFooter(isTransparent: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editorial Branding Block: Logo + Wordmark (pinned just below AuthTopBar)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBranding extends StatelessWidget {
  final AppStrings strings;
  const _WelcomeBranding({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glass badge wrapping the logo icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: const AppLogo(size: 32),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Editorial wordmark with refined letter-spacing
          Text(
            strings.appName,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 3.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
