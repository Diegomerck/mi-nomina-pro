# PROJECT OVERVIEW: Mi Nómina Pro (nomina-televisa-v2)

> **Document Status**: Living Technical Reference Document  
> **Last Updated**: October 2026  
> **Version**: `v.23.13.2 16/10/26` (Build `1.0.0+2`)  
> **Project ID**: `nomina-televisa-v2` | **Package**: `overtime_app`  

---

## 1. App Overview

### Purpose & Target Audience
**Mi Nómina Pro** is a specialized Flutter application built specifically for Televisa workers and shift employees to log daily attendance, track clock-in and clock-out times, calculate daily shift hours, manage base salaries, and compute exact weekly overtime compensation in compliance with Mexican Labor Law (*Ley Federal del Trabajo - LFT*).

### Main Capabilities
- **Authentication & Onboarding**: Employee login/registration mapped to employee numbers (`{empNo}@televisa.com`) or real email addresses via Firebase Auth.
- **Attendance Logging**: Clock-in / clock-out tracking (real-time or manual entry), overnight shift handling, maintenance days (*Día de Mantenimiento*), and absences (*No Laboré Hoy / Falta*).
- **Daily Shift Notes**: Ability to append, edit, or skip custom text notes (*Guardia*, *Turno especial*, etc.) for any daily log.
- **Overtime Calculation Engine**: Automatic computation of 2× (double) and 3× (triple) hourly overtime rates grouped by calendar week.
- **Historical Salary Tracking**: Recalculates past overtime correctly based on salary history on effective dates.
- **Sharing & Reports**: Biweekly overtime summaries formatted in Spanish for sharing via messaging/email.

### Current Version Number
- **Internal Version**: `v.23.13.2` (October 2026 Release).
- **Pubspec Version**: `1.0.0+2` (defined in `pubspec.yaml`).
- **Where Displayed**: App Settings tab footer (`_buildSettingsTab`) and project reference documentation.

---

## 2. Project Structure

```
Mi Nomina Pro All/
├── .firebaserc                # Maps project ID: "nomina-televisa-v2"
├── firebase.json              # Firebase Hosting & Firestore deployment rules
├── firebase_options.dart      # FlutterFire CLI generated configuration for Web, Android, iOS, Windows
├── pubspec.yaml               # App manifest, SDK requirements, and dependencies
├── blueprint.md               # Architecture design & version release log
├── PROJECT_OVERVIEW.md        # Living technical reference document (this file)
├── lib/
│   ├── firebase_options.dart  # Firebase credentials setup
│   └── main.dart              # Core application entrypoint (5,949 lines)
├── web/
│   ├── index.html             # Web entrypoint HTML
│   └── manifest.json          # Web app manifest
└── android/                   # Native Android configuration & manifests
```

### File Responsibilities & Key Files

| File Path | Description / Responsibility |
| :--- | :--- |
| [`lib/main.dart`](file:///c:/Users/Diegomerck/Desktop/PROJECTS/Apps/App%20Televisa/Export/Mi%20Nomina%20Pro%20All/lib/main.dart) | Monolithic application file containing all UI screens, `WorkDay` data model, `OvertimeBreakdown` calculator, Firestore sync logic, local storage, custom time pickers, and dialogs. |
| [`lib/firebase_options.dart`](file:///c:/Users/Diegomerck/Desktop/PROJECTS/Apps/App%20Televisa/Export/Mi%20Nomina%20Pro%20All/lib/firebase_options.dart) | Platform-specific `FirebaseOptions` configurations generated via FlutterFire. |
| [`pubspec.yaml`](file:///c:/Users/Diegomerck/Desktop/PROJECTS/Apps/App%20Televisa/Export/Mi%20Nomina%20Pro%20All/pubspec.yaml) | Defines app name (`overtime_app`), version `1.0.0+2`, and packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `shared_preferences`, `intl`, `share_plus`, `url_launcher`. |

---

## 3. Navigation & UI

The main interface (`TelevisaApp`) uses a top `TabBar` with a dark theme background (`#121212`) and orange accent highlights (`Colors.orange`).

### App Screens / Tabs

```
TelevisaApp (DefaultTabController - 6 Tabs)
 ├── 1. HOY (Today Log & Live Timer)
 ├── 2. QUINCENA (Biweekly Overtime & Calendar)
 ├── 3. AÑO (53-Week Annual Attendance Grid)
 ├── 4. NÓMINA (Pay Slip & Tax Breakdown)
 ├── 5. EXTRAS (Custom Range Overtime Filter)
 └── 6. AJUSTES (Salary & Account Configuration)
```

#### 1. HOY (Today Tab)
- **Data Displayed**: Live date and time (`_timeString`), assigned Clock In (`_entradaDisplay`) and Clock Out (`_salidaDisplay`), elapsed hours summary, estimated daily pay, countdown to departure.
- **Inputs & Controls**:
  - Main Action Button: Toggles state between *Clock In*, *Clock Out*, and *Shift Completed*.
  - Manual Entry: "Entrada" (time picker only) & "Salida" (date + time picker for overnight shifts).
  - Quick Buttons: "DÍA DE MANTENIMIENTO" (asks for clock-in time, logs base shift without overtime) and "NO LABORÉ HOY" (registers absence with $0 pay).
  - Reset Button: "REINICIAR HOY" clears pending clock-in state.

#### 2. QUINCENA (Biweekly Tab)
- **Data Displayed**:
  - Summary Cards: "EXTRAS SEMANA PASADA" and "EXTRAS SEMANA ACTUAL" showing total extra pay (\$) and extra hours (hrs).
  - 2-Week Visual Grid: Shows last week and current week day-by-day.
  - Daily Log Cards: Chronological list of work entries with Spanish date formatting, clock-in, clock-out, real timestamp, overtime breakdown (Base, 2×, 3×), and shift notes.
- **Inputs & Controls**:
  - Share Buttons: `_shareSingleWeekSummary()` formats and shares weekly summary text via `share_plus`.
  - Day Cards: Delete button (`Icons.delete_outline`), "Agregar notas" / "Editar" button.

#### 3. AÑO (Yearly Tab)
- **Data Displayed**: 53-week vertical scrollable grid covering the entire year (Monday to Sunday). Automatically scrolls to the current week on initial render (`_hasAutoScrolledAnoTab`).
- **Visual Encoding**:
  - Day Chips: Color-coded status (Green = normal work day, Blue = maintenance, Red = absence `esFalta`, Yellow outline = weekend day).
  - Weekly Overtime Chips: Display total extra hours and pay per week (`_buildWeekOvertimeSummary`).
- **Inputs & Controls**: Tapping any day chip opens `_showManualDayDialog(dayDate)` for viewing, creating, or editing entries.

#### 4. NÓMINA (Pay Slip Tab)
- **Data Displayed**: Biweekly gross pay estimate, base salary total, accumulated extra hours pay, retention/deduction breakdown, and estimated net pay.

#### 5. EXTRAS (Overtime Breakdown Tab)
- **Data Displayed**: Overtime analytics filtered by customizable date ranges, detailing 2× double hours and 3× triple hours.

#### 6. AJUSTES (Settings Tab)
- **Data Displayed**: User employee number, UID, salary history list (`_salaryHistory`), app version `v.23.10.1`.
- **Inputs**: Text fields for Daily Salary (`_salaryController`), Base Shift Hours (`_baseHoursController`, default `9.5`), and Retention Amount (`_retentionController`). In-line editing with lock/unlock flow and safety confirmation.

### Custom Reusable Widgets & Dialogs

- `_showScrollTimePicker`: Dual-mode time picker (Cupertino scroll wheel & analog clock dial toggle with non-overflowing action header bar).
- `_promptForNotes`: Dark-themed alert dialog with text input, "OMITIR" skip button, and "GUARDAR NOTAS" button.
- `_showManualDayDialog`: Centralized day detail dialog for viewing existing logs, editing pre-filled clock-in/out times & notes via the pencil icon (`Icons.edit`), or creating new attendance entries.

---

## 4. Data Model

### 1. `WorkDay` Model Class
Defined in `lib/main.dart` (lines 393–468):

```dart
class WorkDay {
  String id;                  // Timestamp-based UID or custom ID
  DateTime entrada;           // Scheduled / Assigned Clock-In time
  DateTime salida;            // Scheduled / Assigned Clock-Out time
  DateTime? entradaReal;      // Actual timestamp when Clock In button was pressed
  double sueldoBase;          // Base daily salary active on the entry date
  double baseHours;           // Base shift duration in hours (default: 9.5)
  bool esFalta;               // True if marked as absence ("No Laboré Hoy")
  bool esMantenimiento;       // True if marked as maintenance day
  String notas;               // User text notes for the day
}
```

#### Calculated Properties (Getters)
- `totalHours`: `esFalta ? 0.0 : salida.difference(entrada).inMinutes / 60.0`
- `isOvernight`: `salida.day != entrada.day`
- `extraHoursCount`: `max(0.0, totalHours - baseHours)`
- `dailyPay`: Base daily pay logic (returns `0.0` for `esFalta`, or `sueldoBase` proportional to base hours).

### 2. `OvertimeBreakdown` Class
Defined in `lib/main.dart` (lines 470–485):

```dart
class OvertimeBreakdown {
  double hours2x;  // Overtime hours paid at 2x (double rate)
  double hours3x;  // Overtime hours paid at 3x (triple rate)
  double pay2x;    // Total double overtime pay ($)
  double pay3x;    // Total triple overtime pay ($)
  double totalPay; // pay2x + pay3x ($)
}
```

### 3. Firestore Database Structure

Firestore database: `nomina-televisa-v2`

```
users (collection)
 └── {uid} (document)
      ├── employee_number: "12345"
      ├── user_emp: "12345"
      ├── salary: "500.00"
      ├── base_hours: "9.5"
      ├── retention: "0.00"
      ├── salary_history: [
      │     { "salary": 500.0, "effective_date": "2026-01-01T00:00:00.000" }
      │   ]
      └── history (sub-collection)
           └── {workDayId} (document)
                ├── id: "1725894123000"
                ├── entrada: "2026-09-09T07:30:00.000"
                ├── salida: "2026-09-09T17:00:00.000"
                ├── entradaReal: "2026-09-09T07:28:10.000"
                ├── sueldoBase: 500.0
                ├── baseHours: 9.5
                ├── esFalta: false
                ├── esMantenimiento: false
                └── notas: "Guardia de fin de semana"
```

### Firebase Auth Integration & Data Isolation
- Authentication handled via `FirebaseAuth.instance`.
- User data isolation is enforced by sub-collection routing:  
  `_userHistory = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('history')`.
- All Firestore queries are strictly scoped to the authenticated user's `UID`.

---

## 5. Core Business Logic

### Overtime Calculation Algorithm (`calculateWeeklyOvertimeBreakdown`)
Overtime pay follows Mexican Labor Law (*LFT*):

1. **Hourly Base Rate Formula**:
   $$\text{hourlyRate} = \frac{\text{sueldoBase}}{\text{baseHours}}$$
2. **Weekly Grouping**:
   - Work entries are grouped chronologically by Monday–Sunday week numbers (`_getWeekNumber`).
3. **Daily Extra Hours**:
   $$\text{dailyExtraHours} = \max(0.0, \text{totalHours} - \text{baseHours})$$
4. **2× Double vs. 3× Triple Rate Rules**:
   - Within each calendar week (Monday to Sunday), the first **9 extra hours** accumulated are paid at **2× (Double Rate)**:
     $$\text{pay2x} = \text{hours2x} \times (\text{hourlyRate} \times 2)$$
   - Any extra hours beyond **9 hours** in the same calendar week are paid at **3× (Triple Rate)**:
     $$\text{pay3x} = \text{hours3x} \times (\text{hourlyRate} \times 3)$$
5. **Special Day Rules**:
   - **Absence (`esFalta`)**: `totalHours = 0`, `dailyPay = $0`, `extraHours = 0`.
   - **Maintenance (`esMantenimiento`)**: `totalHours = baseHours`, `dailyPay = sueldoBase`, `extraHours = 0` (0 overtime pay, full base pay).

### Salary History Lookup (`_getSalaryForDate`)
To handle salary raises accurately without corrupting historical logs:
- When calculating pay for a historical entry, `_getSalaryForDate(DateTime date)` scans `_salaryHistory` to retrieve the salary rate in effect on that exact date.

---

## 6. State Management

- **UI State**: Managed via standard Flutter `StatefulWidget` and `setState()`.
- **Backend Sync**:
  - `AuthWrapper` listens to `FirebaseAuth.instance.authStateChanges()` to toggle between `LoginScreen` and `TelevisaApp`.
  - Data updates call `_saveData()` which writes to Cloud Firestore via `WriteBatch` or `.set()` and caches key states locally in `SharedPreferences`.

---

## 7. Known Issues & Tech Debt

1. **Monolithic File Structure**:  
   `lib/main.dart` is ~5,949 lines (242 KB). Refactoring into modular sub-packages (`lib/models/`, `lib/screens/`, `lib/widgets/`, `lib/services/`) is highly recommended for future scalability.
2. **Async Context Lint Warnings**:  
   Two `use_build_context_synchronously` warnings exist in `lib/main.dart` (lines 5059 and 5219) where `Navigator.pop(context)` or `ScaffoldMessenger` is called after async operations without explicit `mounted` checks.

---

## 8. Recent Changes Log

- **v.23.13.2 16/10/26 (Current - Internal Admin Release)**: Consola interna de administración para fusión y migración selectiva de cuentas (`AdminAccountMergeScreen`). Herramienta con acceso restringido para administradores (`minominapro@gmail.com` / UID `RybFq34QonRHbx3m1KitV1Wcft83`) accesible desde la pestaña Ajustes. Búsqueda de cuentas donante y receptora por número de empleado o correo electrónico con validación en tiempo real. Matriz comparativa interactiva campo por campo (turnos con selector de reemplazo exacto para eliminar huérfanos, sueldo diario, jornada, descansos, retención, fomento, cuota sindical, aumentos históricos y perfil) con casillas de verificación independientes para transferencia granular. Sincronización automática del directorio público (`employee_directory`) y marcado de cuenta donante fusionada sin pérdida de registros originales.
- **v.23.13.1 16/10/26**: Acceso dual unificado con Número de Empleado o Correo Electrónico mediante tabla pública de directorio (`employee_directory`) y reglas de seguridad optimizadas. Rediseño moderno y acogedor de la pantalla de acceso con encabezado dinámico, visibilidad de contraseña y botones de acción destacados. Mensajes de error claros y tranquilizadores con diferenciación de contraseña errónea sin riesgo de bloqueo de cuenta. Herramienta interactiva de recuperación de contraseña directamente en pantalla de acceso (`sendPasswordResetEmail`).
- **v.23.12.1 15/10/26**: Implementación de Días de Descanso personalizados con historial por rangos de fechas (soporte para descansos entre semana y turnos especiales). Historial de parámetros para Salario Diario, Jornada Ordinaria, Prima Dominical, Prima Vacacional y Aguinaldo con vigencias históricas independientes sin alterar periodos pasados. Cálculo automático de horas extra al 300% (triple) en días de descanso laborados conforme a la LFT con desglose separado de pago base y prima de descanso. Corrección de teclado con punto decimal en sueldo, protección contra eliminación del último periodo base y auto-cierre/apertura continua de líneas de tiempo.
- **v.23.11.1 13/10/26**: Implementación de Modo Claro / Modo Luz de Día (Daylight Theme) con botón de alternancia en AppBar y persistencia local en SharedPreferences. Accesibilidad visual de alto contraste con textos y números en negro puro (#000000) para lectura bajo luz solar. Rediseño ergonómico de la sección Entrada/Salida en la pestaña Hoy (botones y reloj más grandes, blancos táctiles amplios). Entrada Manual y Salida Manual directa en un paso. Notas integradas a turnos activos antes del cierre. Compatibilidad visual completa en todas las pestañas (Hoy, Quincena, Año, Nómina, Extras, Ajustes). Corrección matemática en el cálculo de nómina para deducciones por faltas (días no laborados) eliminando doble descuento y garantizando pago neto de $0.00 en periodos completos sin asistencia.
- **v.23.9.2 12/10/26**: Desplazamiento automático al entrar a la pestaña Año enfocado en la semana actual. Flujo de edición y guardado en línea en la pestaña Ajustes con bloqueo por defecto, icono de lápiz, verificación y confirmación previa. Eliminación de los botones redundantes 'Guardar Ajustes' y 'Refrescar datos'.
- **v.23.9.1 07/10/26**: Mejora de adaptabilidad responsive en pantallas pequeñas (formularios y diálogos con scroll para evitar bloqueo por teclado virtual). Pestaña Quincena con diseño más compacto, cabecera fija y resumen de semanas en una sola línea. Iconos para compartir resúmenes semanales siempre accesibles. Pestaña Nómina con desplazamiento automático a periodos activos.
- **v.23.8.1**: Se agregó la opción "Festivo" para registrar y gestionar días feriados oficiales (LFT). Rediseño de pestaña "Hoy" con botones más compactos y botón "Reiniciar hoy". Botón de recarga web (flecha circular) junto a la campana para actualización rápida.
- **v.23.7.11**: Campana de notificaciones para comunicar actualizaciones a los usuarios. Confirmación para cerrar sesión (prevenir salidas accidentales).
- **v.23.7.10**: Opción "Vacaciones" para marcar días sin afectar el pago. Notas integradas a registros en Quincena. Corrección visual en calendario y ajuste al cálculo de horas extra.
- **v.23.7.8 09/09/26**: Added daily shift notes system (`notas` field) across Quincena and Año tabs. Added `_buildNotesSection` helper to integrate "Agregar notas" / "Editar" actions into Quincena log cards and day-detail dialogs with Firestore sync. Resolved day chip `BOTTOM OVERFLOWED BY X.0 PIXELS` layout warning across 2-week and 53-week calendar strips using `FittedBox` scaling, tight text leading (`height: 1.0`), and added a subtle orange indicator dot for days with active notes. Added DD/MM/YY date stamp to version number.
- **v.23.7.7**: Dual-mode time picker with non-overflowing responsive header bar ("CANCELAR", "SELECCIONAR HORA", "CONFIRMAR").
- **v.23.7.6 / v.23.7.5**: Replaced standard time pickers with dark-themed scroll wheel (`CupertinoDatePicker`) & analog dial toggle.
- **v.23.7.4**: Salary editing consolidated strictly in "Ajustes" tab.
- **v.23.7.3**: High-contrast red rendering for absence days (`esFalta`).
