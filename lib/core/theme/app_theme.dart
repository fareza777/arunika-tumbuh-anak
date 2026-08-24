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
    Color color = AppColors.ink,
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
    Color color = AppColors.ink,
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

  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = TextTheme(
      displayLarge: serif(size: 36, weight: FontWeight.w600, height: 1.1),
      displayMedium: serif(size: 30, weight: FontWeight.w600, height: 1.15),
      headlineLarge: serif(size: 26, weight: FontWeight.w600, height: 1.2),
      headlineMedium: serif(size: 22, weight: FontWeight.w600, height: 1.25),
      headlineSmall: serif(size: 19, weight: FontWeight.w600, height: 1.3),
      titleLarge: sans(size: 17, weight: FontWeight.w700, height: 1.3),
      titleMedium: sans(size: 15, weight: FontWeight.w700, height: 1.35),
      titleSmall: sans(size: 13.5, weight: FontWeight.w700, height: 1.35),
      bodyLarge: sans(size: 15, weight: FontWeight.w500, height: 1.5),
      bodyMedium: sans(size: 13.5, weight: FontWeight.w500, height: 1.5),
      bodySmall: sans(size: 12, weight: FontWeight.w500, height: 1.45),
      labelLarge: sans(size: 14, weight: FontWeight.w700, letterSpacing: 0.2),
      labelMedium: sans(size: 12, weight: FontWeight.w700, letterSpacing: 0.2),
      labelSmall: sans(size: 10.5, weight: FontWeight.w700, letterSpacing: 0.4),
    );

    final colorScheme = ColorScheme.light(
      primary: AppColors.gold,
      onPrimary: Colors.white,
      primaryContainer: AppColors.goldMist,
      onPrimaryContainer: AppColors.goldDeep,
      secondary: AppColors.goldDeep,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.cream,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.hairline,
      outlineVariant: AppColors.goldSoft,
      shadow: const Color(0xFF8A7A58),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ivory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
        titleTextStyle: serif(size: 21, weight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pearl,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: sans(size: 14, color: AppColors.inkFaint),
        labelStyle: sans(
          size: 13,
          weight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
        prefixIconColor: AppColors.inkFaint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.hairline),
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
          foregroundColor: AppColors.goldDeep,
          textStyle: sans(size: 14, weight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.hairline, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: sans(size: 14, weight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: sans(size: 13.5, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: serif(size: 20, weight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.pearl,
        selectedColor: AppColors.goldMist,
        side: const BorderSide(color: AppColors.hairline),
        labelStyle: sans(size: 12.5, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: sans(size: 13, weight: FontWeight.w700),
        unselectedLabelStyle: sans(size: 13, weight: FontWeight.w600),
        labelColor: AppColors.goldDeep,
        unselectedLabelColor: AppColors.inkSoft,
        indicatorColor: AppColors.gold,
        dividerColor: AppColors.hairline,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.goldMist,
        headerForegroundColor: AppColors.goldDeep,
        todayBorder: const BorderSide(color: AppColors.gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.goldSoft
              : AppColors.hairline,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.hairline,
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
