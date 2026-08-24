import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Layanan notifikasi lokal untuk pengingat jadwal pengukuran.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _baseReminderId = 1000;
  static const String _channelId = 'measurement_reminders';
  static const String _channelName = 'Pengingat Pengukuran';
  static const String _channelDesc =
      'Pengingat rutin untuk mengukur tinggi dan berat badan anak';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Meminta izin notifikasi (Android 13+). Mengembalikan true bila diizinkan.
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
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
    for (var i = 0; i < 8; i++) {
      await _plugin.cancel(id: _baseReminderId + i);
    }
  }
}
