import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';
import 'add_med_screen.dart';
import 'reminders_screen.dart';
import '../database_helper.dart';
import '../notification_service.dart';
import '../widgets/success_overlay.dart';
import 'settings_screen.dart';
import 'onboarding_screen.dart';

void _showEditMedDialog(
    BuildContext context, SettingsProvider settingsState, Medication med) {
  final medState = context.read<MedicationProvider>();
  final nameController = TextEditingController(text: med.name);
  final doseController = TextEditingController(text: med.dose);
  final refillDaysController = TextEditingController(text: '${med.refillDays}');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Medication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: doseController,
            decoration: const InputDecoration(labelText: 'Dosage'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: refillDaysController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Refill Days Remaining'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final dose = doseController.text.trim();
            final refillDays =
                int.tryParse(refillDaysController.text) ?? med.refillDays;

            if (name.isNotEmpty && dose.isNotEmpty) {
              medState.editMedication(
                med.id!,
                Medication(
                  id: med.id,
                  name: name,
                  dose: dose,
                  freq: med.freq,
                  color: med.color,
                  refillDays: refillDays,
                  description: med.description,
                  drugClass: med.drugClass,
                  sideEffects: med.sideEffects,
                  doctor: med.doctor,
                  notes: med.notes,
                  form: med.form,
                  intakeQty: med.intakeQty,
                  supplyQty: med.supplyQty,
                  initialSupply: med.initialSupply,
                ),
              );
              Navigator.of(context).pop();
              SuccessOverlay.showMedicationUpdated(context, medName: name);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showDeleteMedDialog(
    BuildContext context, SettingsProvider settingsState, Medication med) {
  final medState = context.read<MedicationProvider>();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Medication'),
      content: Text(
          'Are you sure you want to delete ${med.name}? All associated alert rules will also be removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            medState.removeMedication(med.id!);
            Navigator.of(context).pop();
            SuccessOverlay.showMedicationDeleted(context, medName: med.name);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medRed, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void _showEditCaregiverDialog(
    BuildContext context, SettingsProvider settingsState, Caregiver caregiver) {
  final nameController = TextEditingController(text: caregiver.name);
  final relationController = TextEditingController(text: caregiver.relation);
  final phoneController = TextEditingController(text: caregiver.phone);
  bool activeVal = caregiver.active;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit Caregiver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: relationController,
                decoration: const InputDecoration(labelText: 'Relationship')),
            TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number')),
            CheckboxListTile(
              title: const Text('Primary Contact'),
              value: activeVal,
              onChanged: (v) =>
                  setDialogState(() => activeVal = v ?? activeVal),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final relation = relationController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isNotEmpty) {
                settingsState.editCaregiver(
                  caregiver.id!,
                  Caregiver(
                    id: caregiver.id,
                    name: name,
                    relation: relation.isNotEmpty ? relation : 'Caregiver',
                    phone: phone.isNotEmpty ? phone : 'Unknown',
                    active: activeVal,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final medState = context.watch<MedicationProvider>();
    final settingsState = context.watch<SettingsProvider>();
    final profile = settingsState.profile;

    if (profile == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFF8B5CF6),
                      Color(0xFFA78BFA)
                    ],
                    stops: [0, 0.6, 1],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 3),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.name,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.4)),
                              Text('DOB: ${profile.dob}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white
                                          .withValues(alpha: 0.75))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    // Split on comma (how onboarding stores them)
                    Builder(builder: (context) {
                      final conditionChips = profile.conditions
                          .split(',')
                          .map((c) => c.trim())
                          .where((c) => c.isNotEmpty && c != 'None')
                          .toList();
                      return Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (conditionChips.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text('No conditions listed',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                            )
                          else
                            for (final c in conditionChips)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(c,
                                    style: const TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                        ],
                      );
                    }),
                    const SizedBox(height: 18),
                    Builder(builder: (context) {
                      final historyState = context.watch<HistoryProvider>();
                      final weeklyAdherence = historyState.calculateWeeklyAdherence(
                          medState.rules, medState.dynamicTodayMeds, medState.meds);
                      return Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${medState.meds.length}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              Text('Active Meds',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${settingsState.caregivers.length}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              Text('Caregivers',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${weeklyAdherence.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              Text('Adherence',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // Active medications
              _Section(
                title: 'Active Medications',
                action: '+ Add',
                onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddMedScreen())),
                child: Column(
                  children: medState.meds.isEmpty
                      ? [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.medication_rounded, size: 28, color: AppColors.ink400),
                                const SizedBox(height: 8),
                                Text('No medications added yet.',
                                    style: TextStyle(fontSize: 12, color: AppColors.ink400)),
                              ],
                            ),
                          )
                        ]
                      : medState.meds
                          .map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1))
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                            color: m.color.withValues(alpha: 0.09),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Icon(Icons.medication_liquid_rounded,
                                            size: 16, color: m.color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink900),
                                            children: [
                                              TextSpan(text: '${m.name} '),
                                              TextSpan(
                                                  text: m.dose,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.ink500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('${m.calculatedDaysRemaining}d left',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: m.calculatedDaysRemaining <= 7
                                                      ? AppColors.medRed
                                                      : AppColors.medGreen)),
                                          Text('refill',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: AppColors.ink400)),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: Icon(Icons.edit_rounded,
                                            size: 18, color: AppColors.ink500),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showEditMedDialog(
                                            context, settingsState, m),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: AppColors.medRed),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showDeleteMedDialog(
                                            context, settingsState, m),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                ),
              ),

              // Care network
              _Section(
                title: 'Care Network',
                action: '+ Add',
                onAction: () {
                  final nameController = TextEditingController();
                  final relationController = TextEditingController();
                  final phoneController = TextEditingController();
                  bool activeVal = true;
                  showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setDialogState) => AlertDialog(
                        title: const Text('Add Caregiver'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                                controller: nameController,
                                decoration:
                                    const InputDecoration(labelText: 'Name')),
                            TextField(
                                controller: relationController,
                                decoration: const InputDecoration(
                                    labelText: 'Relationship')),
                            TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                    labelText: 'Phone Number')),
                            CheckboxListTile(
                              title: const Text('Primary Contact'),
                              value: activeVal,
                              onChanged: (v) => setDialogState(
                                  () => activeVal = v ?? activeVal),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final relation = relationController.text.trim();
                              final phone = phoneController.text.trim();
                              if (name.isNotEmpty) {
                                settingsState.addCaregiver(Caregiver(
                                  name: name,
                                  relation: relation.isNotEmpty
                                      ? relation
                                      : 'Caregiver',
                                  phone: phone,
                                  active: activeVal,
                                ));
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Column(
                  children: settingsState.caregivers.isEmpty
                      ? [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.group_rounded, size: 28, color: AppColors.ink400),
                                const SizedBox(height: 8),
                                Text('No caregivers added yet.',
                                    style: TextStyle(fontSize: 12, color: AppColors.ink400)),
                              ],
                            ),
                          )
                        ]
                      : settingsState.caregivers
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1))
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: c.active
                                              ? const LinearGradient(colors: [
                                                  Color(0xFF8B5CF6),
                                                  Color(0xFF6D28D9)
                                                ])
                                              : null,
                                          color: c.active
                                              ? null
                                              : (AppColors.isDark
                                                  ? const Color(0xFF374151)
                                                  : const Color(0xFFE5E7EB)),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(c.name[0],
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: c.active
                                                    ? Colors.white
                                                    : AppColors.ink400)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(c.name,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.ink900)),
                                            Text(
                                              c.phone.isNotEmpty
                                                  ? '${c.relation} · ${c.phone}'
                                                  : c.relation,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.ink400)),
                                          ],
                                        ),
                                      ),
                                      if (c.active)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: AppColors.isDark
                                                  ? const Color(0xFF062F17)
                                                  : AppColors.medGreenLight,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text('Primary',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.isDark
                                                      ? const Color(0xFF4ADE80)
                                                      : const Color(0xFF15803D))),
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.edit_rounded,
                                            size: 20, color: AppColors.ink500),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showEditCaregiverDialog(
                                            context, settingsState, c),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20, color: AppColors.medRed),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Remove Caregiver'),
                                              content: Text(
                                                  'Are you sure you want to remove ${c.name}?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context).pop(),
                                                    child: const Text('Cancel')),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    settingsState
                                                        .removeCaregiver(c.name);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Remove'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                ),
              ),

              // General Settings
              _Section(
                title: 'General Settings',
                action: '',
                child: Column(
                  children: [
                    for (int i = 0;
                        i < settingsState.profileToggles.length;
                        i++)
                      GestureDetector(
                        onTap: () => settingsState.toggleProfileToggle(i),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: i < settingsState.profileToggles.length - 1
                                ? Border(
                                    bottom:
                                        BorderSide(color: AppColors.hairline))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(settingsState.profileToggles[i].label,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink900)),
                                    Text(settingsState.profileToggles[i].sub,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.ink400)),
                                  ],
                                ),
                              ),
                              _MiniSwitch(
                                  on: settingsState.profileToggles[i].on,
                                  color:
                                      settingsState.profileToggles[i].color ??
                                          AppColors.medGreen),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Alarm & Notification Preferences
              _Section(
                title: 'Alarm & Notification Settings',
                action: 'Manage Rules',
                onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen())),
                child: Column(
                  children: [                    for (int i = 0;
                        i < settingsState.notificationToggles.length;
                        i++)
                      Builder(builder: (context) {
                        final t = settingsState.notificationToggles[i];
                        final isVoice = t.label == 'Voice Reminders';
                        return Opacity(
                          opacity: isVoice ? 0.45 : 1.0,
                          child: GestureDetector(
                            onTap: isVoice
                                ? null
                                : () async {
                                    final medProvider = context.read<MedicationProvider>();
                                    await settingsState.toggleNotificationToggle(i);
                                    for (final rule in medProvider.rules) {
                                      if (rule.active) {
                                        await LocalNotificationService().scheduleReminderNotification(rule);
                                      }
                                    }
                                  },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: AppColors.hairline)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(t.label,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.ink900)),
                                            if (isVoice) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.isDark
                                                      ? const Color(0xFF374151)
                                                      : const Color(0xFFF3F4F6),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text('Soon',
                                                    style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.ink400)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(t.sub,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.ink400)),
                                      ],
                                    ),
                                  ),
                                  _MiniSwitch(
                                      on: isVoice ? false : t.on,
                                      color: t.color ?? AppColors.medGreen),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),


                    // Snooze Duration dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Snooze Duration',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink900)),
                                Text('Time to wait before repeating alerts',
                                    style: TextStyle(
                                        fontSize: 11, color: AppColors.ink400)),
                              ],
                            ),
                          ),
                          DropdownButton<int>(
                            value: settingsState.snoozeDuration,
                            dropdownColor: AppColors.cardBg,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                  value: 5,
                                  child: Text('5 mins',
                                      style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(
                                  value: 10,
                                  child: Text('10 mins',
                                      style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(
                                  value: 15,
                                  child: Text('15 mins',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                settingsState.updateSnoozeDuration(val);
                              }
                            },
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.medBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Reset App Data
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Reset App Data',
                                  style: TextStyle(color: AppColors.medRed)),
                              content: const Text(
                                  'Are you sure you want to completely wipe all app data and reset to defaults? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final medProvider = context.read<MedicationProvider>();
                                    final vitalsProvider = context.read<VitalsProvider>();
                                    final settingsProvider = context.read<SettingsProvider>();
                                    final historyProvider = context.read<HistoryProvider>();

                                    // Cancel all existing scheduled alarms
                                    await LocalNotificationService().cancelAll();

                                    // Reset database and re-seed defaults
                                    await DatabaseHelper.instance.resetToDefaults();

                                    // Reload data into providers
                                    final db = await DatabaseHelper.instance.database;
                                    final medsData = await db.query('medications');
                                    final rulesData = await db.query('reminder_rules');
                                    final todayData = await db.query('today_meds');
                                    final vitalsData = await db.query('vitals');
                                    final caregiversData = await db.query('caregivers');
                                    final togglesData = await db.query('profile_toggles');
                                    final historyData = await db.query('history_items', orderBy: 'id DESC');
                                    final bpData = await db.query('bp_readings');

                                    await medProvider.load(medsData, rulesData, todayData, historyData);
                                    await vitalsProvider.load(vitalsData, bpData);
                                    // Pass null profile so the app routes back to Onboarding
                                    await settingsProvider.load(null, caregiversData, togglesData);
                                    await historyProvider.load(historyData);
                                    await historyProvider.loadPersonalBest();

                                    if (context.mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                                        (route) => false,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.medRed,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.isDark
                              ? AppColors.cardBg
                              : Colors.white,
                          foregroundColor: const Color(0xFFDC2626),
                          side: BorderSide(
                              color: AppColors.isDark
                                  ? const Color(0xFF7F1D1D)
                                  : const Color(0xFFFECACA),
                              width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reset App Data',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Adherely v1.0.1 · Offline-First',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.ink400)),
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

class _Section extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onAction;
  final Widget child;
  const _Section(
      {required this.title,
      required this.action,
      this.onAction,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900)),
              if (action.isNotEmpty)
                GestureDetector(
                  onTap: onAction,
                  child: Text(action,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.medBlue)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  final bool on;
  final Color color;
  const _MiniSwitch({required this.on, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
          color: on
              ? color
              : (AppColors.isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(12)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
            ],
          ),
        ),
      ),
    );
  }
}
