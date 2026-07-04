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
  List<ToggleItem> get globalToggles => List.unmodifiable(_profileToggles);
  
  bool _dbEnabled = true;

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
    if (togglesData.isNotEmpty) {
      _profileToggles.addAll(togglesData.map((t) => ToggleItem(
        label: t['label'] as String,
        sub: t['sub'] as String,
        on: t['on'] == 1,
        color: Color(t['color'] as int),
      )));
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
      const Caregiver(name: 'Robert Mitchell', relation: 'Husband', phone: '(555) 019-2834', active: true),
      const Caregiver(name: 'Emily Mitchell', relation: 'Daughter / Primary Caregiver', phone: '(555) 019-5821', active: false),
    ]);

    _profileToggles.clear();
    _profileToggles.addAll(const [
      ToggleItem(label: 'Push Notifications', sub: 'Daily reminders and refills alerts', on: true, color: Color(0xFF10B981)),
      ToggleItem(label: 'Voice Reminders', sub: 'Audible spoken alerts for schedules', on: true, color: Color(0xFFF59E0B)),
      ToggleItem(label: 'Caregiver SMS Alerts', sub: 'Alert network if doses are missed', on: false, color: Color(0xFF8B5CF6)),
    ]);
    notifyListeners();
  }

  Future<void> toggleGlobal(int index) async {
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
      await db.update('profile_toggles', {'on': !t.on ? 1 : 0}, where: 'label = ?', whereArgs: [t.label]);
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
    _caregivers.add(c);
    notifyListeners();
    if (!_dbEnabled) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('caregivers', {
        'name': c.name,
        'relation': c.relation,
        'phone': c.phone,
        'active': c.active ? 1 : 0,
      });
    } catch (e) {
      debugPrint("DB Write Error: $e");
    }
  }
}
