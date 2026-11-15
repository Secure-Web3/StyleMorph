import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/localization/app_language.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/emulator_config.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_view.dart';
import 'features/shell/presentation/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EmulatorConfig.connectIfEnabled();
  runApp(const ProviderScope(child: StyleMorphApp()));
}

class StyleMorphApp extends ConsumerWidget {
  const StyleMorphApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(localeProvider);
    final isLoggedIn = ref.watch(appStateProvider.select((s) => s.isLoggedIn));

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
      home: isLoggedIn ? const MainShellScreen() : const AuthView(),
    );
  }
}
