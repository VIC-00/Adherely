import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../theme/app_colors.dart';
import '../providers/medication_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../notification_service.dart';
import 'success_overlay.dart';

class AlarmOverlayDialog extends StatefulWidget {
  final int ruleId;
  final String medName;
  final String dose;

  const AlarmOverlayDialog({
    super.key,
    required this.ruleId,
    required this.medName,
    required this.dose,
  });

  @override
  State<AlarmOverlayDialog> createState() => _AlarmOverlayDialogState();
}

class _AlarmOverlayDialogState extends State<AlarmOverlayDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  int _selectedSnoozeMinutes = 5;

  @override
  void initState() {
    super.initState();
    // Read stored value after the first frame so context.read is safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final stored = context.read<SettingsProvider>().snoozeDuration;
        setState(() => _selectedSnoozeMinutes = stored);
      } catch (_) {}
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 20.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTake() async {
    final medProvider = Provider.of<MedicationProvider>(context, listen: false);
    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);

    // 1. Log in MedicationProvider (to update today's meds and db)
    final med = medProvider.meds.firstWhere(
      (m) => m.name.toLowerCase() == widget.medName.toLowerCase(),
      orElse: () => Medication(
        id: widget.ruleId,
        name: widget.medName,
        dose: widget.dose,
        freq: '',
        color: AppColors.medBlue,
        refillDays: 30,
      ),
    );

    if (med.id != null) {
      await medProvider.logMedication(med.id!, MedCardVariant.taken);
    }

    // 2. Add to History
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('jm').format(now);

    final historyItem = HistoryItem(
      med: '${widget.medName} ${widget.dose}',
      date: dateStr,
      time: timeStr,
      taken: true,
      note: 'Taken on time',
    );
    await historyProvider.logHistory(historyItem);

    // 3. Cancel the alarm notification
    await LocalNotificationService().cancelReminder(widget.ruleId);

    // 4. Close the overlay
    if (mounted) {
      Navigator.of(context).pop();
      SuccessOverlay.showDoseLogged(context, medName: widget.medName, dose: widget.dose);
    }
  }

  void _onSnooze() async {
    // Schedule snooze using the plugin in notification service
    final reminderService = LocalNotificationService();

    // We can simulate a snooze trigger by scheduling a new one-off notification in the background
    // To make it run, we can trigger the native snooze function
    // But since we are inside the foreground app, we can do it directly:
    final rule = ReminderRule(
      id: widget.ruleId,
      med: widget.medName,
      dose: widget.dose,
      time: DateFormat('h:mm a').format(
          DateTime.now().add(Duration(minutes: _selectedSnoozeMinutes))),
      types: const [AlertType.push],
      advance: 0,
      color: AppColors.medBlue,
      active: true,
    );

    // Cancel current active notifications
    await reminderService.cancelReminder(widget.ruleId);

    // Schedule the snooze notification
    await reminderService.scheduleReminderNotification(rule);

    if (mounted) {
      Navigator.of(context).pop();
      SuccessOverlay.showSnoozed(context, minutes: _selectedSnoozeMinutes);
    }
  }

  void _onDismiss() async {
    await LocalNotificationService().cancelReminder(widget.ruleId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              // Pulsing Alarm Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.medBlue.withValues(alpha: 0.25),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: _glowAnimation.value / 2,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.medBlue,
                        ),
                        child: const Icon(
                          Icons.alarm_on_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Medication Alert',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'It is time to take your scheduled dose.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.ink500,
                ),
              ),

              const SizedBox(height: 24),

              // Medication Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.medName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dosage: ${widget.dose}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.ink700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Snooze settings Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Snooze Duration',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink700,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _selectedSnoozeMinutes,
                    dropdownColor:
                        isDark ? const Color(0xFF1E293B) : Colors.white,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 mins')),
                      DropdownMenuItem(value: 10, child: Text('10 mins')),
                      DropdownMenuItem(value: 15, child: Text('15 mins')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSnoozeMinutes = val);
                        // Persist the user's choice so the next alarm dialog
                        // opens with the same duration they just selected.
                        try {
                          context.read<SettingsProvider>().updateSnoozeDuration(val);
                        } catch (_) {}
                      }
                    },
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onSnooze,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.ink400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Snooze',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onTake,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.medGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Take Now',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _onDismiss,
                child: Text(
                  'Dismiss',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.ink500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
