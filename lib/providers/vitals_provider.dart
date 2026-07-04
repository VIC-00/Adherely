import 'package:flutter/material.dart';
import '../models.dart';
import '../database_helper.dart';

class VitalsProvider extends ChangeNotifier {
  final List<VitalStat> _vitals = [];
  List<VitalStat> get vitals => List.unmodifiable(_vitals);
  
  bool _dbEnabled = true;

  Future<void> load(List<Map<String, dynamic>> vitalsData) async {
    _vitals.clear();
    if (vitalsData.isNotEmpty) {
      _vitals.addAll(vitalsData.map((v) => VitalStat(
        label: v['label'] as String,
        value: v['value'] as String,
        unit: v['unit'] as String,
        trend: v['trend'] as String,
        color: Color(v['color'] as int),
        bg: Color(v['bg'] as int),
        border: Color(v['border'] as int),
        icon: v['icon'] as String,
      )));
    }
    notifyListeners();
  }
  
  void setDbEnabled(bool enabled) {
    _dbEnabled = enabled;
  }
  
  void setInMemoryDefaults() {
    _vitals.clear();
    _vitals.addAll([
      const VitalStat(label: 'Blood Pressure', value: '118/75', unit: 'mmHg', trend: '↓ improving', color: Color(0xFF10B981), bg: Color(0xFFD1FAE5), border: Color(0xFFA7F3D0), icon: '❤️'),
      const VitalStat(label: 'Heart Rate', value: '72', unit: 'bpm', trend: '↓ stable', color: Color(0xFF3B82F6), bg: Color(0xFFDBEAFE), border: Color(0xFF93C5FD), icon: '⚡'),
      const VitalStat(label: 'Blood Sugar', value: '98', unit: 'mg/dL', trend: '→ stable', color: Color(0xFF14B8A6), bg: Color(0xFFF0FDFA), border: Color(0xFFCCFBF1), icon: '🩸'),
      const VitalStat(label: 'Weight', value: '168.4', unit: 'lbs', trend: '↓ -1.2 lbs', color: Color(0xFF10B981), bg: Color(0xFFD1FAE5), border: Color(0xFFA7F3D0), icon: '⚖️'),
    ]);
    notifyListeners();
  }

  Future<void> addVital(VitalStat v) async {
    _vitals.add(v);
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('vitals', {
        'label': v.label,
        'value': v.value,
        'unit': v.unit,
        'trend': v.trend,
        'color': v.color.toARGB32(),
        'bg': v.bg.value,
        'border': v.border.value,
        'icon': v.icon,
      });
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }

  // Simple hardcoded bp list to replicate existing appstate logic
  List<BPReading> get bpReadings => const [
    BPReading(date: 'Jun 28', sys: 132, dia: 86),
    BPReading(date: 'Jun 29', sys: 128, dia: 84),
    BPReading(date: 'Jun 30', sys: 130, dia: 85),
    BPReading(date: 'Jul 1', sys: 125, dia: 82),
    BPReading(date: 'Jul 2', sys: 122, dia: 80),
    BPReading(date: 'Jul 3', sys: 120, dia: 79),
    BPReading(date: 'Jul 4', sys: 118, dia: 75),
  ];

  void addBpReading(int sys, int dia) { }
}
