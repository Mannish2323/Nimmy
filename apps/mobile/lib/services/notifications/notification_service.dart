import '../../core/native/nimmy_bridge.dart';
import '../../models/reminder.dart';

abstract interface class ReminderScheduler {
  String get timezone;

  Future<void> initialize();

  Future<bool> schedule(NimmyReminder reminder);

  Future<void> cancel(String reminderId);
}

class NativeReminderScheduler implements ReminderScheduler {
  NativeReminderScheduler({this.configuredTimezone = 'UTC'});

  final String configuredTimezone;

  @override
  String get timezone => configuredTimezone;

  @override
  Future<void> initialize() async {
    // Android creates the notification channel lazily when the first alarm
    // fires. This keeps permission prompts tied to an actual user action.
  }

  @override
  Future<bool> schedule(NimmyReminder reminder) async {
    if (!reminder.scheduledAt.isAfter(DateTime.now().toUtc())) return false;
    final result = await NimmyNativeBridge.scheduleAlarm(
      title: 'Nimmy reminder',
      body: reminder.title,
      scheduledTime: reminder.scheduledAt,
      id: _notificationId(reminder.id),
    );
    return result['scheduled'] == true;
  }

  @override
  Future<void> cancel(String reminderId) async {
    await NimmyNativeBridge.cancelAlarm(_notificationId(reminderId));
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
