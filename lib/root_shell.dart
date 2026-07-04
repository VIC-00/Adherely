import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reminders_screen.dart';
import 'widgets/bottom_nav.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  NavTab _tab = NavTab.home;

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
