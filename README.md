# MedAdhere — Flutter App

A pixel-faithful Flutter port of the "Mobile Medication Adherence Dashboard" Figma Make design (React/TSX source).

## What's included

7 screens, matching the original design 1:1 in colors, gradients, spacing, and copy:

- **Dashboard** (`screens/dashboard_screen.dart`) — greeting, streak badge, weekly progress, quick stats, today's medication cards
- **History** (`screens/history_screen.dart`) — adherence summary header, monthly calendar heat-grid, dose log
- **Health & Vitals** (`screens/health_screen.dart`) — vitals grid, blood pressure bar chart, medication impact cards
- **Profile** (`screens/profile_screen.dart`) — patient hero, active medications, care network, notification settings
- **Medication Detail** (`screens/med_detail_screen.dart`) — tabbed view (Overview / Schedule / Side Effects / Refills)
- **Add Medication** (`screens/add_med_screen.dart`) — 3-step form flow with progress indicator
- **Reminders & Alerts** (`screens/reminders_screen.dart`) — notification hub, timeline of alert rules, global settings

Shared components:
- `widgets/medication_card.dart` — the 3-state MedicationCard (upcoming / taken / missed)
- `widgets/bottom_nav.dart` — bottom tab bar (Home / History / Health / Profile)

## Navigation

- `root_shell.dart` hosts the 4 main tabs in an `IndexedStack` behind the bottom nav.
- Tapping any medication card on the Dashboard pushes **Medication Detail**.
- The "+ Add" action on Profile → Active Medications pushes **Add Medication**.
- The "Manage" action on Profile → Notification Settings, and the avatar bell on Dashboard, push **Reminders & Alerts**.

## Design tokens

All colors/spacing are centralized in `theme/app_colors.dart` (mirrors the original `index.css` CSS variables) and `theme/app_theme.dart`. Font is **Inter**, loaded via `google_fonts` (matches the original `@import` of Inter from Google Fonts).

## Running it

```bash
flutter pub get
flutter run
```

Requires Flutter 3.19+ / Dart 3.3+ (uses Dart 3 switch expressions).

## Notes

- All data is currently static/mock (matching the original design's mock data) — wire up state management (Provider/Riverpod/Bloc) and an API/local DB layer when ready.
- `google_fonts` fetches the Inter font at runtime; for offline/production builds consider bundling the font files locally instead.
