import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> scheduleReminderNotification(ReminderRule rule);
  Future<void> cancelReminder(int ruleId);
}

class LocalNotificationService implements INotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Detect the user's local timezone
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation(Platform.localeName.contains('/') ? Platform.localeName : 'UTC'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    await requestPermissions();

    _initialized = true;
  }

  @override
  Future<void> scheduleReminderNotification(ReminderRule rule) async {
    if (!_initialized) await initialize();

    try {
      // Parse the time string, e.g. "8:00 AM" or "2:00 PM"
      final parts = rule.time.split(' ');
      if (parts.length != 2) return;
      
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return;
      
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      
      if (parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      // Calculate time considering the advance minutes
      final now = tz.TZDateTime.now(tz.local);
      final actualDoseTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        0,
      );

      var scheduledTime = actualDoseTime;

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Create a unique integer ID based on the rule ID (hashcode)
      final int notificationId = rule.id.hashCode;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'med_reminders',
        'Medication Reminders',
        channelDescription: 'Notifications for taking your medications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Medication Reminder',
          'Time to take ${rule.med} ${rule.dose}',
          scheduledTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: rule.id?.toString(),
        );
        debugPrint('Scheduled exact notification for ${rule.med} at $scheduledTime');
      } catch (e) {
        debugPrint('Exact alarm scheduling failed, attempting inexact alarm: $e');
        try {
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            'Medication Reminder',
            'Time to take ${rule.med} ${rule.dose}',
            scheduledTime,
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: rule.id?.toString(),
          );
          debugPrint('Scheduled inexact notification for ${rule.med} at $scheduledTime');
        } catch (innerErr) {
          debugPrint('Inexact alarm scheduling failed: $innerErr');
        }
      }
    } catch (e) {
      debugPrint('Failed to schedule reminder notification: $e');
    }
  }

  @override
  Future<void> cancelReminder(int ruleId) async {
    if (!_initialized) return;
    await _flutterLocalNotificationsPlugin.cancel(ruleId);
    debugPrint('Cancelled notification for rule ID $ruleId');
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Cancelled all notifications');
  }
}
