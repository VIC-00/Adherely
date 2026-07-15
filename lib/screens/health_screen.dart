import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';

double _bpBarHeight(int val, {required bool isSystolic}) {
  final double minVal = isSystolic ? 100.0 : 60.0;
  final double maxVal = isSystolic ? 150.0 : 100.0;
  final double ratio = (val - minVal) / (maxVal - minVal);
  return (ratio * 40.0).clamp(4.0, 60.0);
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final medState = context.watch<MedicationProvider>();
    final vitalsState = context.watch<VitalsProvider>();
    final historyState = context.watch<HistoryProvider>();
    final settingsState = context.watch<SettingsProvider>();
    final profileName = settingsState.profile?.name ?? 'User';

    // Dynamically generate med impacts from actual user medications
    final dynamicMedImpacts = medState.meds.map((med) {
      String impact = 'Adherence tracked';
      String icon = '💊';
      IconData iconData = Icons.medication_rounded;
      int weeks = 1;
      int progress = historyState.getMedicationAdherence(med.name);

      final medNameLower = med.name.toLowerCase();

      // 1. Blood Pressure medication (e.g. Lisinopril)
      if (medNameLower.contains('lisinopril') ||
          medNameLower.contains('losartan') ||
          medNameLower.contains('metoprolol') ||
          medNameLower.contains('amlodipine')) {
        icon = '❤️';
        iconData = Icons.monitor_heart_rounded;
        weeks = 4;

        final bpReadings = vitalsState.bpReadings;
        if (bpReadings.length >= 2) {
          final oldestSys = bpReadings.first.sys;
          final latestSys = bpReadings.last.sys;
          final diff = oldestSys - latestSys;
          if (diff > 0) {
            final pct = ((diff / oldestSys) * 100).round();
            impact =
                'Systolic BP reduced by $pct% ($oldestSys → $latestSys mmHg)';
          } else if (diff < 0) {
            final pct = (((-diff) / oldestSys) * 100).round();
            impact =
                'Systolic BP increased by $pct% ($oldestSys → $latestSys mmHg)';
          } else {
            impact = 'Systolic BP stable at $latestSys mmHg';
          }
        } else if (bpReadings.length == 1) {
          impact =
              'Blood pressure logged at ${bpReadings.first.sys}/${bpReadings.first.dia} mmHg';
        } else {
          impact = 'Log BP readings to see medication impact';
        }
      }
      // 2. Blood Sugar medication (e.g. Metformin)
      else if (medNameLower.contains('metformin') ||
          medNameLower.contains('insulin') ||
          medNameLower.contains('glipizide')) {
        icon = '🩸';
        iconData = Icons.bloodtype_rounded;
        weeks = 6;

        final sugarVital = vitalsState.vitals.firstWhere(
          (v) => v.label == 'Blood Sugar',
          orElse: () => const VitalStat(
              label: 'Blood Sugar',
              value: '--',
              unit: '',
              trend: '',
              color: Colors.teal,
              bg: Colors.white,
              border: Colors.white,
              icon: '🩸'),
        );
        if (sugarVital.value != '--') {
          impact =
              'Glucose levels stable at ${sugarVital.value} ${sugarVital.unit}';
        } else {
          impact = 'Glucose levels tracked';
        }
      }
      // 3. Pain, Nerve or other medication (e.g. Gabapentin)
      else if (medNameLower.contains('gabapentin') ||
          medNameLower.contains('ibuprofen') ||
          medNameLower.contains('acetaminophen')) {
        icon = '🧠';
        iconData = Icons.healing_rounded;
        weeks = 2;
        if (progress >= 85) {
          impact = 'Pain managed · Excellent adherence ($progress%)';
        } else if (progress > 50) {
          impact = 'Pain partially managed · Adherence is $progress%';
        } else {
          impact =
              'Missed doses impacting effectiveness ($progress% adherence)';
        }
      }
      // 4. Fallback default medication
      else {
        icon = '💊';
        iconData = Icons.healing_rounded;
        weeks = 3;
        if (progress >= 80) {
          impact = 'Highly effective · Adherence is $progress%';
        } else {
          impact = 'Adherence is $progress% · Take regularly for full effect';
        }
      }

      return MedImpact(
        med: '${med.name} ${med.dose}',
        impact: impact,
        icon: icon,
        weeks: weeks,
        progress: progress,
        color: med.color,
        iconData: iconData,
      );
    }).toList();

    if (dynamicMedImpacts.isEmpty) {
      dynamicMedImpacts.add(const MedImpact(
          med: 'No Meds Added',
          impact: 'Add medications to track impacts',
          icon: 'ℹ️',
          weeks: 0,
          progress: 0));
    }

    // Dynamic header subtitle
    final weeklyAdherence = historyState.calculateWeeklyAdherence(
        medState.rules, medState.dynamicTodayMeds, medState.meds);
    final String headerSubtitle;
    if (medState.meds.isEmpty) {
      headerSubtitle = 'Add your medications to start tracking.';
    } else if (weeklyAdherence >= 85) {
      headerSubtitle = 'Great adherence this week, $profileName!';
    } else if (weeklyAdherence >= 60) {
      headerSubtitle = 'Keep going - consistency makes a difference.';
    } else {
      headerSubtitle = 'Try not to miss doses for best results.';
    }

    // Dynamic vitals badge
    final hasAnyVitals = vitalsState.vitals.any((v) => v.value != '--');
    final String vitalsBadgeText;
    final Color vitalsBadgeDot;
    if (!hasAnyVitals) {
      vitalsBadgeText = 'No vitals logged yet — tap Log Vitals button to add';
      vitalsBadgeDot = const Color(0xFF9CA3AF);
    } else {
      vitalsBadgeText = 'Vitals updated';
      vitalsBadgeDot = const Color(0xFF34D399);
    }

    // Dynamic BP trend badge
    final bpReadings = vitalsState.bpReadings;
    final String bpTrendLabel;
    if (bpReadings.length >= 2) {
      final diff = bpReadings.first.sys - bpReadings.last.sys;
      if (diff > 5) {
        bpTrendLabel = '↓ Improving';
      } else if (diff < -5) {
        bpTrendLabel = '↑ Rising';
      } else {
        bpTrendLabel = '→ Stable';
      }
    } else {
      bpTrendLabel = 'Log readings';
    }

    return Scaffold(
        body: Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
                      Color(0xFF0F766E),
                      Color(0xFF0D9488),
                      Color(0xFF14B8A6)
                    ],
                    stops: [0, 0.6, 1],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HEALTH & VITALS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 4),
                    const Text('Your Progress',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.6)),
                    const SizedBox(height: 4),
                    Text(headerSubtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Dot(color: vitalsBadgeDot),
                          const SizedBox(width: 6),
                          Text(vitalsBadgeText,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Vitals grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children:
                      vitalsState.vitals.map((v) => _VitalCard(v: v)).toList(),
                ),
              ),

              // BP chart
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Blood Pressure Trend',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink900)),
                            Text('7-day history',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.ink400)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.isDark
                                  ? const Color(0xFF1E3A8A)
                                  : AppColors.medBlueLight,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(bpTrendLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 150,
                      child: vitalsState.bpReadings.isEmpty
                          ? Center(
                              child: Text(
                                'No blood pressure data logged yet.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.ink400),
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (int i = 0;
                                    i < vitalsState.bpReadings.length;
                                    i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height: _bpBarHeight(
                                                vitalsState.bpReadings[i].sys,
                                                isSystolic: true),
                                            decoration: BoxDecoration(
                                              color: i ==
                                                      vitalsState.bpReadings
                                                              .length -
                                                          1
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFF93C5FD),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(3)),
                                            ),
                                          ),
                                          Container(
                                            height: _bpBarHeight(
                                                vitalsState.bpReadings[i].dia,
                                                isSystolic: false),
                                            decoration: BoxDecoration(
                                              color: i ==
                                                      vitalsState.bpReadings
                                                              .length -
                                                          1
                                                  ? const Color(0xFF60A5FA)
                                                  : const Color(0xFFBFDBFE),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      bottom:
                                                          Radius.circular(3)),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Builder(
                                            builder: (context) {
                                              final dateStr = vitalsState
                                                  .bpReadings[i].date;
                                              final parts = dateStr.split(', ');
                                              final displayDate =
                                                  parts.isNotEmpty
                                                      ? parts[0]
                                                      : dateStr;
                                              final displayTime =
                                                  parts.length > 1
                                                      ? parts[1]
                                                      : '';
                                              final isLast = i ==
                                                  vitalsState
                                                          .bpReadings.length -
                                                      1;
                                              final textColor = isLast
                                                  ? (AppColors.isDark
                                                      ? const Color(0xFF60A5FA)
                                                      : const Color(0xFF2563EB))
                                                  : AppColors.ink400;

                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    displayDate,
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: textColor,
                                                      fontWeight: isLast
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (displayTime.isNotEmpty)
                                                    Text(
                                                      displayTime,
                                                      style: TextStyle(
                                                        fontSize: 7,
                                                        color: textColor
                                                            .withValues(
                                                                alpha: 0.8),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        _LegendSquare(
                            color: Color(0xFF2563EB), label: 'Systolic'),
                        SizedBox(width: 12),
                        _LegendSquare(
                            color: Color(0xFF60A5FA), label: 'Diastolic'),
                      ],
                    ),
                  ],
                ),
              ),

              // Medication Impact
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medication Impact',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900)),
                    const SizedBox(height: 10),
                    if (dynamicMedImpacts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No medications logged to track impacts.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.ink400),
                        ),
                      )
                    else
                      for (final m in dynamicMedImpacts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
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
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: (m.color ?? AppColors.medBlue)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        m.iconData ?? Icons.healing_rounded,
                                        size: 18,
                                        color: m.color ?? AppColors.medBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(m.med,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink900)),
                                          Text(m.impact,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.ink500)),
                                        ],
                                      ),
                                    ),
                                    Text('${m.weeks}-week trend',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.ink500,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: m.progress / 100,
                                    minHeight: 5,
                                    backgroundColor: AppColors.isDark
                                        ? const Color(0xFF374151)
                                        : const Color(0xFFF3F4F6),
                                    valueColor: AlwaysStoppedAnimation(
                                        m.color ?? AppColors.medTeal),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Effectiveness',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.ink400)),
                                    Text('${m.progress}%',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                m.color ?? AppColors.medTeal)),
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
    ));
  }
}

class _VitalCard extends StatelessWidget {
  final VitalStat v;
  const _VitalCard({required this.v});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.isDark ? AppColors.cardBg : v.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.isDark ? v.color.withValues(alpha: 0.3) : v.border,
          width: AppColors.isDark ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(v.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            v.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
                letterSpacing: -0.4),
          ),
          Text(
            v.unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10,
                color: AppColors.ink500,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            v.trend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: v.color),
          ),
          Text(
            v.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: AppColors.ink400),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _LegendSquare extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendSquare({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.ink500)),
      ],
    );
  }
}
