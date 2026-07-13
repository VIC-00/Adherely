import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'providers/index.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'root_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'models.dart';

class MedAdhereApp extends StatefulWidget {
  const MedAdhereApp({super.key});

  @override
  State<MedAdhereApp> createState() => _MedAdhereAppState();
}

class _MedAdhereAppState extends State<MedAdhereApp> {
  bool _initialized = false;
  
  late MedicationProvider _medicationProvider;
  late VitalsProvider _vitalsProvider;
  late SettingsProvider _settingsProvider;
  late HistoryProvider _historyProvider;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    _medicationProvider = MedicationProvider(LocalNotificationService());
    _vitalsProvider = VitalsProvider();
    _settingsProvider = SettingsProvider();
    _historyProvider = HistoryProvider();

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Load data
      final medsData = await db.query('medications');
      final rulesData = await db.query('reminder_rules');
      final todayData = await db.query('today_meds');
      final vitalsData = await db.query('vitals');
      final caregiversData = await db.query('caregivers');
      final togglesData = await db.query('profile_toggles');
      final historyData = await db.query('history_items', orderBy: 'id DESC');
      final bpData = await db.query('bp_readings');

      // Check daily reset
      final prefs = await SharedPreferences.getInstance();
      final lastRunDate = prefs.getString('last_run_date');
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (lastRunDate != today) {
        // Persist any untaken doses from yesterday into history before wiping the slate.
        // Only do this when we actually have a recorded date (i.e. not the very first install).
        if (lastRunDate != null) {
          final rules = await db.query('reminder_rules', where: 'active = 1');
          final Map<String, int> scheduledCounts = {};
          for (final r in rules) {
            final key = '${r['med']} ${r['dose']}'.trim().toLowerCase();
            scheduledCounts[key] = (scheduledCounts[key] ?? 0) + 1;
          }

          final historyYesterday = await db.query(
            'history_items',
            where: 'date = ? AND taken = 1',
            whereArgs: [lastRunDate],
          );
          final Map<String, int> takenCounts = {};
          for (final h in historyYesterday) {
            final key = (h['med'] as String).trim().toLowerCase();
            takenCounts[key] = (takenCounts[key] ?? 0) + 1;
          }

          for (final entry in scheduledCounts.entries) {
            final key = entry.key;
            final scheduled = entry.value;
            final taken = takenCounts[key] ?? 0;
            if (taken < scheduled) {
              final missedCount = scheduled - taken;
              final ruleMatch = rules.firstWhere((r) => '${r['med']} ${r['dose']}'.trim().toLowerCase() == key);
              final medName = ruleMatch['med'] as String;
              final medDose = ruleMatch['dose'] as String;

              for (int m = 0; m < missedCount; m++) {
                await db.insert('history_items', {
                  'med': '$medName $medDose',
                  'date': lastRunDate,
                  'time': 'Not taken',
                  'taken': 0,
                  'note': 'Missed dose',
                });
              }
            }
          }
        }
        await db.update('today_meds', {'status': 'upcoming'});
        await prefs.setString('last_run_date', today);
        final resetTodayData = await db.query('today_meds');
        await _medicationProvider.load(medsData, rulesData, resetTodayData, historyData);
      } else {
        await _medicationProvider.load(medsData, rulesData, todayData, historyData);
      }

      await _vitalsProvider.load(vitalsData, bpData);
      
      final profileData = await db.query('profile');
      Profile? profile;
      if (profileData.isNotEmpty) {
        final map = profileData.first;
        profile = Profile(
          id: map['id'] as int,
          name: map['name'] as String,
          dob: map['dob'] as String,
          conditions: map['conditions'] as String,
        );
      }
      await _settingsProvider.load(profile, caregiversData, togglesData);
      
      await _historyProvider.load(historyData);
      await _historyProvider.loadPersonalBest();

      // Refresh the rolling window of 7 one-shot alarms for all active rules on app open.
      final notifService = LocalNotificationService();
      await notifService.initialize();
      for (final rule in _medicationProvider.rules) {
        if (rule.active) {
          await notifService.scheduleReminderNotification(rule);
        }
      }
      
    } catch (e) {
      debugPrint("DB init failed, using in-memory: $e");
      _medicationProvider.setDbEnabled(false);
      _vitalsProvider.setDbEnabled(false);
      _settingsProvider.setDbEnabled(false);
      _historyProvider.setDbEnabled(false);

      _medicationProvider.setInMemoryDefaults();
      _vitalsProvider.setInMemoryDefaults();
      _settingsProvider.setInMemoryDefaults();
      _historyProvider.setInMemoryDefaults();
    }

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _medicationProvider),
        ChangeNotifierProvider.value(value: _vitalsProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider.value(value: _historyProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsState, child) {
          final darkModeToggle = settingsState.profileToggles.firstWhere(
            (t) => t.label == 'Dark Mode',
            orElse: () => const ToggleItem(label: 'Dark Mode', sub: '', on: false),
          );
          AppColors.isDark = darkModeToggle.on;
          final themeMode = darkModeToggle.on ? ThemeMode.dark : ThemeMode.light;
          return MaterialApp(
            title: 'Adherely',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: settingsState.profile == null
                ? const OnboardingScreen()
                : const RootShell(),
          );
        },
      ),
    );
  }
}
