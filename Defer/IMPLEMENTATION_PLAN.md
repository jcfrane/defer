# Defer App Implementation Plan

## Goal
Build a SwiftUI + SwiftData iOS app that helps users defer urges/purchases/habits until target dates, track streaks, unlock achievements, and review completed defer history.

---

## Delivery Phases

## Phase 0: Product Definition and Foundations

### 0.1 Product Scope and Principles
- [ ] Define MVP vs post-MVP scope.
- [ ] Finalize supported defer types for v1:
  - [ ] Abstinence defers (e.g., chocolate, masturbation).
  - [ ] Spending defers (e.g., no purchases > $5000).
  - [ ] Custom free-form defers.
- [ ] Define behavioral rules for streaks and failures.
- [ ] Define success criteria (completion, pause, cancel).

### 0.2 Technical Baseline
- [ ] Confirm deployment target (recommended: iOS 17+ for modern SwiftData/SwiftUI APIs).
- [ ] Set architecture baseline:
  - [ ] `MVVM` (widely used with SwiftUI).
  - [ ] Repository/Data Service layer for persistence abstraction.
  - [ ] Coordinator-style lightweight navigation organization if flows grow.
- [ ] Configure app-wide design tokens (color, spacing, typography, motion constants).
- [ ] Configure lints and formatting (SwiftLint/SwiftFormat optional but recommended).

### 0.3 Success Metrics (for roadmap clarity)
- [ ] Track MVP usage metrics design:
  - [ ] Daily active defers.
  - [ ] Completion rate.
  - [ ] Average streak length.
  - [ ] Achievement unlock frequency.

---

## Phase 1: Domain Modeling + SwiftData Schema

### 1.1 Core Entities
- [x] Create `@Model` entities in SwiftData:
  - [x] `DeferItem`
  - [x] `StreakRecord`
  - [x] `Achievement`
  - [x] `CompletionHistory`
  - [x] `Quote` (optional local/remote)

### 1.2 Suggested `DeferItem` Fields
- [x] `id: UUID`
- [x] `title: String` (required)
- [x] `details: String?`
- [x] `category: DeferCategory` (enum)
- [x] `type: DeferType` (abstinence/spending/custom)
- [x] `startDate: Date`
- [x] `targetDate: Date`
- [x] `status: DeferStatus` (active/completed/failed/canceled/paused)
- [x] `strictMode: Bool` (optional, controls failure behavior)
- [x] `streakCount: Int`
- [x] `lastCheckInDate: Date?`
- [x] `currentMilestone: Int` (for badge progress)
- [x] `createdAt: Date`
- [x] `updatedAt: Date`

### 1.3 Suggested Supporting Models
- [x] `StreakRecord`:
  - [x] Per-day/per-check-in status and optional note.
- [x] `CompletionHistory`:
  - [x] Snapshot of completed defer with duration and summary.
- [x] `Achievement`:
  - [x] Badge id, unlock date, source defer/global condition.
- [x] Add `@Relationship` mappings and delete rules.

### 1.4 Repository + Query Strategy
- [x] Implement repository interfaces for CRUD + state transitions.
- [x] Add filtered fetch methods:
  - [x] Active defers.
  - [x] Completed defers.
  - [x] Due soon / overdue.
- [x] Add computed helpers:
  - [x] `daysRemaining`
  - [x] `progressPercent`
  - [x] `isCompletedToday`

---

## Phase 2: Core User Flows (MVP)

### 2.1 Defer Creation Flow
- [x] Build `CreateDeferView` with validations:
  - [x] Title required.
  - [x] Target date must be after start date.
  - [x] Optional preset templates by category.
- [x] Build edit flow (`EditDeferView`).
- [x] Add delete/cancel confirmation UX.

### 2.2 Dashboard
- [x] Build dashboard sections:
  - [x] Active defers list (cards).
  - [x] Remaining days prominent display.
  - [x] Streak indicators.
  - [x] Quick actions (check-in, mark failed, pause).
- [x] Add sorting and filtering:
  - [x] Closest target date.
  - [x] Longest streak.
  - [x] Category filter.

### 2.3 Streak Logic
- [x] Implement check-in mechanism:
  - [x] Daily confirmation.
  - [x] Auto-update streak count.
- [x] Handle missed days policy (grace vs strict).
- [x] Add streak recovery option (optional setting).

### 2.4 Completion and History
- [x] Auto-complete defer when target date passes and status is valid.
- [x] Move completed defer snapshot into `CompletionHistory`.
- [x] Build history timeline view with stats:
  - [x] Total completed.
  - [x] Average defer length.
  - [x] Category completion breakdown.

---

## Phase 3: Achievements and Motivation Layer

### 3.1 Achievement System
- [x] Define unlock conditions:
  - [x] First completed defer.
  - [x] 7-day/30-day/100-day streak.
  - [x] Category mastery milestones.
  - [x] Consecutive successful completions.
- [x] Build achievement engine service to evaluate triggers on events.
- [x] Persist and render earned vs locked badges.

### 3.2 Badge Design System
- [x] Create badge tiers (Bronze/Silver/Gold/Legend).
- [x] Define visual language for each tier.
- [x] Add celebratory unlock animation and haptics.

### 3.3 Motivational Extras
- [x] Quote of the day module (local bundle first, remote later).
- [x] Encourage message logic based on streak state.
- [x] Optional “why I defer this” reminder prompt display.

---

## Phase 4: UI/UX Theme and Visual Direction

### 4.1 Theme Concept: “Growth Through Restraint”
- [x] Visual metaphor: progress as a living tree.
- [x] Core mood: calm, disciplined, optimistic.
- [x] Primary palette:
  - [x] Deep Forest (`#1F4D3A`)
  - [x] Moss (`#6F9E76`)
  - [x] Sand (`#EADFC8`)
  - [x] Accent Amber (`#D79B2E`)
  - [x] Error Clay (`#B44D3A`)
- [x] Use semantic tokens (`primary`, `surface`, `success`, `warning`, `danger`).

### 4.2 Typography and Layout
- [x] Use SF Pro with hierarchy:
  - [x] Large title for countdown.
  - [x] Medium weight for defer titles.
  - [x] Monospaced digits for day counters.
- [x] 8pt spacing system and card-based layout.
- [x] Ensure Dynamic Type support and accessibility contrast.

### 4.3 Motion and Delight
- [x] Tree growth animation linked to streak milestones.
- [x] Card reveal animation on dashboard load.
- [x] Badge unlock burst animation.
- [x] Subtle haptics for check-ins and completion.

### 4.4 Screen Inventory
- [x] Dashboard.
- [x] Defer detail.
- [x] Create/Edit defer.
- [x] Achievements gallery.
- [x] History timeline.
- [x] Settings/Profile.

---

## Phase 5: Notifications, Reminders, and Reliability

### 5.1 Local Notifications
- [x] Request notification permission in context.
- [x] Daily check-in reminders.
- [x] Milestone reminder notifications.
- [x] Target-date approaching alerts.

### 5.2 Reliability and Data Integrity
- [x] Add migration strategy for SwiftData schema versions.
- [x] Add data validation guards for impossible states.
- [x] Add backup/export option (JSON/CSV) for user trust.

### 5.3 Offline-First Behavior
- [x] Ensure all core features run fully offline.
- [x] Queue non-critical operations for later sync (if cloud introduced later).

---

## Phase 6: Authentication and Account Layer (Later)

### 6.1 Sign in with Apple
- [ ] Add Sign in with Apple capability.
- [ ] Implement authentication flow and session handling.
- [ ] Link local data to account identity.
- [ ] Add account deletion/export compliance path.

### 6.2 Optional Cloud Sync (Post-MVP)
- [ ] Evaluate CloudKit integration with SwiftData.
- [ ] Resolve conflict strategy for edits across devices.
- [ ] Add sync status indicators.

---

## Phase 7: QA, Testing, and Release

### 7.1 Automated Tests
- [ ] Unit tests:
  - [ ] Date logic / days remaining.
  - [ ] Streak engine.
  - [ ] Achievement unlock conditions.
  - [ ] Repository CRUD/state transitions.
- [ ] UI tests:
  - [ ] Create defer flow.
  - [ ] Completion flow.
  - [ ] Badge unlock flow.

### 7.2 Manual QA Matrix
- [ ] Fresh install path.
- [ ] Long-running defer path.
- [ ] Failure and recovery path.
- [ ] Time zone/date boundary scenarios.
- [ ] Accessibility checks (VoiceOver, Dynamic Type, contrast).

### 7.3 Release Readiness
- [ ] App Store screenshots and metadata.
- [ ] Privacy labels and data usage disclosures.
- [ ] Crash/error monitoring setup.
- [ ] v1 launch checklist and rollback plan.

---

## Recommended Feature Backlog (Beyond Requested Scope)

- [ ] Accountability partner mode (share streak privately).
- [ ] “Temptation journal” quick notes during urges.
- [ ] Focus mode lock-screen widgets/live activities.
- [ ] Smart insights (“Most difficult category this month”).
- [ ] AI-generated coping suggestions (on-device or private API).

---

## Suggested Build Order (Execution Sequence)

- [ ] Milestone 1: Phases 0-2 (usable MVP).
- [ ] Milestone 2: Phase 3 + basic animations from Phase 4.
- [ ] Milestone 3: Phase 5 reliability + reminders.
- [ ] Milestone 4: Phase 6 Sign in with Apple.
- [ ] Milestone 5: Phase 7 release prep.

---

## Definition of Done (MVP)

- [ ] User can create, edit, and track defers.
- [ ] Dashboard clearly shows days remaining + streak.
- [ ] Completed defers appear in history with stats.
- [ ] Basic achievements unlock correctly.
- [ ] Data persists reliably via SwiftData.
- [ ] App is stable for at least 7-day beta usage without critical defects.
