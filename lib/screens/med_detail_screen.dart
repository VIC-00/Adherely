import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';
import '../widgets/success_overlay.dart';



const _tabs = ['Overview', 'Schedule', 'Side Effects', 'Refills'];

class MedDetailScreen extends StatefulWidget {
  final Medication medication;
  const MedDetailScreen({super.key, required this.medication});

  @override
  State<MedDetailScreen> createState() => _MedDetailScreenState();
}

class _MedDetailScreenState extends State<MedDetailScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final medState = context.watch<MedicationProvider>();
    final historyState = context.watch<HistoryProvider>();

    final med = medState.meds.firstWhere(
      (m) => m.id == widget.medication.id,
      orElse: () => widget.medication,
    );

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            HSLColor.fromColor(med.color)
                                .withLightness((HSLColor.fromColor(med.color).lightness * 0.75).clamp(0.0, 1.0))
                                .toColor(),
                            med.color,
                            HSLColor.fromColor(med.color)
                                .withLightness((HSLColor.fromColor(med.color).lightness * 1.25).clamp(0.0, 1.0))
                                .toColor(),
                          ],
                          stops: const [0, 0.7, 1],
                        ),
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
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.arrow_back_rounded,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                              const Spacer(),
                              PopupMenuButton<String>(
                                tooltip: 'Medication actions',
                                color: AppColors.isDark ? AppColors.cardBg : Colors.white,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditMedDialog(context, med);
                                  } else if (value == 'delete') {
                                    _showDeleteMedDialog(context, med);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_rounded, size: 18, color: AppColors.ink700),
                                        const SizedBox(width: 8),
                                        Text('Edit Medication', style: TextStyle(fontSize: 13, color: AppColors.ink900)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_rounded, size: 18, color: AppColors.medRed),
                                        SizedBox(width: 8),
                                        Text('Delete Medication', style: TextStyle(fontSize: 13, color: AppColors.medRed, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.more_horiz_rounded,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2),
                            ),
                            child: const Icon(Icons.medication_rounded,
                                size: 26, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                           Text(med.name,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.6)),
                          Text(
                            (() {
                              final m = med;
                              final qty = m.intakeQty;
                              final formLower = (m.form ?? 'tablet').toLowerCase();
                              String unit = 'pill';
                              if (formLower.contains('tablet')) {
                                unit = qty == 1.0 ? 'tablet' : 'tablets';
                              } else if (formLower.contains('capsule')) {
                                unit = qty == 1.0 ? 'capsule' : 'capsules';
                              } else if (formLower.contains('liquid')) {
                                unit = 'ml';
                              } else if (formLower.contains('injection')) {
                                unit = qty == 1.0 ? 'injection' : 'injections';
                              } else {
                                unit = qty == 1.0 ? 'unit' : 'units';
                              }
                              final qtyStr = qty.toStringAsFixed(qty == qty.toInt() ? 0 : 1);
                              String doseSpec = '';
                              if (m.dose.isNotEmpty) {
                                if (qty > 1.0) {
                                  doseSpec = ' (${m.dose} each)';
                                } else {
                                  doseSpec = ' (${m.dose})';
                                }
                              }
                              return '$qtyStr $unit$doseSpec · ${m.drugClass ?? "Medication"}';
                            })(),
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 14), Builder(
                             builder: (context) {
                               final timeStr = med.freq.contains('·') ? med.freq.split('·').last.trim() : med.freq;
                               final timesCount = timeStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList().length;
                               final scheduleVal = timesCount > 1 ? '${timesCount}x daily' : timeStr;
                               return Row(
                                 children: [
                                   _StatPill(val: scheduleVal, label: 'Schedule'),
                                   const SizedBox(width: 10),
                                   _StatPill(val: '${historyState.calculateStreakForMed(med.name, medState.dynamicTodayMeds, med)} days', label: 'Streak'),
                                   const SizedBox(width: 10),
                                   _StatPill(val: '${historyState.getMedicationAdherence(med.name)}%', label: 'Adherence'),
                                 ],
                               );
                             }
                           ),
                        ],
                      ),
                    ),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border(
                            bottom: BorderSide(color: AppColors.hairline)),
                      ),
                      child: Row(
                        children: List.generate(_tabs.length, (i) {
                          final active = i == _activeTab;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _activeTab = i),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: active
                                              ? med.color
                                              : Colors.transparent,
                                          width: 2)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _tabs[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? med.color
                                        : AppColors.ink400,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: switch (_activeTab) {
                        0 => _OverviewTab(medication: med),
                        1 => _ScheduleTab(medication: med),
                        2 => _SideEffectsTab(medication: med),
                        _ => _RefillsTab(medication: med),
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border(top: BorderSide(color: AppColors.hairline))),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: medState.getTodayMedStatus(med) == MedCardVariant.taken
                      ? null
                      : () {
                          final medRules = medState.rules.where((r) => r.med.toLowerCase() == med.name.toLowerCase() && r.active).toList();
                          final takenCount = medState.todayTakenCounts[med.id!] ?? 0;

                          void logDose(ReminderRule rule) {
                            medState.logMedication(med.id!, MedCardVariant.taken);
                            final timeStr = DateFormat('h:mm a').format(DateTime.now());
                            historyState.logHistory(HistoryItem(
                              med: '${med.name} ${med.dose}',
                              date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              time: timeStr,
                              taken: true,
                              note: 'Took ${rule.time} dose',
                            ));
                            SuccessOverlay.showDoseLogged(context, medName: med.name, dose: med.dose);
                          }

                          if (medRules.length > 1) {
                            _showDoseSelector(
                              context: context,
                              title: 'Log which dose?',
                              med: med,
                              rules: medState.rules,
                              takenCount: takenCount,
                              onSelected: logDose,
                            );
                          } else if (medRules.isNotEmpty) {
                            logDose(medRules.first);
                          }
                        },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                      medState.getTodayMedStatus(med) == MedCardVariant.taken
                          ? 'Completed'
                          : 'Take Now · ${medState.getNextDoseTime(med)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: med.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedDialog(BuildContext context, Medication med) {
    final medState = context.read<MedicationProvider>();
    final nameController = TextEditingController(text: med.name);
    final doseController = TextEditingController(text: med.dose);
    final intakeController = TextEditingController(text: med.intakeQty.toStringAsFixed(med.intakeQty == med.intakeQty.toInt() ? 0 : 1));
    final supplyController = TextEditingController(text: med.supplyQty.toStringAsFixed(med.supplyQty == med.supplyQty.toInt() ? 0 : 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Edit Medication', style: TextStyle(color: AppColors.ink900, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: AppColors.ink900),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.ink500),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: med.color)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: doseController,
                style: TextStyle(color: AppColors.ink900),
                decoration: InputDecoration(
                  labelText: 'Dosage (Optional)',
                  labelStyle: TextStyle(color: AppColors.ink500),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: med.color)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: intakeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.ink900),
                decoration: InputDecoration(
                  labelText: 'Intake Amount (per dose)',
                  labelStyle: TextStyle(color: AppColors.ink500),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: med.color)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: supplyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.ink900),
                decoration: InputDecoration(
                  labelText: 'Remaining Supply',
                  labelStyle: TextStyle(color: AppColors.ink500),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: med.color)),
                ),
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
              final name = nameController.text.trim();
              final dose = doseController.text.trim();
              final intake = double.tryParse(intakeController.text) ?? med.intakeQty;
              final supply = double.tryParse(supplyController.text) ?? med.supplyQty;

              if (name.isNotEmpty) {
                final newMed = Medication(
                  id: med.id,
                  name: name,
                  dose: dose,
                  freq: med.freq,
                  color: med.color,
                  refillDays: med.refillDays,
                  description: med.description,
                  drugClass: med.drugClass,
                  sideEffects: med.sideEffects,
                  doctor: med.doctor,
                  notes: med.notes,
                  form: med.form,
                  intakeQty: intake,
                  supplyQty: supply,
                  initialSupply: med.initialSupply < supply ? supply : med.initialSupply,
                );
                medState.editMedication(med.id!, newMed);
                Navigator.of(context).pop();
                SuccessOverlay.showMedicationUpdated(context, medName: name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: med.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMedDialog(BuildContext context, Medication med) {
    final medState = context.read<MedicationProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Delete Medication', style: TextStyle(color: AppColors.ink900, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete ${med.name}? All associated alert rules will also be removed.',
          style: TextStyle(color: AppColors.ink700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.ink500)),
          ),
          ElevatedButton(
            onPressed: () {
              medState.removeMedication(med.id!);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close detail screen
              SuccessOverlay.showMedicationDeleted(context, medName: med.name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDoseSelector({
    required BuildContext context,
    required String title,
    required Medication med,
    required List<ReminderRule> rules,
    required int takenCount,
    required Function(ReminderRule rule) onSelected,
  }) {
    final medRules = rules.where((r) => r.med.toLowerCase() == med.name.toLowerCase() && r.active).toList();
    double parseTime(String timeStr) {
      try {
        final parts = timeStr.split(' ');
        if (parts.length != 2) return 0.0;
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);
        if (parts[1].toUpperCase() == 'PM' && hour < 12) {
          hour += 12;
        } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }
        return hour + (minute / 60.0);
      } catch (_) {
        return 0.0;
      }
    }
    medRules.sort((a, b) => parseTime(a.time).compareTo(parseTime(b.time)));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: medRules.length,
              separatorBuilder: (_, __) => Divider(color: AppColors.hairline),
              itemBuilder: (context, index) {
                final rule = medRules[index];
                final isTaken = index < takenCount;

                bool hasTimePassed(String timeStr) {
                  try {
                    final format = DateFormat('h:mm a');
                    final parsedTime = format.parse(timeStr.trim());
                    final now = DateTime.now();
                    final todayTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
                    return todayTime.isBefore(now);
                  } catch (_) {
                    return false;
                  }
                }
                final isPassed = hasTimePassed(rule.time);

                String statusText = 'Upcoming';
                Color statusColor = AppColors.ink500;
                IconData statusIcon = Icons.schedule_rounded;

                if (isTaken) {
                  statusText = 'Taken';
                  statusColor = AppColors.medGreen;
                  statusIcon = Icons.check_circle_rounded;
                } else if (isPassed) {
                  statusText = 'Missed';
                  statusColor = AppColors.medRed;
                  statusIcon = Icons.cancel_rounded;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(statusIcon, color: statusColor, size: 22),
                  title: Text(
                    rule.time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                  subtitle: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: isTaken ? null : () {
                    Navigator.of(context).pop();
                    onSelected(rule);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.ink500)),
            ),
          ],
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String val;
  final String label;
  const _StatPill({required this.val, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(val,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink500,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Medication medication;
  const _OverviewTab({required this.medication});
  @override
  Widget build(BuildContext context) {
    String definitionTitle = 'What is ${medication.name}?';
    Widget description = Text(
      medication.description ?? 'No description provided for ${medication.name}.',
      style: TextStyle(fontSize: 13, color: AppColors.ink700, height: 1.6),
    );

    final medState = context.watch<MedicationProvider>();
    final historyState = context.watch<HistoryProvider>();
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final List<Map<String, dynamic>> computedWeeklyData = List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));
      final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      
      // Determine if taken on this day from history
      bool taken = false;
      if (day.isAfter(today)) {
        taken = false;
      } else if (day.year == today.year && day.month == today.month && day.day == today.day) {
        taken = medState.todayMeds[medication.id!] == MedCardVariant.taken;
      } else {
        final dayItems = historyState.historyItems.where((h) {
          return h.med.toLowerCase().contains(medication.name.toLowerCase()) &&
              historyState.historyDateMatchesDay(h.date, day);
        });
        taken = dayItems.isNotEmpty && dayItems.any((h) => h.taken);
      }
      
      return {
        'day': days[index],
        'taken': taken,
      };
    });



    return Column(
      children: [
        _InfoCard(
          title: definitionTitle,
          child: description,
        ),
        if (medication.doctor != null || medication.notes != null) ...[
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Prescribing Info & Notes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (medication.doctor != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded, size: 16, color: AppColors.medBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Doctor / Pharmacy:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      medication.doctor!,
                      style: TextStyle(fontSize: 13, color: AppColors.ink700),
                    ),
                  ),
                ],
                if (medication.doctor != null && medication.notes != null)
                  const SizedBox(height: 12),
                if (medication.notes != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 16, color: AppColors.medBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Instructions & Notes:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      medication.notes!,
                      style: TextStyle(fontSize: 13, color: AppColors.ink700, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _InfoCard(
          title: 'This Week',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: computedWeeklyData.map((d) {
              final taken = d['taken'] as bool;
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: taken
                          ? AppColors.medGreen
                          : (AppColors.isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                        taken ? Icons.check_rounded : Icons.close_rounded,
                        size: 14,
                        color: taken
                            ? Colors.white
                            : (AppColors.isDark ? const Color(0xFFFCA5A5) : AppColors.medRed)),
                  ),
                  const SizedBox(height: 5),
                  Text(d['day'] as String,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink400)),
                ],
              );
            }).toList(),
          ),
        ),

      ],
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  final Medication medication;
  const _ScheduleTab({required this.medication});

  bool _hasTimePassed(String timeStr) {
    try {
      final cleanTime = timeStr.trim();
      final format = DateFormat('h:mm a');
      final parsedTime = format.parse(cleanTime);
      final now = DateTime.now();
      final todayTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      return todayTime.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  double _parseTimeToDouble(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return 0.0;
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return 0.0;
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      if (parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      return hour + (minute / 60.0);
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final medState = context.watch<MedicationProvider>();
    final historyState = context.watch<HistoryProvider>();

    final rawTimeStr = medication.freq.contains('·') ? medication.freq.split('·').last.trim() : medication.freq;
    final times = rawTimeStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    times.sort((a, b) => _parseTimeToDouble(a).compareTo(_parseTimeToDouble(b)));

    final todayTakenCount = medState.todayTakenCounts[medication.id!] ?? 0;

    String instructions = medication.description ?? 'Take as directed by your physician. Best taken at the same time each day.';

    return _InfoCard(
      title: 'Dosing Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(times.length, (i) {
            final time = times[i];
            final isTaken = i < todayTakenCount;
            final isPassed = _hasTimePassed(time);

            String statusText;
            Color statusColor;
            Color cardBg;
            Color cardBorder;
            IconData statusIcon;
            Color iconColor;

            if (isTaken) {
              final todayItems = historyState.historyItems.where((h) =>
                  h.med.toLowerCase().contains(medication.name.toLowerCase()) &&
                  historyState.historyDateMatchesDay(h.date, DateTime.now()) &&
                  h.taken).toList();
              final actualTime = todayItems.length > i ? todayItems[i].time : time;

              statusText = 'Taken today at $actualTime';
              statusColor = AppColors.isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
              cardBg = AppColors.isDark ? const Color(0xFF062F17) : AppColors.medGreenLight;
              cardBorder = AppColors.isDark ? const Color(0xFF15803D) : AppColors.medGreenBorder;
              statusIcon = Icons.check_circle_rounded;
              iconColor = AppColors.medGreen;
            } else if (isPassed) {
              statusText = 'Missed';
              statusColor = AppColors.medRed;
              cardBg = AppColors.isDark ? const Color(0xFF1A0B0B) : AppColors.medRedLight;
              cardBorder = AppColors.isDark ? const Color(0xFF7F1D1D) : AppColors.medRedBorder;
              statusIcon = Icons.cancel_rounded;
              iconColor = AppColors.medRed;
            } else {
              statusText = 'Scheduled for today';
              statusColor = AppColors.ink500;
              cardBg = AppColors.screenBg;
              cardBorder = AppColors.border;
              statusIcon = Icons.schedule_rounded;
              iconColor = AppColors.ink400;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 20, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(time,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink900)),
                          const SizedBox(height: 2),
                          Text(statusText,
                              style: TextStyle(
                                  fontSize: 11, color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.screenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.medBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instructions,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ink500,
                        height: 1.4,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideEffectsTab extends StatelessWidget {
  final Medication medication;
  const _SideEffectsTab({required this.medication});

  List<Map<String, dynamic>> get sideEffectsList {
    if (medication.sideEffects != null && medication.sideEffects!.isNotEmpty) {
      final list = medication.sideEffects!.split(',');
      return List.generate(list.length, (i) {
        final s = list[i].trim();
        return {
          'effect': s,
          'severity': 'See package insert',
          'color': const Color(0xFF6B7280),
        };
      });
    }
    return const [
      {'effect': 'No recorded side effects', 'severity': '-', 'color': Color(0xFF6B7280)},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: 'Side Effects to Watch',
          child: Column(
            children: sideEffectsList.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.screenBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: s['color'] as Color,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['effect'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink900)),
                            Text('Severity: ${s['severity']}',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.ink400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.isDark ? const Color(0xFF450A0A) : AppColors.medRedLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠️ Seek immediate care if:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))),
              const SizedBox(height: 4),
              Text(
                  'You experience a severe allergic reaction, difficulty breathing, or any symptom that concerns you. Always consult your doctor or pharmacist.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D),
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RefillsTab extends StatelessWidget {
  final Medication medication;
  const _RefillsTab({required this.medication});

  String _refillDueDate(int days) {
    final date = DateTime.now().add(Duration(days: days));
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final medState = context.watch<MedicationProvider>();
    final med = medState.meds.firstWhere((m) => m.id == medication.id, orElse: () => medication);

    final timesStr = med.freq.contains('·') ? med.freq.split('·').last : '';
    final timesCount = timesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).length;
    final dailyIntake = med.intakeQty * (timesCount > 0 ? timesCount : 1);
    final daysRemaining = dailyIntake > 0 ? (med.supplyQty / dailyIntake).ceil() : 0;

    final total = med.initialSupply;
    final remaining = med.supplyQty;
    final progressVal = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;

    String unit = 'pills';
    final formLower = (med.form ?? 'tablet').toLowerCase();
    if (formLower.contains('tablet')) {
      unit = 'tablets';
    } else if (formLower.contains('capsule')) {
      unit = 'capsules';
    } else if (formLower.contains('liquid')) {
      unit = 'ml';
    } else if (formLower.contains('injection')) {
      unit = 'injections';
    }

    final remainingStr = remaining.toStringAsFixed(remaining == remaining.toInt() ? 0 : 1);
    final totalStr = total.toStringAsFixed(total == total.toInt() ? 0 : 1);

    return Column(
      children: [
        _InfoCard(
          title: 'Refill Status',
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(remainingStr,
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: med.color,
                      letterSpacing: -1.2)),
              Text('$unit remaining',
                  style: TextStyle(fontSize: 13, color: AppColors.ink500)),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 8,
                  backgroundColor: med.color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(med.color),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 $unit',
                      style: TextStyle(fontSize: 10, color: AppColors.ink400)),
                  Text('$totalStr $unit',
                      style: TextStyle(fontSize: 10, color: AppColors.ink400)),
                ],
              ),
              const SizedBox(height: 12),
              _KV(k: 'Days remaining', v: '$daysRemaining days'),
              _KV(
                  k: 'Refill due',
                  v: _refillDueDate(daysRemaining),
                  vColor: daysRemaining <= 7
                      ? AppColors.medRed
                      : (AppColors.isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B))),

            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBg,
                  title: const Text('Confirm Refill'),
                  content: Text(
                      'Would you like to reset ${med.name} supply tracker back to $totalStr $unit?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final newMed = Medication(
                          id: med.id,
                          name: med.name,
                          dose: med.dose,
                          freq: med.freq,
                          color: med.color,
                          refillDays: daysRemaining,
                          description: med.description,
                          drugClass: med.drugClass,
                          sideEffects: med.sideEffects,
                          doctor: med.doctor,
                          notes: med.notes,
                          form: med.form,
                          intakeQty: med.intakeQty,
                          supplyQty: med.initialSupply,
                          initialSupply: med.initialSupply,
                        );
                        context.read<MedicationProvider>().editMedication(med.id!, newMed);
                        Navigator.of(context).pop();
                        SuccessOverlay.showRefillLogged(context, medName: med.name);
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: med.color.withValues(alpha: 0.12),
              foregroundColor: med.color,
              side: BorderSide(
                  color: med.color.withValues(alpha: 0.35), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Refill / Reset Supply',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  final Color? vColor;
  const _KV({required this.k, required this.v, this.vColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style: TextStyle(fontSize: 12, color: AppColors.ink500)),
          Text(v,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: vColor ?? AppColors.ink900)),
        ],
      ),
    );
  }
}
