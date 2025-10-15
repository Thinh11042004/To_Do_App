import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/domain/entities/task_entity.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    final settings = const InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(settings);

    tz.initializeTimeZones();
    try {
      final locationName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
    _initialized = true;
  }

  Future<void> scheduleForTask(TaskEntity task) async {
    if (task.id == null) return;
    await init();

    final reminder = task.remindAt ?? task.dueAt;
    if (reminder == null) return;

    final now = DateTime.now();
    if (!reminder.isAfter(now)) return;

    final zonedDate = tz.TZDateTime.from(reminder, tz.local);
    final dueLabel = task.dueAt == null
        ? 'Không có hạn cụ thể'
        : DateFormat('HH:mm dd/MM').format(task.dueAt!);

    await _plugin.zonedSchedule(
      task.id!,
      'Sắp đến hạn: ${task.title}',
      'Hãy hoàn thành trước $dueLabel',
      zonedDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Nhắc nhở công việc',
          channelDescription: 'Thông báo nhắc nhở nhiệm vụ đến hạn',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id.toString(),
    );
  }

  Future<void> cancelReminder(int? id) async {
    if (id == null) return;
    await _plugin.cancel(id);
  }
}