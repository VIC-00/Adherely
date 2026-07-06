import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medadhere.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS medications');
    await db.execute('DROP TABLE IF EXISTS today_meds');
    await db.execute('DROP TABLE IF EXISTS reminder_rules');
    await db.execute('DROP TABLE IF EXISTS caregivers');
    await db.execute('DROP TABLE IF EXISTS vitals');
    await db.execute('DROP TABLE IF EXISTS history_items');
    await db.execute('DROP TABLE IF EXISTS profile_toggles');
    await db.execute('DROP TABLE IF EXISTS profile');
    await db.execute('DROP TABLE IF EXISTS bp_readings');
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    // 1. Medications table
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        freq TEXT NOT NULL,
        color INTEGER NOT NULL,
        refillDays INTEGER NOT NULL,
        description TEXT,
        drugClass TEXT,
        sideEffects TEXT
      )
    ''');

    // 2. Today's meds completion status table
    await db.execute('''
      CREATE TABLE today_meds (
        med_id INTEGER PRIMARY KEY,
        status TEXT NOT NULL,
        FOREIGN KEY (med_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    // 3. Reminder Rules table
    await db.execute('''
      CREATE TABLE reminder_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med TEXT NOT NULL,
        dose TEXT NOT NULL,
        time TEXT NOT NULL,
        types TEXT NOT NULL,
        advance INTEGER NOT NULL,
        color INTEGER NOT NULL,
        active INTEGER NOT NULL
      )
    ''');

    // 4. Caregivers table
    await db.execute('''
      CREATE TABLE caregivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        phone TEXT NOT NULL,
        active INTEGER NOT NULL
      )
    ''');

    // 5. Vitals table
    await db.execute('''
      CREATE TABLE vitals (
        label TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        unit TEXT NOT NULL,
        trend TEXT NOT NULL,
        color INTEGER NOT NULL,
        bg INTEGER NOT NULL,
        border INTEGER NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // 6. History Items table
    await db.execute('''
      CREATE TABLE history_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        taken INTEGER NOT NULL,
        note TEXT NOT NULL
      )
    ''');

    // 7. Profile Toggles table
    await db.execute('''
      CREATE TABLE profile_toggles (
        label TEXT PRIMARY KEY,
        sub TEXT NOT NULL,
        value INTEGER NOT NULL,
        color INTEGER
      )
    ''');

    // 8. Profile Settings table
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        dob TEXT NOT NULL,
        patient_id TEXT NOT NULL,
        conditions TEXT NOT NULL
      )
    ''');

    // 9. BP Readings table
    await db.execute('''
      CREATE TABLE bp_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        sys INTEGER NOT NULL,
        dia INTEGER NOT NULL
      )
    ''');

    // Seed default mock data
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    await _seedData(db);
  }

  Future<void> _seedData(DatabaseExecutor db) async {
    // Seed Profile
    await db.rawInsert('INSERT INTO profile (id, name, dob, patient_id, conditions) VALUES (?, ?, ?, ?, ?)',
      [1, 'Sarah Mitchell', 'Oct 14, 1965', 'PT-894-22X', 'Hypertension · Type 2 Diabetes']);

    // Seed Medications
    await db.rawInsert('INSERT INTO medications (id, name, dose, freq, color, refillDays) VALUES (?, ?, ?, ?, ?, ?)',
      [1, 'Lisinopril', '10mg', 'Once daily · 8 AM', 0xFF3B82F6, 12]);
    await db.rawInsert('INSERT INTO medications (id, name, dose, freq, color, refillDays) VALUES (?, ?, ?, ?, ?, ?)',
      [2, 'Metformin', '500mg', 'Twice daily · 8 AM, 8 PM', 0xFF8B5CF6, 5]);
    await db.rawInsert('INSERT INTO medications (id, name, dose, freq, color, refillDays) VALUES (?, ?, ?, ?, ?, ?)',
      [3, 'Gabapentin', '300mg', 'Once daily · 2 PM', 0xFFF97316, 22]);

    // Seed Today Meds Statuses
    await db.rawInsert('INSERT INTO today_meds (med_id, status) VALUES (?, ?)', [1, 'upcoming']);
    await db.rawInsert('INSERT INTO today_meds (med_id, status) VALUES (?, ?)', [2, 'taken']);
    await db.rawInsert('INSERT INTO today_meds (med_id, status) VALUES (?, ?)', [3, 'missed']);

    // Seed Reminder Rules
    await db.rawInsert('INSERT INTO reminder_rules (id, med, dose, time, types, advance, color, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [1, 'Lisinopril', '10mg', '8:00 AM', 'push,voice', 15, 0xFF3B82F6, 1]);
    await db.rawInsert('INSERT INTO reminder_rules (id, med, dose, time, types, advance, color, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [2, 'Metformin', '500mg', '8:00 AM', 'push', 15, 0xFF8B5CF6, 1]);
    await db.rawInsert('INSERT INTO reminder_rules (id, med, dose, time, types, advance, color, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [3, 'Metformin', '500mg', '8:00 PM', 'push,voice', 15, 0xFF8B5CF6, 1]);
    await db.rawInsert('INSERT INTO reminder_rules (id, med, dose, time, types, advance, color, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [4, 'Gabapentin', '300mg', '2:00 PM', 'push,voice', 0, 0xFFF97316, 0]);

    // Seed Caregivers
    await db.rawInsert('INSERT INTO caregivers (id, name, relation, phone, active) VALUES (?, ?, ?, ?, ?)',
      [1, 'Robert Mitchell', 'Husband', '(555) 019-2834', 1]);
    await db.rawInsert('INSERT INTO caregivers (id, name, relation, phone, active) VALUES (?, ?, ?, ?, ?)',
      [2, 'Emily Mitchell', 'Daughter / Primary Caregiver', '(555) 019-5821', 0]);

    // Seed Vitals
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Blood Pressure', '118/75', 'mmHg', '↓ improving', 0xFF22C55E, 0xFFF0FDF4, 0xFFBBF7D0, '❤️']);
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Heart Rate', '72', 'bpm', '↓ stable', 0xFF3B82F6, 0xFFEFF6FF, 0xFF93C5FD, '⚡']);
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Blood Sugar', '98', 'mg/dL', '→ stable', 0xFF14B8A6, 0xFFF0FDFA, 0xFFCCFBF1, '🩸']);
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Weight', '168.4', 'lbs', '↓ -1.2 lbs', 0xFF10B981, 0xFFD1FAE5, 0xFFA7F3D0, '⚖️']);

    // Seed BP Readings
    await db.rawInsert('INSERT INTO bp_readings (id, date, sys, dia) VALUES (?, ?, ?, ?)', [1, 'Oct 24, 8:00 AM', 120, 80]);
    await db.rawInsert('INSERT INTO bp_readings (id, date, sys, dia) VALUES (?, ?, ?, ?)', [2, 'Oct 23, 8:15 AM', 122, 82]);
    await db.rawInsert('INSERT INTO bp_readings (id, date, sys, dia) VALUES (?, ?, ?, ?)', [3, 'Oct 22, 7:50 AM', 125, 84]);
    await db.rawInsert('INSERT INTO bp_readings (id, date, sys, dia) VALUES (?, ?, ?, ?)', [4, 'Oct 21, 8:10 AM', 128, 86]);

    // Seed Profile & Reminders Toggles
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Dark Mode', 'Matches system settings', 0, 0xFF6B7280]);
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Push Notifications', 'Daily reminders and refills alerts', 1, 0xFF10B981]);
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Voice Reminders', 'Audible spoken alerts for schedules', 1, 0xFFF59E0B]);
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Caregiver SMS Alerts', 'Alert network if doses are missed', 0, 0xFF8B5CF6]);
  }

  // Clear for testing
  Future<void> clearDatabase() async {
    final db = await database;
    await db.execute('DELETE FROM medications');
    await db.execute('DELETE FROM today_meds');
    await db.execute('DELETE FROM reminder_rules');
    await db.execute('DELETE FROM caregivers');
    await db.execute('DELETE FROM vitals');
    await db.execute('DELETE FROM history_items');
    await db.execute('DELETE FROM profile_toggles');
    await db.execute('DELETE FROM profile');
    await db.execute('DELETE FROM bp_readings');
  }

  // Reload defaults
  Future<void> resetToDefaults() async {
    await clearDatabase();
    final db = await database;
    await _seedDefaultData(db);
  }
}
