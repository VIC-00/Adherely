import 'package:flutter/material.dart';
import '../models.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

const _frequencies = [
  'Once daily',
  'Twice daily',
  'Three times daily',
  'Every other day',
  'As needed'
];
const _categories = [
  {'label': 'Blood Pressure', 'icon': '❤️', 'color': Color(0xFFEF4444)},
  {'label': 'Diabetes', 'icon': '🩸', 'color': Color(0xFFF97316)},
  {'label': 'Pain Relief', 'icon': '🧠', 'color': Color(0xFF8B5CF6)},
  {'label': 'Antibiotic', 'icon': '💊', 'color': Color(0xFF22C55E)},
  {'label': 'Thyroid', 'icon': '⚕️', 'color': Color(0xFF3B82F6)},
  {'label': 'Other', 'icon': '📦', 'color': Color(0xFF6B7280)},
];
const _stepLabels = ['Med Info', 'Schedule', 'Details', 'Reminders'];

class AddMedScreen extends StatefulWidget {
  const AddMedScreen({super.key});

  @override
  State<AddMedScreen> createState() => _AddMedScreenState();
}

class _AddMedScreenState extends State<AddMedScreen> {
  int _step = 1;
  String _freq = 'Once daily';
  List<String> _selectedTimes = ['8:00 AM'];
  String _category = 'Blood Pressure';
  bool _reminder = true;
  DateTime _startDate = DateTime.now();

  void _onFreqChanged(String f) {
    setState(() {
      _freq = f;
      if (f == 'Once daily' || f == 'Every other day' || f == 'As needed') {
        _selectedTimes = [_selectedTimes.first];
      } else if (f == 'Twice daily') {
        if (_selectedTimes.length < 2) {
          _selectedTimes = [_selectedTimes.first, '8:00 PM'];
        } else {
          _selectedTimes = _selectedTimes.sublist(0, 2);
        }
      } else if (f == 'Three times daily') {
        if (_selectedTimes.length < 3) {
          if (_selectedTimes.length == 1) {
            _selectedTimes = [_selectedTimes.first, '2:00 PM', '8:00 PM'];
          } else {
            _selectedTimes = [..._selectedTimes, '8:00 PM'];
          }
        } else {
          _selectedTimes = _selectedTimes.sublist(0, 3);
        }
      }
    });
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim();
      final format = DateFormat('h:mm a');
      final parsed = format.parse(clean);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      try {
        final parsed = DateFormat('HH:mm').parse(timeStr.trim());
        return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {
        return const TimeOfDay(hour: 8, minute: 0);
      }
    }
  }

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _supplyController = TextEditingController(text: '30');
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();
  String _form = 'Tablet';
  double _intakeQty = 1.0;

  String _getIntakeUnit() {
    switch (_form.toLowerCase()) {
      case 'tablet':
        return 'tablets';
      case 'capsule':
        return 'capsules';
      case 'liquid':
        return 'ml';
      case 'injection':
        return 'units';
      default:
        return 'units';
    }
  }

  String _getIntakeDescription() {
    switch (_form.toLowerCase()) {
      case 'tablet':
        return 'Number of tablets taken per dose (e.g. 1, 2, or 0.5).';
      case 'capsule':
        return 'Number of capsules taken per dose (e.g. 1 or 2).';
      case 'liquid':
        return 'Volume of liquid taken per dose (e.g. 5 or 10 ml).';
      case 'injection':
        return 'Units or injections taken per dose (e.g. 1 or 12).';
      default:
        return 'Quantity of medicine taken per dose.';
    }
  }

  String _getSupplyLabel() {
    switch (_form.toLowerCase()) {
      case 'tablet':
        return 'Tablets in supply';
      case 'capsule':
        return 'Capsules in supply';
      case 'liquid':
        return 'Liquid volume in supply (ml)';
      case 'injection':
        return 'Injections/Units in supply';
      default:
        return 'Quantity in supply';
    }
  }

  String _getSupplyHint() {
    switch (_form.toLowerCase()) {
      case 'tablet':
        return 'e.g. 30';
      case 'capsule':
        return 'e.g. 30';
      case 'liquid':
        return 'e.g. 150';
      case 'injection':
        return 'e.g. 5';
      default:
        return 'e.g. 30';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _supplyController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
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
              decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border:
                      Border(bottom: BorderSide(color: AppColors.hairline))),
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
                          decoration: BoxDecoration(
                              color: AppColors.isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 16, color: AppColors.ink700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ADD MEDICATION',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: AppColors.ink400)),
                            Text('New Prescription',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink900,
                                    letterSpacing: -0.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(4, (i) {
                      final s = i + 1;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: s <= _step
                                ? const Color(0xFF2563EB)
                                : (AppColors.isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) {
                      final active = i + 1 <= _step;
                      return Text(_stepLabels[i],
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? const Color(0xFF2563EB)
                                  : AppColors.ink400));
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
                  3 => _buildStep3(),
                  _ => _buildStep4(),
                },
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border(top: BorderSide(color: AppColors.hairline))),
              child: Row(
                children: [
                  if (_step > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step -= 1),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFF3F4F6),
                          foregroundColor: AppColors.ink700,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (_step > 1) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_step < 4) {
                          setState(() => _step += 1);
                        } else {
                          final name = _nameController.text.trim();
                          final dose = _doseController.text.trim();

                          // Validation
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a medication name.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            setState(() => _step = 1);
                            return;
                          }

                          final freq = '$_freq · ${_selectedTimes.join(', ')}';
                          final supply =
                              double.tryParse(_supplyController.text.trim()) ?? 30.0;
                          final doctor = _doctorController.text.trim();
                          final notes = _notesController.text.trim();

                          Color color = AppColors.medBlue;
                          if (_category == 'Blood Pressure') {
                            color = const Color(0xFFEF4444);
                          }
                          if (_category == 'Diabetes') {
                            color = const Color(0xFFF97316);
                          }
                          if (_category == 'Pain Relief') {
                            color = const Color(0xFF8B5CF6);
                          }
                          if (_category == 'Antibiotic') {
                            color = const Color(0xFF22C55E);
                          }
                          if (_category == 'Thyroid') {
                            color = const Color(0xFF3B82F6);
                          }

                          final medState = context.read<MedicationProvider>();
                          final alertTypes = <AlertType>[];
                          if (_reminder) alertTypes.add(AlertType.push);

                          medState.addMedication(
                            Medication(
                              name: name,
                              dose: dose,
                              freq: freq,
                              color: color,
                              refillDays: supply.toInt(),
                              doctor: doctor.isNotEmpty ? doctor : null,
                              notes: notes.isNotEmpty ? notes : null,
                              form: _form,
                              intakeQty: _intakeQty,
                              supplyQty: supply,
                              initialSupply: supply,
                              createdAt: _startDate.millisecondsSinceEpoch,
                            ),
                            types: alertTypes,
                            advanceMinutes: 0,
                          );

                          Navigator.of(context).maybePop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                          _step == 4 ? 'Add Medication ✓' : 'Continue →',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
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
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900),
            decoration: InputDecoration(
              hintText: 'e.g. Lisinopril',
              filled: true,
              fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink700),
                  children: const [
                    TextSpan(text: 'Form'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink700),
                  children: const [
                    TextSpan(text: 'Intake Amount (per dose)'),
                    TextSpan(
                        text: ' *', style: TextStyle(color: AppColors.medRed)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: DropdownButtonFormField<String>(
                  initialValue: _form,
                  dropdownColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                  decoration: InputDecoration(
                    filled: true,
                    isDense: true,
                    fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                  items: const ['Tablet', 'Capsule', 'Liquid', 'Injection']
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) => setState(() => _form = v ?? _form),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _intakeQty.toStringAsFixed(_intakeQty == _intakeQty.toInt() ? 0 : 1),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink900),
                            decoration: InputDecoration(
                              hintText: 'e.g. 1',
                              filled: true,
                              isDense: true,
                              fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _intakeQty = double.tryParse(val) ?? 1.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getIntakeUnit(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getIntakeDescription(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.ink400,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
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
                    border: Border.all(
                        color: selected ? color : AppColors.border, width: 2),
                    color: selected
                        ? color.withValues(
                            alpha: AppColors.isDark ? 0.15 : 0.08)
                        : (AppColors.isDark ? AppColors.cardBg : Colors.white),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c['icon'] as String,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(c['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: selected ? color : AppColors.ink500,
                              height: 1.2)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Dosage (Optional)',
          description: 'Strength of a single unit (e.g. 500mg, 10mg, or 100 units/ml).',
          required: false,
          child: TextFormField(
            controller: _doseController,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900),
            decoration: InputDecoration(
              hintText: 'e.g. 10mg',
              filled: true,
              fillColor:
                  AppColors.isDark ? AppColors.cardBg : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppColors.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF2563EB), width: 1.5)),
            ),
          ),
        ),
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
                  onTap: () => _onFreqChanged(f),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected
                          ? (AppColors.isDark
                              ? const Color(0xFF1E3A8A)
                              : AppColors.medBlueLight)
                          : (AppColors.isDark
                              ? AppColors.cardBg
                              : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? (AppColors.isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF2563EB))
                              : AppColors.border,
                          width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? (AppColors.isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF2563EB))
                                    : AppColors.ink700)),
                        if (selected)
                          Icon(Icons.check_rounded,
                              size: 14,
                              color: AppColors.isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF2563EB)),
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
          child: Column(
            children: List.generate(_selectedTimes.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Time ${index + 1}:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _parseTimeOfDay(_selectedTimes[index]),
                            builder: (context, child) {
                              final mediaQuery = MediaQuery.of(context);
                              return MediaQuery(
                                data: mediaQuery.copyWith(
                                  size: Size(
                                      mediaQuery.size.width,
                                      mediaQuery.size.height < 600.0
                                          ? 800.0
                                          : mediaQuery.size.height),
                                  viewInsets:
                                      mediaQuery.viewInsets.copyWith(bottom: 0),
                                  textScaler: TextScaler.noScaling,
                                ),
                                child: OverflowBox(
                                  minHeight: 340.0,
                                  maxHeight: 800.0,
                                  child: child!,
                                ),
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              final hour = picked.hourOfPeriod == 0
                                  ? 12
                                  : picked.hourOfPeriod;
                              final minute =
                                  picked.minute.toString().padLeft(2, '0');
                              final period =
                                  picked.period == DayPeriod.am ? 'AM' : 'PM';
                              _selectedTimes[index] = '$hour:$minute $period';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.isDark
                                ? AppColors.cardBg
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTimes[index],
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink900),
                              ),
                              const Icon(Icons.access_time_filled_rounded,
                                  size: 16, color: AppColors.medBlue),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Supply & Refill',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getSupplyLabel(),
                  style: TextStyle(fontSize: 11, color: AppColors.ink500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _supplyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink900),
                decoration: InputDecoration(
                  hintText: _getSupplyHint(),
                  filled: true,
                  fillColor:
                      AppColors.isDark ? AppColors.cardBg : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 11),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.border, width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.border, width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Track Start Date (Optional)',
          description: 'Choose when the app should start monitoring and triggering alarms for this medication (defaults to Today).',
          child: GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: isDark
                          ? ColorScheme.dark(
                              primary: AppColors.medBlue,
                              onPrimary: Colors.white,
                              surface: AppColors.cardBg,
                              onSurface: Colors.white,
                            )
                          : ColorScheme.light(
                              primary: AppColors.medBlue,
                              onPrimary: Colors.white,
                              onSurface: AppColors.ink900,
                            ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.isDark ? AppColors.cardBg : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM dd, yyyy').format(_startDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.medBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormField(
          label: 'Prescribing Doctor / Pharmacy (Optional)',
          child: TextFormField(
            controller: _doctorController,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900),
            decoration: InputDecoration(
              hintText: 'e.g. Dr. Smith / Walgreens',
              filled: true,
              fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Notes / Instructions (Optional)',
          child: TextFormField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900),
            decoration: InputDecoration(
              hintText: 'e.g. Take with food, avoid drinking alcohol...',
              filled: true,
              fillColor: AppColors.isDark ? AppColors.cardBg : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.isDark
                ? const Color(0xFF1E3A8A)
                : AppColors.medBlueLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.isDark
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MEDICATION SUMMARY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB),
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900),
                  children: [
                    TextSpan(
                        text:
                            _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Medication'),
                    if (_doseController.text.trim().isNotEmpty) ...[
                      const TextSpan(text: ' '),
                      TextSpan(
                          text: _doseController.text.trim(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16)),
                    ],
                  ],
                ),
              ),
              Text('$_freq · ${_selectedTimes.join(', ')}',
                  style: TextStyle(fontSize: 12, color: AppColors.ink500)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.isDark ? AppColors.cardBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ReminderRow(
                label: 'Push Notification',
                sub: 'At scheduled dose time',
                value: _reminder,
                color: const Color(0xFF3B82F6),
                onChanged: (v) => setState(() => _reminder = v),
                showBorder: true,
              ),
              _ReminderRow(
                label: 'Voice Reminder',
                sub: 'Coming soon — not yet available',
                value: false,
                color: AppColors.medOrange,
                onChanged: (_) {}, // disabled
                showBorder: false,
                disabled: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.isDark
                ? const Color(0xFF1C1F27)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFD1D5DB)),
          ),
          child: Row(
            children: [
              Icon(Icons.mic_off_rounded, size: 16,
                  color: AppColors.isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice reminders are coming in a future update. Push notifications are active.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      height: 1.4),
                ),
              ),
            ],
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
  final bool disabled;

  const _ReminderRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.showBorder,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(bottom: BorderSide(color: AppColors.hairline))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900)),
                      if (disabled) ...[
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
                  Text(sub,
                      style: TextStyle(fontSize: 11, color: AppColors.ink400)),
                ],
              ),
            ),
            GestureDetector(
              onTap: disabled ? null : () => onChanged(!value),
              child: Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                    color: value && !disabled
                        ? color
                        : (AppColors.isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(12)),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value && !disabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4)
                        ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final String? description;
  const _FormField(
      {required this.label, this.required = false, required this.child, this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink700),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                    text: ' *', style: TextStyle(color: AppColors.medRed)),
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description!,
            style: TextStyle(
                fontSize: 10,
                color: AppColors.ink400,
                fontWeight: FontWeight.w500,
                height: 1.3),
          ),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}


