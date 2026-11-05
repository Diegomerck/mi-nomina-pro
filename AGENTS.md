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
- **Boundaries & Tool Restrictions**: 
  - **Strict Read-Only on App Code**: The PM Agent is strictly prohibited from modifying executable code (`lib/**`). It must never invoke code-editing tools (`replace_file_content`, `multi_replace_file_content`, `write_to_file` on application code).
  - **Token-Efficient Prompt Handoffs**: When preparing tasks for the Developer, the PM must output **ONLY a concise, high-level prompt (under 15 lines)** containing the problem context, required logic, and acceptance criteria. The PM must **never dump raw code blocks, diffs, or replacement snippets** into the PM chat.
  - **No Unilateral Reversions**: The PM Agent must **NEVER** run destructive git commands (`git checkout`, `git restore`, `git reset`) on modified or working code without explicit user consent. If code exists on disk outside the expected workflow, the PM must pause and ask the user for direction.

### Role 2: Developer (Implementation Agent)
- **Primary Objective**: Implement approved specifications while adhering strictly to code modification constraints.
- **Boundaries**: Focuses solely on the assigned atomic task without introducing unsolicited refactoring or scope creep. Executes static analysis and verification tests.

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

The repository recognizes two official deployment commands:

### A. `PUSH TO LIVE` (Official Public Release)
Full release workflow notifying end users of updates:
1. **Version Documentation**: Update `_changelogTitles` and `_changelogByVersion` in `lib/main.dart` using simple, clear, user-friendly language. Update version strings across the app (`lib/main.dart`, `PROJECT_OVERVIEW.md`, `blueprint.md`).
2. **Release Notes**: Document technical and functional changes in `PROJECT_OVERVIEW.md` and `blueprint.md`.
3. **GitHub Synchronization**: Stage, commit, and push all changes to `origin/master`.
4. **Production Web Build**: Compile the release bundle using `flutter build web`.
5. **Live Deployment**: Deploy live to Firebase Hosting using `firebase deploy --only hosting`.

### B. `PUSH DISCRETE` (Silent / Maintenance Release)
Maintenance release workflow for silent fixes or backend adjustments without end-user notification:
1. **No User Notification**: Do **NOT** modify `_changelogTitles` or `_changelogByVersion` in `lib/main.dart` (ensures users do not receive an unread update badge or popup).
2. **Release Notes & Documentation**: Stage internal notes and version updates in `PROJECT_OVERVIEW.md` and `blueprint.md`.
3. **GitHub Synchronization**: Stage, commit, and push all changes to `origin/master`.
4. **Production Web Build**: Compile the release bundle using `flutter build web`.
5. **Live Deployment**: Deploy live to Firebase Hosting using `firebase deploy --only hosting`.

---

## 6. Language & Communication Protocol
- **Conversational Language**: All agents across all roles must conduct communication, analysis, planning, status reports, and handoff prompts strictly in **English**.
- **Application Context Separation**: Spanish is used exclusively within the application domain itself (e.g., UI labels, error messages, user documentation, and changelogs presented to end users). Agents must never allow Spanish application copy or domain terminology to drift conversational responses away from English.