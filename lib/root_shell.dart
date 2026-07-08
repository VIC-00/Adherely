import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reminders_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/alarm_overlay_dialog.dart';
import 'notification_service.dart';

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
        _showAlarmOverlay(payload);
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
      if (payload != null) {
        _showAlarmOverlay(payload);
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
    );
  }
}
