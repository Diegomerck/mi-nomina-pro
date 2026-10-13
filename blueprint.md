# Blueprint: Mi Nómina Pro (Televisa Overtime Tracker)

## 1. Overview
“Mi Nómina Pro” is a Flutter application designed to track and calculate daily work hours, base pay, and overtime specifically for Televisa employees. It integrates firmly with Firebase for backend storage and authentication.

**Key Capabilities:**
- User Authentication (Login & Registration via email or employee number mapping)
- Onboarding for New Users (setting up Base Salary, Daily Hours, etc.)
- Work Day entry logging (Clock In / Clock Out, missing day marks, maintenance days)
- Automatic calculation of Base Pay vs. Overtime (2x / 3x logic per week)
- History and Summary views for specific periods (Calendar & Pay Periods)
- Dark-themed, customized Material 3 UI design.

## 2. Current Architecture & Implementation
*   **State Management / Structure:** Currently relies heavily on stateful widgets (`StatefulWidget`) managed within a single large `main.dart` file (approx. 5,500 lines). Data models like `WorkDay` are embedded within the same file.
*   **Backend:** Firebase Authentication for identity. Cloud Firestore (`users` collection) for storing profile setup, salary history, and potentially individual workday entries.
*   **Packages used:** `flutter`, `intl` (for dates), `share_plus`, `shared_preferences`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `url_launcher`.
*   **Design:** Deeply customized UI featuring an explicitly customized orange & dark grey/black palette (`Color(0xFF121212)`). Uses Dialogs for popups and SnackBar for alerts continuously.

## 3. Plan for Next Steps
Since you exported the workspace from Firebase Studio to Antigravity (via `@fbs-to-agy-export`), we should define our targets for this session. Below is a suggested roadmap to improve the app:

### Step 3.1: Code Organization & Refactoring (Highly Recommended)
1.  **Split `main.dart`:** The current entry file is >226KB. We should decompose this into logical folders (`lib/models/`, `lib/screens/`, `lib/widgets/`, `lib/services/`).
2.  **Move Models:** Extract `WorkDay` and `OvertimeBreakdown` to `lib/models`.
3.  **Separate Screens:** Extract `AuthWrapper`, `LoginScreen`, `TelevisaApp` to distinct files in `lib/screens`.

### Step 3.2: Requested Features
*Please specify what you would like to build or modify in this session. Common tasks could include:*
*   Adding new UI states or modifying existing flows (e.g. Password Recovery).
*   Enhancing the visual design (typography, animations).
*   Integrating Generative AI via `firebase_ai` (as mentioned in your `GEMINI.md`).
*   Configuring and adding tests using `flutter_test`.

---
## 4. Version History & Release Tracking
*   **v.23.7.1 (Official Baseline Working Version):** Original working version exported from Firebase Studio. Saved as baseline in memory for rollback.
*   **v.23.7.2:** Added temporary "PRUEBA" tab for testing local hot reloading (reverted).
*   **v.23.7.3:** High-contrast absence rendering in Quincena & Año tabs. Absence squares (`esFalta`) rendered in solid red (`Colors.red.shade700`) with high-contrast white typography.
*   **v.23.7.4:** Removed "Sueldo Diario" TextField visual element from "Hoy" tab so salary editing lives exclusively in "Ajustes" tab.
*   **v.23.7.5:** Replaced analog clock dial time pickers with intuitive dark-themed vertical scroll wheel time pickers (`CupertinoDatePicker` / `_showScrollTimePicker`).
*   **v.23.7.6:** Implemented Dual-Mode Time Picker defaulting to Analog Clock dial with a 1-tap header toggle button to switch to Scroll Wheel mode. Redesigned action header bar ("CANCELAR", "SELECCIONAR HORA", "CONFIRMAR") with responsive `FittedBox` scaling so buttons never overflow or get cut off on any phone screen.
*   **v.23.7.7 (09/26):** Separated Analog Clock & Scroll Wheel modes into clean, un-squished individual views with 1-tap toggle button. Updated "Entrada Manual" to bypass DatePicker for "Entrada" (goes straight to time selection) while preserving DatePicker for "Salida" (for overnight shifts). Date tag updated to 09/26 for September release.
*   **v.23.7.8 (09/09/26):** Implemented complete daily shift notes system (`notas` field) across Quincena and Año tabs. Added `_buildNotesSection` to Quincena log cards (both regular and absence cards) with "Agregar notas" / "Editar" actions synced to Firestore. Resolved day chip bottom overflow bug across Quincena and Año calendar strips via responsive `FittedBox` scaling, tight text leading (`height: 1.0`), and added a subtle orange indicator dot (`hasNotes`) for days with active notes. Updated version string format to `23.7.8 09/09/26` (DD/MM/YY).
*   **v.23.7.10:** Added Vacaciones day type, shift notes integration, and overtime calculation refinements.
*   **v.23.7.11:** Added notification bell for in-app update notices and logout confirmation dialog.
*   **v.23.8.1:** Added Día Festivo day type (LFT compliant, double base pay + separate 3x extra hours), compact Hoy tab layout, and web instant reload button.
*   **v.23.9.1 (Official Current Release - 07/10/26):** Enhanced small-screen keyboard adaptability (scrollable dialogs), compact single-line weekly summaries with fixed header in Quincena, always-visible share icons, and auto-scroll in Nómina.


---
*Updated per Version Control rules for Antigravity workspace.*
