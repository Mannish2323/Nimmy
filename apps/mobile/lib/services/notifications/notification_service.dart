import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/reminder.dart';

abstract interface class ReminderScheduler {
  String get timezone;

  Future<void> initialize();

  Future<bool> schedule(NimmyReminder reminder);

  Future<void> cancel(String reminderId);
}

class LocalNotificationService implements ReminderScheduler {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  String _timezone = 'UTC';

  @override
  String get timezone => _timezone;

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      _timezone = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(_timezone));
    } catch (_) {
      _timezone = 'UTC';
      tz.setLocalLocation(tz.UTC);
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
  }

  @override
  Future<bool> schedule(NimmyReminder reminder) async {
    final scheduled = tz.TZDateTime.from(reminder.scheduledAt, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return false;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nimmy_reminders',
        'Nimmy reminders',
        channelDescription: 'Reminders explicitly created with Nimmy',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: _notificationId(reminder.id),
      title: 'Nimmy reminder',
      body: reminder.title,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.id,
      matchDateTimeComponents: reminder.recurrence == null
          ? null
          : DateTimeComponents.dayOfWeekAndTime,
    );
    return true;
  }

  @override
  Future<void> cancel(String reminderId) {
    return _plugin.cancel(id: _notificationId(reminderId));
  }

  int _notificationId(String id) => id.hashCode & 0x7fffffff;
}

class NoopReminderScheduler implements ReminderScheduler {
  @override
  String get timezone => 'UTC';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(NimmyReminder reminder) async => false;

  @override
  Future<void> cancel(String reminderId) async {}
}
