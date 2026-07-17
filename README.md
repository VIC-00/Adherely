# Adherely — Medication Adherence Dashboard

Adherely is a premium, offline-first medication tracking application built in Flutter. It is designed to be highly reliable, fully persistent, and includes native background services for alarm reminders and notifications.

---

## 📱 Features & Screens

Adherely comprises 7 fully interactive screens matching premium typography, colors, and layout guidelines:

1. **Dashboard** (`lib/screens/dashboard_screen.dart`)
   * Current streaks, weekly progress heat-maps, and daily medication cards (upcoming, taken, or future tracking).
   * Tap-navigation to medication details and notifications hub.
2. **History & Analytics** (`lib/screens/history_screen.dart`)
   * Adherence summary headers showing weekly performance rates.
   * Monthly calendar grid with color-coded status states (taken, partial, missed, empty).
   * Interactive calendar cells allowing users to inspect dose logs for any past day.
3. **Health & Vitals** (`lib/screens/health_screen.dart`)
   * Logging and tracking for Blood Pressure, Blood Sugar, Heart Rate, and Weight.
   * Dynamic double-bar chart representing Systolic and Diastolic Blood Pressure readings.
   * Custom medication adherence impact metrics.
4. **Patient Profile** (`lib/screens/profile_screen.dart`)
   * Managing active medication list, adding/editing caregiver networks, and notification settings (Push, Voice, Snooze duration, Continuous alarms).
   * Reset App Data action with safe route stack replacement.
5. **Medication Detail** (`lib/screens/med_detail_screen.dart`)
   * Tabbed interface: **Overview** (weekly status calendar), **Schedule** (dose times), **Side Effects**, and **Refills** (current supply indicators, refill reminders, and supply logging).
6. **Add Medication** (`lib/screens/add_med_screen.dart`)
   * 4-step wizard form to define name, dose, frequency (daily times or PRN), start tracking date (back-dated, today, or future), initial supply, and refill thresholds.
7. **Notification Hub** (`lib/screens/reminders_screen.dart`)
   * Overview list showing all scheduled reminder rules with exact calendar times and quick-switch notifications.

---

## 🛠️ Architecture & Technical Stack

* **State Management:** Fully dynamic state tracking utilizing the **Provider** design pattern. All providers (`MedicationProvider`, `VitalsProvider`, `SettingsProvider`, `HistoryProvider`) are synchronized dynamically.
* **Storage & Persistence:** Offline-first architecture powered by **SQLite** (`sqflite`). Schema migrations are configured for automatic app resets and table initializations.
* **Notification Engine:** Uses `flutter_local_notifications` integrated with a background dispatcher isolate. Supports quick notification drawer actions (`Take` or `Snooze`), custom sound channels, and automatic rolling alarm scheduling.
* **GPU Driver Fallback (Impeller Opt-Out):** Configured with custom Android manifest metadata to force fallback to Skia GLES engine, bypassing format allocation crashes (Gralloc format 56) common on MediaTek Mali chipsets.
* **R8/ProGuard Minification Rules:** Custom [`proguard-rules.pro`](file:///home/vic/Documents/Projects/Mobile%20dev/medadhere_flutter/android/app/proguard-rules.pro) configuration keeping generic serialization types intact for background notifications.

---

## 🚀 Running the App

Restore dependencies and launch the application:

```bash
# Clean cache files
flutter clean

# Restore packages
flutter pub get

# Launch in Debug Mode
flutter run

# Launch/Compile in Release Mode (Optimized)
flutter run --release
flutter build apk
```

Requires Flutter 3.19+ / Dart 3.3+. Runs fully offline and strictly stores all data local to the device for maximum privacy.
