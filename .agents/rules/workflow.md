# Permanent Workflow Rules: Single Conversation Architecture

This document defines the operational workflow for this project to maximize token efficiency, protect code integrity, and ensure smooth transitions between brainstorming and implementation within a single conversation.

---

## 1. Default Mode is ALWAYS PLANNING (Zero Code Edits)

- **Strict Planning Rule**: Unless the user explicitly begins their message with the trigger word **`IMPLEMENTATION`** or **`QUICK FIX`**, the agent must **ALWAYS** treat the turn as **PLANNING / Brainstorming**.
- **Boundaries in Planning Mode**:
  - **NO Code Modifications**: Never edit, create, or delete application code or test files (`lib/**`, `test/**`, etc.).
  - **NO State-Modifying Terminal Commands**: Never run builds (`flutter build`), tests, or git operations. Read-only inspection (`read_file`, search) is permitted to understand existing architecture.
  - **Active Collaboration**: Clarify requirements, highlight architectural trade-offs, identify edge cases (e.g., Firebase security, overtime logic), and agree on precise specifications.
  - **Token Hygiene**: Keep responses concise and lightweight. Avoid dumping full file contents or redundant code diffs into the planning chat.

---

## 2. Single Conversation Lifecycle & Context Hygiene

- **Unified Memory**: Planning and execution both happen in this single conversation thread so that full project context, historical architectural decisions, and previous bugs remain accessible without context switching.
- **Context Compaction (`/compact`)**:
  - Long conversation histories consume significant tokens per turn.
  - The agent should proactively remind the user to run the `/compact` slash command whenever a major feature or sprint has completed, or when the conversation context grows heavy.

---

## 3. Complexity Assessment & Subagent Delegation

The user should never have to guess whether a task is trivial or complex. During the **PLANNING** phase, the agent must evaluate the changes required and declare the recommended execution tier.

### Tier Classification Matrix:
| Tier | Scope / Indicators | Subagent Model | Purpose |
| :--- | :--- | :--- | :--- |
| **Standard Tier** | 1–2 files, localized UI adjustments, styling/theme updates, simple widget refactoring. | `Model: "flash"` | Fastest turnaround, lowest token and credit consumption. |
| **High Tier** | Multi-file refactors, Firestore schema/rules updates, complex state sync, overtime calculation formulas, authentication flows. | `Model: "pro"` | Deep reasoning, rigorous verification, multi-step dependency management. |
| **Quick Fix** | Single typo, 1-line bug fix, localized CSS/style tweak. | **Direct** (no subagent) | Zero subagent overhead. Apply immediately when triggered with `QUICK FIX`. |

### Model Restrictions:
- **Never invoke expensive models** (such as Argon or high-cost custom models) unless the user **explicitly requests them by name** in their prompt.

---

## 4. Execution Protocol on `IMPLEMENTATION` Trigger

When the user sends a message starting with `IMPLEMENTATION`:
1. **Dispatch Subagent**: Automatically invoke the subagent using the assessed tier model (`flash` or `pro`) with clear, targeted instructions and constraints.
2. **Execute Changes**: The subagent applies the drop-in ready code changes and runs static analysis (`flutter analyze`).
3. **Verify Integrity**: Verify that the build remains healthy and no regressions occurred.
4. **Concise Report**: Report back to the user with an itemized, concise summary of files changed and verification status.

---

## 5. Release & Deployment Commands

The project recognizes two explicit commands for live deployment:

- **`PUSH TO LIVE` (Official Release with End-User Notification)**:
  1. Stages and commits all updates to GitHub.
  2. Updates release notes in `PROJECT_OVERVIEW.md` and `blueprint.md`.
  3. Updates user notification text in `lib/main.dart` (`_changelogTitles` and `_changelogByVersion`) using simple, friendly, and non-technical language.
  4. Compiles production web bundle (`flutter build web`).
  5. Deploys live to Firebase Hosting (`firebase deploy --only hosting`).

- **`PUSH DISCRETE` (Silent / Maintenance Release)**:
  1. Stages and commits all updates to GitHub.
  2. Updates release notes in `PROJECT_OVERVIEW.md` and `blueprint.md`.
  3. Does **NOT** update user notification text in `lib/main.dart` (leaves changelog unchanged so users receive no notification badge or popup).
  4. Compiles production web bundle (`flutter build web`).
  5. Deploys live to Firebase Hosting (`firebase deploy --only hosting`).

---

## 6. Communication Protocol

- **Conversational Language**: Conduct all planning, analysis, task summaries, and handoffs in **English**.
- **Domain Separation**: Spanish is reserved exclusively for the application domain (UI text, business copy, end-user changelogs).

