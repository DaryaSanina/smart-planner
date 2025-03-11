import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// This class allows the program to schedule and unschedule notifications
class NotificationAPI {
  static final _notifications = FlutterLocalNotificationsPlugin();

  // This method returns the details of the notification channel
  static Future _notificationDetails() async {
    // Ask for notifications permission
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Check Android version
      if (androidInfo.version.sdkInt >= 33) {
        await Permission.notification.request();
        await Permission.scheduleExactAlarm.request();
      }
    }

    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'smart planner reminder channel id',
        'smart planner reminder channel',
        channelDescription: 'smart planner reminder channel',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // This method schedules a notification
  // [id] is the ID of the notification
  // [title] is the title of the notification
  // [body] is the text that is displayed in the body of the notification
  // [scheduledDate] is the date for which the notification needs to be
  // scheduled
  static Future scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduledDate,
  }) async {
    print(id);
    _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      await _notificationDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload
    );
  }

  // This method cancels a notification with the specified [id]
  static Future<void> cancelNotification(int id) async
  => _notifications.cancel(id);
}