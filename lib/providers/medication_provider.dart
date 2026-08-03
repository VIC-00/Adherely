import 'package:flutter/material.dart';
import '../models.dart';
import '../database_helper.dart';
import '../notification_service.dart';
import 'package:intl/intl.dart';
import '../utils/medication_library.dart';
import '../utils/time_utils.dart';

class MedicationProvider extends ChangeNotifier {
  final INotificationService _notificationService;
  MedicationProvider(this._notificationService);

  final List<Medication> _meds = [];
  List<Medication> get meds => List.unmodifiable(_meds);

  final List<ReminderRule> _rules = [];
  List<ReminderRule> get rules => List.unmodifiable(_rules);

  final Map<int, MedCardVariant> _todayMeds = {};
  Map<int, MedCardVariant> get todayMeds => Map.unmodifiable(_todayMeds);
  
  final Map<int, int> _todayTakenCounts = {};
  Map<int, int> get todayTakenCounts => _todayTakenCounts;
  
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

  Future<void> load(List<Map<String, dynamic>> medsData, List<Map<String, dynamic>> rulesData, List<Map<String, dynamic>> todayData, List<Map<String, dynamic>> historyData) async {
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
      form: m['form'] as String?,
      intakeQty: (m['intakeQty'] as num?)?.toDouble() ?? 1.0,
      supplyQty: (m['supplyQty'] as num?)?.toDouble() ?? 0.0,
      initialSupply: (m['initialSupply'] as num?)?.toDouble() ?? 0.0,
      createdAt: m['createdAt'] as int?,
    )));

    _rules.clear();
    _rules.addAll(rulesData.map((r) {
      final typesStr = r['types'] as String;
      final typesList = typesStr.split(',')
          .where((t) => t.isNotEmpty)
          .map((t) => AlertTypeCodec.fromString(t))
          .whereType<AlertType>() // drops unknown/corrupt values gracefully
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
      final status = MedCardVariantCodec.fromString(statusStr);
      _todayMeds[medId] = status;
    }

    _todayTakenCounts.clear();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final row in historyData) {
      final date = row['date'] as String;
      final taken = row['taken'] as int;
      if (date == todayStr && taken == 1) {
        final medName = (row['med'] as String).trim().toLowerCase();
        final medMatch = _meds.firstWhere(
            (m) => medName.startsWith(m.name.trim().toLowerCase()),
            orElse: () => const Medication(name: '', dose: '', freq: '', color: Colors.blue, refillDays: 0));
        if (medMatch.id != null) {
          _todayTakenCounts[medMatch.id!] = (_todayTakenCounts[medMatch.id!] ?? 0) + 1;
        }
      }
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

    // In DB mode, let SQLite's AUTOINCREMENT assign the ID and read it back.
    // In in-memory mode only, fall back to a timestamp as a local surrogate.
    int medId;
    final customCreatedAt = m.createdAt ?? DateTime.now().millisecondsSinceEpoch;

    if (_dbEnabled) {
      try {
        final db = await DatabaseHelper.instance.database;
        // No 'id' field — SQLite AUTOINCREMENT assigns it.
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
          'form': m.form,
          'intakeQty': m.intakeQty,
          'supplyQty': m.supplyQty,
          'initialSupply': m.initialSupply,
          'createdAt': customCreatedAt,
        });

        await db.insert('today_meds', {
          'med_id': medId,
          'status': MedCardVariant.upcoming.toStorageString(),
        });
      } catch (e) {
        debugPrint("DB write error: $e");
        // Fall back to timestamp surrogate so the med is still usable in-memory.
        medId = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      // In-memory mode: no DB, use timestamp as a local surrogate key.
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
      form: m.form,
      intakeQty: m.intakeQty,
      supplyQty: m.supplyQty,
      initialSupply: m.initialSupply,
      createdAt: customCreatedAt,
    );
    
    _meds.add(medWithId);
    _todayMeds[medId] = MedCardVariant.upcoming;

    if (!m.freq.toLowerCase().contains('as needed')) {
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
              'types': rule.types.map((e) => e.toStorageString()).join(','),
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
      final oldMed = _meds[idx];
      final oldName = oldMed.name;
      
      // Preserve createdAt from the existing record if the incoming edit doesn't set one.
      final finalMed = newMed.copyWith(
        createdAt: newMed.createdAt ?? oldMed.createdAt,
      );
      
      _meds[idx] = finalMed;
      notifyListeners();

      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          await db.update('medications', {
            'name': finalMed.name,
            'dose': finalMed.dose,
            'freq': finalMed.freq,
            'color': finalMed.color.toARGB32(),
            'refillDays': finalMed.refillDays,
            'description': finalMed.description,
            'drugClass': finalMed.drugClass,
            'sideEffects': finalMed.sideEffects,
            'doctor': finalMed.doctor,
            'notes': finalMed.notes,
            'form': finalMed.form,
            'intakeQty': finalMed.intakeQty,
            'supplyQty': finalMed.supplyQty,
            'initialSupply': finalMed.initialSupply,
            'createdAt': finalMed.createdAt,
          }, where: 'id = ?', whereArgs: [medId]);
        } catch (e) {
          debugPrint('DB updateMedication error: $e');
        }
      }

      // Extract the individual time slots from the new freq string —
      // same logic as addMedication so the two stay in sync.
      final freqTimePart = newMed.freq.contains('·')
          ? newMed.freq.split('·').last.trim()
          : newMed.freq;
      final newTimes = freqTimePart
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Collect the existing rules that belong to this medication (in order)
      // so we can pair rule[i] → newTimes[i].
      final matchingRuleIndices = <int>[];
      for (int i = 0; i < _rules.length; i++) {
        if (_rules[i].med == oldName) matchingRuleIndices.add(i);
      }

      for (int j = 0; j < matchingRuleIndices.length; j++) {
        final i = matchingRuleIndices[j];
        final rule = _rules[i];
        // If freq changed from twice-daily to once-daily (or vice-versa), the
        // counts may not match — fall back to the last available time slot.
        final assignedTime = newTimes.isNotEmpty
            ? newTimes[j.clamp(0, newTimes.length - 1)]
            : rule.time;

        final newRule = ReminderRule(
          id: rule.id,
          med: newMed.name,
          dose: newMed.dose,
          time: assignedTime,
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

  Future<void> logMedication(int medId, MedCardVariant status) async {
    _todayMeds[medId] = status;
    if (status == MedCardVariant.taken) {
      _todayTakenCounts[medId] = (_todayTakenCounts[medId] ?? 0) + 1;

      final medIdx = _meds.indexWhere((m) => m.id == medId);
      if (medIdx != -1) {
        final med = _meds[medIdx];
        final newSupply = (med.supplyQty - med.intakeQty).clamp(0.0, double.infinity);
        _meds[medIdx] = med.copyWith(supplyQty: newSupply);
      }
    }
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;

      if (status == MedCardVariant.taken) {
        final medIdx = _meds.indexWhere((m) => m.id == medId);
        if (medIdx != -1) {
          final newSupply = _meds[medIdx].supplyQty;
          await db.update('medications', {
            'supplyQty': newSupply,
          }, where: 'id = ?', whereArgs: [medId]);
        }
      }

      await db.update('today_meds', {
        'status': status.toStorageString(),
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

  Future<void> addRule(
    ReminderRule rule, {
    String? form,
    double intakeQty = 1.0,
    double supplyQty = 0.0,
    double initialSupply = 0.0,
  }) async {
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
        form: form,
        intakeQty: intakeQty,
        supplyQty: supplyQty,
        initialSupply: initialSupply,
        createdAt: newMedId,
      );
      _meds.add(med);
      _todayMeds[newMedId] = MedCardVariant.upcoming;

      ReminderRule finalRule = rule;

      if (_dbEnabled) {
        try {
          final db = await DatabaseHelper.instance.database;
          final insertedMedId = await db.insert('medications', {
            'id': med.id,
            'name': med.name,
            'dose': med.dose,
            'freq': med.freq,
            'color': med.color.toARGB32(),
            'refillDays': med.refillDays,
            'form': med.form,
            'intakeQty': med.intakeQty,
            'supplyQty': med.supplyQty,
            'initialSupply': med.initialSupply,
            'createdAt': med.createdAt,
          });
          await db.insert('today_meds', {
            'med_id': insertedMedId,
            'status': 'upcoming',
          });
          
          final insertedRuleId = await db.insert('reminder_rules', {
            'med': rule.med,
            'dose': rule.dose,
            'time': rule.time,
            'types': rule.types.map((e) => e.toStorageString()).join(','),
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
            'types': rule.types.map((e) => e.toStorageString()).join(','),
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
  
  bool isRuleBeforeCreation(ReminderRule r, Medication med) {
    final createdMs = med.createdAt ?? med.id;
    if (createdMs == null || createdMs < 1000000000000) return false;
    final creationDate = DateTime.fromMillisecondsSinceEpoch(createdMs);
    final now = DateTime.now();
    
    final today = DateTime(now.year, now.month, now.day);
    final creationDateOnly = DateTime(creationDate.year, creationDate.month, creationDate.day);
    
    if (today.isBefore(creationDateOnly)) {
      return true;
    }
    return false;
  }

  double calculateAdherence() {
    int totalPassed = 0;
    int totalTaken = 0;

    final uniqueMeds = _meds.where((m) => _rules.any((r) => r.med.toLowerCase() == m.name.toLowerCase() && r.active)).toList();
    if (uniqueMeds.isEmpty) return 0.0;

    for (final med in uniqueMeds) {
      final medRules = _rules.where((r) => r.med.toLowerCase() == med.name.toLowerCase() && r.active).toList();
      final passedRulesCount = medRules.where((r) {
        if (isRuleBeforeCreation(r, med)) return false;
        return _hasTimePassed(r.time);
      }).length;
      final takenCount = _todayTakenCounts[med.id!] ?? 0;

      totalPassed += passedRulesCount;
      totalTaken += takenCount.clamp(0, passedRulesCount);
    }

    if (totalPassed == 0) return 100.0;
    return (totalTaken / totalPassed) * 100;
  }
  
  int get activeRuleCount => _rules.where((r) => r.active).length;
  
  int get activeMedCount {
    final activeMeds = _rules.where((r) => r.active).map((r) => r.med).toSet();
    return activeMeds.length;
  }

  MedCardVariant getTodayMedStatus(Medication med) {
    if (med.id == null) return MedCardVariant.upcoming;

    final createdMs = med.createdAt ?? med.id;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (createdMs != null && createdMs >= 1000000000000) {
      final creationDate = DateTime.fromMillisecondsSinceEpoch(createdMs);
      final creationDateOnly = DateTime(creationDate.year, creationDate.month, creationDate.day);
      if (today.isBefore(creationDateOnly)) {
        return MedCardVariant.future;
      }
    }

    final medRules = _rules.where((r) => r.med.toLowerCase() == med.name.toLowerCase() && r.active).toList();
    if (medRules.isEmpty) return MedCardVariant.upcoming;

    medRules.sort((a, b) => TimeUtils.toDouble(a.time).compareTo(TimeUtils.toDouble(b.time)));

    final takenCount = _todayTakenCounts[med.id!] ?? 0;
    final totalRules = medRules.length;
    final passedRules = medRules.where((r) {
      if (isRuleBeforeCreation(r, med)) return false;
      return _hasTimePassed(r.time);
    }).toList();

    if (takenCount >= totalRules) {
      return MedCardVariant.taken;
    } else if (takenCount < passedRules.length) {
      return MedCardVariant.missed;
    } else {
      return MedCardVariant.upcoming;
    }
  }


  String getNextDoseTime(Medication med) {
    final medRules = _rules.where((r) => r.med.toLowerCase() == med.name.toLowerCase() && r.active).toList();
    if (medRules.isEmpty) return med.freq;
    medRules.sort((a, b) => TimeUtils.toDouble(a.time).compareTo(TimeUtils.toDouble(b.time)));
    final takenCount = _todayTakenCounts[med.id!] ?? 0;
    if (takenCount < medRules.length) {
      return medRules[takenCount].time;
    }
    return medRules.last.time;
  }

  String getNextMissedDoseTime(Medication med) {
    final medRules = _rules.where((r) => r.med.toLowerCase() == med.name.toLowerCase() && r.active).toList();
    if (medRules.isEmpty) return med.freq;
    medRules.sort((a, b) => TimeUtils.toDouble(a.time).compareTo(TimeUtils.toDouble(b.time)));
    final takenCount = _todayTakenCounts[med.id!] ?? 0;
    final passedRules = medRules.where((r) {
      if (isRuleBeforeCreation(r, med)) return false;
      return _hasTimePassed(r.time);
    }).toList();

    if (takenCount < passedRules.length) {
      return passedRules[takenCount].time;
    }
    return medRules.first.time;
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
      if (oldRule.id == null) return; // rule was never persisted; nothing to cancel
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
      
      _meds[medIdx] = med.copyWith(freq: newFreq);
      
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
