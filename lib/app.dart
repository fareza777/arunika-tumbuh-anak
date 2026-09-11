import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'state/app_settings.dart';
import 'state/monetization_provider.dart';
import 'ui/splash/splash_screen.dart';

/// Nama & identitas aplikasi. Ubah di sini untuk rebrand.
class AppIdentity {
  AppIdentity._();
  static const String name = 'Arunika';
  static const String tagline = 'Tumbuh Bersama';
  static const String fullName = 'Arunika: Tumbuh Bersama';
  static const String version = '1.4.0';
}

class ArunikaApp extends ConsumerWidget {
  const ArunikaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start billing/ads verification before the first feature screen is shown;
    // the controller itself remains non-blocking and returns an initial state.
    ref.watch(monetizationProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppIdentity.fullName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      darkTheme: AppTheme.build(brightness: Brightness.dark),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.of(context).disableAnimations ||
                settings.reducedMotion,
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness == Brightness.dark
                ? SystemUiOverlayStyle.light.copyWith(
                    systemNavigationBarColor: Theme.of(
                      context,
                    ).scaffoldBackgroundColor,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    systemNavigationBarColor: Theme.of(
                      context,
                    ).scaffoldBackgroundColor,
                  ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
