import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/localization/app_language.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/emulator_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/shell/presentation/main_shell_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ),
      darkTheme: AppTheme.buildTheme(
        palette: themeState.palette,
        isDark: true,
      ),
      themeMode: themeState.mode,
      locale: currentLang.locale,
      supportedLocales:
          AppLanguage.supportedLanguages.map((l) => l.locale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final resolvedDark = themeState.resolveIsDark(context);
        return ShadTheme(
          data: AppTheme.buildShadTheme(
            palette: themeState.palette,
            isDark: resolvedDark,
          ),
          child: Directionality(
            textDirection: currentLang.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const _AuthGate(),
    );
  }
}

/// Routes to [MainShellScreen] or [WelcomeScreen] based solely on the real
/// Firebase Auth stream. Shows a neutral splash while the stream is resolving.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);

    return authAsync.when(
      loading: () => const _Splash(),
      error: (_, s) => const WelcomeScreen(),
      data: (user) =>
          user != null ? const MainShellScreen() : const WelcomeScreen(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}
