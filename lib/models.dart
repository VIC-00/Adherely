import 'package:flutter/material.dart';

enum MedCardVariant { upcoming, taken, missed }

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
  });
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

class BpReading {
  final int? id;
  final String date;
  final int sys;
  final int dia;
  const BpReading(this.date, this.sys, this.dia, {this.id});
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

enum AlertType { push, voice, sms, email }

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

class Profile {
  final int? id;
  final String name;
  final String dob;
  final String patientId;
  final String conditions;

  const Profile({
    this.id,
    required this.name,
    required this.dob,
    required this.patientId,
    required this.conditions,
  });
}

class BPReading {
  final String date;
  final int sys;
  final int dia;
  const BPReading({required this.date, required this.sys, required this.dia});
}
