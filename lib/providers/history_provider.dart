import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../database_helper.dart';
import '../utils/time_utils.dart';

class HistoryProvider extends ChangeNotifier {
  DateTime _currentHistoryMonth = DateTime.now();
  DateTime get currentHistoryMonth => _currentHistoryMonth;

  String get currentHistoryMonthLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_currentHistoryMonth.month - 1]} ${_currentHistoryMonth.year}';
  }

  void previousHistoryMonth() {
    _currentHistoryMonth = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month - 1, 1);
    _missedDosesCache = null; // month changed — recount on next read
    notifyListeners();
  }

  void nextHistoryMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final next = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month + 1, 1);
    if (next.isAfter(currentMonth)) return; // don't go past the current month
    _currentHistoryMonth = next;
    _missedDosesCache = null; // month changed — recount on next read
    notifyListeners();
  }

  /// Cached count of missed doses for the currently displayed calendar month.
  /// Invalidated by [load], [logHistory], [previousHistoryMonth], and [nextHistoryMonth].
  int? _missedDosesCache;

  int get missedDoses {
    if (_missedDosesCache != null) return _missedDosesCache!;
    // Only count missed doses within the currently displayed calendar month.
    _missedDosesCache = _historyItems.where((i) {
      if (i.taken) return false;
      try {
        final date = DateTime.parse(i.date);
        return date.year == _currentHistoryMonth.year &&
            date.month == _currentHistoryMonth.month;
      } catch (_) {
        return false;
      }
    }).length;
    return _missedDosesCache!;
  }

  List<List<CalendarCell>> getCalRows(List<ReminderRule> rules, List<Medication> meds) {
    final firstDay = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month, 1);
    final daysInMonth = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; 
    
    List<List<CalendarCell>> rows = [];
    List<CalendarCell> currentRow = List.filled(startWeekday, const CalendarCell(0, DayStatus.empty), growable: true);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month, day);
      DayStatus status = DayStatus.future;
      
      if (!cellDate.isAfter(today)) {
        final dayItems = getDosesForDay(cellDate, rules, meds);
        if (dayItems.isEmpty) {
          status = DayStatus.future; // stays white
        } else {
          final takenCount = dayItems.where((h) => h.taken).length;
          if (takenCount == dayItems.length) {
            status = DayStatus.taken;
          } else if (takenCount > 0) {
            status = DayStatus.partial;
          } else {
            status = DayStatus.missed;
          }
        }
      }
      
      currentRow.add(CalendarCell(day, status)); 
      if (currentRow.length == 7) {
        rows.add(currentRow);
        currentRow = [];
      }
    }
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const CalendarCell(0, DayStatus.empty));
      }
      rows.add(currentRow);
    }
    return rows;
  }

  int getMissedDosesCount(List<ReminderRule> rules, List<Medication> meds) {
    final daysInMonth = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month + 1, 0).day;
    int count = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month, day);
      final dayItems = getDosesForDay(cellDate, rules, meds);
      count += dayItems.where((h) => !h.taken).length;
    }
    return count;
  }

  /// Cache of per-medication adherence percentages.
  /// Cleared whenever [_historyItems] changes (load / logHistory).
  final Map<String, int> _adherenceCache = {};

  int getMedicationAdherence(String medName) {
    final key = medName.toLowerCase();
    if (_adherenceCache.containsKey(key)) return _adherenceCache[key]!;
    final medLogs = _historyItems
        .where((h) => h.med.toLowerCase().contains(key))
        .toList();
    if (medLogs.isEmpty) {
      _adherenceCache[key] = 0;
      return 0;
    }
    final takenCount = medLogs.where((h) => h.taken).length;
    final result = ((takenCount / medLogs.length) * 100).toInt();
    _adherenceCache[key] = result;
    return result;
  }

  final List<HistoryItem> _historyItems = [];
  List<HistoryItem> get historyItems => List.unmodifiable(_historyItems);
  
  bool _dbEnabled = true;

  Future<void> load(List<Map<String, dynamic>> historyData) async {
    _historyItems.clear();
    _historyItems.addAll(historyData.map((h) => HistoryItem(
      id: h['id'] as int,
      med: h['med'] as String,
      date: h['date'] as String,
      time: h['time'] as String,
      taken: h['taken'] == 1,
      note: h['note'] as String,
    )));
    _adherenceCache.clear();      // invalidate stale cached adherence values
    _weeklyAdherenceCache = null; // invalidate stale weekly adherence
    _missedDosesCache = null;     // invalidate stale missed-dose count
    notifyListeners();
  }
  
  void setDbEnabled(bool enabled) {
    _dbEnabled = enabled;
  }

  void setInMemoryDefaults() {
    _historyItems.clear();
    _adherenceCache.clear();
    _weeklyAdherenceCache = null;
    _missedDosesCache = null;
    notifyListeners();
  }

  String formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('MMM d').format(date)}';
    }
    return DateFormat('MMM d').format(date);
  }

  Future<void> logHistory(HistoryItem item) async {
    _historyItems.insert(0, item);
    _adherenceCache.clear();      // new dose changes adherence for this medication
    _weeklyAdherenceCache = null; // new dose may shift this week's rate
    _missedDosesCache = null;     // new dose may change the missed count
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('history_items', {
        'med': item.med,
        'date': item.date,
        'time': item.time,
        'taken': item.taken ? 1 : 0,
        'note': item.note,
      });
      final idx = _historyItems.indexOf(item);
      if (idx != -1) {
        _historyItems[idx] = HistoryItem(
          id: id,
          med: item.med,
          date: item.date,
          time: item.time,
          taken: item.taken,
          note: item.note,
        );
      }
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }

  bool isRuleBeforeCreation(ReminderRule r, Medication med, DateTime checkDate) {
    final createdMs = med.createdAt ?? med.id;
    if (createdMs == null || createdMs < 1000000000000) return false;
    final creationDate = DateTime.fromMillisecondsSinceEpoch(createdMs);
    
    final checkDateOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final creationDateOnly = DateTime(creationDate.year, creationDate.month, creationDate.day);

    if (checkDateOnly.isBefore(creationDateOnly)) {
      return true;
    }
    
    if (checkDateOnly.isAtSameMomentAs(creationDateOnly)) {
      final ruleDateTime = TimeUtils.toDateTime(r.time, checkDateOnly);
      if (ruleDateTime == null) return false;
      return ruleDateTime.isBefore(creationDate);
    }
    
    return false;
  }

  List<HistoryItem> getDosesForDay(DateTime checkDate, List<ReminderRule> rules, List<Medication> meds) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDateOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);
    
    if (checkDateOnly.isAfter(today)) {
      return [];
    }

    final isToday = checkDateOnly.year == now.year &&
        checkDateOnly.month == now.month &&
        checkDateOnly.day == now.day;

    final actualItems = _historyItems.where((h) => historyDateMatchesDay(h.date, checkDateOnly)).toList();

    final Map<String, List<ReminderRule>> groupedRules = {};
    for (final r in rules) {
      if (!r.active) continue;
      final medMatch = meds.firstWhere(
        (m) => m.name.toLowerCase() == r.med.toLowerCase(),
        orElse: () => const Medication(name: '', dose: '', freq: '', color: Colors.blue, refillDays: 0),
      );
      if (medMatch.freq.toLowerCase().contains('as needed')) continue;
      if (isOffDay(medMatch, checkDateOnly)) continue;
      if (isRuleBeforeCreation(r, medMatch, checkDateOnly)) continue;

      final key = '${r.med} ${r.dose}'.trim().toLowerCase();
      groupedRules[key] = (groupedRules[key] ?? [])..add(r);
    }

    final Map<String, int> takenCounts = {};
    for (final h in actualItems) {
      if (h.taken) {
        final key = h.med.trim().toLowerCase();
        takenCounts[key] = (takenCounts[key] ?? 0) + 1;
      }
    }

    final List<HistoryItem> result = List.from(actualItems);

    for (final entry in groupedRules.entries) {
      final key = entry.key;
      final medRules = entry.value;

      final passedRules = isToday 
          ? medRules.where((r) => _hasTimePassed(r.time)).toList()
          : medRules;
          
      final takenCount = takenCounts[key] ?? 0;

      if (takenCount < passedRules.length) {
        final missedCount = passedRules.length - takenCount;
        final ruleMatch = rules.firstWhere((r) => '${r.med} ${r.dose}'.trim().toLowerCase() == key);
        final medName = ruleMatch.med;
        final medDose = ruleMatch.dose;

        for (int i = 0; i < missedCount; i++) {
          final ruleTime = i < passedRules.length ? passedRules[i].time : 'Unknown Time';
          result.add(HistoryItem(
            id: null,
            med: '$medName $medDose',
            date: DateFormat('yyyy-MM-dd').format(checkDateOnly),
            time: ruleTime,
            taken: false,
            note: 'Missed dose',
          ));
        }
      }
    }

    return result;
  }

  List<HistoryItem> getDoseLog(List<ReminderRule> rules, List<Medication> meds) {
    final now = DateTime.now();
    final todayDoses = getDosesForDay(now, rules, meds);
    final pastItems = _historyItems.where((h) => !historyDateMatchesDay(h.date, now)).toList();

    final List<HistoryItem> combined = [];
    combined.addAll(todayDoses);
    combined.addAll(pastItems);
    return combined;
  }

  bool historyDateMatchesDay(String historyDateStr, DateTime day) {
    if (historyDateStr == 'Today' || historyDateStr.startsWith('Today,')) {
      final now = DateTime.now();
      return day.year == now.year && day.month == now.month && day.day == now.day;
    } else if (historyDateStr == 'Yesterday' || historyDateStr.startsWith('Yesterday,')) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return day.year == yesterday.year && day.month == yesterday.month && day.day == yesterday.day;
    } else {
      try {
        final parsedDate = DateTime.tryParse(historyDateStr);
        if (parsedDate != null) {
          return day.year == parsedDate.year && day.month == parsedDate.month && day.day == parsedDate.day;
        }
        final d = DateFormat('MMM d').parse(historyDateStr);
        final year = DateTime.now().year;
        return day.month == d.month && day.day == d.day && day.year == year;
      } catch (_) {
        return false;
      }
    }
  }

  int calculateStreak(Map<int, MedCardVariant> todayMeds) {
    int current = 0;
    for (int i = 0; i <= 365; i++) {
      final checkDate = DateTime.now().subtract(Duration(days: i));
      if (i == 0) {
        final anyTaken = todayMeds.values.any((s) => s == MedCardVariant.taken);
        final allResolved = todayMeds.values.isNotEmpty &&
            todayMeds.values.every((s) => s == MedCardVariant.taken || s == MedCardVariant.missed);
        if (anyTaken) {
          current++;
        } else if (allResolved) {
          break;
        }
      } else {
        final dayItems = _historyItems.where((h) => historyDateMatchesDay(h.date, checkDate)).toList();
        if (dayItems.isEmpty) {
          break;
        } else {
          if (dayItems.any((h) => h.taken)) {
            current++;
          } else {
            break;
          }
        }
      }
    }
    return current;
  }

  int calculateStreakForMed(String medName, Map<int, MedCardVariant> todayMeds, Medication med) {
    int current = 0;
    for (int i = 0; i <= 365; i++) {
      final checkDate = DateTime.now().subtract(Duration(days: i));
      if (i == 0) {
        final todayStatus = todayMeds[med.id];
        if (todayStatus == MedCardVariant.taken) {
          current++;
        } else if (todayStatus == MedCardVariant.missed) {
          break;
        }
      } else {
        final dayItems = _historyItems
            .where((h) => h.med.toLowerCase().contains(medName.toLowerCase()) && historyDateMatchesDay(h.date, checkDate))
            .toList();
        if (dayItems.isEmpty) {
          break;
        } else {
          if (dayItems.any((h) => h.taken)) {
            current++;
          } else {
            break;
          }
        }
      }
    }
    return current;
  }

  /// Cached result of [calculateWeeklyAdherence].
  /// Set dirty by any mutation to [_historyItems] so it is recomputed lazily
  /// on the next call rather than on every widget rebuild.
  double? _weeklyAdherenceCache;

  double calculateWeeklyAdherence(
    List<ReminderRule> rules,
    Map<int, MedCardVariant> todayMeds,
    List<Medication> meds,
  ) {
    if (_weeklyAdherenceCache != null) return _weeklyAdherenceCache!;

    final now = DateTime.now();
    int totalDoses = 0;
    int takenDoses = 0;

    for (int i = 1; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dayItems = getDosesForDay(day, rules, meds);

      final nonPrnItems = dayItems.where((h) {
        final isPrn = meds.any((m) => h.med.toLowerCase().contains(m.name.toLowerCase()) && m.freq.toLowerCase().contains('as needed'));
        return !isPrn;
      }).toList();

      if (nonPrnItems.isNotEmpty) {
        totalDoses += nonPrnItems.length;
        takenDoses += nonPrnItems.where((h) => h.taken).length;
      }
    }

    for (final rule in rules) {
      if (!rule.active) continue;
      final medMatch = meds.firstWhere(
        (m) => m.name.toLowerCase() == rule.med.toLowerCase(),
        orElse: () => const Medication(name: '', dose: '', freq: '', color: Colors.blue, refillDays: 0),
      );
      if (medMatch.freq.toLowerCase().contains('as needed')) continue;
      if (isOffDay(medMatch, now)) continue;
      if (isRuleBeforeCreation(rule, medMatch, now)) continue;

      final status = todayMeds[medMatch.id];
      if (status == MedCardVariant.taken) {
        totalDoses++;
        takenDoses++;
      } else {
        if (_hasTimePassed(rule.time)) {
          totalDoses++;
        }
      }
    }

    _weeklyAdherenceCache = totalDoses == 0 ? 0.0 : (takenDoses / totalDoses) * 100;
    return _weeklyAdherenceCache!;
  }

  bool _hasTimePassed(String timeStr) {
    try {
      final cleanTime = timeStr.trim();
      final format = DateFormat('h:mm a');
      final parsedTime = format.parse(cleanTime);
      final now = DateTime.now();
      final todayTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      return todayTime.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  int _personalBestStreak = 0;

  Future<void> loadPersonalBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (_historyItems.isEmpty) {
      _personalBestStreak = 0;
      await prefs.setInt('personal_best_streak', 0);
    } else {
      _personalBestStreak = prefs.getInt('personal_best_streak') ?? 0;
    }
    notifyListeners();
  }

  Future<void> checkAndUpdatePersonalBest(int currentStreak) async {
    if (currentStreak > _personalBestStreak) {
      _personalBestStreak = currentStreak;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('personal_best_streak', _personalBestStreak);
      notifyListeners();
    }
  }

  int getPersonalBestStreak(int current) {
    if (current > _personalBestStreak) {
      checkAndUpdatePersonalBest(current);
      return current;
    }
    return _personalBestStreak;
  }

  bool isOffDay(Medication med, DateTime date) {
    final freq = med.freq.toLowerCase();
    if (!freq.contains('every other day')) return false;

    final medHistory = _historyItems.where((h) => h.med.toLowerCase().contains(med.name.toLowerCase())).toList();
    if (medHistory.isEmpty) {
      return false;
    }

    DateTime? mostRecentLoggedDate;
    for (final h in medHistory) {
      DateTime? hDate;
      if (h.date == 'Today' || h.date.startsWith('Today,')) {
        hDate = DateTime.now();
      } else if (h.date == 'Yesterday' || h.date.startsWith('Yesterday,')) {
        hDate = DateTime.now().subtract(const Duration(days: 1));
      } else {
        hDate = DateTime.tryParse(h.date);
        if (hDate == null) {
          try {
            final parsed = DateFormat('MMM d').parse(h.date);
            hDate = DateTime(DateTime.now().year, parsed.month, parsed.day);
          } catch (_) {}
        }
      }

      if (hDate != null) {
        final hDateClean = DateTime(hDate.year, hDate.month, hDate.day);
        final dateClean = DateTime(date.year, date.month, date.day);
        if (hDateClean.isBefore(dateClean) || hDateClean.isAtSameMomentAs(dateClean)) {
          if (mostRecentLoggedDate == null || hDateClean.isAfter(mostRecentLoggedDate)) {
            mostRecentLoggedDate = hDateClean;
          }
        }
      }
    }

    if (mostRecentLoggedDate == null) return false;

    final diffDays = DateTime(date.year, date.month, date.day)
        .difference(mostRecentLoggedDate)
        .inDays;

    return diffDays % 2 != 0;
  }
}
