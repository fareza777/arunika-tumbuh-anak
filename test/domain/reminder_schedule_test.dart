import 'package:arunika_growth/domain/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('daily reminder keeps the selected device-local time today', () {
    final jakarta = tz.getLocation('Asia/Jakarta');
    final next = nextDailyJournalReminder(
      now: tz.TZDateTime(jakarta, 2026, 9, 5, 10),
      hour: 20,
      minute: 15,
    );

    expect(next, tz.TZDateTime(jakarta, 2026, 9, 5, 20, 15));
    expect(next.toUtc(), DateTime.utc(2026, 9, 5, 13, 15));
  });

  test('a passed or equal reminder time moves to the next calendar day', () {
    final jakarta = tz.getLocation('Asia/Jakarta');
    for (final minute in [15, 16]) {
      final next = nextDailyJournalReminder(
        now: tz.TZDateTime(jakarta, 2026, 12, 31, 20, minute),
        hour: 20,
        minute: 15,
      );

      expect(next, tz.TZDateTime(jakarta, 2027, 1, 1, 20, 15));
    }
  });

  test('daily reminder preserves wall-clock hour across daylight saving', () {
    final london = tz.getLocation('Europe/London');
    final next = nextDailyJournalReminder(
      now: tz.TZDateTime(london, 2026, 3, 28, 20, 1),
      hour: 20,
      minute: 0,
    );

    expect(next, tz.TZDateTime(london, 2026, 3, 29, 20));
    expect(next.toUtc(), DateTime.utc(2026, 3, 29, 19));
  });

  test('invalid times cannot become a normalized but unintended reminder', () {
    final now = tz.TZDateTime(tz.getLocation('Asia/Jakarta'), 2026, 9, 5);
    for (final time in [(24, 0), (-1, 0), (20, 60), (20, -1)]) {
      expect(
        () =>
            nextDailyJournalReminder(now: now, hour: time.$1, minute: time.$2),
        throwsRangeError,
      );
    }
  });
}
