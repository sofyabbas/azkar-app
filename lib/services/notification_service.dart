import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String soundName = 'adhan',
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel_$soundName',
          'Prayer Times',
          channelDescription: 'Notifications for daily prayers',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundName),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: '$soundName.mp3',
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> testAzanSound(String soundName) async {
    await _flutterLocalNotificationsPlugin.show(
      id: 999, 
      title: 'تجربة الأذان',
      body: 'هذا اختبار لصوت الأذان',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_test_channel_$soundName',
          'Test Prayer Times',
          channelDescription: 'Testing notifications for daily prayers',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundName),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: '$soundName.mp3',
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
