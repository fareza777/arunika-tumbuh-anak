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
    this.darkMode = false,
    this.adsRemoved = false,
    this.reminderEnabled = false,
    this.reminderIntervalWeeks = 4,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.journalReminderEnabled = false,
    this.journalReminderHour = 20,
    this.journalReminderMinute = 0,
  });

  final GrowthStandard standard;
  final bool onboardingDone;
  final bool togetherOnboardingDone;
  final String familyName;
  final bool reducedMotion;
  final bool darkMode;
  final bool adsRemoved;

  /// Pengingat jadwal pengukuran.
  final bool reminderEnabled;
  final int reminderIntervalWeeks;
  final int reminderHour;
  final int reminderMinute;

  /// Persetujuan jurnal berdiri sendiri dari pengingat pengukuran lama.
  final bool journalReminderEnabled;
  final int journalReminderHour;
  final int journalReminderMinute;

  AppSettings copyWith({
    GrowthStandard? standard,
    bool? onboardingDone,
    bool? togetherOnboardingDone,
    String? familyName,
    bool? reducedMotion,
    bool? darkMode,
    bool? adsRemoved,
    bool? reminderEnabled,
    int? reminderIntervalWeeks,
    int? reminderHour,
    int? reminderMinute,
    bool? journalReminderEnabled,
    int? journalReminderHour,
    int? journalReminderMinute,
  }) {
    return AppSettings(
      standard: standard ?? this.standard,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      togetherOnboardingDone:
          togetherOnboardingDone ?? this.togetherOnboardingDone,
      familyName: familyName ?? this.familyName,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      darkMode: darkMode ?? this.darkMode,
      adsRemoved: adsRemoved ?? this.adsRemoved,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalWeeks:
          reminderIntervalWeeks ?? this.reminderIntervalWeeks,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      journalReminderEnabled:
          journalReminderEnabled ?? this.journalReminderEnabled,
      journalReminderHour: journalReminderHour ?? this.journalReminderHour,
      journalReminderMinute:
          journalReminderMinute ?? this.journalReminderMinute,
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
  static const _kDarkMode = 'dark_mode';
  static const _kAdsRemoved = 'ads_removed_hint';
  static const _kReminderEnabled = 'reminder_enabled';
  static const _kReminderWeeks = 'reminder_weeks';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMinute = 'reminder_minute';
  static const _kJournalReminderEnabled = 'journal_reminder_enabled';
  static const _kJournalReminderHour = 'journal_reminder_hour';
  static const _kJournalReminderMinute = 'journal_reminder_minute';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    return AppSettings(
      standard: GrowthStandard
          .values[_boundedInt(_kStandard, 0, GrowthStandard.values.length - 1)],
      onboardingDone: _prefs.getBool(_kOnboarding) ?? false,
      togetherOnboardingDone: _prefs.getBool(_kTogetherOnboarding) ?? false,
      familyName: _prefs.getString(_kFamilyName) ?? 'Keluarga',
      reducedMotion: _prefs.getBool(_kReducedMotion) ?? false,
      darkMode: _prefs.getBool(_kDarkMode) ?? false,
      adsRemoved: _prefs.getBool(_kAdsRemoved) ?? false,
      reminderEnabled: _prefs.getBool(_kReminderEnabled) ?? false,
      reminderIntervalWeeks: _prefs.getInt(_kReminderWeeks) ?? 4,
      reminderHour: _prefs.getInt(_kReminderHour) ?? 8,
      reminderMinute: _prefs.getInt(_kReminderMinute) ?? 0,
      journalReminderEnabled: _prefs.getBool(_kJournalReminderEnabled) ?? false,
      journalReminderHour: _boundedInt(_kJournalReminderHour, 20, 23),
      journalReminderMinute: _boundedInt(_kJournalReminderMinute, 0, 59),
    );
  }

  int _boundedInt(String key, int fallback, int maximum) {
    final value = _prefs.get(key);
    return value is int && value >= 0 && value <= maximum ? value : fallback;
  }

  Future<void> update(AppSettings next) async {
    RangeError.checkValueInInterval(next.journalReminderHour, 0, 23, 'hour');
    RangeError.checkValueInInterval(
      next.journalReminderMinute,
      0,
      59,
      'minute',
    );
    final values = <String, Object>{
      _kStandard: next.standard.index,
      _kOnboarding: next.onboardingDone,
      _kTogetherOnboarding: next.togetherOnboardingDone,
      _kFamilyName: next.familyName,
      _kReducedMotion: next.reducedMotion,
      _kDarkMode: next.darkMode,
      _kAdsRemoved: next.adsRemoved,
      _kReminderEnabled: next.reminderEnabled,
      _kReminderWeeks: next.reminderIntervalWeeks,
      _kReminderHour: next.reminderHour,
      _kReminderMinute: next.reminderMinute,
      _kJournalReminderEnabled: next.journalReminderEnabled,
      _kJournalReminderHour: next.journalReminderHour,
      _kJournalReminderMinute: next.journalReminderMinute,
    };
    final previous = <String, Object?>{};
    try {
      for (final entry in values.entries) {
        if (_prefs.get(entry.key) == entry.value) continue;
        previous[entry.key] = _prefs.get(entry.key);
        await _write(entry.key, entry.value);
      }
    } catch (_) {
      // Keep a failed save recoverable; never display a successful preference
      // change before the device has acknowledged it.
      for (final entry in previous.entries.toList().reversed) {
        try {
          await _write(entry.key, entry.value);
        } catch (_) {
          // Preserve the original failure for the caller's retry UI.
        }
      }
      rethrow;
    }
    state = next;
  }

  Future<void> _write(String key, Object? value) async {
    final saved = await switch (value) {
      bool value => _prefs.setBool(key, value),
      int value => _prefs.setInt(key, value),
      String value => _prefs.setString(key, value),
      null => _prefs.remove(key),
      _ => throw ArgumentError.value(value, key),
    };
    if (!saved) throw StateError('Pengaturan belum berhasil disimpan.');
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
