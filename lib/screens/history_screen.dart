import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';

const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];



const Map<DayStatus, Color> _statusColor = {
  DayStatus.taken: Color(0xFF22C55E),
  DayStatus.missed: Color(0xFFEF4444),
  DayStatus.partial: Color(0xFFF59E0B),
  DayStatus.future: Color(0xFFE5E7EB),
  DayStatus.empty: Colors.transparent,
};



class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final medState = context.watch<MedicationProvider>();
//     final vitalsState = context.watch<VitalsProvider>();
//     final settingsState = context.watch<SettingsProvider>();
    final historyState = context.watch<HistoryProvider>();
    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADHERENCE HISTORY',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 4),
                    Text(historyState.currentHistoryMonthLabel,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _HeaderStat(v: '${medState.calculateAdherence()}%', l: 'Adherence'),
                        const SizedBox(width: 16),
                        _HeaderStat(v: '${historyState.calculateStreak(medState.todayMeds)}', l: 'Day Streak'),
                        const SizedBox(width: 16),
                        _HeaderStat(v: '${historyState.missedDoses}', l: 'Missed'),
                      ],
                    ),
                  ],
                ),
              ),

              // Calendar card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(historyState.currentHistoryMonthLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: historyState.previousHistoryMonth,
                              child: const _ChevronBtn(icon: Icons.chevron_left_rounded),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: historyState.nextHistoryMonth,
                              child: const _ChevronBtn(icon: Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _days
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.ink400)),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    for (final row in historyState.calRows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: row.map((cell) {
                            final now = DateTime.now();
                            final isToday = historyState.currentHistoryMonth.year == now.year && historyState.currentHistoryMonth.month == now.month && cell.day == now.day;
                            final color = _statusColor[cell.status]!;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Container(
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: cell.status == DayStatus.empty ? Colors.transparent : color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isToday ? Border.all(color: const Color(0xFF1D4ED8), width: 2) : null,
                                  ),
                                  child: cell.day > 0
                                      ? Text(
                                          '${cell.day}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                            color: (cell.status == DayStatus.taken || cell.status == DayStatus.missed || cell.status == DayStatus.partial)
                                                ? Colors.white
                                                : const Color(0xFF374151),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: Color(0xFF22C55E), label: 'Taken'),
                        SizedBox(width: 12),
                        _LegendDot(color: Color(0xFFEF4444), label: 'Missed'),
                        SizedBox(width: 12),
                        _LegendDot(color: Color(0xFFF59E0B), label: 'Partial'),
                      ],
                    ),
                  ],
                ),
              ),

              // Dose log
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Dose Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                    ),
                    for (final item in historyState.historyItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                            border: Border(left: BorderSide(color: item.taken ? AppColors.medGreen : AppColors.medRed, width: 3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: item.taken ? AppColors.medGreenLight : AppColors.medRedLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.taken ? Icons.check_rounded : Icons.close_rounded,
                                  size: 14,
                                  color: item.taken ? AppColors.medGreen : AppColors.medRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.med,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                                    const SizedBox(height: 1),
                                    Text(item.date, style: const TextStyle(fontSize: 11, color: AppColors.ink500)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(item.time,
                                      style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w700,
                                          color: item.taken ? const Color(0xFF15803D) : const Color(0xFFB91C1C))),
                                  const SizedBox(height: 1),
                                  Text(item.note, style: const TextStyle(fontSize: 10, color: AppColors.ink400)),
                                ],
                              ),
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
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String v;
  final String l;
  const _HeaderStat({required this.v, required this.l});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(l, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.65), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ChevronBtn extends StatelessWidget {
  final IconData icon;
  const _ChevronBtn({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: AppColors.ink500),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.ink500, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
