import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pill_time/pages/alarmPage.dart';

class Notify {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  final GlobalKey<NavigatorState> navigatorKey;

  Notify({required this.navigatorKey});

  Future<void> init() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pill_channel',
      'Pill Reminder',
      description: 'Medication reminders',
      importance: Importance.max,
    );

    await _initNotifications();

    final android = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.createNotificationChannel(channel);

    await _checkIfLaunchedByNotification();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _openAlarmPage();
      },
    );
  }

  Future<void> _checkIfLaunchedByNotification() async {
    final details = await notifications.getNotificationAppLaunchDetails();

    if (details != null && details.didNotificationLaunchApp) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _openAlarmPage();
      });
    }
  }

  void _openAlarmPage() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AlarmPage()),
    );
  }

  Future<void> scheduleNotification(
    String title,
    String body,
    tz.TZDateTime time,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    if (time.isBefore(now)) {
      time = now.add(const Duration(seconds: 5));
    }

    await notifications.zonedSchedule(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // ✅ ID único
      title: title,
      body: body,
      scheduledDate: time,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pill_channel',
          'Pill Reminder',
          channelDescription: 'Canal de lembretes',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: "alarm",
    );
  }

  Future<void> showNow() async {
    await notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: "Teste",
      body: "Notificação imediata",
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('pill_channel', 'Pill Reminder'),
      ),
    );
  }

  Future<void> startAlarmService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Alarme',
      notificationText: 'Executando...',
      callback: startCallback,
    );
  }

  // necessário para o isolate
  @pragma('vm:entry-point')
  void startCallback() {
    FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
  }
}

class AlarmTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    FlutterForegroundTask.launchApp("/alarm");
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isForground) async {}
}
