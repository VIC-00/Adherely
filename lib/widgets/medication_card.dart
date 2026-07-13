import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../theme/app_colors.dart';

class MedicationCard extends StatefulWidget {
  final MedCardVariant variant;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onTakeNow;
  final VoidCallback? onLogTaken;
  final VoidCallback? onReschedule;
  final String name;
  final String dose;
  final String time;
  final int? refillDays;
  final Color? color;
  final int takenCount;

  const MedicationCard({
    super.key,
    required this.variant,
    this.compact = false,
    this.onTap,
    this.onTakeNow,
    this.onLogTaken,
    this.onReschedule,
    this.name = '',
    this.dose = '',
    this.time = '',
    this.refillDays,
    this.color,
    this.takenCount = 0,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  bool _taken = false;
  bool _rescheduled = false;

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final child = switch (widget.variant) {
      MedCardVariant.upcoming => _UpcomingCard(
          compact: widget.compact,
          name: widget.name,
          dose: widget.dose,
          time: widget.time,
          refillDays: widget.refillDays,
          onTakeNow: widget.onTakeNow,
          color: widget.color,
          takenCount: widget.takenCount,
        ),
      MedCardVariant.taken => _TakenCard(
          compact: widget.compact,
          name: widget.name,
          dose: widget.dose,
          time: widget.time,
          refillDays: widget.refillDays,
          takenCount: widget.takenCount,
        ),
      MedCardVariant.missed => _MissedCard(
          compact: widget.compact,
          name: widget.name,
          dose: widget.dose,
          time: widget.time,
          taken: _taken,
          rescheduled: _rescheduled,
          refillDays: widget.refillDays,
          takenCount: widget.takenCount,
          onTaken: () {
            setState(() => _taken = true);
            if (widget.onLogTaken != null) widget.onLogTaken!();
          },
          onReschedule: () {
            setState(() => _rescheduled = true);
            if (widget.onReschedule != null) widget.onReschedule!();
          },
        ),
    };

    return Semantics(
      button: true,
      label: 'Medication card for ${widget.name}, ${widget.dose}. Status: ${widget.variant.name}.',
      hint: 'Double tap to view details',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final bool compact;
  final String name;
  final String dose;
  final String time;
  final int? refillDays;
  final VoidCallback? onTakeNow;
  final Color? color;
  final int takenCount;

  const _UpcomingCard({
    required this.compact,
    required this.name,
    required this.dose,
    required this.time,
    this.refillDays,
    this.onTakeNow,
    this.color,
    required this.takenCount,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 14.0 : 18.0;
    final themeColor = color ?? const Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: themeColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 12 : 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColor,
                  themeColor.withValues(alpha: 0.85),
                  themeColor.withValues(alpha: 0.7),
                ],
                stops: const [0, 0.65, 1],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'UPCOMING',
                            style: TextStyle(
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFCD34D),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 16 : 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        dose,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTimePills(time, takenCount, false),
                  ],
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 12 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (refillDays != null && refillDays! <= 7)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: compact ? 10 : 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.isDark ? const Color(0xFF2C2415) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFBBF24).withValues(alpha: AppColors.isDark ? 0.3 : 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            refillDays == 0
                                ? 'Out of supply! Refill immediately.'
                                : 'Refill Soon — only $refillDays day${refillDays == 1 ? '' : 's'} left',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTakeNow,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('Take Now',
                        style: TextStyle(fontSize: compact ? 14 : 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: compact ? 12 : 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                // Only show plain refill text when NOT already showing the urgent amber banner above
                if (refillDays == null || refillDays! > 7)
                  Text(
                    refillDays != null
                        ? 'Refill in $refillDays day${refillDays == 1 ? '' : 's'}'
                        : 'Refill info unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.ink400,
                      fontWeight: FontWeight.w400,
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


// ------------------------------------------------------------------ Taken
class _TakenCard extends StatelessWidget {
  final bool compact;
  final String name;
  final String dose;
  final String time;
  final int? refillDays;
  final int takenCount;

  const _TakenCard({
    required this.compact,
    required this.name,
    required this.dose,
    required this.time,
    this.refillDays,
    required this.takenCount,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 14.0 : 18.0;
    return Opacity(
      opacity: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.medGreenBorder, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 20,
                vertical: compact ? 12 : 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: compact ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: compact ? 16 : 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          dose,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTimePills(time, takenCount, true),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 20,
                vertical: compact ? 10 : 14,
              ),
              color: AppColors.isDark ? const Color(0xFF062F17) : AppColors.medGreenLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text(
                        'Taken today ✓',
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                        ),
                      ),
                      const Spacer(),
                      if (refillDays != null && refillDays! <= 7)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.isDark ? const Color(0xFF2C2415) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⚠️ $refillDays d left',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                            ),
                          ),
                        )
                      else
                        Text(
                          refillDays != null ? '$refillDays d left' : '',
                          style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.ink500),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.medGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Missed

class _MissedCard extends StatelessWidget {
  final bool compact;
  final bool taken;
  final bool rescheduled;
  final VoidCallback onTaken;
  final VoidCallback onReschedule;
  final String name;
  final String dose;
  final String time;
  final int? refillDays;
  final int takenCount;

  const _MissedCard({
    required this.compact,
    required this.taken,
    required this.rescheduled,
    required this.onTaken,
    required this.onReschedule,
    required this.name,
    required this.dose,
    required this.time,
    this.refillDays,
    required this.takenCount,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 14.0 : 18.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.medRedBorder, width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.medRed.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 12 : 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MISSED',
                            style: TextStyle(
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ACTION REQUIRED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 16 : 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        dose,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTimePills(time, takenCount, false),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 12 : 14,
            ),
            color: AppColors.isDark ? const Color(0xFF450A0A) : AppColors.medRedLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_rounded, size: 13, color: AppColors.medRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Missed dose — action required',
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    if (refillDays != null && refillDays! <= 7)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.isDark ? const Color(0xFF2C2415) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '⚠️ $refillDays d left',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onTaken,
                        icon: taken ? const Icon(Icons.check_rounded, size: 13) : const SizedBox.shrink(),
                        label: Text(taken ? 'Logged' : 'Log as Taken',
                            style: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: taken ? const Color(0xFF15803D) : const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: taken ? 0 : 2,
                          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReschedule,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: rescheduled
                              ? const Color(0xFF374151)
                              : (AppColors.isDark ? AppColors.cardBg : Colors.white),
                          foregroundColor: rescheduled ? const Color(0xFF9CA3AF) : AppColors.ink900,
                          side: BorderSide(
                              color: rescheduled ? const Color(0xFF6B7280) : AppColors.border, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(rescheduled ? 'Rescheduled' : 'Reschedule',
                            style: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildTimePills(String timeStr, int takenCount, bool isTakenState) {
  final times = timeStr.split(',').map((t) => t.trim()).toList();
  return Wrap(
    spacing: 5,
    runSpacing: 4,
    alignment: WrapAlignment.end,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: times.map((t) {
      final int idx = times.indexOf(t);
      final bool isDoseTaken = isTakenState || idx < takenCount;
      final bool isDosePassed = _hasTimePassed(t);

      Color pillBg;
      Color pillBorder;
      IconData pillIcon;

      if (isDoseTaken) {
        pillBg = Colors.white.withValues(alpha: 0.25);
        pillBorder = Colors.white.withValues(alpha: 0.4);
        pillIcon = Icons.check_rounded;
      } else if (isDosePassed) {
        pillBg = const Color(0xFFEF4444).withValues(alpha: 0.35);
        pillBorder = const Color(0xFFEF4444).withValues(alpha: 0.6);
        pillIcon = Icons.close_rounded;
      } else {
        pillBg = Colors.white.withValues(alpha: 0.1);
        pillBorder = Colors.white.withValues(alpha: 0.2);
        pillIcon = Icons.access_time_rounded;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: pillBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pillIcon, size: 9, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

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
