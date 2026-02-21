# Defer Reframe Execution Tracker

Status: Active  
Last Updated: February 17, 2026  
Scope: Delayed gratification reframe execution across sessions

## 1. Source of Truth

- Product direction: `/Users/jcfrane/projects/Defer/Defer/Docs/PRODUCT_REFRAME_SPEC.md`
- This tracker: `/Users/jcfrane/projects/Defer/Defer/Docs/REFRAME_EXECUTION_TRACKER.md`
- Session handoff: `/Users/jcfrane/projects/Defer/Defer/Docs/SESSION_HANDOFF.md`

## 2. Baseline Diagnosis (Current App Reality)

These findings explain why the current app feels like a sobriety/streak tracker rather than a delayed gratification app.

1. Core model is streak/check-in/strict-mode driven in:
   - `/Users/jcfrane/projects/Defer/Defer/Domain/DeferItem.swift`
   - `/Users/jcfrane/projects/Defer/Defer/Domain/DeferEnums.swift`
2. Repository automates check-ins and strict failures:
   - `/Users/jcfrane/projects/Defer/Defer/Data/DeferRepository.swift`
3. Primary user actions are check-in/pause/fail:
   - `/Users/jcfrane/projects/Defer/Defer/UI/Details/Views/DeferDetailView.swift`
   - `/Users/jcfrane/projects/Defer/Defer/UI/Home/Views/Components/HomeDeferCardView.swift`
4. Form framing is strict accountability rather than intentional delay protocols:
   - `/Users/jcfrane/projects/Defer/Defer/UI/Forms/Views/DeferFormView.swift`
5. Achievement logic is mostly streak/completion-run based:
   - `/Users/jcfrane/projects/Defer/Defer/Domain/AchievementCatalog.swift`
6. History tracks completion snapshots, not full decision outcomes:
   - `/Users/jcfrane/projects/Defer/Defer/UI/History/Views/HistoryView.swift`
   - `/Users/jcfrane/projects/Defer/Defer/Domain/CompletionHistory.swift`
7. Notifications are check-in/milestone/target-date reminders, not urge-time interventions:
   - `/Users/jcfrane/projects/Defer/Defer/Data/LocalNotificationManager.swift`
8. Home scoring and copy are streak-centric:
   - `/Users/jcfrane/projects/Defer/Defer/UI/Home/Views/Components/HomeSummaryCardView.swift`
   - `/Users/jcfrane/projects/Defer/Defer/Data/MotivationService.swift`
9. No automated test target currently detected; state-machine refactors need tests.

## 3. Reframed Product Loop (Target)

1. Capture desire quickly.
2. Commit to a delay protocol (10m, 24h, 72h, payday, custom).
3. Apply friction/interventions during waiting.
4. Re-evaluate at decision checkpoint.
5. Record outcome and reflection.
6. Reward intentional decisions.

## 4. Program Plan (10-12 Weeks)

Status legend:

- `Not Started`
- `In Progress`
- `Blocked`
- `Done`

### Phase 0: Product Reframe Spec (Week 1)

- Status: `Done`
- Goal: lock product language, metrics, and event taxonomy for delayed gratification.
- Exit Criteria:
  - Product reframe spec approved.
  - Core metrics and event set defined.
- Notes:
  - Spec created and updated for "new app, no production users":
    - `/Users/jcfrane/projects/Defer/Defer/Docs/PRODUCT_REFRAME_SPEC.md`

### Phase 1: Domain + State Machine Expansion (Weeks 2-3)

- Status: `Done`
- Goal: add delayed-gratification data model and outcomes.
- Planned Work:
  - Add models: `DelayIntent`, `DelayProtocol`, `UrgeLog`, `DecisionOutcome`, `RewardLedgerEntry`.
  - Add outcomes: `resisted`, `intentional_yes`, `postponed`, `gave_in`, `canceled`.
  - Keep legacy compatibility only if needed for dev/test continuity.
- Exit Criteria:
  - App runs with new schema.
  - Core outcomes representable end-to-end.

### Phase 2: Repository + Services Refactor (Weeks 3-4)

- Status: `Done`
- Goal: introduce delayed-gratification repository and engines.
- Planned Work:
  - Add repository methods: `captureIntent`, `startDelay`, `logUrge`, `completeDecision`, `postponeDecision`.
  - Add `DecisionEngine` and `RewardEngine`.
  - Keep legacy repository behind adapter until UI cutover.
- Exit Criteria:
  - Transition rules deterministic and unit-testable.

### Phase 3: Home Loop Redesign (Weeks 4-5)

- Status: `Done`
- Goal: move Home from streak dashboard to decision queue.
- Planned Work:
  - Queues: `Needs Decision Now`, `In Delay Window`, `Recent Urges`.
  - Replace streak-first scorecards with intentionality metrics.
  - Change CTA to "Capture Desire."
- Exit Criteria:
  - One-tap capture + due-decision workflow live on Home.

### Phase 4: Form + Detail Flow Rebuild (Weeks 5-6)

- Status: `Done`
- Goal: replace check-in/fail workflow with delay protocol + decision flow.
- Planned Work:
  - Form fields: desire, why, protocol, friction plan, fallback action.
  - Detail actions: `Log Urge`, `Apply Coping`, `Decide Now`, `Postpone`.
  - Keep MVVM ownership in view models.
- Exit Criteria:
  - Full intent journey works without legacy check-in actions.

### Phase 5: History + Insights Upgrade (Weeks 6-7)

- Status: `Done`
- Goal: show decision quality trends instead of completion-only stats.
- Planned Work:
  - Include all outcomes.
  - Add trends: impulse prevented, intentional purchase rate, delay quality, regret trend.
- Exit Criteria:
  - User can evaluate whether decision quality is improving.

### Phase 6: Achievements + Rewards Overhaul (Weeks 7-8)

- Status: `Done`
- Goal: reward delayed-gratification behavior quality.
- Planned Work:
  - Rework achievement catalog and unlock logic.
  - Add reward ledger and planned rewards.
- Exit Criteria:
  - Rewards tied to intentional behavior, not streak length alone.

### Phase 7: Notification Strategy Rewrite (Weeks 8-9)

- Status: `Done`
- Goal: switch from generic check-ins to event-driven decision nudges.
- Planned Work:
  - Delay-expiry reminders.
  - High-risk time window nudges.
  - Pending decision prompts.
  - Coping suggestion reminders.
- Exit Criteria:
  - Notification behavior maps to active delay protocols.

### Phase 8: Background Processing + Reliability (Week 9)

- Status: `Done`
- Goal: process checkpoint logic safely in background.
- Planned Work:
  - Replace strict-mode enforcement jobs with checkpoint/outcome jobs.
  - Ensure timezone-safe and idempotent execution.
- Exit Criteria:
  - No duplicate outcomes or corrupted state from background runs.

### Phase 9: Testing + Analytics + Launch Readiness (Weeks 10-12)

- Status: `Not Started`
- Goal: stabilize and validate the reframe.
- Planned Work:
  - Add unit tests for state transitions/repository rules.
  - Add UI tests for capture -> wait -> decide flow.
  - Instrument metrics from reframe spec.
- Exit Criteria:
  - Stable metrics, passing tests, launch confidence.

## 5. Immediate High-Impact Quick Wins (1 Week)

- [x] Replace streak/fail/strict-mode copy with delay/decision-checkpoint language in Home/Form/Detail.
- [x] Add "why this matters" and "decision not before" fields to capture intent quality.
- [x] Add outcome options beyond completed/failed (`intentional_yes`, `postponed`, `resisted`).
- [x] Fix ongoing filter to avoid treating failed items as ongoing:
  - `/Users/jcfrane/projects/Defer/Defer/UI/Home/Models/HomeFiltering.swift`

## 6. Suggested Work Item IDs

Use these IDs in commits and PR notes to keep continuity across sessions:

- `RF-000` tracker and handoff setup
- `RF-001` domain models and enums
- `RF-002` repository/state-machine methods
- `RF-003` Home queue redesign
- `RF-004` Form flow redesign
- `RF-005` Detail decision actions
- `RF-006` History outcome analytics
- `RF-007` Achievement/reward redesign
- `RF-008` notification strategy rewrite
- `RF-009` background task rewrite
- `RF-010` tests and analytics instrumentation

## 7. Risks and Watchouts

1. Product drift back to streak-first language during UI edits.
2. Half-migrated state where legacy and new models conflict.
3. Missing tests during state-machine changes.
4. Notification complexity around scheduling and deduping.
5. Timezone/date-boundary bugs in delay checkpoints.

## 8. Next Session Recommended Start

1. Implement `RF-010` tests for lifecycle transitions (`active_wait` -> `checkpoint_due` -> `resolved/canceled`).
2. Add explicit notification scheduling tests for checkpoint/mid-delay/high-risk/postpone requests.
3. Add analytics verification tests for MVP event taxonomy coverage.
