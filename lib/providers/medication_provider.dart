import 'package:flutter/material.dart';
import '../models.dart';
import '../database_helper.dart';
import '../notification_service.dart';

class MedicationProvider extends ChangeNotifier {
  final INotificationService _notificationService;
  MedicationProvider(this._notificationService);

  final List<Medication> _meds = [];
  List<Medication> get meds => List.unmodifiable(_meds);

  final List<ReminderRule> _rules = [];
  List<ReminderRule> get rules => List.unmodifiable(_rules);

  final Map<int, MedCardVariant> _todayMeds = {};
  Map<int, MedCardVariant> get todayMeds => Map.unmodifiable(_todayMeds);

  bool _dbEnabled = true;

  Future<void> load(List<Map<String, dynamic>> medsData, List<Map<String, dynamic>> rulesData, List<Map<String, dynamic>> todayData) async {
    _meds.clear();
    _meds.addAll(medsData.map((m) => Medication(
      id: m['id'] as int,
      name: m['name'] as String,
      dose: m['dose'] as String,
      freq: m['freq'] as String,
      color: Color(m['color'] as int),
      refillDays: m['refillDays'] as int,
      description: m['description'] as String?,
      drugClass: m['drugClass'] as String?,
      sideEffects: m['sideEffects'] as String?,
    )));

    _rules.clear();
    _rules.addAll(rulesData.map((r) {
      final typesStr = r['types'] as String;
      final typesList = typesStr.split(',')
          .where((t) => t.isNotEmpty)
          .map((t) => AlertType.values.firstWhere((v) => v.toString().split('.').last == t))
          .toList();
      return ReminderRule(
        id: r['id'] as int,
        med: r['med'] as String,
        dose: r['dose'] as String,
        time: r['time'] as String,
        types: typesList,
        advance: r['advance'] as int,
        color: Color(r['color'] as int),
        active: r['active'] == 1,
      );
    }));

    _todayMeds.clear();
    for (final row in todayData) {
      final medId = row['med_id'] as int;
      final statusStr = row['status'] as String;
      final status = MedCardVariant.values.firstWhere(
        (v) => v.toString().split('.').last == statusStr,
        orElse: () => MedCardVariant.upcoming,
      );
      _todayMeds[medId] = status;
    }
    notifyListeners();
  }

  void setDbEnabled(bool enabled) {
    _dbEnabled = enabled;
  }

  void setInMemoryDefaults() {
    _meds.clear();
    _meds.addAll(const [
      Medication(name: 'Lisinopril', dose: '10mg', freq: 'Once daily · 8 AM', color: Color(0xFF3B82F6), refillDays: 12),
      Medication(name: 'Metformin', dose: '500mg', freq: 'Twice daily · 8 AM, 8 PM', color: Color(0xFF8B5CF6), refillDays: 5),
      Medication(name: 'Gabapentin', dose: '300mg', freq: 'Once daily · 2 PM', color: Color(0xFFF97316), refillDays: 22),
    ]);
    
    _todayMeds.clear();
    _todayMeds[1] = MedCardVariant.upcoming;
    _todayMeds[2] = MedCardVariant.taken;
    _todayMeds[3] = MedCardVariant.missed;
    
    _rules.clear();
    _rules.addAll(const [
      ReminderRule(id: 1, med: 'Lisinopril', dose: '10mg', time: '8:00 AM', types: [AlertType.push, AlertType.voice], advance: 15, color: Color(0xFF3B82F6), active: true),
      ReminderRule(id: 2, med: 'Metformin', dose: '500mg', time: '8:00 AM', types: [AlertType.push], advance: 10, color: Color(0xFF8B5CF6), active: true),
      ReminderRule(id: 3, med: 'Metformin', dose: '500mg', time: '8:00 PM', types: [AlertType.push, AlertType.voice], advance: 15, color: Color(0xFF8B5CF6), active: true),
      ReminderRule(id: 4, med: 'Gabapentin', dose: '300mg', time: '2:00 PM', types: [AlertType.push, AlertType.sms], advance: 15, color: Color(0xFFF97316), active: false),
    ]);
    notifyListeners();
  }

  Future<void> addMedication(Medication m, {List<AlertType>? types, int? advanceMinutes}) async {
    final dbMedId = m.id ?? DateTime.now().millisecondsSinceEpoch;
    final medWithId = Medication(
      id: dbMedId,
      name: m.name,
      dose: m.dose,
      freq: m.freq,
      color: m.color,
      refillDays: m.refillDays,
      description: m.description,
      drugClass: m.drugClass,
      sideEffects: m.sideEffects,
    );
    
    _meds.add(medWithId);
    
    _todayMeds[dbMedId] = MedCardVariant.upcoming;

    final baseTime = m.freq.contains('·') ? m.freq.split('·').last.trim() : '8:00 AM';
    final times = baseTime.split(',').map((e) => e.trim()).toList();
    
    for (final t in times) {
      final rule = ReminderRule(
        med: m.name,
        dose: m.dose,
        time: t,
        types: types ?? const [AlertType.push],
        advance: advanceMinutes ?? 10,
        color: m.color,
        active: true,
      );
      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          final insertedRuleId = await db.insert('reminder_rules', {
            'med': rule.med,
            'dose': rule.dose,
            'time': rule.time,
            'types': rule.types.map((e) => e.toString().split('.').last).join(','),
            'advance': rule.advance,
            'color': rule.color.toARGB32(),
            'active': rule.active ? 1 : 0,
          });
          final insertedRule = ReminderRule(
            id: insertedRuleId,
            med: rule.med,
            dose: rule.dose,
            time: rule.time,
            types: rule.types,
            advance: rule.advance,
            color: rule.color,
            active: rule.active,
          );
          _rules.add(insertedRule);
          _notificationService.scheduleReminderNotification(insertedRule);
        } catch(e) {
          debugPrint("Failed saving rule: $e");
          final fallbackRule = ReminderRule(
            id: DateTime.now().millisecondsSinceEpoch + times.indexOf(t),
            med: rule.med,
            dose: rule.dose,
            time: rule.time,
            types: rule.types,
            advance: rule.advance,
            color: rule.color,
            active: rule.active,
          );
          _rules.add(fallbackRule);
        }
      } else {
        final localRule = ReminderRule(
          id: DateTime.now().millisecondsSinceEpoch + times.indexOf(t),
          med: rule.med,
          dose: rule.dose,
          time: rule.time,
          types: rule.types,
          advance: rule.advance,
          color: rule.color,
          active: rule.active,
        );
        _rules.add(localRule);
      }
    }

    notifyListeners();

    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final insertedId = await db.insert('medications', {
        'name': m.name,
        'dose': m.dose,
        'freq': m.freq,
        'color': m.color.toARGB32(),
        'refillDays': m.refillDays,
        'description': m.description,
        'drugClass': m.drugClass,
        'sideEffects': m.sideEffects,
      });
      await db.insert('today_meds', {
        'med_id': insertedId,
        'status': MedCardVariant.upcoming.toString().split('.').last,
      });
    } catch(e) {
      debugPrint("DB write error: $e");
    }
  }

  Future<void> removeMedication(int medId) async {
    final idx = _meds.indexWhere((m) => m.id == medId);
    if (idx != -1) {
      final med = _meds[idx];
      _meds.removeAt(idx);
      _todayMeds.remove(medId);
      
      final rulesToRemove = _rules.where((r) => r.med == med.name).toList();
      for (final r in rulesToRemove) {
        _rules.removeWhere((e) => e.id == r.id);
        if (r.id != null) {
          _notificationService.cancelReminder(r.id!);
        }
      }
      notifyListeners();

      if (!_dbEnabled) return;
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('medications', where: 'id = ?', whereArgs: [medId]);
        await db.delete('today_meds', where: 'med_id = ?', whereArgs: [medId]);
        await db.delete('reminder_rules', where: 'med = ?', whereArgs: [med.name]);
      } catch(e) {
        debugPrint("DB write error: $e");
      }
    }
  }

  Future<void> editMedication(int medId, Medication newMed) async {
    final idx = _meds.indexWhere((m) => m.id == medId);
    if (idx != -1) {
      final oldName = _meds[idx].name;
      _meds[idx] = newMed;
      notifyListeners();

      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          await db.update('medications', {
            'name': newMed.name,
            'dose': newMed.dose,
            'freq': newMed.freq,
            'color': newMed.color.toARGB32(),
            'refillDays': newMed.refillDays,
            'description': newMed.description,
            'drugClass': newMed.drugClass,
            'sideEffects': newMed.sideEffects,
          }, where: 'id = ?', whereArgs: [medId]);
        } catch(e) {}
      }

      for (int i = 0; i < _rules.length; i++) {
        final rule = _rules[i];
        if (rule.med == oldName) {
          final newRule = ReminderRule(
            id: rule.id,
            med: newMed.name,
            dose: newMed.dose,
            time: newMed.freq.contains('·') ? newMed.freq.split('·').last.trim() : newMed.freq,
            types: rule.types,
            advance: rule.advance,
            color: newMed.color,
            active: rule.active,
          );
          _rules[i] = newRule;
          
          if (_dbEnabled) {
            try {
              final db = await DatabaseHelper.instance.database;
              await db.update('reminder_rules', {
                'med': newRule.med,
                'dose': newRule.dose,
                'time': newRule.time,
                'color': newRule.color.toARGB32(),
              }, where: 'id = ?', whereArgs: [rule.id]);
            } catch(e) {}
          }
          if (newRule.active && newRule.id != null) {
            _notificationService.scheduleReminderNotification(newRule);
          }
        }
      }
    }
  }

  Future<void> logMedication(int medId, MedCardVariant status) async {
    _todayMeds[medId] = status;
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('today_meds', {
        'status': status.toString().split('.').last,
      }, where: 'med_id = ?', whereArgs: [medId]);
    } catch(e) {
      debugPrint("DB Write Error: $e");
    }
  }

  Future<void> addRule(ReminderRule rule) async {
    final exists = _meds.any((m) => m.name.toLowerCase() == rule.med.toLowerCase());
    if (!exists) {
      final newMedId = DateTime.now().millisecondsSinceEpoch;
      final med = Medication(
        id: newMedId,
        name: rule.med,
        dose: rule.dose,
        freq: 'Once daily · ${rule.time}',
        color: rule.color,
        refillDays: 30,
      );
      _meds.add(med);
      _todayMeds[newMedId] = MedCardVariant.upcoming;

      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          final insertedMedId = await db.insert('medications', {
            'name': med.name,
            'dose': med.dose,
            'freq': med.freq,
            'color': med.color.toARGB32(),
            'refillDays': med.refillDays,
          });
          await db.insert('today_meds', {
            'med_id': insertedMedId,
            'status': 'upcoming',
          });
          
          final insertedRuleId = await db.insert('reminder_rules', {
            'med': rule.med,
            'dose': rule.dose,
            'time': rule.time,
            'types': rule.types.map((e) => e.toString().split('.').last).join(','),
            'advance': rule.advance,
            'color': rule.color.toARGB32(),
            'active': rule.active ? 1 : 0,
          });
          
          _rules.add(ReminderRule(
            id: insertedRuleId,
            med: rule.med,
            dose: rule.dose,
            time: rule.time,
            types: rule.types,
            advance: rule.advance,
            color: rule.color,
            active: rule.active,
          ));
        } catch(e) {}
      } else {
        _rules.add(rule);
      }
      notifyListeners();
    } else {
      _rules.add(rule);
      notifyListeners();
      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          final insertedId = await db.insert('reminder_rules', {
            'med': rule.med,
            'dose': rule.dose,
            'time': rule.time,
            'types': rule.types.map((e) => e.toString().split('.').last).join(','),
            'advance': rule.advance,
            'color': rule.color.toARGB32(),
            'active': rule.active ? 1 : 0,
          });
          
          final idx = _rules.indexOf(rule);
          if (idx != -1) {
            _rules[idx] = ReminderRule(
              id: insertedId,
              med: rule.med,
              dose: rule.dose,
              time: rule.time,
              types: rule.types,
              advance: rule.advance,
              color: rule.color,
              active: rule.active,
            );
            _notificationService.scheduleReminderNotification(_rules[idx]);
          }
        } catch(e) {}
      }
    }
  }

  Future<void> toggleRule(int ruleId) async {
    final idx = _rules.indexWhere((r) => r.id == ruleId);
    if (idx == -1) return;
    final r = _rules[idx];
    _rules[idx] = ReminderRule(
      id: r.id,
      med: r.med,
      dose: r.dose,
      time: r.time,
      types: r.types,
      advance: r.advance,
      color: r.color,
      active: !r.active,
    );
    notifyListeners();

    if (_dbEnabled) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update('reminder_rules', {'active': !r.active ? 1 : 0}, where: 'id = ?', whereArgs: [ruleId]);
      } catch(e) {}
    }

    if (!r.active) {
      _notificationService.scheduleReminderNotification(_rules[idx]);
    } else if (r.id != null) {
      _notificationService.cancelReminder(r.id!);
    }
  }
  
  double calculateAdherence() {
    if (_todayMeds.isEmpty) return 100.0;
    final takenCount = _todayMeds.values.where((v) => v == MedCardVariant.taken).length;
    return (takenCount / _todayMeds.length) * 100;
  }
  
  int get activeRuleCount => _rules.where((r) => r.active).length;
  
  int get activeMedCount {
    final activeMeds = _rules.where((r) => r.active).map((r) => r.med).toSet();
    return activeMeds.length;
  }
}
