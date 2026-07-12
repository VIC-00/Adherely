import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../database_helper.dart';

class HistoryProvider extends ChangeNotifier {
  DateTime _currentHistoryMonth = DateTime.now();
  DateTime get currentHistoryMonth => _currentHistoryMonth;

  String get currentHistoryMonthLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_currentHistoryMonth.month - 1]} ${_currentHistoryMonth.year}';
  }

  void previousHistoryMonth() {
    _currentHistoryMonth = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month - 1, 1);
    notifyListeners();
  }

  void nextHistoryMonth() {
    _currentHistoryMonth = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month + 1, 1);
    notifyListeners();
  }

  int get missedDoses {
    // Only count missed doses within the currently displayed calendar month
    return _historyItems.where((i) {
      if (i.taken) return false;
      try {
        final date = DateTime.parse(i.date);
        return date.year == _currentHistoryMonth.year &&
            date.month == _currentHistoryMonth.month;
      } catch (_) {
        return false;
      }
    }).length;
  }

  List<List<CalendarCell>> get calRows {
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
        final dayItems = _historyItems.where((h) => historyDateMatchesDay(h.date, cellDate)).toList();
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

  int getMedicationAdherence(String medName) {
    final medLogs = _historyItems
        .where((h) => h.med.toLowerCase().contains(medName.toLowerCase()))
        .toList();
    if (medLogs.isEmpty) return 100;
    final takenCount = medLogs.where((h) => h.taken).length;
    return ((takenCount / medLogs.length) * 100).toInt();
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
    notifyListeners();
  }
  
  void setDbEnabled(bool enabled) {
    _dbEnabled = enabled;
  }

  void setInMemoryDefaults() {
    _historyItems.clear();
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
      // Optionally update the local item with the inserted ID
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

  List<HistoryItem> getDosesForDay(int day) {
    final checkDate = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month, day);
    return _historyItems.where((h) => historyDateMatchesDay(h.date, checkDate)).toList();
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
        // Today: only count if at least one med was taken.
        // If the day isn't fully resolved yet (some still upcoming) we skip
        // today without breaking the streak — the user still has time.
        final anyTaken = todayMeds.values.any((s) => s == MedCardVariant.taken);
        final allResolved = todayMeds.values.isNotEmpty &&
            todayMeds.values.every((s) => s == MedCardVariant.taken || s == MedCardVariant.missed);
        if (anyTaken) {
          current++;
        } else if (allResolved) {
          // All meds were missed today — streak is broken
          break;
        }
        // else: day not done yet, don't count but don't break → continue
      } else {
        final dayItems = _historyItems.where((h) => historyDateMatchesDay(h.date, checkDate)).toList();
        if (dayItems.isEmpty) {
          // No record for this past day = missed entirely → streak breaks
          break;
        } else {
          if (dayItems.any((h) => h.taken)) {
            current++;
          } else {
            break; // recorded but all doses were missed
          }
        }
      }
    }
    return current > 0 ? current : 1;
  }

  /// Adherence over the last 7 days based on history_items.
  /// Returns a value from 0.0 to 100.0.
  double calculateWeeklyAdherence() {
    final now = DateTime.now();
    int totalDoses = 0;
    int takenDoses = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dayItems = _historyItems
          .where((h) => historyDateMatchesDay(h.date, day))
          .toList();
      if (dayItems.isNotEmpty) {
        totalDoses += dayItems.length;
        takenDoses += dayItems.where((h) => h.taken).length;
      }
    }
    if (totalDoses == 0) return 100.0; // new user — no data yet
    return (takenDoses / totalDoses) * 100;
  }

  int _personalBestStreak = 0;

  Future<void> loadPersonalBest() async {
    final prefs = await SharedPreferences.getInstance();
    _personalBestStreak = prefs.getInt('personal_best_streak') ?? 0;
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
    return _personalBestStreak > 0 ? _personalBestStreak : 1;
  }
}
