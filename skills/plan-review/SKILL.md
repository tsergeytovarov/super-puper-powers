---
name: plan-review
description: Use when plan-writing finished a plan after author self-review - dispatches a clean-context subagent to verify spec coverage, cross-task consistency and absence of placeholders before execution
---

# Plan Review

## Overview

A plan author cannot reliably catch their own blind spots any more than a spec author can — the self-review checklist in `plan-writing` is useful, but it is still the same mind checking its own work. A bug in a plan is worse than a bug in a spec: the plan is what a fresh subagent follows task-by-task with zero codebase context, so an uncovered requirement, a placeholder, or a type mismatch between tasks doesn't stay contained — it multiplies across every task that touches it. This skill dispatches an independent reviewer subagent with a clean context — the plan and the spec it implements, nothing else — to catch that before subagent-driven execution starts.

**Core principle:** The reviewer never inherits the authoring session's context or history. It sees only the plan and the spec, the same way the fresh per-task subagents that will execute the plan would.

## Process

1. **Locate the inputs.** You need the path to the plan just written (`docs/spp/05-plans/<filename>.md`) and the path to the spec it implements (the corresponding file under `docs/spp/04-specs/`).

2. **Read `docs/spp/pipeline-state.md` first.** This skill runs inside `plan-writing`'s tail — after the author's self-review, before the "N tasks — start?" execution-handoff gate. It does not itself advance `current_phase`; that stays owned by `plan-writing`.

3. **Dispatch a clean-context subagent.** Use the reviewer prompt at `${CLAUDE_PLUGIN_ROOT}/skills/plan-review/plan-reviewer.md` (relative to this skill directory: `plan-reviewer.md`). Fill in the plan path and the spec path, and give the subagent exactly those two files — do NOT pass it the conversation history, your design rationale, or anything else from the authoring session. The subagent must review the plan the way the fresh per-task implementer subagents will: with no memory of why any decision was made.

4. **The reviewer checks:**
   - **Spec coverage** — every requirement in the spec maps to a task in the plan. A requirement with no corresponding task is a defect, not an oversight to wave through.
   - **Cross-task consistency** — types, method signatures, and property names used in one task match how earlier tasks defined them. A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug a single-task implementer cannot see, because they only read their own task.
   - **Placeholders** — per the "No Placeholders" list in `plan-writing`: "TBD", "TODO", "implement later", "fill in details"; "add appropriate error handling" / "add validation" / "handle edge cases"; "write tests for the above" without actual test code; "similar to Task N" without repeating the code; steps that describe what to do without showing how; references to types, functions, or methods not defined in any task.
   - **Step feasibility** — commands referenced in steps actually exist, file paths are real (not invented), and an implementer could follow each step without getting stuck.

5. **Findings carry severity: Critical / Important / Minor.** Fix every Critical and Important finding in the plan. Minor findings are advisory — note them, don't block on them.

6. **Repeat until clean.** Re-invoke the subagent (fresh clean context again, not the same subagent instance carrying prior findings) after fixing. Loop until a review pass returns zero Critical/Important findings. This mirrors the `spec-review` fix/re-review loop: no cap on rounds, the exit condition is a clean pass, not a round count.

7. **No findings file.** The subagent's report lives in its response for that dispatch — nothing is written to disk for it. What persists is the outcome: append an entry to the Decisions log in `docs/spp/pipeline-state.md` recording how many rounds the review took and the final result (e.g., "plan-review: 1 round, clean pass"). This is what makes the pipeline resumable if a session ends mid-review — the next session doesn't need the dropped subagent's output, just the log entry telling it whether the gate is clear.

8. **Next step.** Control returns to `plan-writing`, which proceeds to the execution handoff ("N tasks — start?") once the review is clean. This skill does not talk to the user and does not itself trigger `super-puper-powers:subagent-driven-development`.

## Red Flags

**Never:**
- Pass the authoring session's context, chat history, or your own reasoning to the reviewer subagent instead of a clean brief of just the plan and the spec — that defeats the entire point of an independent review.
- Accept a plan where a spec requirement has no corresponding task, even if it seems like it would obviously get covered "along the way" during implementation.
- Let a placeholder like "add appropriate error handling" or "similar to Task N" (without repeating the code) through because the reviewer judged it "probably fine" — these are exactly the patterns the "No Placeholders" list exists to catch, and a fresh per-task implementer subagent has no way to resolve them correctly on its own.
- Wave through a type, signature, or name mismatch between tasks because "the intent is clearly the same" — a mismatch here becomes a runtime bug once two separately-dispatched task subagents each implement their own side.
- Proceed to the "N tasks — start?" execution gate while any Critical or Important finding from the latest round is still unresolved.
- Skip logging the round count and outcome to the Decisions log — without it, a resumed session can't tell whether this gate already passed.
- Reuse the same reviewer subagent across rounds instead of dispatching fresh each time — a subagent that already saw its own prior findings and the author's fixes is no longer an independent reviewer.

## Next step

When this stage is complete, tell the user in their own language that:
- this stage is done;
- the next logical step is the `subagent-driven-development` skill;
- they should start it in a fresh chat so that skill gets clean context.

Do not auto-invoke the next skill. The user drives the transition — offer, do not proceed.
