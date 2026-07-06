---
name: data-boundaries
description: Use during phase 6, after implementation's final whole-branch review and before the acceptance demo (orchestrator-driven) - makes data storage explicit, verifies export, and checks storage boundaries and risks, writing docs/spp/06-data-boundaries.md; also runnable standalone when asked where a product's data lives or whether its storage and export are sound
---

## Overview

This is a phase-6 checkpoint, not a numbered phase of its own. It runs after subagent-driven-development's final whole-branch review completes and before the orchestrator's acceptance demo. By this point the implementation exists and has been reviewed for correctness — this checkpoint asks a narrower question the code review doesn't: does anyone actually know where the product's data lives, and can the owner get it back out?

Storage decisions are easy to leave implicit. A working slice can ship with data quietly sitting in `localStorage` or a JSON file because that's what the first line of code happened to do, not because anyone chose it. That's fine as a starting point and wrong as a permanent state — the owner needs to know it, in product terms, before they stand in front of an acceptance demo.

Findings from this checkpoint become fix-tasks, handled the same way any other whole-branch-review finding is handled. There is no separate human gate here — the acceptance demo remains the only human-facing gate of phase 6. This checkpoint just makes sure that when the demo happens, the storage story behind it is explicit and sound instead of accidental.

## When this runs

Orchestrator-driven, inside phase 6: after subagent-driven-development's final whole-branch review, before the acceptance demo. The orchestrator invokes this skill directly — it is not something the vendored subagent-driven-development skill knows to call.

Standalone: whenever asked where a product's data lives, or whether its storage and export are sound, independent of any pipeline in progress.

## Process

### 0. Confirm ordering

Read `docs/spp/pipeline-state.md`. Confirm the final whole-branch review is done and the acceptance demo hasn't run yet — this checkpoint sits between the two. If running standalone (no pipeline in progress), skip state entirely and go straight to step 1.

### 1. Locate where data physically lives

Find it in the actual code, not from memory of what was planned. Read the storage/save/load code paths. Identify the concrete mechanism: `localStorage`, a JSON file, an embedded/local database, a server database — whatever it actually is right now, on this tree.

### 2. Confirm the storage decision

Check whether this matches a decision already recorded in `03-stack.md` or under `04-specs/`. Two outcomes:

- **It matches an explicit decision** — cite it, move on.
- **It was left implicit** — the code does something, but no doc ever chose it. This is normal, not a failure to flag as someone's mistake. Fix it here: write the decision explicitly now, in the artifact (step 5), stating what layer is in use and why it fits the current MVP.

Do not treat "storage was implicit" as license to change the storage layer. The job is to make the existing decision explicit and judge whether it holds, not to introduce a new layer because the explicit version now looks primitive.

### 3. Verify export

If the product claims to let the owner or user get their data out, prove it, don't take the claim on faith:

- Create a small amount of real data (two or three records) through the product itself.
- Run the export.
- Open the exported file and read it.
- Confirm it parses and contains the fields actually persisted.
- Confirm it contains **no leaked or extra fields** — no tokens, keys, session data, debug dumps, or stack traces.

If there is no export at all and the storage layer is local (browser or file), that absence is itself a boundary risk to record in step 4 — a local-only product with no way to get data out is a real gap, not a nitpick.

### 4. List boundary risks and the next growth layer

For the storage layer identified in step 1, name what breaks it: what happens on a second device, a second user, an incognito window, a lost browser profile, a server restart. For each real risk, state whether it's a blocker for this MVP or acceptable for now.

Name the next growth layer explicitly: the concrete condition under which this storage choice stops being enough (e.g. "move to a server database when accounts or multi-device access are needed") — not a vague "will need to scale eventually."

### 5. Write the artifact

Write `docs/spp/06-data-boundaries.md` per the Artifact section below.

### 6. Update state

Write the artifact `docs/spp/06-data-boundaries.md` — its presence on disk is what the orchestrator checks before the acceptance demo. If a pipeline journal is being kept, you may note completion there too, but the on-disk artifact is the source of truth, not a flag field. Hand control back to the orchestrator.

## Artifact

`docs/spp/06-data-boundaries.md` contains:

- **Storage map** — where data lives right now (the concrete mechanism from step 1), and the decision behind it (cited from `03-stack.md`/`04-specs/`, or written explicitly here if it was implicit).
- **Export verification** — what was tested, what the export contains, confirmation of no leaked/extra fields (or the finding that export is missing).
- **Boundary findings table** — one row per risk identified in step 4:

  | Risk | Blocker? | Fix or defer |
  |---|---|---|
  | e.g. data lost if browser storage is cleared | no | defer — acceptable for single-user MVP; export is the mitigation |
  | e.g. no export exists | yes | fix — add JSON export before acceptance demo |

- **Next growth layer** — the concrete trigger condition for moving beyond the current storage layer.

## Done

- Storage decision is recorded explicitly, not left implicit.
- Export has been verified against real data, or its absence is recorded as a named risk.
- Every boundary risk in the table is marked either fixed or deferred with a stated reason.
- `docs/spp/06-data-boundaries.md` exists on disk (this is what the orchestrator checks, not a flag field).

Running standalone (no pipeline): the on-disk artifact is optional — report the storage map and boundary findings directly instead.

## Red Flags

| Thought | Reality |
|---|---|
| "Storage was never chosen explicitly, someone screwed up" | Normal outcome of early phases leaving storage implicit. This checkpoint exists to fix that now, not to assign blame for it. |
| "The implicit choice was localStorage, but that looks amateur — I'll upgrade to a real database while I'm here" | Not this checkpoint's job. Judge whether the existing layer fits the current MVP; changing the layer is a fix-task with its own scope, not something to slip in silently here. |
| "Export exists in the code, so it must work" | Verify it against real data created through the product, then open the file by hand. A code path that exists and one that actually produces a correct, secret-free file are different claims. |
| "This is a phase-6 checkpoint, so it needs its own owner-facing gate" | No separate human gate here. Findings become fix-tasks; the acceptance demo remains the only human gate of phase 6. |
| "No real risks here, I'll leave the boundary table empty" | Every storage layer has at least one real boundary (device loss, browser clear, no multi-user support, etc.) — find it and record blocker/fix/defer, don't leave the table blank because nothing is currently on fire. |

## Next step

This is a phase-6 checkpoint. When it's done:
- in a running pipeline, control returns to the orchestrator, which runs `pre-show-audit` next, then the acceptance demo;
- run standalone, just tell the user the data-storage check is done and what you found.

Do not auto-invoke anything. The orchestrator or the user drives what comes next.
