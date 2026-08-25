import 'package:arunika_growth/core/theme/app_theme.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dark mode preference is part of the settings value', () {
    const settings = AppSettings();
    final dark = settings.copyWith(darkMode: true);

    expect(settings.darkMode, isFalse);
    expect(dark.darkMode, isTrue);
    expect(dark.familyName, settings.familyName);
  });

  test('settings notifier restores dark mode from local preferences', () async {
    SharedPreferences.setMockInitialValues({'dark_mode': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(settingsProvider).darkMode, isTrue);
  });

  test('light and dark themes use distinct surfaces', () {
    final light = AppTheme.build(brightness: Brightness.light);
    final dark = AppTheme.build(brightness: Brightness.dark);

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
    expect(dark.colorScheme.onSurface, isNot(light.colorScheme.onSurface));
  });
}
