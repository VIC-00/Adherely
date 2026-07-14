import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';
import '../notification_service.dart';
import '../widgets/success_overlay.dart';

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
    final settingsState = context.watch<SettingsProvider>();
    // Sort rules chronologically by their time string
    final rules = [...medState.rules]..sort((a, b) {
      try {
        TimeOfDay parseTime(String t) {
          final parts = t.split(' ');
          final hm = parts[0].split(':');
          int h = int.parse(hm[0]);
          final m = int.parse(hm[1]);
          if (parts[1].toUpperCase() == 'PM' && h < 12) h += 12;
          if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
          return TimeOfDay(hour: h, minute: m);
        }
        final ta = parseTime(a.time);
        final tb = parseTime(b.time);
        return (ta.hour * 60 + ta.minute).compareTo(tb.hour * 60 + tb.minute);
      } catch (_) {
        return 0;
      }
    });

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
                    // Push count + Snooze stats row
                    Builder(builder: (context) {
                      final pushCount = rules.where((r) => r.active && r.types.contains(AlertType.push)).length;
                      final snoozeSetting = settingsState.notificationToggles
                          .firstWhere((t) => t.label == 'Snooze Duration', orElse: () => const ToggleItem(label: 'Snooze Duration', sub: '5 minutes', on: true));
                      final snoozeLabel = snoozeSetting.sub.split(' ').first;
                      return Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    const Text('🔔', style: TextStyle(fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('$pushCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                                    Text('Push', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.65), letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    const Text('⏱️', style: TextStyle(fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('${snoozeLabel}m', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                                    Text('Snooze', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.65), letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
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
                    if (rules.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off_rounded, size: 32, color: AppColors.ink400),
                            const SizedBox(height: 8),
                            Text('No reminders set yet.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink700)),
                            const SizedBox(height: 4),
                            Text('Add a medication or use the button below.', style: TextStyle(fontSize: 11, color: AppColors.ink400)),
                          ],
                        ),
                      )
                    else
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
                      final intakeController = TextEditingController(text: '1');
                      final supplyController = TextEditingController(text: '30');
                      final timeController = TextEditingController(text: '8:00 AM');
                      showDialog(
                        context: context,
                        builder: (context) {
                          final hasMeds = medState.meds.isNotEmpty;
                          String? selectedMed = hasMeds ? medState.meds.first.name : null;
                          bool isNew = !hasMeds;

                          String customForm = 'Tablet';
                          double customIntake = 1.0;
                          double customSupply = 30.0;

                          if (hasMeds && selectedMed != null) {
                            medController.text = selectedMed;
                          }

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                backgroundColor: AppColors.cardBg,
                                title: Text('Add Custom Reminder', style: TextStyle(color: AppColors.ink900, fontWeight: FontWeight.bold)),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (hasMeds) ...[
                                        Text('Select Medication', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink700)),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          initialValue: isNew ? '__new__' : selectedMed,
                                          dropdownColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                                          ),
                                          items: [
                                            ...medState.meds.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name))),
                                            const DropdownMenuItem(value: '__new__', child: Text('+ Add New Medication...')),
                                          ],
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == '__new__') {
                                                isNew = true;
                                                medController.text = '';
                                              } else {
                                                isNew = false;
                                                selectedMed = val;
                                                medController.text = val ?? '';
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                      if (isNew) ...[
                                        Text('New Medication Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink700)),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: medController,
                                          style: TextStyle(fontSize: 13, color: AppColors.ink900),
                                          decoration: InputDecoration(
                                            hintText: 'e.g. Metformin',
                                            filled: true,
                                            fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text('Form', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink700)),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          initialValue: customForm,
                                          dropdownColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                                          ),
                                          items: const ['Tablet', 'Capsule', 'Liquid', 'Injection']
                                              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                                              .toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              customForm = v ?? 'Tablet';
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        Text('Intake Amount (per dose)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink700)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: intakeController,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                style: TextStyle(fontSize: 13, color: AppColors.ink900),
                                                decoration: InputDecoration(
                                                  hintText: 'e.g. 1',
                                                  filled: true,
                                                  fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                                                ),
                                                onChanged: (val) {
                                                  setState(() {
                                                    customIntake = double.tryParse(val) ?? 1.0;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              (() {
                                                final f = customForm.toLowerCase();
                                                if (f.contains('tablet')) return customIntake == 1.0 ? 'tablet' : 'tablets';
                                                if (f.contains('capsule')) return customIntake == 1.0 ? 'capsule' : 'capsules';
                                                if (f.contains('liquid')) return 'ml';
                                                if (f.contains('injection')) return customIntake == 1.0 ? 'injection' : 'injections';
                                                return 'units';
                                              })(),
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink700),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          (() {
                                            final f = customForm.toLowerCase();
                                            if (f.contains('liquid')) return 'Liquid volume in supply (ml)';
                                            if (f.contains('tablet')) return 'Tablets in supply';
                                            if (f.contains('capsule')) return 'Capsules in supply';
                                            if (f.contains('injection')) return 'Injections in supply';
                                            return 'Units in supply';
                                          })(),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink700),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: supplyController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: TextStyle(fontSize: 13, color: AppColors.ink900),
                                          decoration: InputDecoration(
                                            hintText: 'e.g. 30',
                                            filled: true,
                                            fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              customSupply = double.tryParse(val) ?? 30.0;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                      Text('Reminder Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink700)),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: timeController,
                                        readOnly: true,
                                        style: TextStyle(fontSize: 13, color: AppColors.ink900),
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 8:00 AM',
                                          filled: true,
                                          fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
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
                                            setState(() {
                                              timeController.text = '$hour:$minute $period';
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Cancel', style: TextStyle(color: AppColors.ink500)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final medName = medController.text.trim();
                                      final time = timeController.text.trim();
                                      if (medName.isNotEmpty) {
                                        if (isNew) {
                                          medState.addRule(
                                            ReminderRule(
                                              id: null,
                                              med: medName,
                                              dose: '', // dosage is optional/empty
                                              time: time.isNotEmpty ? time : '8:00 AM',
                                              types: [AlertType.push],
                                              advance: 0,
                                              color: AppColors.medBlue,
                                              active: true,
                                            ),
                                            form: customForm,
                                            intakeQty: customIntake,
                                            supplyQty: customSupply,
                                            initialSupply: customSupply,
                                          );
                                        } else {
                                          final matchingMed = medState.meds.firstWhere((m) => m.name == selectedMed);
                                          medState.addRule(
                                            ReminderRule(
                                              id: null,
                                              med: medName,
                                              dose: matchingMed.dose,
                                              time: time.isNotEmpty ? time : '8:00 AM',
                                              types: [AlertType.push],
                                              advance: 0,
                                              color: matchingMed.color,
                                              active: true,
                                            ),
                                          );
                                        }
                                        Navigator.of(context).pop();
                                        SuccessOverlay.showReminderAdded(context, medName: medName, time: time.isNotEmpty ? time : '8:00 AM');
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isNew ? AppColors.medBlue : (medState.meds.firstWhere((m) => m.name == selectedMed).color),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Add'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
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
                            Builder(builder: (context) {
                              final t = settingsState.notificationToggles[i];
                              final isVoice = t.label == 'Voice Reminders';
                              return Opacity(
                                opacity: isVoice ? 0.45 : 1.0,
                                child: GestureDetector(
                                  onTap: isVoice
                                      ? null
                                      : () async {
                                          final medProvider = context.read<MedicationProvider>();
                                          await settingsState.toggleNotificationToggle(i);
                                          for (final rule in medProvider.rules) {
                                            if (rule.active) {
                                              await LocalNotificationService().scheduleReminderNotification(rule);
                                            }
                                          }
                                        },
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
                                              Row(
                                                children: [
                                                  Text(t.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                                                  if (isVoice) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.isDark
                                                            ? const Color(0xFF374151)
                                                            : const Color(0xFFF3F4F6),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text('Soon',
                                                          style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w700,
                                                              color: AppColors.ink400)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(t.sub, style: TextStyle(fontSize: 11, color: AppColors.ink400)),
                                            ],
                                          ),
                                        ),
                                        _StaticSwitch(on: isVoice ? false : t.on, color: t.color!),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
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
                            // Show a "Soon" chip for voice type since it's disabled
                            if (t == AlertType.voice) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔊', style: TextStyle(fontSize: 10)),
                                    const SizedBox(width: 3),
                                    Text('Soon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink400)),
                                  ],
                                ),
                              );
                            }
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

