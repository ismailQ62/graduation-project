import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class NotificationController {
  static final FlutterLocalNotificationsPlugin _notificationPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationPlugin.initialize(initSettings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required String sound,

    int id = 0,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'lorescue_channel_$sound', // unique per sound
          'LoRescue Alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound('emergency_alarm'),
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationPlugin.show(id, title, body, platformDetails);
  }
}
