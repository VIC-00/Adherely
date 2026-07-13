import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SuccessOverlay extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final List<Color> gradientColors;
  final Color titleColor;

  const SuccessOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.gradientColors,
    required this.titleColor,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required List<Color> gradientColors,
    required Color titleColor,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => SuccessOverlay(
        title: title,
        message: message,
        icon: icon,
        gradientColors: gradientColors,
        titleColor: titleColor,
      ),
    );
  }

  // Pre-configured helper show methods:
  
  static void showDoseLogged(BuildContext context, {required String medName, required String dose}) {
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(now);
    show(
      context: context,
      title: 'Dose Logged!',
      message: '$medName\nDosage: $dose\nLogged at $timeStr',
      icon: Icons.check_rounded,
      gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
      titleColor: const Color(0xFF10B981),
    );
  }

  static void showRescheduled(BuildContext context, {required String medName, required String time}) {
    show(
      context: context,
      title: 'Rescheduled!',
      message: '$medName is now scheduled for\n$time',
      icon: Icons.edit_calendar_rounded,
      gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      titleColor: const Color(0xFF2563EB),
    );
  }

  static void showReminderAdded(BuildContext context, {required String medName, required String time}) {
    show(
      context: context,
      title: 'Reminder Added!',
      message: 'New alert for $medName set at\n$time',
      icon: Icons.add_alert_rounded,
      gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      titleColor: const Color(0xFF8B5CF6),
    );
  }

  static void showSnoozed(BuildContext context, {required int minutes}) {
    show(
      context: context,
      title: 'Alarm Snoozed',
      message: 'Reminding you again in $minutes minutes',
      icon: Icons.snooze_rounded,
      gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      titleColor: const Color(0xFFD97706),
    );
  }

  static void showVitalsLogged(BuildContext context, {required String vitalType}) {
    show(
      context: context,
      title: 'Vitals Logged!',
      message: 'Your $vitalType readings have been recorded successfully.',
      icon: Icons.add_chart_rounded,
      gradientColors: [const Color(0xFF0F766E), const Color(0xFF0D9488)],
      titleColor: const Color(0xFF0F766E),
    );
  }

  static void showRefillLogged(BuildContext context, {required String medName}) {
    show(
      context: context,
      title: 'Refill Logged!',
      message: 'Refill history updated for $medName.',
      icon: Icons.local_pharmacy_rounded,
      gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
      titleColor: const Color(0xFF0D9488),
    );
  }

  static void showMedicationUpdated(BuildContext context, {required String medName}) {
    show(
      context: context,
      title: 'Medication Updated!',
      message: '$medName details saved successfully.',
      icon: Icons.update_rounded,
      gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      titleColor: const Color(0xFF3B82F6),
    );
  }

  static void showMedicationDeleted(BuildContext context, {required String medName}) {
    show(
      context: context,
      title: 'Medication Deleted',
      message: '$medName was removed from your active list.',
      icon: Icons.delete_sweep_rounded,
      gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      titleColor: const Color(0xFFEF4444),
    );
  }

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    _autoCloseTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B).withValues(alpha: 0.95),
                            const Color(0xFF0F172A).withValues(alpha: 0.95),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.95),
                            const Color(0xFFF8FAFC).withValues(alpha: 0.95),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Checkmark Badge
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: widget.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.gradientColors.first.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: widget.titleColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.4)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                        ),
                      ),
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Motivational line
                    Text(
                      'Keep it up! You\'re staying on track.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
