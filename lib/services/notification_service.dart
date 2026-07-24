import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingTest = false;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

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

    // Request permissions for Android 13+ (Notifications) and Android 12+ (Exact Alarms)
    final androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();

      final sounds = ['adhan', 'adhan_makkah', 'adhan_madinah', 'adhan_egypt', 'adhan_aqsa'];
      for (var snd in sounds) {
        try {
          final channel = AndroidNotificationChannel(
            'prayer_channel_${snd}_v4',
            'مواقيت الصلاة والأذان',
            description: 'تنبيهات أوقات الصلاة بالأذان',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(snd),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            enableVibration: true,
          );
          await androidImplementation.createNotificationChannel(channel);
        } catch (_) {}
      }
    }
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String soundName = 'adhan',
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Create wall-clock exact TZDateTime matching local scheduledTime
    final scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_channel_${soundName}_v4',
        'مواقيت الصلاة والأذان',
        channelDescription: 'تنبيهات أوقات الصلاة بالآذان',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundName),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        sound: '$soundName.mp3',
        presentSound: true,
      ),
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  Future<void> testAzanSound(String soundName) async {
    // If already playing, stop test audio
    if (_isPlayingTest) {
      await _audioPlayer.stop();
      _isPlayingTest = false;
      return;
    }

    // Play Adhan audio test directly via AudioPlayer
    try {
      await _audioPlayer.stop();
      _isPlayingTest = true;
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlayingTest = false;
      });
      await _audioPlayer.play(AssetSource('android/app/src/main/res/raw/$soundName.mp3'));
    } catch (_) {}

    // Show test notification as well
    await _flutterLocalNotificationsPlugin.show(
      id: 999,
      title: 'تجربة الأذان',
      body: 'هذا اختبار لصوت الأذان المحدد',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_test_channel_${soundName}_v2',
          'تجربة صوت الأذان',
          channelDescription: 'اختبار نغمة وتنبيه الأذان',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundName),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: '$soundName.mp3',
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> stopTestSound() async {
    await _audioPlayer.stop();
    _isPlayingTest = false;
  }

  Future<void> scheduleAzkarNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'azkar_reminders_channel_v1',
        'تنبيهات الأذكار والورد اليومي',
        channelDescription: 'تنبيهات حث المسلم على أذكار الصباح والمساء والنوم',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
      ),
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
