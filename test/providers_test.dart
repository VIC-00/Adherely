import 'package:flutter_test/flutter_test.dart';
import 'package:medadhere/providers/index.dart';
import 'package:medadhere/models.dart';
import 'package:flutter/material.dart';
import 'package:medadhere/notification_service.dart';

class MockNotificationService implements INotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> requestPermissions() async {}
  @override
  Future<void> scheduleReminderNotification(ReminderRule rule) async {}
  @override
  Future<void> cancelReminder(int ruleId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  test('MedicationProvider initializes with default values when DB fails', () async {
    final state = MedicationProvider(MockNotificationService());
    state.setDbEnabled(false);
    state.setInMemoryDefaults();
    
    expect(state.meds.isNotEmpty, true);
    expect(state.meds.length, 3); // The 3 dummy meds
  });

  test('addMedication adds med and rule', () async {
    final state = MedicationProvider(MockNotificationService());
    state.setDbEnabled(false);
    state.setInMemoryDefaults();
    
    final initialCount = state.meds.length;
    final initialRuleCount = state.rules.length;

    await state.addMedication(
      const Medication(
        name: 'Test Med',
        dose: '10mg',
        freq: 'Once daily',
        color: Colors.blue,
        refillDays: 30,
      ),
    );

    expect(state.meds.length, initialCount + 1);
    expect(state.meds.last.name, 'Test Med');
    expect(state.rules.length, initialRuleCount + 1);
    expect(state.rules.last.med, 'Test Med');
  });

  test('removeMedication removes med, status, and rules', () async {
    final state = MedicationProvider(MockNotificationService());
    state.setDbEnabled(false);
    state.setInMemoryDefaults();

    // add a med to remove
    await state.addMedication(
      const Medication(
        name: 'Delete Me',
        dose: '10mg',
        freq: 'Once daily',
        color: Colors.red,
        refillDays: 30,
      ),
    );
    
    final addedMed = state.meds.last;
    final medId = addedMed.id!;

    expect(state.meds.any((m) => m.id == medId), true);
    
    await state.removeMedication(medId);
    
    expect(state.meds.any((m) => m.id == medId), false);
    expect(state.todayMeds.containsKey(medId), false);
    expect(state.rules.any((r) => r.med == 'Delete Me'), false);
  });
}
