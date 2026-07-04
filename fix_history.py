import re

with open('lib/providers/history_provider.dart', 'r') as f:
    content = f.read()

# Add missing properties
if 'DateTime _currentHistoryMonth' not in content:
    addition = """
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

  int get missedDoses => _historyItems.where((i) => !i.taken).length;

  List<List<CalendarCell>> get calRows {
    final firstDay = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month, 1);
    final daysInMonth = DateTime(_currentHistoryMonth.year, _currentHistoryMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; 
    
    List<List<CalendarCell>> rows = [];
    List<CalendarCell> currentRow = List.filled(startWeekday, const CalendarCell(0, DayStatus.empty), growable: true);
    
    for (int day = 1; day <= daysInMonth; day++) {
      currentRow.add(CalendarCell(day, DayStatus.taken)); 
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
"""
    content = content.replace('class HistoryProvider extends ChangeNotifier {', 'class HistoryProvider extends ChangeNotifier {' + addition)
    with open('lib/providers/history_provider.dart', 'w') as f:
        f.write(content)

with open('lib/screens/dashboard_screen.dart', 'r') as f:
    content = f.read()

content = content.replace('medState.logMedication(med.id!, med.name, MedCardVariant.taken);', 'medState.logMedication(med.id!, MedCardVariant.taken);')
content = content.replace('medState.logMedication(med.id!, med.name, MedCardVariant.upcoming);', 'medState.logMedication(med.id!, MedCardVariant.upcoming);')

with open('lib/screens/dashboard_screen.dart', 'w') as f:
    f.write(content)

with open('lib/screens/health_screen.dart', 'r') as f:
    content = f.read()

content = content.replace('int progress = medState.calculateAdherence();', 'int progress = medState.calculateAdherence().toInt();')
# Also for state.adherenceRate string interpolation if it was double
with open('lib/screens/health_screen.dart', 'w') as f:
    f.write(content)

# Fix widget_test.dart
with open('test/widget_test.dart', 'r') as f:
    content = f.read()
# Wait, MedAdhereApp is in main.dart? Let's check imports in widget_test.dart.
# Oh, widget_test.dart imports package:medadhere/main.dart but we might have renamed the app widget.
