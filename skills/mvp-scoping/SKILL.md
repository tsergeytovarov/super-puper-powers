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

- `docs/spp/00-idea-brief.md` — the original problem, audience, success criterion, budget, timeline, and the **differentiation** answer: how this product is different from what already exists, what people do today instead.
- `docs/spp/01-discovery-report.md` — competitors, legal risks, market read, feasibility, the **idea killers** section, and the **differentiator verdict** (survives / weak / killed) that discovery's competitor research landed on; this is what keeps prioritization honest instead of wishful.

Hold on to the differentiator claim, its verdict, and the idea killers specifically — step 2 checks the must list against all three, not just against the brief in general.

On starting work, write `current_phase: 2`, `phase_status: in_progress`.

### 1. Build the full feature list

From the brief and the discovery report, list every feature or capability either document implies or states outright — including ones the user never named explicitly but that the problem statement requires. Don't prune yet. This list exists so prioritization has something complete to cut from; a list assembled while already trimming just hides the cuts instead of making them.

### 2. Prioritize: must / later / never

Sort the full list into three buckets:

- **Must** — the product does not solve the stated problem without this.
- **Later** — real value, but the problem is still solved without it in version one.
- **Never** — out of scope for this product, not just this version (distinct from "later" — say which one and why).

Obvious calls (a to-do app clearly needs to create items; it clearly doesn't need a plugin marketplace) don't need a question each — place them yourself and note the placement when you present the scope. Ask the user only about the **contentious items**: the ones where reasonable people would disagree, or where the brief's success criterion doesn't obviously settle it. Ask about **one contentious item per question**. Never batch two contentious calls into one message — a non-technical user asked to weigh two trade-offs at once tends to answer only the one that's easier to picture, and the other gets rubber-stamped without real consideration.

**Verify the differentiator landed in must.** Once the buckets are sorted, explicitly check: does the feature or capability that embodies the brief's differentiation answer sit in **must**? This is a distinct, mandatory check, not something that falls out of the general sort automatically — a differentiator can legally lose every individual prioritization call it's involved in (each one looking reasonable on its own) and still end up in later or never as a result, quietly gutting the product of the one thing that was supposed to set it apart. Also check it against the idea killers in `01-discovery-report.md`: if discovery flagged a competitive gap or weakness that the differentiator is specifically supposed to close, confirm the must-list item that closes it is the same one, not a watered-down substitute.

If the differentiator is in must, note that explicitly when you present the scope — a one-line confirmation, not a silent pass. If it has drifted to **later** or **never**, that placement is not final on the strength of the ordinary must/later/never reasoning alone: flag it as its own contentious item at the gate in step 7, state in plain product language what the product loses by not differentiating at launch, and require the owner to explicitly accept that trade-off rather than let it ride through as one row in a table.

**Then check discovery's differentiator verdict, separately from where the item landed in the buckets.** The must/later/never placement answers "is it scoped in"; the verdict from `01-discovery-report.md` answers a different question — "does it actually hold up against competitors" — and both matter:

- **Verdict `survives`** — proceed with the must-list check above as described; no further action beyond the one-line confirmation.
- **Verdict `weak` or `killed`** — this is not a scoping question and it does not get resolved by moving the item between buckets. Whether the differentiator sits in must or has drifted to later, a `weak`/`killed` verdict means discovery already concluded the competitive edge behind it is thin or gone. Do not silently leave it in must as if the verdict didn't happen, and do not push it to later as a way to defer the problem — either move quietly reframes a competitive finding as a scheduling detail. Surface it as its own explicit owner call at the gate in step 7 (see below), independent of whatever the must/later/never table says.

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

**If the differentiator drifted to later or never** (per the check in step 2), this is not covered by ordinary scenario approval — surface it as its own explicit call at this gate, separate from the scenario sign-off: state in plain product language what makes this product different from what exists today, and that the current scope launches without it. Ask the owner to explicitly accept that trade-off. Do not let it pass silently inside a "yes, approved" on the scenario list — the owner may be approving the walking skeleton without registering that the one thing that was supposed to set the product apart isn't in it.

**If discovery's differentiator verdict is `weak` or `killed`** (per the check in step 2), this is a second, separate gate question — ask it regardless of whether the differentiator sits in must or drifted to later, and regardless of whether the must/later/never trade-off above was also triggered. Put it to the owner in plain product terms, not scoping vocabulary: the thing that was supposed to make this product different turned out to be thin — competitors mostly already do it — or already fully covered by them. Ask directly: **is the MVP still worth building as scoped, or does the differentiator need rethinking before building anything?** This is a signal toward pivot, not a formality — do not answer it yourself by quietly leaving the item in must (that ignores the verdict) or by nudging it to later (that reframes a competitive problem as a timing problem). The owner's answer, whatever it is, must be logged in the Decisions log.

- **On approval:** set `phase_status: approved`, log the decision in the Decisions log (date, phase 2, "MVP scope approved," who approved it). If the differentiator was deferred, log that acceptance as its own line in the Decisions log, separate from the general scope approval — date, phase 2, "differentiator deferred to later/never, accepted by owner," the reason given. If discovery's verdict was `weak`/`killed`, log the owner's call on it as its own line too — date, phase 2, "differentiator verdict weak/killed, owner decided [proceed as scoped / rethink differentiator]," the reasoning given — independent of and in addition to the deferred-differentiator line above if both apply.
- **On requested changes:** update the scope document — and the must/later/never calls behind it if the correction implies a different priority — and re-ask. If the requested change is to pull the differentiator back into must, re-run the affected prioritization calls, not just the scope document text. If the owner's call on a `weak`/`killed` verdict is to rethink the differentiator, that is a brief-level change — treat it as a signal to return to discovery or idea-intake, not something this skill resolves by re-sorting the feature list.

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
| "Each of these three calls that touch the differentiator was individually reasonable, so the overall placement must be fine" | Individually reasonable calls can still add up to the differentiator drifting out of must — that's exactly why it needs an explicit, separate check after sorting, not just trust in the sum of the individual calls. |
| "The differentiator ended up in later, but that's covered by the general must/later/never table the owner already saw" | A drifted differentiator needs its own explicit flag and owner acceptance at the gate, in plain product language — not a row the owner can approve without registering what it costs the product's positioning. |
| "Discovery's verdict was 'weak,' but the item is still sitting in must, so we're fine" | Being in must answers a scoping question, not a competitive one. A `weak`/`killed` verdict means the edge itself is thin regardless of which bucket the item sits in — leaving it in must without surfacing the verdict just ignores what discovery found. |
| "The differentiator verdict was 'killed,' I'll quietly move it to later so it stops being the headline risk" | Moving a `killed`-verdict item to later reframes a competitive dead-end as a scheduling choice. It's not a scoping fix — it needs its own explicit owner call at the gate, not a bucket change that buries it. |
| "Discovery already said 'weak' in its report, mvp-scoping doesn't need to re-raise it" | Discovery stating the verdict and mvp-scoping surfacing it as an explicit owner call at this gate are different obligations. A verdict mentioned once in a prior artifact is not the same as a decision logged at this phase's gate. |
