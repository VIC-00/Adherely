import 'package:flutter/material.dart';
import '../models.dart';
import '../database_helper.dart';
import '../notification_service.dart';
import 'package:intl/intl.dart';
import '../utils/medication_library.dart';

class MedicationProvider extends ChangeNotifier {
  final INotificationService _notificationService;
  MedicationProvider(this._notificationService);

  final List<Medication> _meds = [];
  List<Medication> get meds => List.unmodifiable(_meds);

  final List<ReminderRule> _rules = [];
  List<ReminderRule> get rules => List.unmodifiable(_rules);

  final Map<int, MedCardVariant> _todayMeds = {};
  Map<int, MedCardVariant> get todayMeds => Map.unmodifiable(_todayMeds);
  
  Map<int, MedCardVariant> get dynamicTodayMeds {
    final Map<int, MedCardVariant> dynamicMeds = {};
    for (final med in _meds) {
      if (med.id != null) {
        dynamicMeds[med.id!] = getTodayMedStatus(med);
      }
    }
    return dynamicMeds;
  }

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
      doctor: m['doctor'] as String?,
      notes: m['notes'] as String?,
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
    _todayMeds.clear();
    _rules.clear();
    notifyListeners();
  }
  Future<void> addMedication(Medication m, {List<AlertType>? types, int? advanceMinutes}) async {
    final Map<String, String?> libraryDetails = MedicationLibrary.getDetails(m.name) ?? <String, String?>{
      'drugClass': 'General Medication',
      'description': 'Used to treat symptoms as directed by your healthcare provider. Please consult your physician or pharmacist for specific instructions and details about this medication.',
      'sideEffects': null
    };

    int medId;
    if (_dbEnabled) {
      try {
        final db = await DatabaseHelper.instance.database;
        medId = await db.insert('medications', {
          'name': m.name,
          'dose': m.dose,
          'freq': m.freq,
          'color': m.color.toARGB32(),
          'refillDays': m.refillDays,
          'description': m.description ?? libraryDetails['description'],
          'drugClass': m.drugClass ?? libraryDetails['drugClass'],
          'sideEffects': m.sideEffects ?? libraryDetails['sideEffects'],
          'doctor': m.doctor,
          'notes': m.notes,
        });

        await db.insert('today_meds', {
          'med_id': medId,
          'status': MedCardVariant.upcoming.toString().split('.').last,
        });
      } catch (e) {
        debugPrint("DB write error: $e");
        medId = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      medId = DateTime.now().millisecondsSinceEpoch;
    }

    final medWithId = Medication(
      id: medId,
      name: m.name,
      dose: m.dose,
      freq: m.freq,
      color: m.color,
      refillDays: m.refillDays,
      description: m.description ?? libraryDetails['description'],
      drugClass: m.drugClass ?? libraryDetails['drugClass'],
      sideEffects: m.sideEffects ?? libraryDetails['sideEffects'],
      doctor: m.doctor,
      notes: m.notes,
    );
    
    _meds.add(medWithId);
    _todayMeds[medId] = MedCardVariant.upcoming;

    final baseTime = m.freq.contains('·') ? m.freq.split('·').last.trim() : '8:00 AM';
    final times = baseTime.split(',').map((e) => e.trim()).toList();
    
    for (final t in times) {
      final rule = ReminderRule(
        med: m.name,
        dose: m.dose,
        time: t,
        types: types ?? const [AlertType.push],
        advance: advanceMinutes ?? 0,
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
          _notificationService.scheduleReminderNotification(fallbackRule);
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
        _notificationService.scheduleReminderNotification(localRule);
      }
    }

    notifyListeners();
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
            'doctor': newMed.doctor,
            'notes': newMed.notes,
          }, where: 'id = ?', whereArgs: [medId]);
        } catch (e) {
          debugPrint('DB updateMedication error: $e');
        }
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
            } catch (e) {
              debugPrint('DB updateRule error: $e');
            }
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

      // Cancel and reschedule alarms for this medication based on the new taken status
      final medList = _meds.where((m) => m.id == medId);
      if (medList.isNotEmpty) {
        final med = medList.first;
        final medRules = _rules.where((r) => r.med.toLowerCase() == med.name.toLowerCase());
        for (final rule in medRules) {
          if (rule.id != null) {
            await _notificationService.cancelReminder(rule.id!);
            if (rule.active) {
              await _notificationService.scheduleReminderNotification(rule);
            }
          }
        }
      }
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

      ReminderRule finalRule = rule;

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
          
          finalRule = ReminderRule(
            id: insertedRuleId,
            med: rule.med,
            dose: rule.dose,
            time: rule.time,
            types: rule.types,
            advance: rule.advance,
            color: rule.color,
            active: rule.active,
          );
        } catch(e) {
          debugPrint("Failed saving rule: $e");
          finalRule = ReminderRule(
            id: DateTime.now().millisecondsSinceEpoch,
            med: rule.med,
            dose: rule.dose,
            time: rule.time,
            types: rule.types,
            advance: rule.advance,
            color: rule.color,
            active: rule.active,
          );
        }
      } else {
        finalRule = ReminderRule(
          id: DateTime.now().millisecondsSinceEpoch,
          med: rule.med,
          dose: rule.dose,
          time: rule.time,
          types: rule.types,
          advance: rule.advance,
          color: rule.color,
          active: rule.active,
        );
      }
      _rules.add(finalRule);
      if (finalRule.active) {
        _notificationService.scheduleReminderNotification(finalRule);
      }
      notifyListeners();
    } else {
      ReminderRule finalRule = rule;
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
          
          finalRule = ReminderRule(
            id: insertedId,
            med: rule.med,
            dose: rule.dose,
            time: rule.time,
            types: rule.types,
            advance: rule.advance,
            color: rule.color,
            active: rule.active,
          );
        } catch(e) {
          debugPrint("Failed saving rule: $e");
          finalRule = ReminderRule(
            id: DateTime.now().millisecondsSinceEpoch,
            med: rule.med,
            dose: rule.dose,
            time: rule.time,
            types: rule.types,
            advance: rule.advance,
            color: rule.color,
            active: rule.active,
          );
        }
      } else {
        finalRule = ReminderRule(
          id: DateTime.now().millisecondsSinceEpoch,
          med: rule.med,
          dose: rule.dose,
          time: rule.time,
          types: rule.types,
          advance: rule.advance,
          color: rule.color,
          active: rule.active,
        );
      }
      _rules.add(finalRule);
      if (finalRule.active) {
        _notificationService.scheduleReminderNotification(finalRule);
      }
      notifyListeners();
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
      } catch (e) {
        debugPrint('DB toggleRule error: $e');
      }
    }

    if (!r.active) {
      _notificationService.scheduleReminderNotification(_rules[idx]);
    } else if (r.id != null) {
      _notificationService.cancelReminder(r.id!);
    }
  }
  
  double calculateAdherence() {
    if (_todayMeds.isEmpty) return 0.0;
    final takenCount = _todayMeds.values.where((v) => v == MedCardVariant.taken).length;
    return (takenCount / _todayMeds.length) * 100;
  }
  
  int get activeRuleCount => _rules.where((r) => r.active).length;
  
  int get activeMedCount {
    final activeMeds = _rules.where((r) => r.active).map((r) => r.med).toSet();
    return activeMeds.length;
  }

  MedCardVariant getTodayMedStatus(Medication med) {
    if (med.id == null) return MedCardVariant.upcoming;
    final rawStatus = _todayMeds[med.id!];
    if (rawStatus == null) return MedCardVariant.upcoming;
    if (rawStatus == MedCardVariant.upcoming) {
      final timeStr = med.freq.contains('·')
          ? med.freq.split('·').last.trim()
          : med.freq;
      // Split by comma to check each individual time slot (e.g. "8:00 AM, 8:00 PM")
      // If ANY scheduled time has passed and the med hasn't been taken → missed
      final slots = timeStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      if (slots.any((t) => _hasTimePassed(t))) {
        return MedCardVariant.missed;
      }
    }
    return rawStatus;
  }

  bool _hasTimePassed(String timeStr) {
    try {
      final cleanTime = timeStr.trim();
      final format = DateFormat('h:mm a');
      final parsedTime = format.parse(cleanTime);
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      return now.isAfter(scheduledDateTime);
    } catch (_) {
      try {
        final parsedTime = DateFormat('HH:mm').parse(timeStr.trim());
        final now = DateTime.now();
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );
        return now.isAfter(scheduledDateTime);
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> rescheduleRule(int medId, String oldTime, String newTime) async {
    // Use orElse so we don't throw if the med is no longer in the list
    final medMatches = _meds.where((m) => m.id == medId);
    if (medMatches.isEmpty) return;
    final med = medMatches.first;
    final ruleIdx = _rules.indexWhere((r) => r.med == med.name && r.time == oldTime);
    if (ruleIdx != -1) {
      final oldRule = _rules[ruleIdx];
      // Cancel old alarm
      await _notificationService.cancelReminder(oldRule.id!);
      
      // Update rule in memory
      final updatedRule = ReminderRule(
        id: oldRule.id,
        med: oldRule.med,
        dose: oldRule.dose,
        time: newTime,
        types: oldRule.types,
        advance: oldRule.advance,
        color: oldRule.color,
        active: oldRule.active,
      );
      _rules[ruleIdx] = updatedRule;
      
      // Schedule new alarm
      await _notificationService.scheduleReminderNotification(updatedRule);
      
      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          await db.update(
            'reminder_rules',
            {'time': newTime},
            where: 'id = ?',
            whereArgs: [oldRule.id],
          );
        } catch (e) {
          debugPrint('DB rescheduleRule (rule) error: $e');
        }
      }
    }
    
    // 2. Update the medication freq string in memory & DB
    final medIdx = _meds.indexWhere((m) => m.id == medId);
    if (medIdx != -1) {
      final med = _meds[medIdx];
      final baseFreq = med.freq.split('·').first.trim();
      final timePart = med.freq.split('·').last.trim();
      final times = timePart.split(',').map((e) => e.trim()).toList();
      final timeIdx = times.indexOf(oldTime);
      if (timeIdx != -1) {
        times[timeIdx] = newTime;
      } else {
        if (times.isNotEmpty) times[0] = newTime;
      }
      final newFreq = '$baseFreq · ${times.join(', ')}';
      
      _meds[medIdx] = Medication(
        id: med.id,
        name: med.name,
        dose: med.dose,
        freq: newFreq,
        color: med.color,
        refillDays: med.refillDays,
        description: med.description,
        drugClass: med.drugClass,
        sideEffects: med.sideEffects,
      );
      
      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          await db.update(
            'medications',
            {'freq': newFreq},
            where: 'id = ?',
            whereArgs: [medId],
          );
        } catch (e) {
          debugPrint('DB rescheduleRule (med freq) error: $e');
        }
      }
    }
    
    // 3. Mark the state back to upcoming
    _todayMeds[medId] = MedCardVariant.upcoming;
    if (_dbEnabled) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'today_meds',
          {'status': 'upcoming'},
          where: 'med_id = ?',
          whereArgs: [medId],
        );
      } catch (e) {
        debugPrint('DB rescheduleRule (today_meds) error: $e');
      }
    }
    
    notifyListeners();
  }
}
