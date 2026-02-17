# Product Reframe Spec: Defer

Status: Draft  
Last Updated: February 17, 2026  
Owner: Product + Engineering

## 1. Purpose

This document defines how Defer shifts from a streak-centric self-control tracker to a delayed gratification app focused on improving decision quality over time.

This spec is the product contract for design, engineering, and copy before feature implementation.

### 1.1 Launch Assumption

This is treated as a new app launch with no production users.  
Because there is no live user data to preserve, database migration work is optional and only needed if we choose to keep local dev/test seed data continuity across schema changes.

## 2. Reframed Product Positioning

### 2.1 Positioning Statement

Defer helps people insert a structured waiting period between impulse and action so they can make more intentional decisions.

### 2.2 What Defer Is

- A decision quality coach for moments of impulse.
- A delay protocol system with checkpoints and reflection.
- A personal operating system for choosing "want most" over "want now."

### 2.3 What Defer Is Not

- Not a sobriety app.
- Not primarily a streak app.
- Not a guilt or punishment tracker.
- Not a generic to-do list.

## 3. Target Users and Jobs To Be Done

### 3.1 Primary Users

- People who make impulse purchases and regret them later.
- People who want to reduce reactive habits (scrolling, snacking, etc.).
- People trying to train intentional restraint, not strict abstinence identity.

### 3.2 Core Jobs To Be Done

- "When I feel an urge, help me pause long enough to choose deliberately."
- "Give me a simple protocol to delay, not just a vague promise."
- "Show me whether my choices are actually getting better."

## 4. Core Behavior Loop

1. Capture Desire  
User records what they want, context, and urgency.

2. Commit To Delay  
User picks a protocol (for example: 10 minutes, 24 hours, 72 hours, until payday, custom date).

3. Navigate The Wait  
User logs urges, applies coping actions, and receives context-aware nudges.

4. Decision Checkpoint  
At the delay endpoint, user chooses: intentional yes, postponed, resisted, or gave in.

5. Reflection And Reinforcement  
User records quick reflection and receives progress signals tied to decision quality.

## 5. Product Principles

1. Decision quality over streak length.
2. Friction by design at impulse moments.
3. Reflection must be lightweight (10 to 20 seconds).
4. Progress is measured by intentional outcomes, not perfection.
5. Language must remain neutral, supportive, and specific.

## 6. Outcome Model and State Machine

### 6.1 Decision Outcomes

- `resisted`
- `intentional_yes`
- `postponed`
- `gave_in`
- `canceled`

### 6.2 Intent Lifecycle States

- `active_wait`
- `checkpoint_due`
- `resolved`
- `canceled`

### 6.3 Allowed Transitions

- `active_wait` -> `checkpoint_due` (delay end reached)
- `active_wait` -> `resolved` (user decides early with explicit confirmation)
- `checkpoint_due` -> `resolved` (outcome recorded)
- `active_wait` -> `canceled` (user cancels)
- `checkpoint_due` -> `active_wait` (user postpones with new protocol)

### 6.4 Legacy Mapping (Current App -> Reframed App)

- `completed` -> `resolved` with inferred `resisted` or `intentional_yes` (requires migration assumption).
- `failed` -> `resolved` with `gave_in`.
- `canceled` -> `canceled`.
- `paused` -> `active_wait` with suppressed reminders.

## 7. MVP Scope (Reframe v1)

### 7.1 In Scope

- Fast desire capture flow.
- Delay protocol presets + custom protocol.
- Urge logging during wait.
- Decision checkpoint screen with explicit outcomes.
- Reflection prompt (short, optional but encouraged).
- New history model for all outcomes.
- Notifications for checkpoint and high-risk timing.
- Metrics dashboard for decision quality.

### 7.2 Out of Scope

- Social/accountability partner features.
- AI coach/chat.
- Multi-device cloud sync.
- Advanced behavioral experiments.

## 8. Information Architecture (Tab-Level)

1. Home  
Queue of active waits, due checkpoints, and quick-capture entry.

2. Achievements  
Badges for intentional decisions, delay adherence, reflection consistency, and urge navigation.

3. History  
Timeline of outcomes and trend views (intentional rate, regret trend, saved spend estimate).

4. Settings  
Notification preferences and personal protocol defaults.

## 9. Screen Role Changes (Current -> Reframed)

### 9.1 Home

- Replace streak-first summaries with intentionality metrics.
- Prioritize "Needs Decision Now" and "In Delay Window."
- Keep one-tap capture always visible.

### 9.2 Form

- Replace strict mode framing with delay protocol setup.
- Add fields:
  - desire/item/action
  - why it matters
  - estimated cost (optional)
  - desired delay protocol
  - fallback action during urge

### 9.3 Detail

- Replace `Check In / Pause / Fail` with:
  - `Log Urge`
  - `Use Fallback`
  - `Decide Now`
  - `Postpone`

### 9.4 History

- Show all outcomes, not only completions.
- Add outcome mix and regret trend.
- Keep category analysis, but tie it to decision quality.

### 9.5 Achievements

- Replace streak-heavy criteria with behavior-quality criteria.

## 10. Copy and Language Rules

### 10.1 Avoid Terms

- "sober"
- "relapse"
- "clean"
- "failed streak"
- "punishment"

### 10.2 Preferred Terms

- "delay"
- "checkpoint"
- "intentional choice"
- "urge log"
- "decision quality"
- "postpone"

### 10.3 Voice

- Calm, direct, non-judgmental.
- Specific next actions.
- No shame framing.

## 11. Success Metrics and Definitions

### 11.1 North Star

Intentional Decision Rate (IDR):

`(intentional_yes + resisted) / (all resolved intents)`

### 11.2 Supporting Metrics

- Delay Adherence Rate:
  - `resolved after scheduled checkpoint / all resolved intents`
- Average Delay Honored:
  - mean(hours between capture and final decision)
- Impulse Spend Avoided (optional estimate):
  - sum(estimated_cost for resisted outcomes)
- Reflection Completion Rate:
  - `resolved intents with reflection / all resolved intents`
- Regret Delta:
  - average(post-decision regret score minus pre-delay urge score)

## 12. Analytics Event Taxonomy (MVP)

- `desire_captured`
- `delay_protocol_selected`
- `urge_logged`
- `checkpoint_due`
- `decision_recorded`
- `decision_postponed`
- `reflection_submitted`
- `notification_opened`

Each event must include:

- `intent_id`
- `category`
- `protocol_type`
- `protocol_duration_hours`
- `timestamp`

## 13. Notification Strategy (Reframed)

### 13.1 Required Notification Types

- Checkpoint due reminder.
- Mid-delay support nudge for long protocols.
- High-risk time reminder (user-configured windows).
- Postpone confirmation reminder.

### 13.2 Deprioritized

- Generic daily check-in reminders not tied to active intents.

## 14. Data and Migration Requirements

1. No production migration is required for launch because there are no existing users.
2. If preserving local dev/test data, map legacy statuses into the new resolved/canceled model.
3. If migration is implemented for internal continuity, ensure idempotent execution and safe reset behavior.

## 15. Non-Functional Requirements

- Offline-first for all core flows.
- Timezone-safe checkpoint calculations.
- Accessibility parity with existing UI.
- Privacy-first storage (all local unless user opts into future sync).

## 16. Reframe Acceptance Criteria

The reframe is complete when all criteria below are true:

1. Home no longer presents streak as primary success metric.
2. New intent capture includes delay protocol and context.
3. Detail flow supports urge logging and outcome decisioning.
4. History includes all outcomes, not only completions.
5. Achievement system rewards intentional decision behaviors.
6. Notification system is checkpoint-driven, not generic daily check-in-driven.
7. Copy across app follows language rules in Section 10.
8. Metrics in Section 11 are calculable from production events.

## 17. Delivery Milestones

1. Product and copy freeze for this spec.
2. Domain schema implementation (migration only if internal data continuity is needed).
3. Repository/state-machine refactor.
4. Home/Form/Detail flow conversion.
5. History + achievements conversion.
6. Notification and analytics rollout.
7. QA and release validation against acceptance criteria.

## 18. Open Decisions

1. Should intentional purchases after delay count as "wins" equally with resisted outcomes?
2. Is regret scoring required in MVP or post-MVP?
3. Do we keep any visible streak concept as a secondary metric?
4. Should postpone actions have hard limits per intent?
