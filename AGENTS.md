# Project Guide and Rules: Mi Nómina Pro

This document establishes the architecture, conventions, multi-agent workflows, and critical business rules for any AI agent or developer contributing to this repository.

---

## 1. Project Overview
**Mi Nómina Pro** is a Flutter-based application with a Firebase backend designed for calculating, recording, and tracking payroll and overtime compensation.
- **Frontend / Framework**: Flutter (Dart)
- **Backend / Services**: Firebase Auth, Cloud Firestore
- **Target Platforms**: Web, Mobile

---

## 2. Multi-Agent Operating Model (3-Agent Pattern)
All work within this repository is partitioned across three distinct agent roles to maintain clean context hygiene:

### Role 1: Project Manager / Planning Architect (PM)
- **Primary Objective**: Break down feature requirements, evaluate architectural risks, define atomic work items, and maintain the implementation roadmap.
- **Boundaries**: Does not write or modify executable application code. Delivers structured specifications and explicit acceptance criteria for the Developer.

### Role 2: Developer
- **Primary Objective**: Implement approved specifications while adhering strictly to code modification constraints.
- **Boundaries**: Focuses solely on the assigned atomic task without introducing unsolicited refactoring or scope creep.

### Role 3: Code Reviewer / QA
- **Primary Objective**: Audit all proposed changes prior to integration. Validates business logic (overtime arithmetic), checks Firestore security models, and enforces state consistency.
- **Boundaries**: Does not author code directly; issues clear, actionable pass/fail verdicts with itemized findings.

---

## 3. Strict Code Modification Protocol
Any agent generating code changes must follow these exact instructions:

1. **Target File Path**: Explicitly state the full relative file path (e.g., `lib/features/...`).
2. **Search Block (Ctrl+F Match)**: Provide the exact, complete block of existing code to search for within the file.
3. **Replacement Block**: Provide the exact, full block of code to copy and paste over the matched block.
4. **No Code Truncation**: Never use placeholders (e.g., `// ... rest of the code remains the same`, `/* existing logic */`). The replacement snippet must be 100% complete and drop-in ready.
5. **Dependency Integrity**: Do not alter `pubspec.yaml` package versions without explicit instruction.

---

## 4. Business Logic & Security Standards
- **Overtime Calculations**: All payroll formulas, overtime multipliers, and rounding behaviors must be deterministic and verifiable.
- **User Scoping & Isolation**: All Firestore reads/writes must be scoped strictly under the authenticated user's ID (`users/{uid}/...`).
- **Version Control Hygiene**: All synchronization across machines must go through Git/GitHub branches using concise, imperative commit messages.

---

## 5. Release & Deployment Protocol ("Publish New Version")
Whenever the user instructs to "publish this new version" (or any equivalent wording):
1. **Version Documentation**: Update `_changelogByVersion`, version strings in `lib/main.dart`, `PROJECT_OVERVIEW.md`, and `blueprint.md`.
2. **GitHub Synchronization**: Stage, commit, and push all changes to `origin/master`.
3. **Production Web Build**: Compile the release bundle using `flutter build web`.
4. **Live Deployment**: Deploy to Firebase Hosting using `firebase deploy --only hosting`.