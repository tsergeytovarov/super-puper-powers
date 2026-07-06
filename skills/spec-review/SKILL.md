---
name: spec-review
description: Use when spec-writing finished a spec after author self-review - dispatches a clean-context subagent to adversarially review the spec against MVP scope before any planning happens
---

# Spec Review

## Overview

An author cannot reliably catch their own blind spots in a spec they just wrote — they know what they meant, so ambiguous or missing coverage reads as fine to them. This skill dispatches an independent reviewer subagent with a clean context — the spec, the MVP scope, and the stack file, nothing else — to check the spec adversarially before any implementation planning starts.

**Core principle:** The reviewer never inherits the authoring session's context or history. It sees only the artifacts, the same way a future implementer would.

## Process

1. **Locate the inputs.** You need the path to the spec just written, plus `docs/spp/02-mvp-scope.md` and `docs/spp/03-stack.md` from the current project.

2. **Dispatch a clean-context subagent.** Use the reviewer prompt at `${CLAUDE_PLUGIN_ROOT}/skills/spec-review/spec-reviewer.md` (relative to this skill directory: `spec-reviewer.md`). Fill in the spec path and the two input file paths, and give the subagent exactly those three files — do NOT pass it the conversation history, your design rationale, or anything else from the authoring session. The subagent must review the spec the way a stranger would, with no knowledge of what you intended.

3. **The reviewer checks:**
   - **Completeness vs MVP scope** — every must-scenario in `02-mvp-scope.md` is covered somewhere in the spec.
   - **Contradictions** — sections that conflict with each other.
   - **Ambiguities** — any requirement that could be read two different ways. An interpretable-both-ways requirement is a defect, not a style note.
   - **Infeasibility on the chosen stack** — anything the spec asks for that the stack in `03-stack.md` can't actually do.
   - **Placeholders** — "TBD", "TODO", unfinished sections.

4. **Findings carry severity: Critical / Important / Minor.** Fix every Critical and Important finding in the spec. Minor findings are advisory — note them, don't block on them.

5. **Repeat until clean.** Re-invoke the subagent (fresh clean context again, not the same subagent instance carrying prior findings) after fixing. Loop until a review pass returns zero Critical/Important findings. This mirrors the upstream task-review-loop pattern used in subagent-driven-development: fix, re-review, repeat — no cap on rounds, the exit condition is a clean pass, not a round count.

6. **No findings file.** The subagent's report lives in its response for that dispatch — nothing is written to disk for it. What persists is the outcome: append an entry to the Decisions log in `docs/spp/pipeline-state.md` recording how many rounds the review took and the final result (e.g., "spec-review: 2 rounds, clean pass"). This is what makes the pipeline resumable if a session ends mid-review — the next session doesn't need the dropped subagent's output, just the log entry telling it whether the gate is clear.

7. **Next skill.** If the project has more than one spec, invoke `super-puper-powers:cross-spec-review` next. Otherwise, control returns to `spec-writing` to produce the product summary and run the user-facing gate — this skill does not talk to the user and does not advance `current_phase` itself.

## Red Flags

**Never:**
- Pass the authoring session's context, chat history, or your own reasoning to the reviewer subagent instead of a clean brief of just the three files — that defeats the entire point of an independent review.
- Accept a spec where a must-scenario from `02-mvp-scope.md` has no corresponding coverage in the spec, even if it seems implied.
- Treat a requirement that reads two different ways as acceptable because "an implementer will probably figure out the right one" — pick the interpretation now, in the spec, or it's an open Critical/Important finding.
- Move on to `cross-spec-review` or back to `spec-writing`'s summary/gate step while any Critical or Important finding from the latest round is still unresolved.
- Skip logging the round count and outcome to the Decisions log — without it, a resumed session can't tell whether this gate already passed.
- Reuse the same reviewer subagent across rounds instead of dispatching fresh each time — a subagent that already saw its own prior findings and the author's fixes is no longer an independent reviewer.

## Next step

When this stage is complete, tell the user in their own language that:
- this stage is done;
- the next logical step is `cross-spec-review` if `docs/spp/04-specs/` holds more than
  one spec, otherwise `plan-writing`;
- they should start it in a fresh chat so that skill gets clean context.

Do not auto-invoke the next skill. The user drives the transition — offer, do not proceed.
