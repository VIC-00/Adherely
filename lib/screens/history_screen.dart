import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

const Map<DayStatus, Color> _statusColor = {
  DayStatus.taken: Color(0xFF22C55E),
  DayStatus.missed: Color(0xFFEF4444),
  DayStatus.partial: Color(0xFFF59E0B),
  DayStatus.future: Colors.transparent,
  DayStatus.empty: Colors.transparent,
};

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final medState = context.watch<MedicationProvider>();
    final historyState = context.watch<HistoryProvider>();

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 4),
                    Text(historyState.currentHistoryMonthLabel,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.6)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _HeaderStat(
                            v: '${historyState.calculateWeeklyAdherence().toStringAsFixed(0)}%',
                            l: 'Adherence'),
                        const SizedBox(width: 16),
                        _HeaderStat(
                            v: '${historyState.calculateStreak(medState.todayMeds)}',
                            l: 'Day Streak'),
                        const SizedBox(width: 16),
                        _HeaderStat(
                            v: '${historyState.missedDoses}', l: 'Missed'),
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
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(historyState.currentHistoryMonthLabel,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink900)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: historyState.previousHistoryMonth,
                              child: const _ChevronBtn(
                                  icon: Icons.chevron_left_rounded),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: historyState.nextHistoryMonth,
                              child: const _ChevronBtn(
                                  icon: Icons.chevron_right_rounded),
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
                                  child: Text(d,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink400)),
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
                            final isToday =
                                historyState.currentHistoryMonth.year ==
                                        now.year &&
                                    historyState.currentHistoryMonth.month ==
                                        now.month &&
                                    cell.day == now.day;
                            final Color color = _statusColor[cell.status]!;

                            Widget cellWidget = Container(
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cell.status == DayStatus.empty
                                    ? Colors.transparent
                                    : color,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(
                                        color: AppColors.isDark
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF1D4ED8),
                                        width: 2)
                                    : null,
                              ),
                              child: cell.day > 0
                                  ? Text(
                                      '${cell.day}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isToday
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color:
                                            (cell.status == DayStatus.taken ||
                                                    cell.status ==
                                                        DayStatus.missed ||
                                                    cell.status ==
                                                        DayStatus.partial)
                                                ? Colors.white
                                                : AppColors.ink700,
                                      ),
                                    )
                                  : null,
                            );

                            if (cell.day > 0 &&
                                cell.status != DayStatus.future &&
                                cell.status != DayStatus.empty) {
                              cellWidget = GestureDetector(
                                onTap: () => _showDayDosesDialog(
                                    context, historyState, cell.day),
                                child: cellWidget,
                              );
                            }

                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: cellWidget,
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Dose Log',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink900)),
                    ),
                    if (historyState.historyItems.isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.border, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text('No logged doses yet.',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink400)),
                      )
                    else
                      for (final item in historyState.historyItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1))
                              ],
                              border: Border(
                                  left: BorderSide(
                                      color: item.taken
                                          ? AppColors.medGreen
                                          : AppColors.medRed,
                                      width: 3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: item.taken
                                        ? (AppColors.isDark
                                            ? const Color(0xFF14532D)
                                                .withValues(alpha: 0.3)
                                            : AppColors.medGreenLight)
                                        : (AppColors.isDark
                                            ? const Color(0xFF7F1D1D)
                                                .withValues(alpha: 0.3)
                                            : AppColors.medRedLight),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.taken
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
                                    size: 14,
                                    color: item.taken
                                        ? AppColors.medGreen
                                        : AppColors.medRed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.med,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink900)),
                                      const SizedBox(height: 1),
                                      Text(_displayDate(item.date),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.ink500)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(item.time,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: item.taken
                                                ? (AppColors.isDark
                                                    ? const Color(0xFF4ADE80)
                                                    : const Color(0xFF15803D))
                                                : (AppColors.isDark
                                                    ? const Color(0xFFFCA5A5)
                                                    : const Color(
                                                        0xFFB91C1C)))),
                                    const SizedBox(height: 1),
                                    Text(item.note,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.ink400)),
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

  String _displayDate(String dateStr) {
    try {
      // Handle legacy "Today" / "Yesterday" strings from old DB rows
      if (dateStr == 'Today' || dateStr.startsWith('Today,')) {
        return 'Today';
      }
      if (dateStr == 'Yesterday' || dateStr.startsWith('Yesterday,')) {
        return 'Yesterday';
      }
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      }
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _showDayDosesDialog(
      BuildContext context, HistoryProvider historyState, int day) {
    final doses = historyState.getDosesForDay(day);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text(
            'Doses on Day $day',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900),
          ),
          content: doses.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No doses logged on this day.',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.ink500)),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: doses.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: AppColors.hairline),
                      itemBuilder: (context, index) {
                      final item = doses[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              item.taken
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: item.taken
                                  ? AppColors.medGreen
                                  : AppColors.medRed,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.med,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink900),
                                  ),
                                  if (item.note.isNotEmpty)
                                    Text(
                                      item.note,
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: AppColors.ink400),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              item.time,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.taken
                                    ? AppColors.medGreen
                                    : AppColors.medRed,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: AppColors.medBlue)),
            ),
          ],
        );
      },
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
        Text(v,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        Text(l,
            style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500)),
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
      decoration: BoxDecoration(
          color: AppColors.isDark
              ? const Color(0xFF374151)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8)),
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
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: AppColors.ink500,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
