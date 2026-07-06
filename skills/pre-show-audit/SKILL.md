---
name: pre-show-audit
description: Use during phase 6, after data-boundaries and before the acceptance demo (orchestrator-driven) - audits a built product for hidden pre-show risks (broken mobile, failing build, stray debug text, leaky export, input that breaks the UI) plus minimal security, writes docs/spp/06-pre-show-audit.md and turns blockers into fix-tasks; also runnable standalone when asked to check a product before showing it
---

## Overview

This is a phase-6 checkpoint, not a numbered phase of its own. It runs after the `data-boundaries` checkpoint and before the orchestrator's acceptance demo. By this point the implementation is reviewed and the storage story is explicit — this checkpoint asks a different question: will the first person who sees this product trust it in the first ten seconds?

Users don't see architecture. They see a stray `console.log` on screen, a title that still says "New App", a layout that breaks the moment they open it on a phone, or an export file that turns out to contain a debug dump instead of their data. None of that is a design flaw — it's the kind of thing that gets noticed instantly and reads as "nobody checked this before showing it to me."

The failure mode this checkpoint guards against is the prompt "check everything and fix everything." That prompt merges finding problems with changing code, and an agent given free rein under it will fix some things, invent three more, and quietly touch something that already worked. The order matters: audit first, with no fixes. Then classify. Only then fix — and only what's confirmed as a blocker.

Findings from this checkpoint become fix-tasks, handled the same way any other whole-branch-review finding is handled. There is no separate human gate here — the acceptance demo remains the only human-facing gate of phase 6. This checkpoint exists so that by the time the demo happens, the obvious risks have already been caught and closed, not discovered live in front of the owner.

## When this runs

Orchestrator-driven, inside phase 6: after the `data-boundaries` checkpoint, before the acceptance demo. The orchestrator invokes this skill directly.

Standalone: whenever asked to check a product before showing it, independent of any pipeline in progress.

## Process

### 0. Confirm ordering

Confirm `docs/spp/06-data-boundaries.md` exists on disk — this checkpoint runs after data-boundaries, not instead of it. If it does not exist and a pipeline is in progress, run `data-boundaries` first. If running standalone, skip this ordering check and go to step 1.

### 1. Audit — no fixes yet

Produce findings only. Do not touch code, text, dependencies, storage, export format, or UI while auditing. Cover these categories:

- **Title/meta** — does the page title and description actually describe this product, or is it still a placeholder? Favicon not the framework default, if the product is shown publicly.
- **Broken mobile** — open the main flow at mobile width. Does anything overlap, overflow, or become unusable?
- **Build health** — find the project's actual scripts (test, type-check, build, lint) and run whichever exist. Don't invent a command that isn't there; if a check is missing, say so and note what compensates for its absence (manual pass, smoke check).
- **Stray debug text** — leftover `console.log`, placeholder copy, temporary flags, or test data visible in the running UI.
- **Export JSON leaking extra data** — if the product exports data, generate a real export and read the file. Confirm it contains only the fields the product actually persists — no tokens, session data, debug dumps, or stack traces riding along.
- **Inputs that break the UI** — long text in name/title/notes-style fields, empty required fields, unusual characters. Does anything overflow or crash the layout?

### 2. Minimal security pass

Not a pentest — a baseline that a small product with no security review should still clear:

- No `.env` file, keys, tokens, or credentials committed to Git.
- No secrets embedded in client-side code.
- User input isn't inserted as raw HTML — check the fields most likely to hold free text (name, notes, description-style inputs) for an obvious XSS opening.
- The export checked in step 1 contains no leaked secrets or session data (same check, security framing).

### 3. Classify each finding

For every finding from steps 1–2, record: severity, and whether it blocks a normal first show. A blocker breaks the app, breaks the main scenario, leaks data, corrupts the export, or makes the product look visibly unfinished to someone seeing it cold. Anything else — polish, future SEO, a larger accessibility pass, an unscoped new feature — is not a blocker.

If the audit turns up an unreasonable number of findings, stop before fixing anything and flag it: the fix step needs to be re-scoped into smaller pieces, not run as one large change.

### 4. Fix blockers

Fix only what step 3 marked as a blocker. For anything not fixed, record an explicit reason it's deferred — "acceptable for this demo because X," not silence. Do not introduce new dependencies, redesign, or add functionality outside what the finding requires.

### 5. Write the artifact

Write `docs/spp/06-pre-show-audit.md` per the Artifact section below.

### 6. Update state

Write the artifact `docs/spp/06-pre-show-audit.md` — its presence on disk is what the orchestrator checks before the acceptance demo. If a pipeline journal is being kept, you may note completion there too, but the on-disk artifact is the source of truth, not a flag field. Hand control back to the orchestrator.

## Artifact

`docs/spp/06-pre-show-audit.md` contains:

- **Quality gates** — which commands were run (test/type-check/build/lint), their result, and for any that don't exist in this project, what compensates for its absence.
- **Findings table** — one row per finding from steps 1–2:

  | Risk | Severity | Blocker? | Fix or defer |
  |---|---|---|---|
  | e.g. title still reads "New App" | low | yes | fix — set real product title |
  | e.g. export JSON includes a debug `_meta` field | high | yes | fix — strip before demo |
  | e.g. no favicon set | low | no | defer — cosmetic, backlog |

- **Security baseline** — what was checked (secrets in Git, client-side secrets, raw-HTML input, export leakage) and the result of each.
- **Re-check** — after fixes: what changed, which checks were re-run and passed, what was verified by hand, what remains deferred.

## Done

- Audit report produced before any fix was made.
- Every finding is classified as blocker or not, with a stated reason when deferred.
- All blockers are fixed, or explicitly deferred with a reason recorded in the artifact.
- `docs/spp/06-pre-show-audit.md` exists on disk (this is what the orchestrator checks, not a flag field).

Running standalone (no pipeline): the on-disk artifact is optional — report the audit findings directly instead.

## Red Flags

| Thought | Reality |
|---|---|
| "I'll just check and fix everything in one pass" | Mixes discovery with change and invites scope creep. Audit first with zero fixes, classify, then fix only confirmed blockers. |
| "The build passes, so the product is fine" | Green checks mean the project is technically alive, not that it's ready to show. A passing build with a broken mobile layout still fails this checkpoint. |
| "This finding is interesting, I'll fix it even though it's not a blocker" | Not this checkpoint's job. Non-blockers go to backlog, not into the fix step, however easy the fix looks. |
| "There's a lot of findings, I'll just push through and fix them all" | Stop and flag it instead. A large fix batch right before a demo is itself a risk — re-scope into smaller pieces rather than making a big undisclosed change. |
| "The export code exists, so it must be clean" | Generate a real export and read the file. A code path that exists and one that produces a secret-free file are different claims. |
| "This is a phase-6 checkpoint, so it needs its own owner-facing gate" | No separate human gate here. Findings become fix-tasks; the acceptance demo remains the only human gate of phase 6. |

## Next step

This is a phase-6 checkpoint. When it's done:
- in a running pipeline, control returns to the orchestrator, which proceeds to the acceptance demo;
- run standalone, just tell the user the pre-show audit is done and what you found.

Do not auto-invoke anything. The orchestrator or the user drives what comes next.
