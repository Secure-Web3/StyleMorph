import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/admin_language.dart';
import 'core/state/admin_state.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/consumer_web_portal_screen.dart';
import 'features/layout/presentation/admin_scaffold.dart';
import 'features/seller_portal/presentation/seller_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StyleMorphAdminApp()));
}

class StyleMorphAdminApp extends ConsumerWidget {
  const StyleMorphAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final currentLang = ref.watch(adminLanguageProvider);
    final authRole = ref.watch(authRoleProvider);

    Widget homeView;
    switch (authRole) {
      case AuthGateRole.landing:
        homeView = const AuthGateScreen();
        break;
      case AuthGateRole.admin:
        homeView = const AdminScaffold();
        break;
      case AuthGateRole.seller:
        homeView = const SellerScaffold();
        break;
      case AuthGateRole.consumerWebapp:
        homeView = const ConsumerWebPortalScreen();
        break;
    }

    return MaterialApp(
      title: 'StyleMorph Admin & Portals',
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
          AdminLanguage.values.map((l) => l.locale).toList(),
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
            textDirection: currentLang.direction,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: homeView,
    );
  }
}
