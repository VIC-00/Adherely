/// Shared utility for parsing the app's 12-hour time strings (e.g. "8:00 AM").
///
/// This is the single source of truth for time parsing — previously the same
/// logic was duplicated inline across 6 files. If the time format ever changes,
/// only this file needs to be updated.
library;

import 'package:flutter/material.dart';

class TimeUtils {
  TimeUtils._(); // non-instantiable

  /// Parses [timeStr] (e.g. "8:00 AM", "10:30 PM") and returns
  /// `hour + minute / 60.0` for use in comparisons and sorts.
  /// Returns `0.0` on any parse error.
  static double toDouble(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) return 0.0;
      final hm = parts[0].split(':');
      if (hm.length != 2) return 0.0;
      int hour = int.parse(hm[0]);
      final int minute = int.parse(hm[1]);
      final String period = parts[1].toUpperCase();
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return hour + (minute / 60.0);
    } catch (_) {
      return 0.0;
    }
  }

  /// Parses [timeStr] into a Flutter [TimeOfDay].
  /// Throws [FormatException] on parse failure so callers can handle it.
  static TimeOfDay toTimeOfDay(String timeStr) {
    final parts = timeStr.trim().split(' ');
    if (parts.length != 2) throw FormatException('Bad time: $timeStr');
    final hm = parts[0].split(':');
    if (hm.length != 2) throw FormatException('Bad time: $timeStr');
    int hour = int.parse(hm[0]);
    final int minute = int.parse(hm[1]);
    final String period = parts[1].toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Parses [timeStr] and combines it with [date] to produce a full [DateTime].
  /// Returns null on any parse error.
  static DateTime? toDateTime(String timeStr, DateTime date) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.isEmpty) return null;
      final hm = parts[0].split(':');
      if (hm.length != 2) return null;
      int hour = int.parse(hm[0]);
      final int minute = int.parse(hm[1]);
      if (parts.length > 1) {
        final String period = parts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }
}
