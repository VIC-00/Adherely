import 'package:flutter/material.dart';
import '../models.dart';
import '../database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  Profile? _profile;
  Profile? get profile => _profile;

  final List<Caregiver> _caregivers = [];
  List<Caregiver> get caregivers => List.unmodifiable(_caregivers);

  final List<ToggleItem> _profileToggles = [];
  List<ToggleItem> get profileToggles => List.unmodifiable(_profileToggles);
  
  final List<ToggleItem> _notificationToggles = [];
  List<ToggleItem> get notificationToggles => List.unmodifiable(_notificationToggles);
  List<ToggleItem> get globalToggles => List.unmodifiable(_notificationToggles);
  
  bool _dbEnabled = true;
  int _snoozeDuration = 5;
  int get snoozeDuration => _snoozeDuration;

  Future<void> updateSnoozeDuration(int minutes) async {
    _snoozeDuration = minutes;
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('profile_toggles', {
        'sub': '$minutes minutes',
        'value': minutes,
      }, where: 'label = ?', whereArgs: ['Snooze Duration']);
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }

  Future<void> load(Profile? profile, List<Map<String, dynamic>> caregiversData, List<Map<String, dynamic>> togglesData) async {
    _profile = profile;
    
    _caregivers.clear();
    _caregivers.addAll(caregiversData.map((c) => Caregiver(
      id: c['id'] as int,
      name: c['name'] as String,
      relation: c['relation'] as String,
      phone: c['phone'] as String,
      active: c['active'] == 1,
    )));

    _profileToggles.clear();
    _notificationToggles.clear();
    if (togglesData.isNotEmpty) {
      for (final t in togglesData) {
        final label = t['label'] as String;
        if (label == 'Snooze Duration') {
          _snoozeDuration = t['value'] as int;
          continue;
        }
        final toggle = ToggleItem(
          label: label,
          sub: t['sub'] as String,
          on: t['value'] == 1,
          color: t['color'] != null ? Color(t['color'] as int) : null,
        );
        if (toggle.label == 'Dark Mode') {
          _profileToggles.add(toggle);
        } else if (toggle.label == 'Push Notifications' || 
                   toggle.label == 'Voice Reminders' || 
                   toggle.label == 'Caregiver SMS Alerts' ||
                   toggle.label == 'Continuous Alarm') {
          _notificationToggles.add(toggle);
        }
      }
    }
    notifyListeners();
  }
  
  void setDbEnabled(bool enabled) {
    _dbEnabled = enabled;
  }
  
  void setInMemoryDefaults() {
    _profile = const Profile(
      id: 1,
      name: 'Sarah Mitchell',
      dob: 'Oct 14, 1965',
      patientId: 'PT-894-22X',
      conditions: 'Hypertension · Type 2 Diabetes',
    );

    _caregivers.clear();
    _caregivers.addAll([
      const Caregiver(id: 1, name: 'Robert Mitchell', relation: 'Husband', phone: '(555) 019-2834', active: true),
      const Caregiver(id: 2, name: 'Emily Mitchell', relation: 'Daughter / Primary Caregiver', phone: '(555) 019-5821', active: false),
    ]);

    _profileToggles.clear();
    _profileToggles.add(const ToggleItem(label: 'Dark Mode', sub: 'Matches system settings', on: false, color: Color(0xFF6B7280)));

    _notificationToggles.clear();
    _notificationToggles.addAll(const [
      ToggleItem(label: 'Push Notifications', sub: 'Daily reminders and refills alerts', on: true, color: Color(0xFF10B981)),
      ToggleItem(label: 'Voice Reminders', sub: 'Audible spoken alerts for schedules', on: true, color: Color(0xFFF59E0B)),
      ToggleItem(label: 'Caregiver SMS Alerts', sub: 'Alert network if doses are missed', on: false, color: Color(0xFF8B5CF6)),
      ToggleItem(label: 'Continuous Alarm', sub: 'Loop alarm ringtone until dismissed', on: true, color: Color(0xFF3B82F6)),
    ]);
    _snoozeDuration = 5;
    notifyListeners();
  }

  Future<void> toggleProfileToggle(int index) async {
    if (index < 0 || index >= _profileToggles.length) return;
    final t = _profileToggles[index];
    _profileToggles[index] = ToggleItem(
      label: t.label,
      sub: t.sub,
      on: !t.on,
      color: t.color,
    );
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('profile_toggles', {'value': !t.on ? 1 : 0}, where: 'label = ?', whereArgs: [t.label]);
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }

  Future<void> toggleNotificationToggle(int index) async {
    if (index < 0 || index >= _notificationToggles.length) return;
    final t = _notificationToggles[index];
    _notificationToggles[index] = ToggleItem(
      label: t.label,
      sub: t.sub,
      on: !t.on,
      color: t.color,
    );
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('profile_toggles', {'value': !t.on ? 1 : 0}, where: 'label = ?', whereArgs: [t.label]);
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }

  Future<void> toggleCaregiver(int id) async {
    final idx = _caregivers.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _caregivers[idx];
      _caregivers[idx] = Caregiver(
        id: c.id,
        name: c.name,
        relation: c.relation,
        phone: c.phone,
        active: !c.active,
      );
      notifyListeners();
      if (!_dbEnabled) return;
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update('caregivers', {'active': !c.active ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint("DB Write Error: $e");
      }
    }
  }

  Future<void> removeCaregiver(String name) async {
    _caregivers.removeWhere((c) => c.name == name);
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('caregivers', where: 'name = ?', whereArgs: [name]);
    } catch(e) {
      debugPrint("DB error: $e");
    }
  }

  Future<void> addCaregiver(Caregiver c) async {
    if (!_dbEnabled) {
      _caregivers.add(c);
      notifyListeners();
      return;
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final insertedId = await db.insert('caregivers', {
        'name': c.name,
        'relation': c.relation,
        'phone': c.phone,
        'active': c.active ? 1 : 0,
      });
      _caregivers.add(Caregiver(
        id: insertedId,
        name: c.name,
        relation: c.relation,
        phone: c.phone,
        active: c.active,
      ));
      notifyListeners();
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }

  Future<void> editCaregiver(int id, Caregiver newCaregiver) async {
    final idx = _caregivers.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _caregivers[idx] = newCaregiver;
      notifyListeners();
      if (!_dbEnabled) return;
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update('caregivers', {
          'name': newCaregiver.name,
          'relation': newCaregiver.relation,
          'phone': newCaregiver.phone,
          'active': newCaregiver.active ? 1 : 0,
        }, where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint("DB Caregiver Update Error: $e");
      }
    }
  }
}
