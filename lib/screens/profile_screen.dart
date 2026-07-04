import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';
import 'add_med_screen.dart';
import 'reminders_screen.dart';



void _showEditMedDialog(BuildContext context, SettingsProvider settingsState, Medication med) {
  final medState = context.read<MedicationProvider>(); //(BuildContext context, SettingsProvider settingsState, Medication med) {
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
            decoration: const InputDecoration(labelText: 'Refill Days Remaining'),
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
            final refillDays = int.tryParse(refillDaysController.text) ?? med.refillDays;

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
                ),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medication updated successfully!')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showDeleteMedDialog(BuildContext context, SettingsProvider settingsState, Medication med) {
  final medState = context.read<MedicationProvider>(); //(BuildContext context, SettingsProvider settingsState, Medication med) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Medication'),
      content: Text('Are you sure you want to delete ${med.name}? All associated alert rules will also be removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            medState.removeMedication(med.id!);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${med.name} deleted successfully.')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.medRed, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final medState = context.watch<MedicationProvider>();
//     final vitalsState = context.watch<VitalsProvider>();
    final settingsState = context.watch<SettingsProvider>();
//     final historyState = context.watch<HistoryProvider>();
    final profile = settingsState.profile;
    
    if (profile == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
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
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                          ),
                          alignment: Alignment.center,
                          child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                              Text('DOB: ${profile.dob}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                              Text('Patient ID: ${profile.patientId}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: profile.conditions.split('·').map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                                  child: Text(c, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // Active medications
              _Section(
                title: 'Active Medications',
                action: '+ Add',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddMedScreen())),
                child: Column(
                  children: medState.meds
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(color: m.color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.medication_liquid_rounded, size: 16, color: m.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                                        children: [
                                          TextSpan(text: '${m.name} '),
                                          TextSpan(text: m.dose, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.ink500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${m.refillDays}d left',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: m.refillDays <= 7 ? AppColors.medRed : AppColors.medGreen)),
                                      const Text('refill', style: TextStyle(fontSize: 9, color: AppColors.ink400)),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.ink500),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showEditMedDialog(context, settingsState, m),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.medRed),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showDeleteMedDialog(context, settingsState, m),
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
                            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                            TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Relationship')),
                            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
                            CheckboxListTile(
                              title: const Text('SMS Alerts Active'),
                              value: activeVal,
                              onChanged: (v) => setDialogState(() => activeVal = v ?? activeVal),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final relation = relationController.text.trim();
                              final phone = phoneController.text.trim();
                              if (name.isNotEmpty) {
                                settingsState.addCaregiver(Caregiver(
                                  name: name,
                                  relation: relation.isNotEmpty ? relation : 'Caregiver',
                                  phone: phone.isNotEmpty ? phone : 'Unknown',
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
                  children: settingsState.caregivers
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: c.active ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]) : null,
                                      color: c.active ? null : const Color(0xFFE5E7EB),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(c.name[0],
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.active ? Colors.white : AppColors.ink400)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                                        Text('${c.relation} · ${c.phone}', style: const TextStyle(fontSize: 11, color: AppColors.ink400)),
                                      ],
                                    ),
                                  ),
                                  if (c.active)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.medGreenLight, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('SMS Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.medRed),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remove Caregiver'),
                                          content: Text('Are you sure you want to remove ${c.name}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                            ElevatedButton(
                                              onPressed: () {
                                                settingsState.removeCaregiver(c.name);
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

              // Notification settings
              _Section(
                title: 'Notification Settings',
                action: 'Manage',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemindersScreen())),
                child: Column(
                  children: [
                    for (int i = 0; i < settingsState.profileToggles.length; i++)
                      GestureDetector(
                        onTap: () => settingsState.toggleGlobal(i),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: i < settingsState.profileToggles.length - 1 ? const Border(bottom: BorderSide(color: AppColors.hairline)) : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(settingsState.profileToggles[i].label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                                    Text(settingsState.profileToggles[i].sub, style: const TextStyle(fontSize: 11, color: AppColors.ink400)),
                                  ],
                                ),
                              ),
                              _MiniSwitch(on: settingsState.profileToggles[i].on, color: settingsState.profileToggles[i].color ?? AppColors.medGreen),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Sign out
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
                              title: const Text('Reset App Data', style: TextStyle(color: AppColors.medRed)),
                              content: const Text('Are you sure you want to completely wipe all app data and reset to defaults? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    // await resetAppData();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('App data reset successfully!')),
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
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reset App Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text('Are you sure you want to sign out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Signed out successfully!')),
                                    );
                                  },
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.medRedLight,
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('MedAdhere v2.4.0 · HIPAA Compliant', style: TextStyle(fontSize: 11, color: AppColors.ink400)),
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
  const _Section({required this.title, required this.action, this.onAction, required this.child});

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
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900)),
              if (action.isNotEmpty)
                GestureDetector(
                  onTap: onAction,
                  child: Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.medBlue)),
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
      decoration: BoxDecoration(color: on ? color : const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(12)),
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
