import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The next occurrence of a daily wall-clock time in the supplied location.
/// Construct the next calendar day rather than adding 24 hours across DST.
tz.TZDateTime nextDailyJournalReminder({
  required tz.TZDateTime now,
  required int hour,
  required int minute,
}) {
  RangeError.checkValueInInterval(hour, 0, 23, 'hour');
  RangeError.checkValueInInterval(minute, 0, 59, 'minute');
  var next = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!next.isAfter(now)) {
    next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }
  return next;
}

/// Local family reminders, plus the retained API for historical screens.
class NotificationService {
  NotificationService();

  static final NotificationService instance = NotificationService();

  static const _deviceTimezone = MethodChannel(
    'id.arunika.arunika_growth/device_timezone',
  );
  static const int _journalReminderId = 2000;
  static const String _journalChannelId = 'family_journal_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _baseReminderId = 1000;
  static const String _channelId = 'measurement_reminders';
  static const String _channelName = 'Pengingat Pengukuran';
  static const String _channelDesc =
      'Pengingat rutin untuk mengukur tinggi dan berat badan anak';

  bool _initialized = false;
  Future<void>? _initialization;

  Future<void> init() async {
    if (_initialized) return;
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('ic_stat_journal');
    const settings = InitializationSettings(android: android);
    final initialized = await _plugin.initialize(settings: settings);
    if (initialized != true) {
      throw StateError('Layanan pengingat belum tersedia di perangkat ini.');
    }
    _initialized = true;
  }

  /// Meminta izin notifikasi (Android 13+). Mengembalikan true bila diizinkan.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted == true && await hasPermission();
  }

  /// Read the current permission without prompting on launch or resume.
  Future<bool> hasPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() != true) return false;
    final channels = await android?.getNotificationChannels();
    return !(channels ?? <AndroidNotificationChannel>[]).any(
      (channel) =>
          channel.id == _journalChannelId &&
          channel.importance == Importance.none,
    );
  }

  Future<void> _refreshDeviceTimezone() async {
    final name = await _deviceTimezone.invokeMethod<String>('getLocalTimezone');
    if (name == null || name.isEmpty) {
      throw StateError('Zona waktu perangkat belum dapat dibaca. Coba lagi.');
    }
    // A missing/unknown zone is an actionable failure, never a silent UTC
    // fallback that schedules a reminder at the wrong local hour.
    tz.setLocalLocation(tz.getLocation(name));
  }

  Future<void> scheduleDailyJournalReminder({
    required int hour,
    required int minute,
  }) async {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    await init();
    await _refreshDeviceTimezone();
    final next = nextDailyJournalReminder(
      now: tz.TZDateTime.now(tz.local),
      hour: hour,
      minute: minute,
    );
    await _plugin.zonedSchedule(
      id: _journalReminderId,
      title: 'Satu momen untuk keluarga',
      body: 'Luangkan sebentar untuk mencatat cerita atau kebiasaan hari ini.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _journalChannelId,
          'Pengingat Jurnal Keluarga',
          channelDescription:
              'Pengingat harian pilihanmu untuk jurnal keluarga',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_stat_journal',
          visibility: NotificationVisibility.private,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'family_journal',
    );
  }

  Future<void> cancelJournalReminder() async {
    await init();
    await _plugin.cancel(id: _journalReminderId);
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  /// Menjadwalkan pengingat berulang setiap [intervalWeeks] minggu
  /// pada jam [hour]:[minute]. Menjadwalkan 8 kejadian ke depan.
  Future<void> scheduleMeasurementReminders({
    required int intervalWeeks,
    required int hour,
    required int minute,
    required String childName,
  }) async {
    RangeError.checkValueInInterval(intervalWeeks, 1, 52, 'intervalWeeks');
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    await init();
    await _refreshDeviceTimezone();
    await cancelReminders();

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (next.isBefore(now)) {
      next = next.add(Duration(days: 7 * intervalWeeks));
    }

    for (var i = 0; i < 8; i++) {
      final when = next.add(Duration(days: 7 * intervalWeeks * i));
      await _plugin.zonedSchedule(
        id: _baseReminderId + i,
        title: 'Waktunya Mengukur',
        body: childName.isEmpty
            ? 'Yuk catat tinggi & berat badan si kecil hari ini.'
            : 'Yuk catat tinggi & berat badan $childName hari ini.',
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelReminders() async {
    await init();
    for (var i = 0; i < 8; i++) {
      await _plugin.cancel(id: _baseReminderId + i);
    }
  }
}
