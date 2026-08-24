import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'state/monetization_provider.dart';
import 'ui/splash/splash_screen.dart';

/// Nama & identitas aplikasi. Ubah di sini untuk rebrand.
class AppIdentity {
  AppIdentity._();
  static const String name = 'Arunika';
  static const String tagline = 'Tumbuh Kembang Anak';
  static const String fullName = 'Arunika: Tumbuh Kembang Anak';
  static const String version = '1.2.0';
}

class ArunikaApp extends ConsumerWidget {
  const ArunikaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start billing/ads verification before the first feature screen is shown;
    // the controller itself remains non-blocking and returns an initial state.
    ref.watch(monetizationProvider);

    return MaterialApp(
      title: AppIdentity.fullName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Hormati pembesaran font sistem, tapi batasi agar tata letak tidak rusak.
      builder: (context, child) {
        final scaler = MediaQuery.textScalerOf(context);
        final clamped = scaler.scale(1.0).clamp(1.0, 1.3).toDouble();
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(clamped)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
