import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());

/// A daily local notification reminding the user to log a check-in.
/// Scheduled on-device; nothing is sent to a server.
class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Box _settings = Hive.box('settings');
  bool _initialized = false;

  static const _id = 1001;
  static const _enabledKey = 'reminderEnabled';
  static const _minutesKey = 'reminderMinutes';

  bool get enabled => _settings.get(_enabledKey, defaultValue: false) as bool;

  TimeOfDay get time {
    final m = _settings.get(_minutesKey, defaultValue: 20 * 60) as int;
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  Future<void> _init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // Unknown zone name: tz.local stays UTC and the reminder fires at UTC time.
    }
    // Permission is asked from [enable], when the user turns reminders on.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwin,
    ));
    _initialized = true;
  }

  /// Asks for notification permission and schedules the reminder.
  /// Returns false when the user declined the system prompt.
  Future<bool> enable(TimeOfDay at) async {
    await _init();
    final granted = await _requestPermission();
    if (!granted) return false;
    await _settings.put(_enabledKey, true);
    await _settings.put(_minutesKey, at.hour * 60 + at.minute);
    await _schedule(at);
    return true;
  }

  Future<void> disable() async {
    await _init();
    await _settings.put(_enabledKey, false);
    await _plugin.cancel(_id);
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  Future<void> _schedule(TimeOfDay at) async {
    await _plugin.cancel(_id);
    await _plugin.zonedSchedule(
      _id,
      'How are you feeling?',
      'Take a moment for your daily INPROV check-in.',
      nextInstanceOf(at, tz.TZDateTime.now(tz.local)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_checkin',
          'Daily check-in',
          channelDescription: 'A daily reminder to log your mood',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

/// The next moment at [at] that is strictly after [now].
@visibleForTesting
tz.TZDateTime nextInstanceOf(TimeOfDay at, tz.TZDateTime now) {
  var next = tz.TZDateTime(now.location, now.year, now.month, now.day, at.hour, at.minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  return next;
}
