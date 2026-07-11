import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';
import '../widgets/medication_card.dart';
import 'med_detail_screen.dart';
import 'add_med_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onOpenReminders;
  const DashboardScreen({super.key, this.onOpenReminders});
  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final medState = context.watch<MedicationProvider>();
    final settingsState = context.watch<SettingsProvider>();
    final profileName = settingsState.profile?.name ?? 'User';
    final profileInitial = profileName.isNotEmpty ? profileName[0].toUpperCase() : 'U';
    final historyState = context.watch<HistoryProvider>();
    final meds = medState.meds;
    final total = meds.length;
    final taken =
        meds.where((m) => medState.getTodayMedStatus(m) == MedCardVariant.taken).length;
    final missed =
        meds.where((m) => medState.getTodayMedStatus(m) == MedCardVariant.missed).length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.isDark
              ? [const Color(0xFF111827), const Color(0xFF1F2937)]
              : [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            historyState.formatDateLabel(DateTime.now()),
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.ink500,
                                fontWeight: FontWeight.w500),
                          ),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink900,
                                letterSpacing: -0.6,
                                height: 1.2,
                              ),
                              children: [
                                TextSpan(text: '${(DateTime.now().hour < 12 ? 'Good morning' : DateTime.now().hour < 17 ? 'Good afternoon' : 'Good evening')},\n'),
                                TextSpan(
                                    text: '$profileName!',
                                    style: TextStyle(color: AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onOpenReminders,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.medBlue
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(profileInitial,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                          if (medState.rules.where((r) => r.active).isNotEmpty)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${medState.rules.where((r) => r.active).length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Streak badge
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: AppColors.isDark ? 0.15 : 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _FlameIcon(),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CURRENT STREAK',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.white.withValues(alpha: 0.75))),
                          Text('${historyState.calculateStreak(medState.dynamicTodayMeds)} Days',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  height: 1)),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              left: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personal best',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w500)),
                            Text('${historyState.getPersonalBestStreak(historyState.calculateStreak(medState.dynamicTodayMeds))} days',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.isDark ? const Color(0xFF1F2937) : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: historyState.calculateWeeklyAdherence() / 100.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF2563EB),
                                Color(0xFF60A5FA)
                              ]),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${historyState.calculateWeeklyAdherence().toStringAsFixed(0)}% this week',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))),
                  ],
                ),
              ),

              // Quick stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    _StatChip(
                        val: '$total',
                        label: 'Today',
                        color: AppColors.medBlue,
                        bg: AppColors.medBlueLight),
                    const SizedBox(width: 8),
                    _StatChip(
                        val: '$taken',
                        label: 'Taken',
                        color: AppColors.medGreen,
                        bg: AppColors.medGreenLight),
                    const SizedBox(width: 8),
                    _StatChip(
                        val: '$missed',
                        label: 'Missed',
                        color: AppColors.medRed,
                        bg: AppColors.medRedLight),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Medications",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900)),
                    Text('$taken of $total done',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.isDark ? const Color(0xFF60A5FA) : AppColors.medBlue)),
                  ],
                ),
              ),

              if (meds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : AppColors.medBlueLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('💊', style: TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Medications Logged',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your scheduled daily medications and intake reminders will appear here once added.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AddMedScreen()),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Your First Medication', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Column(
                    children: meds.map((med) {
                      final variant = medState.getTodayMedStatus(med);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MedicationCard(
                          variant: variant,
                          compact: true,
                          name: med.name,
                          dose: med.dose,
                          time: med.freq.contains('·')
                              ? med.freq.split('·').last.trim()
                              : med.freq,
                          refillDays: med.refillDays,
                          color: med.color,
                          onTakeNow: () {
                            medState.logMedication(med.id!, MedCardVariant.taken);
                            final timeStr = DateFormat('h:mm a').format(DateTime.now());
                            historyState.logHistory(HistoryItem(
                              med: '${med.name} ${med.dose}',
                              date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              time: timeStr,
                              taken: true,
                              note: 'On time',
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${med.name} marked as taken!')),
                            );
                          },
                          onLogTaken: () {
                            medState.logMedication(med.id!, MedCardVariant.taken);
                            final timeStr = DateFormat('h:mm a').format(DateTime.now());
                            historyState.logHistory(HistoryItem(
                              med: '${med.name} ${med.dose}',
                              date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              time: timeStr,
                              taken: true,
                              note: 'Logged late',
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${med.name} marked as taken!')),
                            );
                          },
                          onReschedule: () async {
                            final oldTime = med.freq.contains('·')
                                ? med.freq.split('·').last.trim().split(',').first.trim()
                                : med.freq;
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
                              final newTime = '$hour:$minute $period';
                              
                              await medState.rescheduleRule(med.id!, oldTime, newTime);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${med.name} rescheduled to $newTime!')),
                                );
                              }
                            }
                          },
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => MedDetailScreen(medication: med)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String val;
  final String label;
  final Color color;
  final Color bg;
  const _StatChip(
      {required this.val,
      required this.label,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.isDark ? AppColors.cardBg : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.isDark ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: AppColors.isDark ? 1.5 : 0,
          ),
        ),
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.75))),
          ],
        ),
      ),
    );
  }
}

class _FlameIcon extends StatelessWidget {
  const _FlameIcon();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Icon(Icons.local_fire_department_rounded,
          color: Color(0xFF93C5FD), size: 20),
    );
  }
}
