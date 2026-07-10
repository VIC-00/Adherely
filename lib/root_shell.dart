import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/add_med_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/alarm_overlay_dialog.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'providers/index.dart';
import 'models.dart';
import 'database_helper.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  NavTab _tab = NavTab.home;
  StreamSubscription<String?>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = LocalNotificationService.selectNotificationStream.stream.listen((String? payload) {
      if (payload != null) {
        if (payload.startsWith('action|')) {
          _handleNotificationAction(payload);
        } else {
          _showAlarmOverlay(payload);
        }
      }
    });
    _checkAppLaunchPayload();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAppLaunchPayload() async {
    // Wait briefly for UI layout to complete before modal trigger
    await Future.delayed(const Duration(milliseconds: 500));
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final NotificationAppLaunchDetails? details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp && details.notificationResponse != null) {
      final payload = details.notificationResponse!.payload;
      final actionId = details.notificationResponse!.actionId;
      if (payload != null) {
        if (actionId != null) {
          _handleNotificationAction('action|$actionId|$payload');
        } else {
          _showAlarmOverlay(payload);
        }
      }
    }
  }

  void _handleNotificationAction(String actionPayload) async {
    final parts = actionPayload.split('|');
    if (parts.length < 5) return;
    final action = parts[1]; // 'take' or 'snooze'
    final String medName = parts[3];

    if (!mounted) return;
    final medState = context.read<MedicationProvider>();
    final historyState = context.read<HistoryProvider>();

    // Find medication by name
    final medIndex = medState.meds.indexWhere((m) => m.name.toLowerCase() == medName.toLowerCase());
    if (medIndex != -1) {
      final med = medState.meds[medIndex];
      if (action == 'take') {
        medState.logMedication(med.id!, MedCardVariant.taken);
        final timeStr = DateFormat('h:mm a').format(DateTime.now());
        historyState.logHistory(HistoryItem(
          med: '${med.name} ${med.dose}',
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          time: timeStr,
          taken: true,
          note: 'Logged from notification bar',
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${med.name} marked as taken!')),
        );
      } else if (action == 'snooze') {
        // Retrieve snooze duration
        int snoozeMinutes = 5;
        try {
          final db = await DatabaseHelper.instance.database;
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

        final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
        final snoozeTimeStr = DateFormat('h:mm a').format(snoozeTime);
        final oldTime = med.freq.contains('·')
            ? med.freq.split('·').last.trim().split(',').first.trim()
            : med.freq;

        await medState.rescheduleRule(med.id!, oldTime, snoozeTimeStr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${med.name} snoozed for $snoozeMinutes mins (new time: $snoozeTimeStr)')),
          );
        }
      }
    }
  }

  void _showAlarmOverlay(String payload) {
    final parts = payload.split('|');
    if (parts.length < 3) return;
    final int? ruleId = int.tryParse(parts[0]);
    final String medName = parts[1];
    final String dose = parts[2];

    if (ruleId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlarmOverlayDialog(
          ruleId: ruleId,
          medName: medName,
          dose: dose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: [
          DashboardScreen(
            onOpenReminders: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
          const HistoryScreen(),
          const HealthScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNav(
        active: _tab,
        onTap: (t) => setState(() => _tab = t),
      ),
      floatingActionButton: _tab == NavTab.home
          ? FloatingActionButton(
              heroTag: 'root_add_med_fab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddMedScreen()),
                );
              },
              backgroundColor: const Color(0xFF2563EB),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }
}
