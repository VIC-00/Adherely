import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';

const _frequencies = ['Once daily', 'Twice daily', 'Three times daily', 'Every other day', 'As needed'];
const _times = ['6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM', '12:00 PM', '2:00 PM', '6:00 PM', '8:00 PM', '10:00 PM', 'Custom...'];
const _categories = [
  {'label': 'Blood Pressure', 'icon': '❤️', 'color': Color(0xFFEF4444)},
  {'label': 'Diabetes', 'icon': '🩸', 'color': Color(0xFFF97316)},
  {'label': 'Pain Relief', 'icon': '🧠', 'color': Color(0xFF8B5CF6)},
  {'label': 'Antibiotic', 'icon': '💊', 'color': Color(0xFF22C55E)},
  {'label': 'Thyroid', 'icon': '⚕️', 'color': Color(0xFF3B82F6)},
  {'label': 'Other', 'icon': '📦', 'color': Color(0xFF6B7280)},
];
const _stepLabels = ['Med Info', 'Schedule', 'Reminders'];

class AddMedScreen extends StatefulWidget {
  const AddMedScreen({super.key});

  @override
  State<AddMedScreen> createState() => _AddMedScreenState();
}

class _AddMedScreenState extends State<AddMedScreen> {
  int _step = 1;
  String _freq = 'Once daily';
  String _time = '8:00 AM';
  String _category = 'Blood Pressure';
  bool _reminder = true;
  bool _voiceAlert = true;

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _supplyController = TextEditingController(text: '30');
  final _refillAlertController = TextEditingController(text: '7');
  String _form = 'Tablet';

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _supplyController.dispose();
    _refillAlertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.hairline))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.ink700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ADD MEDICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.ink400)),
                            Text('New Prescription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink900, letterSpacing: -0.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(3, (i) {
                      final s = i + 1;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: s <= _step ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (i) {
                      final active = i + 1 <= _step;
                      return Text(_stepLabels[i],
                          style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? const Color(0xFF2563EB) : AppColors.ink400));
                    }),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: switch (_step) {
                  1 => _buildStep1(),
                  2 => _buildStep2(),
                  _ => _buildStep3(),
                },
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.hairline))),
              child: Row(
                children: [
                  if (_step > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step -= 1),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: AppColors.ink700,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (_step > 1) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_step < 3) {
                          setState(() => _step += 1);
                        } else {
                          final name = _nameController.text.trim();
                          final dose = _doseController.text.trim();
                          final freq = '$_freq · $_time';
                          final supply = int.tryParse(_supplyController.text.trim()) ?? 30;

                          Color color = AppColors.medBlue;
                          if (_category == 'Blood Pressure') color = const Color(0xFFEF4444);
                          if (_category == 'Diabetes') color = const Color(0xFFF97316);
                          if (_category == 'Pain Relief') color = const Color(0xFF8B5CF6);
                          if (_category == 'Antibiotic') color = const Color(0xFF22C55E);
                          if (_category == 'Thyroid') color = const Color(0xFF3B82F6);

                          final medState = context.read<MedicationProvider>();
//     final vitalsState = context.watch<VitalsProvider>();
//     final settingsState = context.watch<SettingsProvider>();
//     final historyState = context.watch<HistoryProvider>();
                          final alertTypes = <AlertType>[];
                          if (_reminder) alertTypes.add(AlertType.push);
                          if (_voiceAlert) alertTypes.add(AlertType.voice);

                          medState.addMedication(
                            Medication(
                              name: name.isNotEmpty ? name : 'Unnamed Medication',
                              dose: dose.isNotEmpty ? dose : 'unknown dose',
                              freq: freq,
                              color: color,
                              refillDays: supply,
                            ),
                            types: alertTypes,
                            advanceMinutes: 15,
                          );

                          Navigator.of(context).maybePop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(_step == 3 ? 'Add Medication ✓' : 'Continue →', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormField(
          label: 'Medication Name',
          required: true,
          child: TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
            decoration: InputDecoration(
              hintText: 'e.g. Lisinopril',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Dosage',
                required: true,
                child: TextFormField(
                  controller: _doseController,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                  decoration: InputDecoration(
                    hintText: 'e.g. 10mg',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FormField(
                label: 'Form',
                child: DropdownButtonFormField<String>(
                  initialValue: _form,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                  items: const ['Tablet', 'Capsule', 'Liquid', 'Injection']
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) => setState(() => _form = v ?? _form),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Category',
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.6,
            children: _categories.map((c) {
              final selected = _category == c['label'];
              final color = c['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _category = c['label'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? color : AppColors.border, width: 2),
                    color: selected ? color.withValues(alpha: 0.08) : Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c['icon'] as String, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(c['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: selected ? color : AppColors.ink500, height: 1.2)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        const _FormField(label: 'Prescribing Doctor', child: _TextInput(hint: "Doctor's name", initial: 'Dr. Nguyen')),
        const SizedBox(height: 16),
        const _FormField(label: 'Notes (optional)', child: _TextInput(hint: 'Any special instructions...', maxLines: 3)),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormField(
          label: 'Frequency',
          child: Column(
            children: _frequencies.map((f) {
              final selected = _freq == f;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _freq = f),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.medBlueLight : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? const Color(0xFF2563EB) : AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFF2563EB) : AppColors.ink700)),
                        if (selected) const Icon(Icons.check_rounded, size: 14, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Dose Time(s)',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _times.map((t) {
              final selected = _time == t || (t == 'Custom...' && !_times.sublist(0, _times.length - 1).contains(_time));
              final displayText = (t == 'Custom...' && selected) ? _time : t;
              return GestureDetector(
                onTap: () async {
                  if (t == 'Custom...') {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _time = picked.format(context);
                      });
                    }
                  } else {
                    setState(() => _time = t);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.medBlueLight : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? const Color(0xFF2563EB) : AppColors.border, width: 1.5),
                  ),
                  child: Text(displayText, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFF2563EB) : AppColors.ink700)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Supply & Refill',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pills in supply', style: TextStyle(fontSize: 11, color: AppColors.ink500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _supplyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                      decoration: InputDecoration(
                        hintText: 'e.g. 30',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Refill alert (days)', style: TextStyle(fontSize: 11, color: AppColors.ink500)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _refillAlertController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                      decoration: InputDecoration(
                        hintText: 'e.g. 7',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.medBlueLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MEDICATION SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB), letterSpacing: 0.8)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink900),
                  children: [
                    TextSpan(text: '${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Medication'} '),
                    TextSpan(text: _doseController.text.trim().isNotEmpty ? _doseController.text.trim() : 'dose', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  ],
                ),
              ),
              Text('$_freq · $_time', style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ReminderRow(
                label: 'Push Notification',
                sub: '15 min before dose',
                value: _reminder,
                color: const Color(0xFF3B82F6),
                onChanged: (v) => setState(() => _reminder = v),
                showBorder: true,
              ),
              _ReminderRow(
                label: 'Voice Reminder',
                sub: 'Spoken alert at dose time',
                value: _voiceAlert,
                color: AppColors.medOrange,
                onChanged: (v) => setState(() => _voiceAlert = v),
                showBorder: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.medOrange.withValues(alpha: 0.2)),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF7C2D12)),
              children: [
                const TextSpan(text: 'Voice reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' will play: '),
                TextSpan(text: '"Time to take your ${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'medication'} ${_doseController.text.trim().isNotEmpty ? _doseController.text.trim() : ''}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                TextSpan(text: ' at $_time.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final bool showBorder;

  const _ReminderRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: AppColors.hairline)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.ink400)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(color: value ? color : const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(12)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const _FormField({required this.label, this.required = false, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink700),
            children: [
              TextSpan(text: label),
              if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.medRed)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  final String? hint;
  final String? initial;
  final int maxLines;
  const _TextInput({this.hint, this.initial, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      ),
    );
  }
}


