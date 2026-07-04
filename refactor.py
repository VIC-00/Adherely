import os
import re

files_to_process = [
    'lib/screens/med_detail_screen.dart',
    'lib/screens/history_screen.dart',
    'lib/screens/add_med_screen.dart',
    'lib/screens/reminders_screen.dart',
    'lib/screens/health_screen.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/dashboard_screen.dart'
]

vitals_props = ['vitals', 'addVital', 'bpReadings']
settings_props = ['profile', 'caregivers', 'globalToggles', 'toggleGlobal', 'toggleCaregiver']
history_props = ['historyItems', 'formatDateLabel', 'logHistory', 'calculateStreak', 'getPersonalBestStreak']
med_props = ['meds', 'todayMeds', 'rules', 'addMedication', 'removeMedication', 'editMedication', 'logMedication', 'addRule', 'toggleRule', 'calculateAdherence', 'activeRuleCount', 'activeMedCount']

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # 1. Update imports
    content = content.replace("import '../state.dart';", "import 'package:provider/provider.dart';\nimport '../providers/index.dart';")
    
    # Dashboard uses Provider implicitly? No, we will just ensure it has package:provider
    
    # 2. Replace the state initialization
    state_pattern = r'final\s+state\s*=\s*AppStateProvider\.of\(context\);'
    
    provider_inits = """final medState = context.watch<MedicationProvider>();
    final vitalsState = context.watch<VitalsProvider>();
    final settingsState = context.watch<SettingsProvider>();
    final historyState = context.watch<HistoryProvider>();"""
    
    content = re.sub(state_pattern, provider_inits, content)

    # 3. Replace state.prop with correct_provider.prop
    for prop in vitals_props:
        content = re.sub(r'\bstate\.' + prop + r'\b', f'vitalsState.{prop}', content)
    for prop in settings_props:
        content = re.sub(r'\bstate\.' + prop + r'\b', f'settingsState.{prop}', content)
    for prop in history_props:
        content = re.sub(r'\bstate\.' + prop + r'\b', f'historyState.{prop}', content)
    for prop in med_props:
        content = re.sub(r'\bstate\.' + prop + r'\b', f'medState.{prop}', content)

    # Some screens might use `state.streak` directly which was a getter in AppState.
    # We moved streak calculation to historyState.calculateStreak(medState.todayMeds)
    # So we need to handle that.
    content = re.sub(r'\bstate\.streak\b', 'historyState.calculateStreak(medState.todayMeds)', content)
    
    # And state.personalBestStreak -> historyState.getPersonalBestStreak(historyState.calculateStreak(medState.todayMeds))
    content = re.sub(r'\bstate\.personalBestStreak\b', 'historyState.getPersonalBestStreak(historyState.calculateStreak(medState.todayMeds))', content)
    
    # Dashboard has state.formattedToday
    content = re.sub(r'\bstate\.formattedToday\b', "historyState.formatDateLabel(DateTime.now())", content)

    # Dashboard has state.greeting -> let's just inline it or replace
    greeting_inline = "(DateTime.now().hour < 12 ? 'Good morning' : DateTime.now().hour < 17 ? 'Good afternoon' : 'Good evening')"
    content = re.sub(r'\bstate\.greeting\b', greeting_inline, content)

    with open(filepath, 'w') as f:
        f.write(content)

for filepath in files_to_process:
    process_file(filepath)
    print(f'Processed {filepath}')
