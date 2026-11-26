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
import 'core/services/app_check_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/biometric_service.dart';
import 'core/services/emulator_config.dart';
import 'core/services/prefetch/app_prefetch_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/referral_service.dart';
import 'core/services/screenshot_protection_service.dart';
import 'core/services/session_persistence_service.dart';
import 'core/services/two_factor_service.dart';
import 'core/services/welcome_persistence_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_media_image.dart';
import 'core/widgets/app_update_dialog.dart';
import 'core/widgets/unified_splash_screen.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/state/app_state.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/presentation/biometric_lock_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/auth/presentation/widgets/two_factor_verify_screen.dart';
import 'features/profile/presentation/widgets/sessions_sub_tab.dart';
import 'features/shell/presentation/main_shell_screen.dart';
import 'features/wardrobe/presentation/wardrobe_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (ScreenshotProtectionService.kEnableScreenshotProtection) {
    ScreenshotProtectionService().enableProtection();
  } else {
    ScreenshotProtectionService().disableProtection();
  }

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
    await AppCheckService.initialize();
    await PushNotificationService.initialize();
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

/// Coordinates throttled automatic update checks and once-per-session
/// optional update dialog presentation.
@visibleForTesting
class AppUpdateSessionCoordinator {
  static const Duration autoCheckCooldown = Duration(minutes: 30);

  DateTime? _lastCheckAt;
  bool _isChecking = false;
  bool _optionalDialogShownThisSession = false;
  bool _lastCheckWasForced = false;
  bool _isDialogOpen = false;

  bool shouldRunAutoCheck({bool manual = false, DateTime? now}) {
    if (_isChecking) return false;
    if (manual || _lastCheckWasForced) return true;
    final last = _lastCheckAt;
    if (last == null) return true;
    return (now ?? DateTime.now()).difference(last) >= autoCheckCooldown;
  }

  bool shouldShowDialog({required bool isForced}) {
    if (_isDialogOpen) return false;
    if (isForced) return true;
    return !_optionalDialogShownThisSession;
  }

  void markCheckCompleted({
    required bool isForced,
    bool dialogShown = false,
    DateTime? now,
  }) {
    _lastCheckAt = now ?? DateTime.now();
    _lastCheckWasForced = isForced;
    if (dialogShown && !isForced) {
      _optionalDialogShownThisSession = true;
    }
  }

  Future<void> checkAndPrompt(
    BuildContext context,
    AppUpdateService service, {
    bool manual = false,
  }) async {
    if (!shouldRunAutoCheck(manual: manual)) return;

    _isChecking = true;
    try {
      final result = await service.checkForUpdate(
        manual: manual || _lastCheckWasForced,
      );
      final canShow =
          result.updateAvailable &&
          result.remoteInfo != null &&
          shouldShowDialog(isForced: result.isForced);
      markCheckCompleted(isForced: result.isForced, dialogShown: canShow);

      if (canShow && context.mounted) {
        _isDialogOpen = true;
        try {
          await AppUpdateDialog.show(
            context,
            remoteInfo: result.remoteInfo!,
            isForced: result.isForced,
          );
        } finally {
          _isDialogOpen = false;
        }
      }
    } finally {
      _isChecking = false;
    }
  }
}

/// Routes to [MainShellScreen] or [WelcomeScreen] based on Firebase Auth stream.
/// When a user is authenticated, holds on [UnifiedSplashScreen] until Firestore profile
/// data has been fetched and applied to [AppState] (gate-level pre-fetch).
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate>
    with WidgetsBindingObserver {
  final AppUpdateSessionCoordinator _updateCoordinator =
      AppUpdateSessionCoordinator();
  bool _launchUpdateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PushNotificationService.setOnAppUpdateTap(() {
      if (!mounted) return;
      _updateCoordinator.checkAndPrompt(
        context,
        ref.read(appUpdateServiceProvider),
        manual: true,
      );
    });
  }

  @override
  void dispose() {
    PushNotificationService.setOnAppUpdateTap(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = ref.read(authStateChangesProvider).value;
      final appState = ref.read(appStateProvider);
      if (user != null &&
          appState.isProfileLoaded &&
          appState.loadedUid == user.uid) {
        _updateCoordinator.checkAndPrompt(
          context,
          ref.read(appUpdateServiceProvider),
        );
      }
    }

    if (kIsWeb) return;
    if (state == AppLifecycleState.paused) {
      final isAuthenticating = ref
          .read(biometricServiceProvider)
          .isAuthenticating;
      final isLockEnabled =
          ref.read(biometricLockEnabledProvider).value ?? false;
      final isUnlocked = ref.read(biometricUnlockedProvider);
      if (!isAuthenticating && isLockEnabled && isUnlocked) {
        ref.read(biometricUnlockedProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _launchUpdateChecked = false;
          if (ref.read(twoFactorSessionVerifiedProvider)) {
            Future.microtask(() {
              ref.read(twoFactorSessionVerifiedProvider.notifier).state = false;
            });
          }
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
          final biometricLockAsync = ref.watch(biometricLockEnabledProvider);
          if (biometricLockAsync.isLoading) {
            return const UnifiedSplashScreen();
          }
          final isLockEnabled = biometricLockAsync.value ?? false;
          final isUnlocked = ref.watch(biometricUnlockedProvider);
          if (isLockEnabled && !isUnlocked) {
            return const BiometricLockScreen();
          }
        }

        // 1b. Two-Factor Authentication (2FA) Login Verification Gate
        final twoFactorAsync = ref.watch(twoFactorConfigProvider(user.uid));
        if (twoFactorAsync.isLoading) {
          return const UnifiedSplashScreen();
        }
        final twoFactorConfig = twoFactorAsync.value ?? const TwoFactorConfig();
        final is2faVerified = ref.watch(twoFactorSessionVerifiedProvider);
        if (twoFactorConfig.enabled && !is2faVerified) {
          return TwoFactorVerifyScreen(
            uid: user.uid,
            email: user.email ?? '',
            config: twoFactorConfig,
          );
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

        if (!_launchUpdateChecked) {
          _launchUpdateChecked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _updateCoordinator.checkAndPrompt(
              context,
              ref.read(appUpdateServiceProvider),
            );
          });
        }

        return const SessionRevocationListener(child: MainShellScreen());
      },
    );
  }
}
