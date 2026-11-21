import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/referral_service.dart';
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

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  static const String defaultAssetBackground = 'assets/images/welcome_bg.jpg';

  static Widget buildFadeFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    return _WelcomeScreenState._fadeFrameBuilder(
      context,
      child,
      frame,
      wasSynchronouslyLoaded,
    );
  }

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  ImageProvider? _precachedProvider;

  @override
  void initState() {
    super.initState();
    ReferralService().captureReferralFromUri(Uri.base).catchError((e) {
      debugPrint('[WelcomeScreen] captureReferral error: $e');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final remoteUrl = ref.read(welcomeBackgroundUrlProvider);
    final ImageProvider provider = remoteUrl != null
        ? NetworkImage(remoteUrl)
        : const AssetImage(WelcomeScreen.defaultAssetBackground);

    if (_precachedProvider != provider) {
      _precachedProvider = provider;
      precacheImage(provider, context).catchError((e) {
        debugPrint('[WelcomeScreen] precacheImage notice: $e');
      });
    }
  }

  static Widget _fadeFrameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) {
      return child;
    }
    return AnimatedOpacity(
      opacity: frame == null ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    ref.watch(localeProvider);
    final strings = context.strings;
    final remoteUrl = ref.watch(welcomeBackgroundUrlProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141210),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Luxury Editorial Base Gradient (Zero white flash on slow connections) ──
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF141210),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1B18), // Warm editorial surface
                  Color(0xFF141210), // Deep editorial background
                  Color(0xFF0D0C0A), // Shadowed base
                ],
              ),
            ),
          ),

          // ── 2. Hero Background Image with Smooth Fade-in ──
          Positioned.fill(
            child: remoteUrl != null
                ? Image.network(
                    remoteUrl,
                    fit: BoxFit.cover,
                    frameBuilder: _fadeFrameBuilder,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  )
                : Image.asset(
                    WelcomeScreen.defaultAssetBackground,
                    fit: BoxFit.cover,
                    frameBuilder: _fadeFrameBuilder,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
          ),

          // ── 3. Dark Readability Gradient Overlay ──
          Positioned.fill(
            child: DecoratedBox(
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
            ),
          ),

          // ── 4. Main Content (TopBar, Branding, CTA, Footer) ──
          SafeArea(
            child: Column(
              children: [
                // Universal Top Header (Pinned at top)
                const AuthTopBar(isTransparent: true),

                // Branding (Logo & App Title) below top bar
                _WelcomeBranding(strings: strings),

                // Spacer to push bottom content down
                const Spacer(),

                // Bottom Content Section
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
                        style: AppTypography.titleMedium(color: Colors.white),
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

                // Universal Footer (Pinned at bottom)
                const AuthFooter(isTransparent: true),
              ],
            ),
          ),
        ],
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
