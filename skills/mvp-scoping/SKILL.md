---
name: mvp-scoping
description: Use when discovery is approved with a go decision (phase 1 approved in docs/spp/pipeline-state.md) - turns the brief and discovery report into a prioritized MVP scope built around a walking skeleton scenario
---

## Overview

This is phase 2 of the SPP pipeline. Discovery said "go" — the idea clears legal, market, and competitive checks. Now someone has to decide what the *first* version actually is, and the honest answer is never "everything in the brief." This skill turns the full feature list into a ruthless must / later / never split, then builds the smallest end-to-end scenario that proves the product's value — the walking skeleton.

The gate at the end approves scenarios, not features. The person approving this is not a developer and cannot evaluate a feature breakdown or an architecture — they can evaluate "if I do X, does Y happen the way I expect." That's the only language this phase's gate speaks.

## Process

### 0. Confirm the trigger and read state

Read `docs/spp/pipeline-state.md`. This skill applies only when `current_phase: 1` and `phase_status: approved` — discovery ran and the decision was "go." Read both inputs before doing anything else:

- `docs/spp/00-idea-brief.md` — the original problem, audience, success criterion, budget, timeline.
- `docs/spp/01-discovery-report.md` — competitors, legal risks, market read, feasibility; this is what keeps prioritization honest instead of wishful.

On starting work, write `current_phase: 2`, `phase_status: in_progress`.

### 1. Build the full feature list

From the brief and the discovery report, list every feature or capability either document implies or states outright — including ones the user never named explicitly but that the problem statement requires. Don't prune yet. This list exists so prioritization has something complete to cut from; a list assembled while already trimming just hides the cuts instead of making them.

### 2. Prioritize: must / later / never

Sort the full list into three buckets:

- **Must** — the product does not solve the stated problem without this.
- **Later** — real value, but the problem is still solved without it in version one.
- **Never** — out of scope for this product, not just this version (distinct from "later" — say which one and why).

Obvious calls (a to-do app clearly needs to create items; it clearly doesn't need a plugin marketplace) don't need a question each — place them yourself and note the placement when you present the scope. Ask the user only about the **contentious items**: the ones where reasonable people would disagree, or where the brief's success criterion doesn't obviously settle it. Ask about **one contentious item per question**. Never batch two contentious calls into one message — a non-technical user asked to weigh two trade-offs at once tends to answer only the one that's easier to picture, and the other gets rubber-stamped without real consideration.

### 3. Design the walking skeleton

The walking skeleton is the minimal end-to-end **user** scenario that exercises the full path through the product and proves the core value — not a feature, not a technical smoke test, not "the login screen works." It's the thinnest slice where a real user starts with the problem from the brief and ends with it solved, however crudely, using only **must** items.

Write it as one primary scenario, plus any additional must-have scenarios needed to cover the rest of the must list end to end. Every scenario in this section takes the form:

> User does X → Y happens.

Concrete and observable on both sides: X is an action a real user takes, Y is a result they can see or feel — never an internal state change with no visible effect.

### 4. Define MVP success metrics

State how the person will know the MVP worked, tying back to the brief's success criterion from `00-idea-brief.md`. Concrete and measurable in product terms — "10 people finish the sign-up flow," not "good engagement." If the brief's success criterion was vague, don't manufacture false precision here; say what's still vague and why.

### 5. Write "What the MVP will NOT do"

A dedicated section — not a footnote, not folded into the "never" bucket — listing what the product visibly will *not* do at launch, in plain language a non-technical reader would notice missing. This includes real "later" items that a user might reasonably expect on day one. The point is to set expectations before the acceptance demo in phase 6 — it restates the user-visible consequence of the must/later split, it doesn't relitigate it or open a second decision point.

### 6. Write the artifact

Write `docs/spp/02-mvp-scope.md` with:

- The full feature list with must / later / never against each item, and a one-line reason for every **never**.
- The walking skeleton and any other must-have scenarios, each in the "user does X → Y happens" form.
- MVP success metrics.
- "What the MVP will NOT do."

### 7. Gate

Present the **list of scenarios** — not the feature list, not the must/later/never table — and ask the user to approve it. The feature table and the "will not do" section are supporting context the user can skim; what they are actually signing off on is: does this sequence of user actions and outcomes match what they expect the first version to do. This distinction matters — a feature list describes a build, a scenario describes an experience, and only the second is something the person approving can meaningfully judge. While the question is outstanding, `phase_status: gate_pending`.

- **On approval:** set `phase_status: approved`, log the decision in the Decisions log (date, phase 2, "MVP scope approved," who approved it).
- **On requested changes:** update the scope document — and the must/later/never calls behind it if the correction implies a different priority — and re-ask.

### 8. Hand off

State the next step explicitly: **"Next: the `super-puper-powers:stack-selection` skill."** Do not start stack decisions yourself — technical tooling is that skill's job, not this one's.

## Red Flags

| Thought | Reality |
|---|---|
| "I'll show the must/later/never table and call that the gate" | The gate approves the list of scenarios, not the feature table. A feature list is a build plan the user can't meaningfully evaluate; a scenario is an experience they can. Approving the wrong artifact leaves the actual behavior unconfirmed. |
| "These three prioritization calls are all related, I'll ask them together" | One contentious item per question, always. Batching trade-offs produces a rubber-stamped answer on whichever item is harder to picture, not a real decision on both. |
| "The must/later/never split covers scope, I don't need a separate 'will NOT do' section" | It's a required, dedicated section, not implied by the table. Its job is to set expectations in plain language before the acceptance demo — a table entry marked "later" doesn't do that for a non-technical reader skimming the doc once. |
| "I'll scope this by listing which must-have features are in v1" | The unit of MVP scope is the walking skeleton scenario, not the feature. A feature list can be complete and still not describe an actual usable path through the product — scenarios force the end-to-end check that a feature checklist skips. |
| "The walking skeleton is basically a technical smoke test — confirms the server starts, the DB connects" | It's a user scenario, not an infra check. If it isn't expressible as "user does X → Y happens" with a human on both ends, it isn't the walking skeleton. |
| "This feature is obviously out of scope for now, I'll mark it 'never' since it's not happening soon" | "Never" and "later" are different claims — "later" means real value deferred, "never" means out of scope for this product, period. Marking a deferred feature "never" forecloses something the user may have expected to revisit. |
