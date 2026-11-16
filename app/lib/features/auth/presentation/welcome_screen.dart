import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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

                // ── 2. Branding (Logo & App Title) ───────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogo(size: 76),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            strings.appName,
                            style: AppTypography.displayLarge(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 3. Bottom Content Section ────────────────────────────
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── 4. Universal Footer (Pinned at bottom) ───────────────
                const AuthFooter(isTransparent: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
