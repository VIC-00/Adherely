import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';

const Map<AlertType, AlertInfo> _alertIcons = {
  AlertType.push: AlertInfo('🔔', 'Push', AppColors.medBlue),
  AlertType.voice: AlertInfo('🔊', 'Voice', AppColors.medOrange),
};



class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final medState = context.watch<MedicationProvider>();
//     final vitalsState = context.watch<VitalsProvider>();
    final settingsState = context.watch<SettingsProvider>();
//     final historyState = context.watch<HistoryProvider>();
    final rules = medState.rules;

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('REMINDERS & ALERTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 4),
                    const Text('Notification Hub', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6)),
                    Text('${medState.activeRuleCount} active rules · ${medState.activeMedCount} medications', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
                    const SizedBox(height: 14),
                    Row(
                      children: [AlertType.push, AlertType.voice].map((t) {
                        final info = _alertIcons[t]!;
                        final count = rules.where((r) => r.active && r.types.contains(t)).length;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  Text(info.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('$count', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text(info.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.65), letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Timeline
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Alert Schedule", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Positioned(
                          left: 6,
                          top: 8,
                          bottom: 8,
                          child: Container(
                              width: 2,
                              color: AppColors.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            children: [
                              for (int i = 0; i < rules.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(bottom: i < rules.length - 1 ? 12 : 0),
                                  child: _RuleCard(rule: rules[i], onToggle: () => medState.toggleRule(rules[i].id!)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Add custom reminder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final medController = TextEditingController();
                      final doseController = TextEditingController();
                      final timeController = TextEditingController(text: '8:00 AM');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add Custom Reminder'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: medController,
                                  decoration: const InputDecoration(
                                    labelText: 'Medication Name',
                                    hintText: 'e.g. Metformin',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: doseController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dosage',
                                    hintText: 'e.g. 500mg',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: timeController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Time',
                                    hintText: 'e.g. 8:00 AM',
                                  ),
                                  onTap: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                      builder: (context, child) {
                                        final mediaQuery = MediaQuery.of(context);
                                        return MediaQuery(
                                          data: mediaQuery.copyWith(
                                            size: Size(mediaQuery.size.width, mediaQuery.size.height < 600.0 ? 800.0 : mediaQuery.size.height),
                                            viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0),
                                            textScaler: TextScaler.noScaling,
                                          ),
                                          child: OverflowBox(
                                            minHeight: 340.0,
                                            maxHeight: 800.0,
                                            child: child!,
                                          ),
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                                      final minute = picked.minute.toString().padLeft(2, '0');
                                      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                                      timeController.text = '$hour:$minute $period';
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final med = medController.text.trim();
                                final dose = doseController.text.trim();
                                final time = timeController.text.trim();
                                if (med.isNotEmpty) {
                                  medState.addRule(ReminderRule(
                                    id: DateTime.now().millisecondsSinceEpoch,
                                    med: med,
                                    dose: dose.isNotEmpty ? dose : '1 pill',
                                    time: time.isNotEmpty ? time : '8:00 AM',
                                    types: [AlertType.push],
                                    advance: 0,
                                    color: AppColors.medBlue,
                                    active: true,
                                  ));
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added reminder for $med!')),
                                  );
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.add_rounded,
                        size: 16,
                        color: AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                    label: const Text('Add Custom Reminder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.isDark ? const Color(0xFF1E3A8A) : AppColors.medBlueLight,
                      foregroundColor: AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      side: BorderSide(
                          color: AppColors.isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              // Global settings
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (int i = 0; i < settingsState.notificationToggles.length; i++)
                            GestureDetector(
                              onTap: () => settingsState.toggleNotificationToggle(i),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                decoration: BoxDecoration(
                                  border: i < settingsState.notificationToggles.length - 1 ? Border(bottom: BorderSide(color: AppColors.hairline)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(settingsState.notificationToggles[i].label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                                          Text(settingsState.notificationToggles[i].sub, style: TextStyle(fontSize: 11, color: AppColors.ink400)),
                                        ],
                                      ),
                                    ),
                                    _StaticSwitch(on: settingsState.notificationToggles[i].on, color: settingsState.notificationToggles[i].color!),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final ReminderRule rule;
  final VoidCallback onToggle;
  const _RuleCard({required this.rule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -20,
          top: 16,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: rule.active ? rule.color : (AppColors.isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.isDark ? AppColors.canvasBg : Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 0, spreadRadius: 2)],
            ),
          ),
        ),
        Opacity(
          opacity: rule.active ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
              border: Border(
                  left: BorderSide(
                      color: rule.active
                          ? rule.color
                          : (AppColors.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                      width: 3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(rule.time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                          const SizedBox(width: 4),
                          Text('·', style: TextStyle(fontSize: 11, color: AppColors.ink400)),
                          const SizedBox(width: 4),
                          Text('${rule.med} ${rule.dose}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: rule.color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          ...rule.types.map((t) {
                            final info = _alertIcons[t]!;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: info.color.withValues(alpha: AppColors.isDark ? 0.16 : 0.08),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(info.icon, style: const TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(info.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: info.color)),
                                ],
                              ),
                            );
                          }),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(5)),
                            child: Text('−${rule.advance}min', style: TextStyle(fontSize: 10, color: AppColors.ink500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 36,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                        color: rule.active
                            ? rule.color
                            : (AppColors.isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(11)),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: rule.active ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 3)]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StaticSwitch extends StatelessWidget {
  final bool on;
  final Color color;
  const _StaticSwitch({required this.on, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
          color: on ? color : (AppColors.isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(12)),
      child: Align(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
        ),
      ),
    );
  }
}

