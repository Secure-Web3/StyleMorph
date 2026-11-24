import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/localization/app_language.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/biometric_service.dart';
import 'core/services/emulator_config.dart';
import 'core/services/prefetch/app_prefetch_service.dart';
import 'core/services/referral_service.dart';
import 'core/services/screenshot_protection_service.dart';
import 'core/services/session_persistence_service.dart';
import 'core/services/welcome_persistence_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_media_image.dart';
import 'core/widgets/unified_splash_screen.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/state/app_state.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/presentation/biometric_lock_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/profile/presentation/widgets/sessions_sub_tab.dart';
import 'features/shell/presentation/main_shell_screen.dart';
import 'features/wardrobe/presentation/wardrobe_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ScreenshotProtectionService().enableProtection();

  // Capture pending referral code from URL early before screen routing or Firebase init
  try {
    await ReferralService().captureReferralFromUri(Uri.base);
  } catch (e) {
    debugPrint('[ReferralCapture] Startup notice: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await EmulatorConfig.connectIfEnabled(
      connectAuth: (host, port) async {
        await FirebaseAuth.instance.useAuthEmulator(host, port);
      },
      connectFirestore: (host, port) {
        FirebaseFirestore.instance.useFirestoreEmulator(host, port);
      },
    );
    await SessionPersistenceService()
        .checkAndClearNonPersistentSessionOnStartup();
  } catch (e) {
    debugPrint('[FirebaseInit] Notice: $e');
  }
  runApp(const ProviderScope(child: StyleMorphApp()));
}

class StyleMorphApp extends ConsumerWidget {
  const StyleMorphApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(localeProvider);

    return MaterialApp(
      title: 'StyleMorph',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(
        palette: themeState.palette,
        isDark: false,
        localeCode: currentLang.code,
      ),
      darkTheme: AppTheme.buildTheme(
        palette: themeState.palette,
        isDark: true,
        localeCode: currentLang.code,
      ),
      themeMode: themeState.mode,
      locale: currentLang.locale,
      supportedLocales: AppLanguage.supportedLanguages
          .map((l) => l.locale)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final resolvedDark = themeState.resolveIsDark(context);
        final activeColors = AppColors.resolve(
          themeState.palette,
          resolvedDark,
        );
        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: activeColors.bg,
          statusBarIconBrightness: resolvedDark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: resolvedDark
              ? Brightness.dark
              : Brightness.light,
          systemNavigationBarColor: activeColors.bg,
          systemNavigationBarIconBrightness: resolvedDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        );
        SystemChrome.setSystemUIOverlayStyle(overlayStyle);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: ShadTheme(
            data: AppTheme.buildShadTheme(
              palette: themeState.palette,
              isDark: resolvedDark,
            ),
            child: Directionality(
              textDirection: currentLang.textDirection,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const _AuthGate(),
    );
  }
}

/// Routes to [MainShellScreen] or [WelcomeScreen] based on Firebase Auth stream.
/// When a user is authenticated, holds on [UnifiedSplashScreen] until Firestore profile
/// data has been fetched and applied to [AppState] (gate-level pre-fetch).
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final appState = ref.watch(appStateProvider);
    final appNotifier = ref.read(appStateProvider.notifier);
    final hasSeenWelcomeAsync = ref.watch(hasSeenWelcomeProvider);

    return authAsync.when(
      loading: () => const UnifiedSplashScreen(),
      error: (_, s) {
        final hasSeen = hasSeenWelcomeAsync.value ?? false;
        return hasSeen ? const AuthScreen() : const WelcomeScreen();
      },
      data: (user) {
        if (user == null) {
          if (appState.isProfileLoaded || appState.loadedUid != null) {
            AppMediaImage.clearCache();
            ref.read(appPrefetchServiceProvider).reset();
            Future.microtask(() {
              appNotifier.resetUserSession();
              ref.invalidate(wardrobeProvider);
            });
          }
          return hasSeenWelcomeAsync.when(
            loading: () => const UnifiedSplashScreen(),
            error: (_, _) => const AuthScreen(),
            data: (hasSeen) =>
                hasSeen ? const AuthScreen() : const WelcomeScreen(),
          );
        }

        // Ensure has_seen_welcome is persisted once a valid authenticated session exists
        if (hasSeenWelcomeAsync.value == false) {
          Future.microtask(
            () => ref.read(hasSeenWelcomeProvider.notifier).markSeen(),
          );
        }

        // 1. Mobile Biometric App Lock Check
        if (!kIsWeb) {
          final isLockEnabled =
              ref.watch(biometricLockEnabledProvider).value ?? false;
          final isUnlocked = ref.watch(biometricUnlockedProvider);
          if (isLockEnabled && !isUnlocked) {
            return const BiometricLockScreen();
          }
        }

        // 2. Gate-Level Pre-Fetch: Ensure profile is loaded for current authenticated UID
        if (!appState.isProfileLoaded || appState.loadedUid != user.uid) {
          if (appState.loadedUid != null && appState.loadedUid != user.uid) {
            AppMediaImage.clearCache();
            ref.read(appPrefetchServiceProvider).reset();
            Future.microtask(() {
              appNotifier.resetUserSession();
              ref.invalidate(wardrobeProvider);
              appNotifier.loadProfileFromFirestore();
            });
          } else {
            Future.microtask(() => appNotifier.loadProfileFromFirestore());
          }
          return const UnifiedSplashScreen();
        }

        return const SessionRevocationListener(child: MainShellScreen());
      },
    );
  }
}
