import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../database_helper.dart';

class VitalsProvider extends ChangeNotifier {
  final List<VitalStat> _vitals = [];
  List<VitalStat> get vitals => List.unmodifiable(_vitals);
  
  final List<BPReading> _bpReadings = [];
  List<BPReading> get bpReadings => List.unmodifiable(_bpReadings);
  
  bool _dbEnabled = true;

  Future<void> load(List<Map<String, dynamic>> vitalsData, List<Map<String, dynamic>> bpData) async {
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
    
    _bpReadings.clear();
    if (bpData.isNotEmpty) {
      _bpReadings.addAll(bpData.map((b) => BPReading(
        date: b['date'] as String,
        sys: b['sys'] as int,
        dia: b['dia'] as int,
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
    
    _bpReadings.clear();
    _bpReadings.addAll([
      const BPReading(date: 'Jun 28', sys: 132, dia: 86),
      const BPReading(date: 'Jun 29', sys: 128, dia: 84),
      const BPReading(date: 'Jun 30', sys: 130, dia: 85),
      const BPReading(date: 'Jul 1', sys: 125, dia: 82),
      const BPReading(date: 'Jul 2', sys: 122, dia: 80),
      const BPReading(date: 'Jul 3', sys: 120, dia: 79),
      const BPReading(date: 'Jul 4', sys: 118, dia: 75),
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
        'bg': v.bg.toARGB32(),
        'border': v.border.toARGB32(),
        'icon': v.icon,
      });
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }

  Future<void> addBpReading(int sys, int dia) async {
    final dateStr = DateFormat('MMM d').format(DateTime.now());
    final reading = BPReading(date: dateStr, sys: sys, dia: dia);
    _bpReadings.add(reading);
    if (_bpReadings.length > 7) {
      _bpReadings.removeAt(0);
    }
    await updateVital('Blood Pressure', '$sys/$dia');
    
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('bp_readings', {
        'date': dateStr,
        'sys': sys,
        'dia': dia,
      });
    } catch (e) {
      debugPrint("DB BP Insert Error: $e");
    }
  }

  Future<void> updateVital(String label, String value) async {
    final idx = _vitals.indexWhere((v) => v.label == label);
    if (idx != -1) {
      final old = _vitals[idx];
      
      String trend = old.trend;
      Color color = old.color;
      Color bg = old.bg;
      Color border = old.border;
      
      if (label == 'Blood Pressure') {
        final parts = value.split('/');
        if (parts.length == 2) {
          final sys = int.tryParse(parts[0]) ?? 120;
          final dia = int.tryParse(parts[1]) ?? 80;
          if (sys < 120 && dia < 80) {
            trend = 'Normal';
            color = const Color(0xFF10B981);
            bg = const Color(0xFFD1FAE5);
            border = const Color(0xFFA7F3D0);
          } else if (sys < 130 && dia < 80) {
            trend = 'Elevated';
            color = const Color(0xFFF59E0B);
            bg = const Color(0xFFFEF3C7);
            border = const Color(0xFFFDE68A);
          } else if (sys < 140 || dia < 90) {
            trend = 'Stage 1 High';
            color = const Color(0xFFF97316);
            bg = const Color(0xFFFFEDD5);
            border = const Color(0xFFFED7AA);
          } else {
            trend = 'Stage 2 High';
            color = const Color(0xFFEF4444);
            bg = const Color(0xFFFEE2E2);
            border = const Color(0xFFFCA5A5);
          }
        }
      } else if (label == 'Heart Rate') {
        final hr = int.tryParse(value) ?? 72;
        if (hr >= 60 && hr <= 100) {
          trend = 'Normal';
          color = const Color(0xFF10B981);
          bg = const Color(0xFFD1FAE5);
          border = const Color(0xFFA7F3D0);
        } else if (hr < 60) {
          trend = 'Low (Bradycardia)';
          color = const Color(0xFFEF4444);
          bg = const Color(0xFFFEE2E2);
          border = const Color(0xFFFCA5A5);
        } else {
          trend = 'High (Tachycardia)';
          color = const Color(0xFFEF4444);
          bg = const Color(0xFFFEE2E2);
          border = const Color(0xFFFCA5A5);
        }
      } else if (label == 'Blood Sugar') {
        final bs = int.tryParse(value) ?? 98;
        if (bs >= 70 && bs <= 140) {
          trend = 'Normal';
          color = const Color(0xFF10B981);
          bg = const Color(0xFFD1FAE5);
          border = const Color(0xFFA7F3D0);
        } else if (bs < 70) {
          trend = 'Low (Hypoglycemia)';
          color = const Color(0xFFEF4444);
          bg = const Color(0xFFFEE2E2);
          border = const Color(0xFFFCA5A5);
        } else {
          trend = 'High (Hyperglycemia)';
          color = const Color(0xFFEF4444);
          bg = const Color(0xFFFEE2E2);
          border = const Color(0xFFFCA5A5);
        }
      } else if (label == 'Weight') {
        final currentWeight = double.tryParse(value) ?? 168.4;
        final prevWeight = double.tryParse(old.value) ?? 168.4;
        final diff = currentWeight - prevWeight;
        if (diff < 0) {
          trend = '↓ ${diff.toStringAsFixed(1)} lbs';
          color = const Color(0xFF10B981);
          bg = const Color(0xFFD1FAE5);
          border = const Color(0xFFA7F3D0);
        } else if (diff > 0) {
          trend = '↑ +${diff.toStringAsFixed(1)} lbs';
          color = const Color(0xFFEF4444);
          bg = const Color(0xFFFEE2E2);
          border = const Color(0xFFFCA5A5);
        } else {
          trend = '→ stable';
          color = const Color(0xFF3B82F6);
          bg = const Color(0xFFDBEAFE);
          border = const Color(0xFF93C5FD);
        }
      }
      
      _vitals[idx] = VitalStat(
        label: label,
        value: value,
        unit: old.unit,
        trend: trend,
        color: color,
        bg: bg,
        border: border,
        icon: old.icon,
      );
      
      notifyListeners();
      
      if (!_dbEnabled) return;
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update('vitals', {
          'value': value,
          'trend': trend,
          'color': color.toARGB32(),
          'bg': bg.toARGB32(),
          'border': border.toARGB32(),
        }, where: 'label = ?', whereArgs: [label]);
      } catch (e) {
        debugPrint("DB Vital Update Error: $e");
      }
    }
  }
}
