# Roadmap & Feature Backlog: Mi Nómina Pro

This document serves as the project's living idea repository, feature backlog, and architectural planning space for upcoming capabilities to review and implement in future development cycles.

---

## 📌 Proposed Features & Architectural Backlog

### Feature 1: In-App Admin Account & User Management Dashboard
* **Status**: Proposed / Under Evaluation
* **Target Audience**: App Administrator / Payroll Supervisor
* **Objective**: Provide authorized administrators with an in-app dashboard to monitor active users, inspect shift logs/calculations for troubleshooting, and manage employee profiles securely without accessing the Firebase Console directly.

#### 1. Architecture & Role-Based Access Control (RBAC)
To distinguish between regular employees and administrators:
* **Option A: Firestore Document Role Flag (Recommended for speed & flexibility)**
  * Add `role: "admin"` (or `isAdmin: true`) to the admin's document in Firestore (`users/{uid}`).
  * On app launch or profile load, the app checks if `userData['role'] == 'admin'` and conditionally enables admin routes/UI controls.
* **Option B: Firebase Auth Custom Claims (Enterprise standard)**
  * Set `{ "admin": true }` directly on the Firebase Auth JWT token via Firebase Admin SDK or a Cloud Function.
  * Allows instantaneous, tamper-proof client and server-side validation.
* **Option C: Admin Whitelist (Quick prototype)**
  * Maintain a secure list of admin employee numbers or emails in code/remote config to unlock admin mode.

#### 2. Key Capabilities for the Admin Panel
1. **User Directory**:
   * Searchable list of all registered employees (filtering by Name, Employee Number, or Email).
   * Quick status indicators: active daily salary, registered date, and last sync timestamp.
2. **Attendance & Shift Inspection**:
   * Select any employee to inspect their daily attendance cards, shift notes, and overtime calculations.
   * Useful for diagnosing employee questions when calculations or hours seem inconsistent.
3. **Profile & Data Correction**:
   * Edit mistyped employee numbers or profile fields directly from the UI.
   * Trigger password resets or assist locked-out users.
4. **Payroll & App Telemetry**:
   * View aggregated quincena summaries (e.g., total overtime hours across all employees).
   * Track adoption and active user count per pay period.

#### 3. Security & Governance Standards
* **Firestore Security Rules**: Update security rules to allow read/write access to `/users/{userId}` and `/users/{userId}/history/{docId}` only if `request.auth.token.admin == true` or if the requesting user's document has `role == 'admin'`.
* **Privacy Compliance**: Ensure sensitive employee compensation details are strictly isolated from unauthorized users.
* **Pagination & Read Efficiency**: Enforce query limits (`limit(20)`) and search filters to avoid excessive Firestore document reads across large user bases.

---

### Feature 2: Future Candidates & Idea Backlog
* [ ] **Biometric Login (Mobile)**: Support for Face ID / Fingerprint on Android & iOS for faster access.
* [ ] **PDF / Excel Export**: One-tap export of biweekly payroll breakdowns into downloadable PDF receipts or Excel sheets.
* [ ] **Automated Reminders**: Push notification reminders before shift start or if a user forgot to clock out at the end of their shift.
* [ ] **Offline Persistence / Queueing**: Enhanced offline caching for shift clock-ins when cellular or Wi-Fi signal is unavailable inside studio facilities.
