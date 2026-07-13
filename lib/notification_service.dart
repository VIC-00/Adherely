import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:sqflite/sqflite.dart';
import 'models.dart';
import 'database_helper.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> scheduleReminderNotification(ReminderRule rule);
  Future<void> cancelReminder(int ruleId);
  Future<void> cancelAll();
}

class LocalNotificationService implements INotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Notification timezone initialized successfully: $timeZoneName');
    } catch (e) {
      debugPrint('First timezone attempt failed: $e');
      try {
        tz.setLocalLocation(tz.getLocation(Platform.localeName.contains('/') ? Platform.localeName : 'UTC'));
      } catch (inner) {
        debugPrint('Second timezone attempt failed: $inner');
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
        debugPrint('Notification tapped: ${response.payload} (action: ${response.actionId})');
        if (response.actionId != null) {
          selectNotificationStream.add('action|${response.actionId}|${response.payload ?? ""}');
        } else {
          selectNotificationStream.add(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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

      // Check if this is an "every other day" medication and if it was already taken today
      bool isEveryOtherDay = false;
      bool isTakenToday = false;
      try {
        final db = await DatabaseHelper.instance.database;
        final medRows = await db.query('medications', where: 'name = ?', whereArgs: [rule.med]);
        if (medRows.isNotEmpty) {
          final freq = medRows.first['freq'] as String? ?? '';
          isEveryOtherDay = freq.toLowerCase().contains('every other day');

          final medId = medRows.first['id'] as int;
          final todayRows = await db.query('today_meds', where: 'med_id = ?', whereArgs: [medId]);
          if (todayRows.isNotEmpty) {
            isTakenToday = todayRows.first['status'] == 'taken';
          }
        }
      } catch (_) {}

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('Notification timezone time: $now');

      final tz.TZDateTime actualDoseTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        0,
      );

      var scheduledTime = actualDoseTime.subtract(Duration(minutes: rule.advance));

      if (scheduledTime.isBefore(now) || isTakenToday) {
        // For every-other-day: skip to 2 days out instead of 1
        scheduledTime = scheduledTime.add(Duration(days: isEveryOtherDay ? 2 : 1));
      }

      // Create a unique 32-bit integer ID based on the rule ID to prevent overflow in Java
      final int notificationId = rule.id != null ? (rule.id! % 2147483647) : (DateTime.now().millisecondsSinceEpoch % 2147483647);

      // Read settings from DB
      bool pushEnabled = true;
      bool loopAlarm = true;
      try {
        final db = await DatabaseHelper.instance.database;
        final List<Map<String, dynamic>> pushSettings = await db.query(
          'profile_toggles',
          where: 'label = ?',
          whereArgs: ['Push Notifications'],
        );
        if (pushSettings.isNotEmpty) {
          pushEnabled = (pushSettings.first['value'] as int) == 1;
        }

        final List<Map<String, dynamic>> alarmModeSettings = await db.query(
          'profile_toggles',
          where: 'label = ?',
          whereArgs: ['Continuous Alarm'],
        );
        if (alarmModeSettings.isNotEmpty) {
          loopAlarm = (alarmModeSettings.first['value'] as int) == 1;
        }
      } catch (_) {}

      if (!pushEnabled) {
        debugPrint('Push notifications are disabled globally. Cancelling and skipping schedule for ${rule.med}.');
        if (rule.id != null) {
          await cancelReminder(rule.id!);
        }
        return;
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'med_reminders',
        'Medication Reminders',
        channelDescription: 'Notifications for taking your medications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        audioAttributesUsage: loopAlarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        category: loopAlarm ? AndroidNotificationCategory.alarm : null,
        ongoing: loopAlarm,
        additionalFlags: loopAlarm ? Int32List.fromList(<int>[4]) : null,
        sound: loopAlarm ? const UriAndroidNotificationSound("content://settings/system/alarm_alert") : null,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction('take', 'Take', cancelNotification: true, showsUserInterface: true),
          AndroidNotificationAction('snooze', 'Snooze', cancelNotification: true, showsUserInterface: true),
        ],
      );
      
      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final payloadStr = '${rule.id}|${rule.med}|${rule.dose}';

      final step = isEveryOtherDay ? 2 : 1;
      final startDay = isTakenToday || scheduledTime.isBefore(now) ? step : 0;

      // Schedule 7 instances (e.g. today/tomorrow and next 6 scheduled days)
      for (int i = 0; i < 7; i++) {
        final dayOffset = startDay + (i * step);
        final occurrenceTime = scheduledTime.add(Duration(days: dayOffset));
        final int uniqueId = (notificationId + dayOffset * 100000) % 2147483647;

        try {
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            uniqueId,
            'Medication Reminder',
            'Time to take ${rule.med} ${rule.dose}',
            occurrenceTime,
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: null, // one-shot absolute alarm
            payload: payloadStr,
          );
          debugPrint('Scheduled notification for ${rule.med} (instance $i) at $occurrenceTime');
        } catch (e) {
          debugPrint('Exact alarm scheduling failed for instance $i, attempting inexact alarm: $e');
          try {
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              uniqueId,
              'Medication Reminder',
              'Time to take ${rule.med} ${rule.dose}',
              occurrenceTime,
              platformChannelSpecifics,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: null,
              payload: payloadStr,
            );
            debugPrint('Scheduled inexact notification for ${rule.med} (instance $i) at $occurrenceTime');
          } catch (innerErr) {
            debugPrint('Inexact alarm scheduling failed for instance $i: $innerErr');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to schedule reminder notification: $e');
    }
  }

  @override
  Future<void> cancelReminder(int ruleId) async {
    if (!_initialized) return;
    final int baseId = ruleId % 2147483647;
    for (int i = 0; i < 15; i++) { // cancel today (0) and next 14 days
      final int uniqueId = (baseId + i * 100000) % 2147483647;
      await _flutterLocalNotificationsPlugin.cancel(uniqueId);
      await _flutterLocalNotificationsPlugin.cancel((uniqueId + 5000) % 2147483647);
    }
    debugPrint('Cancelled notification and snooze for rule ID $ruleId');
  }

  @override
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Cancelled all notifications');
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Background notification action clicked: ${notificationResponse.actionId}');
  final String? payload = notificationResponse.payload;
  if (payload == null) return;

  final parts = payload.split('|');
  if (parts.length < 3) return;
  final int? ruleId = int.tryParse(parts[0]);
  final String med = parts[1];
  final String dose = parts[2];

  if (notificationResponse.actionId == 'take') {
    await _handleTakeActionInBackground(med);
  } else if (notificationResponse.actionId == 'snooze') {
    if (ruleId != null) {
      await _handleSnoozeActionInBackground(ruleId, med, dose);
    }
  }
}

Future<void> _handleTakeActionInBackground(String medName) async {
  try {
    final db = await DatabaseHelper.instance.database;

    // 1. Find the medication ID in the database
    final List<Map<String, dynamic>> medMaps = await db.query(
      'medications',
      where: 'name = ?',
      whereArgs: [medName],
    );
    if (medMaps.isNotEmpty) {
      final medId = medMaps.first['id'] as int;
      // Update status in today_meds to 'taken'
      await db.insert(
        'today_meds',
        {'med_id': medId, 'status': 'taken'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Insert record in history_items
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await db.insert('history_items', {
      'med': medName,
      'date': dateStr,
      'time': timeStr,
      'taken': 1,
      'note': 'Logged from background action',
    });
    debugPrint('Background Take action completed for med: $medName');
  } catch (e) {
    debugPrint('Error handling background Take action: $e');
  }
}

Future<void> _handleSnoozeActionInBackground(int ruleId, String med, String dose) async {
  try {
    final db = await DatabaseHelper.instance.database;
    int snoozeMinutes = 5;
    try {
      final List<Map<String, dynamic>> snoozeSettings = await db.query(
        'profile_toggles',
        where: 'label = ?',
        whereArgs: ['Snooze Duration'],
      );
      if (snoozeSettings.isNotEmpty) {
        final subStr = snoozeSettings.first['sub'] as String;
        snoozeMinutes = int.tryParse(subStr.split(' ').first) ?? 5;
      }
    } catch (_) {}

    // Initialize timezones in this background isolate
    tz.initializeTimeZones();
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    final now = tz.TZDateTime.now(tz.local);
    final snoozeTime = now.add(Duration(minutes: snoozeMinutes));

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    bool loopAlarm = true;
    try {
      final List<Map<String, dynamic>> alarmModeSettings = await db.query(
        'profile_toggles',
        where: 'label = ?',
        whereArgs: ['Continuous Alarm'],
      );
      if (alarmModeSettings.isNotEmpty) {
        loopAlarm = (alarmModeSettings.first['value'] as int) == 1;
      }
    } catch (_) {}

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'med_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for taking your medications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      audioAttributesUsage: loopAlarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
      category: loopAlarm ? AndroidNotificationCategory.alarm : null,
      ongoing: loopAlarm,
      additionalFlags: loopAlarm ? Int32List.fromList(<int>[4]) : null,
      sound: loopAlarm ? const UriAndroidNotificationSound("content://settings/system/alarm_alert") : null,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction('take', 'Take', cancelNotification: true),
        AndroidNotificationAction('snooze', 'Snooze', cancelNotification: true),
      ],
    );

    final notificationId = (ruleId + 5000) % 2147483647; // offset id for snoozed alarms to avoid overwriting

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Snoozed: Medication Reminder',
      'Time to take $med $dose',
      snoozeTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$ruleId|$med|$dose',
    );
    debugPrint('Background Snooze alarm scheduled for: $snoozeTime');
  } catch (e) {
    debugPrint('Error handling background Snooze action: $e');
  }
}
