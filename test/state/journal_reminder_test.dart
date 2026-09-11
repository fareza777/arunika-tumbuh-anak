import 'dart:async';

import 'package:arunika_growth/domain/notifications/notification_service.dart';
import 'package:arunika_growth/state/app_settings.dart';
import 'package:arunika_growth/state/journal_reminder_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const deviceTimezone = MethodChannel(
    'id.arunika.arunika_growth/device_timezone',
  );
  final calls = <MethodCall>[];
  var permissionGranted = true;
  var timezone = 'Asia/Jakarta';
  var failTimezone = false;
  var failSchedule = false;
  var channelBlocked = false;
  String? failSettingKey;
  Completer<bool>? permissionResponse;
  late SharedPreferences prefs;
  late ProviderContainer container;

  Future<void> open(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(
          _FaultInjectingPreferences(prefs, (key) {
            if (key != failSettingKey) return false;
            failSettingKey = null;
            return true;
          }),
        ),
        notificationServiceProvider.overrideWithValue(NotificationService()),
      ],
    );
    addTearDown(container.dispose);
  }

  setUp(() {
    calls.clear();
    permissionGranted = true;
    timezone = 'Asia/Jakarta';
    failTimezone = false;
    failSchedule = false;
    channelBlocked = false;
    failSettingKey = null;
    permissionResponse = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notifications, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'requestNotificationsPermission':
          return permissionResponse?.future ?? permissionGranted;
        case 'areNotificationsEnabled':
          return permissionGranted;
        case 'getNotificationChannels':
          if (channelBlocked) {
            return [
              {
                'id': 'family_journal_reminders',
                'name': 'Pengingat Jurnal Keluarga',
                'description': null,
                'groupId': null,
                'showBadge': true,
                'importance': 0,
                'bypassDnd': false,
                'playSound': false,
                'sound': null,
                'enableLights': false,
                'enableVibration': true,
                'vibrationPattern': null,
                'ledColor': 0,
                'audioAttributesUsage': 5,
              },
            ];
          }
          return <Object>[];
        case 'zonedSchedule':
          if (failSchedule) {
            throw PlatformException(code: 'schedule_failed');
          }
          return null;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(deviceTimezone, (call) async {
      expect(call.method, 'getLocalTimezone');
      if (failTimezone) throw PlatformException(code: 'timezone_unavailable');
      return timezone;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(notifications, null);
      messenger.setMockMethodCallHandler(deviceTimezone, null);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  test(
    'legacy measurement consent does not opt into family reminders',
    () async {
      await open({
        'reminder_enabled': true,
        'reminder_hour': 8,
        'reminder_minute': 30,
      });

      final settings = container.read(settingsProvider);
      expect(settings.journalReminderEnabled, isFalse);
      expect(settings.journalReminderHour, 20);
      expect(settings.journalReminderMinute, 0);
      expect(settings.reminderEnabled, isTrue);
      expect(settings.reminderHour, 8);
      expect(settings.reminderMinute, 30);
    },
  );

  test(
    'journal time persists separately from legacy measurement time',
    () async {
      await open({'reminder_hour': 8, 'reminder_minute': 30});

      expect(
        await container
            .read(journalReminderProvider)
            .setTime(hour: 21, minute: 45),
        isTrue,
      );
      expect(prefs.getInt('journal_reminder_hour'), 21);
      expect(prefs.getInt('journal_reminder_minute'), 45);
      expect(prefs.getInt('reminder_hour'), 8);
      expect(prefs.getInt('reminder_minute'), 30);
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);

      container.invalidate(settingsProvider);
      final restored = container.read(settingsProvider);
      expect(restored.journalReminderHour, 21);
      expect(restored.journalReminderMinute, 45);
      expect(restored.journalReminderEnabled, isFalse);
    },
  );

  test(
    'invalid saved settings use safe defaults instead of crashing',
    () async {
      await open({
        'standard': 999,
        'journal_reminder_hour': 24,
        'journal_reminder_minute': -1,
      });

      final settings = container.read(settingsProvider);
      expect(settings.journalReminderHour, 20);
      expect(settings.journalReminderMinute, 0);
    },
  );

  test('denied permission keeps reminders disabled and unscheduled', () async {
    await open({});
    permissionGranted = false;

    final granted = await container
        .read(journalReminderProvider)
        .setEnabled(true);

    expect(granted, isFalse);
    expect(container.read(settingsProvider).journalReminderEnabled, isFalse);
    expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    expect(calls.where((call) => call.method == 'cancel'), isNotEmpty);
  });

  test(
    'enabling schedules one daily inexact reminder in the device zone',
    () async {
      await open({'journal_reminder_hour': 21, 'journal_reminder_minute': 45});

      expect(
        await container.read(journalReminderProvider).setEnabled(true),
        isTrue,
      );

      final scheduled = calls.singleWhere(
        (call) => call.method == 'zonedSchedule',
      );
      final args = Map<String, dynamic>.from(scheduled.arguments as Map);
      expect(args['timeZoneName'], 'Asia/Jakarta');
      expect(args['scheduledDateTime'], contains('T21:45:00'));
      expect(args['matchDateTimeComponents'], 0);
      expect(
        args['platformSpecifics']['scheduleMode'],
        'inexactAllowWhileIdle',
      );
      expect(prefs.getBool('journal_reminder_enabled'), isTrue);

      calls.clear();
      expect(
        await container.read(journalReminderProvider).setEnabled(false),
        isTrue,
      );
      expect(container.read(settingsProvider).journalReminderEnabled, isFalse);
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
      final cancelled = calls.singleWhere((call) => call.method == 'cancel');
      expect(cancelled.arguments['id'], args['id']);
    },
  );

  test(
    'resume refreshes timezone without requesting permission again',
    () async {
      await open({'journal_reminder_enabled': true});
      await container.read(journalReminderProvider).sync();
      calls.clear();
      timezone = 'Asia/Makassar';

      await container.read(journalReminderProvider).sync();

      final scheduled = calls.singleWhere(
        (call) => call.method == 'zonedSchedule',
      );
      expect(scheduled.arguments['timeZoneName'], 'Asia/Makassar');
      expect(
        calls.where((call) => call.method == 'requestNotificationsPermission'),
        isEmpty,
      );
    },
  );

  test(
    'permission revoked outside app cancels and clears enabled preference',
    () async {
      await open({'journal_reminder_enabled': true});
      permissionGranted = false;

      await container.read(journalReminderProvider).sync();

      expect(container.read(settingsProvider).journalReminderEnabled, isFalse);
      expect(prefs.getBool('journal_reminder_enabled'), isFalse);
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    },
  );

  test(
    'timezone failure preserves preference and reports retry instead of UTC',
    () async {
      await open({'journal_reminder_enabled': true});
      failTimezone = true;

      await expectLater(
        container.read(journalReminderProvider).sync(),
        throwsA(isA<PlatformException>()),
      );

      expect(container.read(settingsProvider).journalReminderEnabled, isTrue);
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    },
  );

  test('failed scheduling never saves a false enabled confirmation', () async {
    await open({});
    failSchedule = true;

    await expectLater(
      container.read(journalReminderProvider).setEnabled(true),
      throwsA(isA<PlatformException>()),
    );

    expect(container.read(settingsProvider).journalReminderEnabled, isFalse);
    expect(prefs.getBool('journal_reminder_enabled'), isNot(true));
  });

  test(
    'failed preference write cancels a new schedule and restores settings',
    () async {
      await open({});
      failSettingKey = 'journal_reminder_enabled';

      await expectLater(
        container.read(journalReminderProvider).setEnabled(true),
        throwsStateError,
      );

      expect(container.read(settingsProvider).journalReminderEnabled, isFalse);
      expect(prefs.getBool('journal_reminder_enabled'), isNot(true));
      final scheduled = calls.singleWhere(
        (call) => call.method == 'zonedSchedule',
      );
      expect(calls.last.method, 'cancel');
      expect(calls.last.arguments['id'], scheduled.arguments['id']);
    },
  );

  test('failed disabling restores the previously enabled schedule', () async {
    await open({'journal_reminder_enabled': true});
    failSettingKey = 'journal_reminder_enabled';

    await expectLater(
      container.read(journalReminderProvider).setEnabled(false),
      throwsStateError,
    );

    expect(container.read(settingsProvider).journalReminderEnabled, isTrue);
    expect(prefs.getBool('journal_reminder_enabled'), isTrue);
    final scheduled = calls.singleWhere(
      (call) => call.method == 'zonedSchedule',
    );
    expect(scheduled.arguments['scheduledDateTime'], contains('T20:00:00'));
  });

  test(
    'resume during permission dialog cannot cancel the new opt-in',
    () async {
      await open({});
      permissionResponse = Completer<bool>();
      final controller = container.read(journalReminderProvider);
      final enabling = controller.setEnabled(true);
      final resuming = controller.sync();
      permissionResponse!.complete(true);

      expect(await enabling, isTrue);
      await resuming;

      expect(container.read(settingsProvider).journalReminderEnabled, isTrue);
      expect(calls.last.method, 'zonedSchedule');
      final scheduledIds = calls
          .where((call) => call.method == 'zonedSchedule')
          .map((call) => call.arguments['id'])
          .toSet();
      expect(scheduledIds, hasLength(1));
    },
  );
  test('a blocked journal channel is treated as denied permission', () async {
    await open({});
    channelBlocked = true;

    expect(
      await container.read(journalReminderProvider).setEnabled(true),
      isFalse,
    );

    expect(container.read(settingsProvider).journalReminderEnabled, isFalse);
    expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
  });

  test(
    'changing an enabled reminder replaces its time without another opt-in',
    () async {
      await open({'journal_reminder_enabled': true});

      expect(
        await container
            .read(journalReminderProvider)
            .setTime(hour: 7, minute: 30),
        isTrue,
      );

      final scheduled = calls.singleWhere(
        (call) => call.method == 'zonedSchedule',
      );
      expect(scheduled.arguments['scheduledDateTime'], contains('T07:30:00'));
      expect(prefs.getInt('journal_reminder_hour'), 7);
      expect(prefs.getInt('journal_reminder_minute'), 30);
      expect(prefs.getBool('journal_reminder_enabled'), isTrue);
      expect(
        calls.where((call) => call.method == 'requestNotificationsPermission'),
        isEmpty,
      );
    },
  );
}

/// Exercise the real preferences cache and persistence, but inject one failed
/// acknowledgement as a device storage failure can occur after a write.
class _FaultInjectingPreferences extends Fake implements SharedPreferences {
  _FaultInjectingPreferences(this.delegate, this.failWrite);

  final SharedPreferences delegate;
  final bool Function(String) failWrite;

  @override
  Object? get(String key) => delegate.get(key);
  @override
  bool? getBool(String key) => delegate.getBool(key);
  @override
  int? getInt(String key) => delegate.getInt(key);
  @override
  String? getString(String key) => delegate.getString(key);
  @override
  Future<bool> setBool(String key, bool value) async =>
      await delegate.setBool(key, value) && !failWrite(key);
  @override
  Future<bool> setInt(String key, int value) async =>
      await delegate.setInt(key, value) && !failWrite(key);
  @override
  Future<bool> setString(String key, String value) async =>
      await delegate.setString(key, value) && !failWrite(key);
  @override
  Future<bool> remove(String key) => delegate.remove(key);
}
