import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema utama Arunika — "light luxury".
/// Serif Fraunces untuk judul (kesan editorial premium),
/// Plus Jakarta Sans untuk isi (bersih dan mudah dibaca).
/// Kedua font dibundel di assets/fonts agar sepenuhnya offline.
class AppTheme {
  AppTheme._();

  /// Font display serif untuk judul besar.
  static TextStyle serif({
    double size = 24,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double letterSpacing = 0,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  /// Font sans untuk isi.
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData build({Brightness brightness = Brightness.light}) {
    final dark = brightness == Brightness.dark;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final foreground = dark ? AppColors.nightText : AppColors.ink;
    final foregroundSoft = dark ? AppColors.nightTextSoft : AppColors.inkSoft;
    final foregroundFaint = dark
        ? AppColors.nightTextFaint
        : AppColors.inkFaint;
    final canvas = dark ? AppColors.nightCanvas : AppColors.ivory;
    final surface = dark ? AppColors.nightSurface : AppColors.surface;
    final surfaceRaised = dark ? AppColors.nightSurfaceRaised : AppColors.cream;
    final outline = dark ? AppColors.nightHairline : AppColors.hairline;
    final primaryContainer = dark
        ? AppColors.nightGoldMist
        : AppColors.goldMist;
    final onPrimaryContainer = dark
        ? const Color(0xFFFFE8AE)
        : AppColors.goldDeep;

    final textTheme = TextTheme(
      displayLarge: serif(
        size: 36,
        weight: FontWeight.w600,
        height: 1.1,
        color: foreground,
      ),
      displayMedium: serif(
        size: 30,
        weight: FontWeight.w600,
        height: 1.15,
        color: foreground,
      ),
      headlineLarge: serif(
        size: 26,
        weight: FontWeight.w600,
        height: 1.2,
        color: foreground,
      ),
      headlineMedium: serif(
        size: 22,
        weight: FontWeight.w600,
        height: 1.25,
        color: foreground,
      ),
      headlineSmall: serif(
        size: 19,
        weight: FontWeight.w600,
        height: 1.3,
        color: foreground,
      ),
      titleLarge: sans(
        size: 17,
        weight: FontWeight.w700,
        height: 1.3,
        color: foreground,
      ),
      titleMedium: sans(
        size: 15,
        weight: FontWeight.w700,
        height: 1.35,
        color: foreground,
      ),
      titleSmall: sans(
        size: 13.5,
        weight: FontWeight.w700,
        height: 1.35,
        color: foreground,
      ),
      bodyLarge: sans(
        size: 15,
        weight: FontWeight.w500,
        height: 1.5,
        color: foreground,
      ),
      bodyMedium: sans(
        size: 13.5,
        weight: FontWeight.w500,
        height: 1.5,
        color: foreground,
      ),
      bodySmall: sans(
        size: 12,
        weight: FontWeight.w500,
        height: 1.45,
        color: foreground,
      ),
      labelLarge: sans(
        size: 14,
        weight: FontWeight.w700,
        letterSpacing: 0.2,
        color: foreground,
      ),
      labelMedium: sans(
        size: 12,
        weight: FontWeight.w700,
        letterSpacing: 0.2,
        color: foreground,
      ),
      labelSmall: sans(
        size: 10.5,
        weight: FontWeight.w700,
        letterSpacing: 0.4,
        color: foreground,
      ),
    );

    final colorScheme = (dark ? ColorScheme.dark() : ColorScheme.light())
        .copyWith(
          primary: AppColors.gold,
          onPrimary: dark ? AppColors.ink : Colors.white,
          primaryContainer: primaryContainer,
          onPrimaryContainer: onPrimaryContainer,
          secondary: dark ? const Color(0xFFB7CDBB) : AppColors.goldDeep,
          onSecondary: dark ? AppColors.ink : Colors.white,
          surface: surface,
          onSurface: foreground,
          onSurfaceVariant: foregroundSoft,
          surfaceContainerHighest: surfaceRaised,
          error: AppColors.danger,
          onError: Colors.white,
          outline: outline,
          outlineVariant: dark ? AppColors.nightGoldMist : AppColors.goldSoft,
          shadow: dark ? Colors.black : const Color(0xFF8A7A58),
        );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: foreground, size: 22),
        titleTextStyle: serif(
          size: 21,
          weight: FontWeight.w600,
          color: foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.nightSurfaceRaised : AppColors.pearl,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: sans(size: 14, color: foregroundFaint),
        labelStyle: sans(
          size: 13,
          weight: FontWeight.w600,
          color: foregroundSoft,
        ),
        prefixIconColor: foregroundFaint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: sans(
            size: 15,
            weight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? const Color(0xFFFFD982) : AppColors.goldDeep,
          textStyle: sans(
            size: 14,
            weight: FontWeight.w700,
            color: dark ? const Color(0xFFFFD982) : AppColors.goldDeep,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: outline, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: sans(size: 14, weight: FontWeight.w700, color: foreground),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? AppColors.nightSurfaceRaised : AppColors.ink,
        contentTextStyle: sans(size: 13.5, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: serif(
          size: 20,
          weight: FontWeight.w600,
          color: foreground,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: dark ? AppColors.nightSurfaceRaised : AppColors.pearl,
        selectedColor: primaryContainer,
        side: BorderSide(color: outline),
        labelStyle: sans(
          size: 12.5,
          weight: FontWeight.w600,
          color: foreground,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: sans(size: 13, weight: FontWeight.w700),
        unselectedLabelStyle: sans(size: 13, weight: FontWeight.w600),
        labelColor: dark ? const Color(0xFFFFD982) : AppColors.goldDeep,
        unselectedLabelColor: foregroundSoft,
        indicatorColor: AppColors.gold,
        dividerColor: outline,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primaryContainer,
        headerForegroundColor: onPrimaryContainer,
        todayBorder: const BorderSide(color: AppColors.gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : foregroundFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? AppColors.nightGoldMist : AppColors.goldSoft)
              : outline,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: outline,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }
}
