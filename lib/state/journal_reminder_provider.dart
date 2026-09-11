import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notifications/notification_service.dart';
import 'app_settings.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final journalReminderProvider = Provider<JournalReminderController>(
  JournalReminderController.new,
);

/// Coordinates persisted consent with the real device schedule. Calls are
/// serialized because permission dialogs can trigger an app-resume sync.
class JournalReminderController {
  JournalReminderController(this._ref);

  final Ref _ref;
  Future<void> _pending = Future<void>.value();

  NotificationService get _service => _ref.read(notificationServiceProvider);
  AppSettings get _settings => _ref.read(settingsProvider);

  /// False means permission was denied; other failures are reported to the UI.
  Future<bool> setEnabled(bool enabled) => _serialize(() async {
    if (!enabled) {
      final before = _settings;
      await _service.cancelJournalReminder();
      try {
        await _save(enabled: false);
      } catch (_) {
        if (before.journalReminderEnabled) {
          await _service.scheduleDailyJournalReminder(
            hour: before.journalReminderHour,
            minute: before.journalReminderMinute,
          );
        }
        rethrow;
      }
      return true;
    }
    if (!await _service.requestPermission()) {
      await _service.cancelJournalReminder();
      await _save(enabled: false);
      return false;
    }
    final before = _settings;
    await _service.scheduleDailyJournalReminder(
      hour: before.journalReminderHour,
      minute: before.journalReminderMinute,
    );
    try {
      await _save(enabled: true);
    } catch (_) {
      if (!before.journalReminderEnabled) {
        await _service.cancelJournalReminder();
      }
      rethrow;
    }
    return true;
  });

  /// Choosing a time never opts the family in or shows a permission dialog.
  Future<bool> setTime({required int hour, required int minute}) =>
      _serialize(() async {
        RangeError.checkValueInInterval(hour, 0, 23, 'hour');
        RangeError.checkValueInInterval(minute, 0, 59, 'minute');
        final before = _settings;
        if (!before.journalReminderEnabled) {
          await _save(hour: hour, minute: minute);
          return true;
        }
        if (!await _service.hasPermission()) {
          await _service.cancelJournalReminder();
          await _save(enabled: false, hour: hour, minute: minute);
          return false;
        }
        await _service.scheduleDailyJournalReminder(hour: hour, minute: minute);
        try {
          await _save(hour: hour, minute: minute);
        } catch (_) {
          await _service.scheduleDailyJournalReminder(
            hour: before.journalReminderHour,
            minute: before.journalReminderMinute,
          );
          rethrow;
        }
        return true;
      });

  /// Restore on startup/resume, refresh device timezone, and stop historical
  /// measurement reminders that are outside the active family product.
  Future<void> sync() => _serialize(() async {
    await _service.cancelReminders();
    if (!_settings.journalReminderEnabled) {
      await _service.cancelJournalReminder();
      return;
    }
    if (!await _service.hasPermission()) {
      await _service.cancelJournalReminder();
      await _save(enabled: false);
      return;
    }
    await _service.scheduleDailyJournalReminder(
      hour: _settings.journalReminderHour,
      minute: _settings.journalReminderMinute,
    );
  });

  Future<void> _save({bool? enabled, int? hour, int? minute}) => _ref
      .read(settingsProvider.notifier)
      .update(
        _settings.copyWith(
          journalReminderEnabled: enabled,
          journalReminderHour: hour,
          journalReminderMinute: minute,
        ),
      );

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
