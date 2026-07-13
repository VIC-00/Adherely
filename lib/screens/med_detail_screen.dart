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
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1D4ED8),
                            Color(0xFF2563EB),
                            Color(0xFF3B82F6)
                          ],
                          stops: [0, 0.7, 1],
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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.more_horiz_rounded,
                                    size: 18, color: Colors.white),
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
                           Text(widget.medication.name,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.6)),
                          Text(
                            '${widget.medication.dose} · ${widget.medication.drugClass ?? "Medication"}',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 14),
                           Row(
                            children: [
                              _StatPill(val: widget.medication.freq.contains('·') ? widget.medication.freq.split('·').last.trim() : widget.medication.freq, label: 'Schedule'),
                              const SizedBox(width: 10),
                              _StatPill(val: '${historyState.calculateStreak(medState.todayMeds)} days', label: 'Streak'),
                              const SizedBox(width: 10),
                              _StatPill(val: '${medState.calculateAdherence().toStringAsFixed(0)}%', label: 'Adherence'),
                            ],
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
                                              ? const Color(0xFF2563EB)
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
                                        ? const Color(0xFF2563EB)
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
                        0 => _OverviewTab(medication: widget.medication),
                        1 => _ScheduleTab(medication: widget.medication),
                        2 => _SideEffectsTab(medication: widget.medication),
                        _ => _RefillsTab(medication: widget.medication),
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
                  onPressed: medState.todayMeds[widget.medication.id!] == MedCardVariant.taken
                      ? null
                      : () {
                          medState.logMedication(widget.medication.id!, MedCardVariant.taken);
                          SuccessOverlay.showDoseLogged(context,
                              medName: widget.medication.name,
                              dose: widget.medication.dose);
                        },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                      medState.todayMeds[widget.medication.id!] == MedCardVariant.taken
                          ? 'Completed'
                          : 'Take Now · ${widget.medication.freq.contains('·') ? widget.medication.freq.split('·').last.trim() : widget.medication.freq}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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

  @override
  Widget build(BuildContext context) {
    final medState = context.watch<MedicationProvider>();
    final historyState = context.watch<HistoryProvider>();
    final variant = medState.todayMeds[medication.id!] ?? MedCardVariant.upcoming;
    final timeStr = medication.freq.contains('·') ? medication.freq.split('·').last.trim() : medication.freq;

    String statusText = 'Scheduled for today';
    Color statusColor = AppColors.ink500;
    if (variant == MedCardVariant.taken) {
      final todayItems = historyState.historyItems.where((h) => 
          h.med.contains(medication.name) && 
          historyState.historyDateMatchesDay(h.date, DateTime.now()) &&
          h.taken);
      final takenTime = todayItems.isNotEmpty ? todayItems.first.time : timeStr;
      statusText = 'Taken today at $takenTime';
      statusColor = AppColors.isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    } else if (variant == MedCardVariant.missed) {
      statusText = 'Missed today';
      statusColor = AppColors.medRed;
    }

    String instructions = medication.description ?? 'Take as directed by your physician. Best taken at the same time each day.';

    return _InfoCard(
      title: 'Dosing Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: variant == MedCardVariant.taken
                  ? (AppColors.isDark ? const Color(0xFF062F17) : AppColors.medGreenLight)
                  : AppColors.screenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: variant == MedCardVariant.taken
                      ? (AppColors.isDark ? const Color(0xFF15803D) : AppColors.medGreenBorder)
                      : AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: variant == MedCardVariant.taken ? AppColors.medGreen : AppColors.ink400, shape: BoxShape.circle),
                  child: Icon(variant == MedCardVariant.taken ? Icons.check_rounded : Icons.schedule_rounded,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeStr,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(8)),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 11, color: AppColors.ink500, height: 1.4),
                children: [
                  TextSpan(
                      text: 'Instructions: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink700)),
                  TextSpan(text: instructions),
                ],
              ),
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
    final isTwiceDaily = medication.freq.contains('Twice');
    final isThreeTimesDaily = medication.freq.contains('Three times');
    final factor = isThreeTimesDaily ? 3 : (isTwiceDaily ? 2 : 1);
    final pillsRemaining = medication.refillDays * factor;
    final totalPills = medication.refillDays * factor; // same as remaining until user logs refill
    final progressVal = totalPills > 0 ? (pillsRemaining / totalPills).clamp(0.0, 1.0) : 0.0;



    return Column(
      children: [
        _InfoCard(
          title: 'Refill Status',
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text('$pillsRemaining',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      letterSpacing: -1.2)),
              Text('pills remaining',
                  style: TextStyle(fontSize: 13, color: AppColors.ink500)),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 8,
                  backgroundColor: AppColors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                  valueColor: AlwaysStoppedAnimation(AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 pills',
                      style: TextStyle(fontSize: 10, color: AppColors.ink400)),
                  Text('$totalPills pills',
                      style: TextStyle(fontSize: 10, color: AppColors.ink400)),
                ],
              ),
              const SizedBox(height: 12),
              _KV(k: 'Days remaining', v: '${medication.refillDays} days'),
              _KV(
                  k: 'Refill due',
                  v: _refillDueDate(medication.refillDays),
                  vColor: medication.refillDays <= 7
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
                  title: const Text('Confirm Refill'),
                  content: Text(
                      'Would you like to reset ${medication.name} supply tracker back to 30 days?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final newMed = Medication(
                          id: medication.id,
                          name: medication.name,
                          dose: medication.dose,
                          freq: medication.freq,
                          color: medication.color,
                          refillDays: 30,
                          description: medication.description,
                          drugClass: medication.drugClass,
                          sideEffects: medication.sideEffects,
                        );
                        context.read<MedicationProvider>().editMedication(medication.id!, newMed);
                        Navigator.of(context).pop();
                        SuccessOverlay.showRefillLogged(context, medName: medication.name);
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.isDark ? const Color(0xFF1E3A8A) : AppColors.medBlueLight,
              foregroundColor: AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              side: BorderSide(
                  color: AppColors.isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE), width: 1.5),
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
