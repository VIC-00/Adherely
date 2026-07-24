import 'package:flutter/material.dart';

enum MedCardVariant { upcoming, taken, missed, future }

/// Stable storage codec for [MedCardVariant].
/// Update ONLY this map if a value is ever renamed — DB records stay valid.
extension MedCardVariantCodec on MedCardVariant {
  /// Returns the canonical DB string for this variant.
  String toStorageString() {
    switch (this) {
      case MedCardVariant.upcoming: return 'upcoming';
      case MedCardVariant.taken:    return 'taken';
      case MedCardVariant.missed:   return 'missed';
      case MedCardVariant.future:   return 'future';
    }
  }

  /// Parses a DB string back to a [MedCardVariant].
  /// Falls back to [MedCardVariant.upcoming] for unknown values.
  static MedCardVariant fromString(String s) {
    switch (s) {
      case 'taken':   return MedCardVariant.taken;
      case 'missed':  return MedCardVariant.missed;
      case 'future':  return MedCardVariant.future;
      default:        return MedCardVariant.upcoming;
    }
  }
}

class Medication {
  final int? id;
  final String name;
  final String dose;
  final String freq;
  final Color color;
  final int refillDays;

  final String? description;
  final String? drugClass;
  final String? sideEffects;
  final String? doctor;
  final String? notes;

  final String? form;
  final double intakeQty;
  final double supplyQty;
  final double initialSupply;
  final int? createdAt;

  const Medication({
    this.id,
    required this.name,
    required this.dose,
    required this.freq,
    required this.color,
    required this.refillDays,
    this.description,
    this.drugClass,
    this.sideEffects,
    this.doctor,
    this.notes,
    this.form,
    this.intakeQty = 1.0,
    this.supplyQty = 0.0,
    this.initialSupply = 0.0,
    this.createdAt,
  });

  int get calculatedDaysRemaining {
    final timesStr = freq.contains('·') ? freq.split('·').last : '';
    final timesCount = timesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).length;
    final dailyIntake = intakeQty * (timesCount > 0 ? timesCount : 1);
    return dailyIntake > 0 ? (supplyQty / dailyIntake).ceil() : 0;
  }
}

class Caregiver {
  final int? id;
  final String name;
  final String relation;
  final String phone;
  final bool active;

  const Caregiver({
    this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.active,
  });
}

class ToggleItem {
  final String label;
  final String sub;
  final bool on;
  final Color? color;

  const ToggleItem({
    required this.label,
    required this.sub,
    required this.on,
    this.color,
  });
}

enum DayStatus { taken, missed, partial, future, empty }

class CalendarCell {
  final int day;
  final DayStatus status;
  const CalendarCell(this.day, this.status);
}

class HistoryItem {
  final int? id;
  final String date;
  final String med;
  final String time;
  final bool taken;
  final String note;

  const HistoryItem({
    this.id,
    required this.date,
    required this.med,
    required this.time,
    required this.taken,
    required this.note,
  });
}

class VitalStat {
  final String label;
  final String value;
  final String unit;
  final String trend;
  final Color color;
  final Color bg;
  final Color border;
  final String icon;

  const VitalStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.trend,
    required this.color,
    required this.bg,
    required this.border,
    required this.icon,
  });
}

class MedImpact {
  final String med;
  final String impact;
  final String icon;
  final int weeks;
  final int progress;
  final Color? color;
  final IconData? iconData;

  const MedImpact({
    required this.med,
    required this.impact,
    required this.icon,
    required this.weeks,
    required this.progress,
    this.color,
    this.iconData,
  });
}
enum AlertType { push, voice }

/// Stable storage codec for [AlertType].
/// Update ONLY this map if a value is ever renamed — DB records stay valid.
extension AlertTypeCodec on AlertType {
  /// Returns the canonical DB string for this alert type.
  String toStorageString() {
    switch (this) {
      case AlertType.push:  return 'push';
      case AlertType.voice: return 'voice';
    }
  }

  /// Parses a DB string back to an [AlertType].
  /// Returns null for unknown values so callers can skip bad entries.
  static AlertType? fromString(String s) {
    switch (s) {
      case 'push':  return AlertType.push;
      case 'voice': return AlertType.voice;
      default:      return null;
    }
  }
}

class AlertInfo {
  final String icon;
  final String label;
  final Color color;
  const AlertInfo(this.icon, this.label, this.color);
}

class ReminderRule {
  final int? id;
  final String med;
  final String dose;
  final String time;
  final List<AlertType> types;
  final int advance;
  final Color color;
  final bool active;

  const ReminderRule({
    this.id,
    required this.med,
    required this.dose,
    required this.time,
    required this.types,
    required this.advance,
    required this.color,
    required this.active,
  });
}

// Profile model definition
class Profile {
  final int? id;
  final String name;
  final String dob;
  final String conditions;

  const Profile({
    this.id,
    required this.name,
    required this.dob,
    required this.conditions,
  });
}

class BPReading {
  final String date;
  final int sys;
  final int dia;
  const BPReading({required this.date, required this.sys, required this.dia});
}
