---
name: cross-spec-review
description: Use when spec-review passed and docs/spp/04-specs/ contains more than one spec - reviews the whole spec set for interface consistency, seam gaps, contradictions and build order
---

# Cross-Spec Review

## Overview

When a product decomposes into multiple sub-project specs, each spec passes its own `spec-review` in isolation — but isolation is exactly the blind spot. A reviewer looking at spec A alone has no way to notice that spec B calls the same interface by a different name, or that a scenario spanning both sub-projects is fully described in neither. This skill dispatches a single independent reviewer subagent that reads the entire spec set at once, the only vantage point from which those cross-spec defects are visible.

**Core principle:** One subagent, one clean context, all specs at once. Not one subagent per spec, not a subagent that inherits the authoring session — a single review pass over the complete set, the same way an implementer would need to hold the whole set in mind to build any one piece of it correctly.

## Process

1. **Confirm the trigger.** This skill only runs when `docs/spp/04-specs/` contains more than one spec. A single spec has no seams to check — read `docs/spp/pipeline-state.md` to confirm `subproject_order` is still relevant, and skip straight back to `spec-writing` if there is in fact only one spec.

2. **Locate the inputs.** Every spec file under `docs/spp/04-specs/` (excluding `summary-for-review.md`, which is the product-facing output, not an input). Optionally the MVP scope and stack files if the reviewer needs them to judge feasibility of a cross-spec contract, but the primary input is the full spec set itself.

3. **Dispatch one clean-context subagent with the whole set.** Give it every spec file at once — not the authoring session's history, not your own design rationale, not a summary you wrote of what each spec contains. The subagent must read the specs directly, the same way a stranger building against all of them would. Do not split this into one dispatch per spec; a subagent that only ever sees one spec at a time cannot catch a mismatch between two of them.

4. **The reviewer checks:**
   - **Interface consistency between sub-projects** — names, types, and contracts that one spec defines and another consumes must match exactly. A shared identifier spelled two different ways, or a payload shape described differently on each side, is a defect.
   - **Seam gaps** — any scenario that crosses two sub-projects (starts in one, continues in another) needs the handoff itself described: what crosses the seam, in what shape, and who is responsible for what on each side. A scenario that's covered inside each spec individually but never actually connected at the boundary is a gap.
   - **Contradictions** — statements in one spec that conflict with statements in another (not just within a single spec, which `spec-review` already covers).
   - **Build order** — the dependency graph across sub-projects: which ones the others depend on, and therefore what must be built first. This isn't advisory color; it's a required output (see below).

5. **Findings carry severity: Critical / Important / Minor**, same scale as `spec-review`. Fix every Critical and Important finding — in whichever spec(s) it lives — before the gate.

6. **Repeat until clean.** Re-invoke the subagent (fresh clean context again, not the same instance carrying prior findings, with the updated full spec set) after fixing. Loop until a review pass returns zero Critical/Important findings — same fix/re-review loop as `spec-review`, no cap on rounds, exit condition is a clean pass.

7. **Write the recommended build order to state.** Once the review is clean, the subagent's recommended sub-project implementation order goes into the `subproject_order` field in `docs/spp/pipeline-state.md` — a list of sub-project slugs in build order. This is not optional even on a clean pass with no findings: `subproject_order` has two downstream consumers — `plan-writing` uses it to order the plans it writes, and the phase-6 orchestrator uses it to order execution. Leaving it `null` breaks both.

8. **No findings file.** Same as `spec-review`: the subagent's report lives in its response for that dispatch, nothing persists to disk for it. What persists is the outcome — append an entry to the Decisions log in `docs/spp/pipeline-state.md` recording how many rounds the review took and the final result (e.g., "cross-spec-review: 1 round, clean pass, subproject_order: [api, worker, dashboard]"). This keeps the pipeline resumable if a session ends mid-review.

9. **Next skill.** Control returns to `spec-writing` to produce the product summary and run the user-facing gate. This skill does not talk to the user and does not advance `current_phase` itself.

## Red Flags

**Never:**
- Review specs one at a time, even by dispatching several subagents in parallel — a per-spec view cannot see a seam gap or an interface mismatch that only exists in the relationship between two specs. It must be one subagent holding the whole set at once.
- Leave `subproject_order` unwritten after a clean pass. A clean review with no findings still owes the state file a build order; skipping it silently breaks `plan-writing` and the phase-6 orchestrator, which both read that field expecting a value.
- Wave through an interface name or type that differs between two specs because "the meaning is obviously the same" — an implementer building against one spec won't see the other, and a mismatch here becomes a runtime bug that adversarial review is specifically meant to catch before it's written.
- Mark a scenario that crosses a seam as covered because each side individually mentions it — check that the handoff itself (what crosses, in what shape, who owns what) is actually described, not just that both ends exist.
- Skip logging the round count, outcome, and resulting `subproject_order` to the Decisions log — without it, a resumed session can't tell whether this gate already passed or what order was decided.
- Reuse the same reviewer subagent across rounds instead of dispatching fresh each time with the updated spec set — a subagent that already saw its own prior findings is no longer an independent reviewer.
