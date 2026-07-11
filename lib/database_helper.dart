import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

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
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 6) {
        // Safe migration: rename old profile table, copy data to new profile table without patient_id
        await db.execute('ALTER TABLE profile RENAME TO profile_old');
        await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            dob TEXT NOT NULL,
            conditions TEXT NOT NULL
          )
        ''');
        await db.execute('INSERT INTO profile (id, name, dob, conditions) SELECT id, name, dob, conditions FROM profile_old');
        await db.execute('DROP TABLE profile_old');
      }
    } catch (e) {
      debugPrint("Migration error: $e");
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

    // Seed default data (blank vitals + settings toggles)
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    await _seedData(db);
  }

  Future<void> _seedData(DatabaseExecutor db) async {
    // Seed Vitals with blank values
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Blood Pressure', '--', 'mmHg', 'No readings', 0xFF22C55E, 0xFFF0FDF4, 0xFFBBF7D0, '❤️']);
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Heart Rate', '--', 'bpm', 'No readings', 0xFF3B82F6, 0xFFEFF6FF, 0xFF93C5FD, '⚡']);
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Blood Sugar', '--', 'mg/dL', 'No readings', 0xFF14B8A6, 0xFFF0FDFA, 0xFFCCFBF1, '🩸']);
    await db.rawInsert('INSERT INTO vitals (label, value, unit, trend, color, bg, border, icon) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['Weight', '--', 'lbs', 'No readings', 0xFF10B981, 0xFFD1FAE5, 0xFFA7F3D0, '⚖️']);

    // Seed Profile & Reminders Toggles
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Dark Mode', 'Matches system settings', 0, 0xFF6B7280]);
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Push Notifications', 'Daily reminders and refills alerts', 1, 0xFF10B981]);
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Voice Reminders', 'Audible spoken alerts for schedules', 1, 0xFFF59E0B]);
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Continuous Alarm', 'Loop alarm ringtone until dismissed', 1, 0xFF3B82F6]);
    await db.rawInsert('INSERT INTO profile_toggles (label, sub, value, color) VALUES (?, ?, ?, ?)',
      ['Snooze Duration', '5 minutes', 5, 0xFFEF4444]);
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
