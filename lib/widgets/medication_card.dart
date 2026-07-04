import 'package:flutter/material.dart';
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

  const MedicationCard({
    super.key,
    required this.variant,
    this.compact = false,
    this.onTap,
    this.onTakeNow,
    this.onLogTaken,
    this.onReschedule,
    this.name = 'Lisinopril',
    this.dose = '10mg · Oral tablet',
    this.time = '8:00 AM',
    this.refillDays,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  bool _taken = false;
  bool _rescheduled = false;

  @override
  Widget build(BuildContext context) {
    final child = switch (widget.variant) {
      MedCardVariant.upcoming => _UpcomingCard(
          compact: widget.compact,
          name: widget.name,
          dose: widget.dose,
          time: widget.time,
          refillDays: widget.refillDays,
          onTakeNow: widget.onTakeNow,
        ),
      MedCardVariant.taken => _TakenCard(
          compact: widget.compact,
          name: widget.name,
          dose: widget.dose,
          refillDays: widget.refillDays,
        ),
      MedCardVariant.missed => _MissedCard(
          compact: widget.compact,
          name: widget.name,
          dose: widget.dose,
          time: widget.time,
          taken: _taken,
          rescheduled: _rescheduled,
          refillDays: widget.refillDays,
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

  const _UpcomingCard({
    required this.compact,
    required this.name,
    required this.dose,
    required this.time,
    this.refillDays,
    this.onTakeNow,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 14.0 : 18.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x333B82F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.medBlue.withValues(alpha: 0.18),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                stops: [0, 0.6, 1],
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
                        vertical: compact ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 5),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_rounded, size: 10, color: Color(0xFFFCD34D)),
                          SizedBox(width: 4),
                          Text(
                            'Sync Pending',
                            style: TextStyle(
                              color: Color(0xFFFCD34D),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 14,
                    vertical: compact ? 8 : 10,
                  ),
                  margin: EdgeInsets.only(bottom: compact ? 12 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.medOrange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up_rounded, size: 22, color: AppColors.medOrange),
                      const SizedBox(width: 12),
                      const _SoundWave(),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'VOICE REMINDER',
                            style: TextStyle(
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.medOrange,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Active · 7:55 AM',
                            style: TextStyle(fontSize: 9, color: Color(0xFF78716C)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (refillDays != null && refillDays! <= 7)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: compact ? 10 : 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
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
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
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
                const SizedBox(height: 8),
                Text(
                  refillDays != null
                      ? 'Refill in $refillDays day${refillDays == 1 ? '' : 's'}'
                      : 'Refill info unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: (refillDays != null && refillDays! <= 7)
                        ? const Color(0xFFF59E0B)
                        : AppColors.ink400,
                    fontWeight: (refillDays != null && refillDays! <= 7)
                        ? FontWeight.w600
                        : FontWeight.w400,
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

class _SoundWave extends StatelessWidget {
  const _SoundWave();
  static const _bars = [4.0, 8.0, 12.0, 16.0, 10.0, 14.0, 6.0, 11.0, 8.0, 5.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < _bars.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 3,
                height: _bars[i],
                decoration: BoxDecoration(
                  color: AppColors.medOrange.withValues(alpha: 0.5 + (i % 3) * 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
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
  final int? refillDays;

  const _TakenCard({
    required this.compact,
    required this.name,
    required this.dose,
    this.refillDays,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 14.0 : 18.0;
    return Opacity(
      opacity: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                  colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)],
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
                  Container(
                    width: compact ? 36 : 44,
                    height: compact ? 36 : 44,
                    decoration: BoxDecoration(
                      color: AppColors.medGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.medGreen.withValues(alpha: 0.2), blurRadius: 0, spreadRadius: 4),
                      ],
                    ),
                    child: Icon(Icons.check_rounded, size: compact ? 18 : 22, color: Colors.white),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 20,
                vertical: compact ? 10 : 14,
              ),
              color: AppColors.medGreenLight,
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
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const Spacer(),
                      if (refillDays != null && refillDays! <= 7)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⚠️ $refillDays d left',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
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
                      color: const Color(0xFFBBF7D0),
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
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 14.0 : 18.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Colors.white),
                      Text(time,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w700)),
                      Text('overdue', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 12 : 14,
            ),
            color: AppColors.medRedLight,
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
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    if (refillDays != null && refillDays! <= 7)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '⚠️ $refillDays d left',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
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
                          backgroundColor: rescheduled ? const Color(0xFF374151) : Colors.white,
                          foregroundColor: rescheduled ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
                          side: BorderSide(color: rescheduled ? const Color(0xFF6B7280) : AppColors.border, width: 1.5),
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
