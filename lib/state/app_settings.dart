import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/standards/growth_standards.dart';

/// Preferensi aplikasi yang tersimpan di perangkat.
class AppSettings {
  const AppSettings({
    this.standard = GrowthStandard.whoAuto,
    this.onboardingDone = false,
    this.togetherOnboardingDone = false,
    this.familyName = 'Keluarga',
    this.reducedMotion = false,
    this.adsRemoved = false,
    this.reminderEnabled = false,
    this.reminderIntervalWeeks = 4,
    this.reminderHour = 8,
    this.reminderMinute = 0,
  });

  final GrowthStandard standard;
  final bool onboardingDone;
  final bool togetherOnboardingDone;
  final String familyName;
  final bool reducedMotion;
  final bool adsRemoved;

  /// Pengingat jadwal pengukuran.
  final bool reminderEnabled;
  final int reminderIntervalWeeks;
  final int reminderHour;
  final int reminderMinute;

  AppSettings copyWith({
    GrowthStandard? standard,
    bool? onboardingDone,
    bool? togetherOnboardingDone,
    String? familyName,
    bool? reducedMotion,
    bool? adsRemoved,
    bool? reminderEnabled,
    int? reminderIntervalWeeks,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppSettings(
      standard: standard ?? this.standard,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      togetherOnboardingDone:
          togetherOnboardingDone ?? this.togetherOnboardingDone,
      familyName: familyName ?? this.familyName,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      adsRemoved: adsRemoved ?? this.adsRemoved,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalWeeks:
          reminderIntervalWeeks ?? this.reminderIntervalWeeks,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

/// SharedPreferences instance, di-override di main().
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider belum di-override'),
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kStandard = 'standard';
  static const _kOnboarding = 'onboarding_done';
  static const _kTogetherOnboarding = 'together_onboarding_done';
  static const _kFamilyName = 'family_name';
  static const _kReducedMotion = 'reduced_motion';
  static const _kAdsRemoved = 'ads_removed_hint';
  static const _kReminderEnabled = 'reminder_enabled';
  static const _kReminderWeeks = 'reminder_weeks';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMinute = 'reminder_minute';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    return AppSettings(
      standard: GrowthStandard.values[_prefs.getInt(_kStandard) ?? 0],
      onboardingDone: _prefs.getBool(_kOnboarding) ?? false,
      togetherOnboardingDone: _prefs.getBool(_kTogetherOnboarding) ?? false,
      familyName: _prefs.getString(_kFamilyName) ?? 'Keluarga',
      reducedMotion: _prefs.getBool(_kReducedMotion) ?? false,
      adsRemoved: _prefs.getBool(_kAdsRemoved) ?? false,
      reminderEnabled: _prefs.getBool(_kReminderEnabled) ?? false,
      reminderIntervalWeeks: _prefs.getInt(_kReminderWeeks) ?? 4,
      reminderHour: _prefs.getInt(_kReminderHour) ?? 8,
      reminderMinute: _prefs.getInt(_kReminderMinute) ?? 0,
    );
  }

  Future<void> update(AppSettings next) async {
    state = next;
    await _prefs.setInt(_kStandard, next.standard.index);
    await _prefs.setBool(_kOnboarding, next.onboardingDone);
    await _prefs.setBool(_kTogetherOnboarding, next.togetherOnboardingDone);
    await _prefs.setString(_kFamilyName, next.familyName);
    await _prefs.setBool(_kReducedMotion, next.reducedMotion);
    await _prefs.setBool(_kAdsRemoved, next.adsRemoved);
    await _prefs.setBool(_kReminderEnabled, next.reminderEnabled);
    await _prefs.setInt(_kReminderWeeks, next.reminderIntervalWeeks);
    await _prefs.setInt(_kReminderHour, next.reminderHour);
    await _prefs.setInt(_kReminderMinute, next.reminderMinute);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
