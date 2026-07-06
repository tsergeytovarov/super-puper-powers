# SPP Freeform Dispatch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn SPP from an enforcing pipeline state-machine into an upstream-`superpowers`-style set of freely-callable skills plus a context-routing dispatcher, without losing phase-6 safety.

**Architecture:** The orchestrator `using-super-puper-powers` becomes a context router (recommends the 0→9 route, never enforces it). `pipeline-state.md` degrades from an enforcing state-machine to an optional cross-chat journal. Phase-6 safety gates move from state-file strings into on-disk artifact self-checks inside the skills. Every phase skill ends with a next-step hint; the user drives transitions.

**Tech Stack:** Markdown skills (`skills/*/SKILL.md`), one slash command (`commands/spp.md`). No runtime code. Verification is `grep`/file reads, not unit tests.

---

## Conventions used by every task

**Next-step block** — the exact English instruction appended near the end of a phase skill (each task names its own `<next-skill>`):

```markdown
## Next step

When this stage is complete, tell the user in their own language that:
- this stage is done;
- the next logical step is the `<next-skill>` skill;
- they should start it in a fresh chat so that skill gets clean context.

Do not auto-invoke the next skill. The user drives the transition — offer, do not proceed.
```

**Trigger rule** — a skill's `description:` frontmatter must name an artifact precondition, never `phase N approved in pipeline-state.md`.

**Commit discipline** — each task ends in one commit. Running this plan is the user's authorization to commit those steps. Conventional Commits, Russian description (per repo `git-workflow.md`).

---

## WAVE 1 — the heart

### Task 1: Orchestrator — state-machine → router

**Files:**
- Modify: `skills/using-super-puper-powers/SKILL.md`

- [ ] **Step 1: Read the current orchestrator in full**

Run: read `skills/using-super-puper-powers/SKILL.md` end to end. It currently contains: the vendored-modifications header, Pipeline Map, Session Start Protocol, State Machine, phase-6 hard-gates, Phase 6 Execution Profile, Mid-Pipeline Entry, Gate Language, Skill Priority, On-demand helpers, Red Flags, platform notes.

- [ ] **Step 2: Rewrite the Pipeline Map framing from enforcement to recommendation**

Keep the phase table (0→9, skill, artifact, gate). Replace any "exactly one gate / MUST" framing around it with a recommendation preamble:

```markdown
## Recommended Route

The SPP route turns a product idea into a deployed product across ten phases, 0-9.
This is a **recommended order, not an enforced one.** Every phase has one worker
skill and writes one artifact under `docs/spp/`. You may enter at any phase, run a
single skill standalone, or skip phases — the dispatcher never blocks you on order.
Each phase skill ends by suggesting the next one; you decide when to take it.
```

- [ ] **Step 3: Delete the enforcing State Machine and the cross-phase hard-gate**

Remove the `## State Machine` section and the hard-gate:

```
<HARD-GATE>Phase N+1 MUST NOT start until phase N's gate is approved in docs/spp/pipeline-state.md.</HARD-GATE>
```

Replace the `## Session Start Protocol` with a router protocol:

```markdown
## Session Start Protocol

At the start of a session:

1. If the user names a skill or describes a task, match it and invoke that skill —
   directly, regardless of any pipeline position. This is the default path.
2. If `docs/spp/pipeline-state.md` exists, read it as **memory** (what this project
   is, what has already been done, decisions taken). Use it for context only — never
   to force "continue phase N". At most, remind the user where they left off and let
   them choose.
3. If the user is describing a fresh product idea and no journal exists, offer to
   start at phase 0 by invoking `idea-intake`.

The dispatcher routes by context, like upstream `using-superpowers`. It does not
drive the user through phases.
```

- [ ] **Step 4: Convert phase-6 hard-gates to on-disk self-checks (keep the safety)**

The two phase-6 machine-check hard-gates stay, but reworded to check the **file on disk**, decoupled from `phase_status` strings. Replace the acceptance-demo-before-demo gate:

```markdown
<HARD-GATE>
Before starting the acceptance demo, machine-check the artifacts ON DISK: confirm
`docs/spp/06-data-boundaries.md` and `docs/spp/06-pre-show-audit.md` both exist and
record their check as done. If either is missing, STOP and run the missing checkpoint
skill (`data-boundaries`, then `pre-show-audit`) before the demo. Read the files; do
not rely on memory or on pipeline-state.md.
</HARD-GATE>
```

Replace the finishing-a-development-branch gate:

```markdown
<HARD-GATE>
Before ANY invocation of finishing-a-development-branch — including one arriving from
inside subagent-driven-development — machine-check ON DISK that
`docs/spp/06-acceptance-demo.md` exists and records the demo as approved. If it does
not, STOP: warn the user the product has no passed acceptance demo and that merging or
releasing it is risky, and require an explicit "yes, proceed anyway" before continuing.
This reads the file directly, not pipeline-state.md.
</HARD-GATE>
```

Note the shift: the demo-before-release gate is now a **warn-and-require-explicit-yes**, not an absolute stop (owner drives). The data-boundaries/pre-show-audit-before-demo gate stays an absolute stop — those are cheap and precede any human showing.

- [ ] **Step 5: Update the vendored-modifications header**

Append to the `Modifications:` line in the header block:

```
; reworked the enforcing state-machine into a context router — cross-phase order is now a recommendation, pipeline-state.md is an optional journal, and phase-6 safety gates read on-disk artifacts instead of state-file phase status
```

- [ ] **Step 6: Update Red Flags table**

Remove rows that assert enforced ordering (`"I'll start phase N+1, the gate is obviously fine" | approved in the state file...`). Keep the phase-6 safety rows (acceptance demo, data-boundaries/pre-show-audit machine-checks) but reword "pipeline-state.md" → "the on-disk artifact".

- [ ] **Step 7: Verify**

Run: `grep -c "MUST NOT start" skills/using-super-puper-powers/SKILL.md`
Expected: `0`

Run: `grep -c "Recommended Route\|routes by context" skills/using-super-puper-powers/SKILL.md`
Expected: `≥ 2`

Run: `grep -c "06-acceptance-demo.md\|06-data-boundaries.md\|06-pre-show-audit.md" skills/using-super-puper-powers/SKILL.md`
Expected: `≥ 3` (safety self-checks preserved)

- [ ] **Step 8: Commit**

```bash
git add skills/using-super-puper-powers/SKILL.md
git commit -m "refactor(orchestrator): превратить стейт-машину в диспетчер-роутер

Межфазовый hard-gate зависимостей убран, порядок фаз стал рекомендацией.
pipeline-state.md теперь необязательный журнал. Защиты фазы 6 читают
артефакты на диске, а не строки стейта."
```

---

### Task 2: `/spp` command → router semantics

**Files:**
- Modify: `commands/spp.md`

- [ ] **Step 1: Read the current command**

Run: read `commands/spp.md`. It currently reads `pipeline-state.md` and continues "from current_phase according to the state machine".

- [ ] **Step 2: Rewrite the body to router semantics**

```markdown
---
description: Start or route the Super Puper Powers skills
---

Invoke the `super-puper-powers:using-super-puper-powers` skill (the dispatcher) first.

- If the user named a skill or task, the dispatcher routes to it directly — no
  pipeline position required.
- If `docs/spp/pipeline-state.md` exists, the dispatcher reads it as memory and
  reminds the user where they left off, without forcing the next phase.
- If the user is describing a fresh product idea and no journal exists, offer to
  start at phase 0 with `idea-intake`.

The route 0→9 is a recommendation, not an enforced sequence. Any skill is callable
at any time.
```

- [ ] **Step 3: Verify**

Run: `grep -c "state machine\|current_phase" commands/spp.md`
Expected: `0`

- [ ] **Step 4: Commit**

```bash
git add commands/spp.md
git commit -m "refactor(commands): /spp роутит по контексту вместо стейт-машины"
```

---

### Task 3: `idea-intake` — standalone trigger + next-step

**Files:**
- Modify: `skills/idea-intake/SKILL.md`

- [ ] **Step 1: Replace the description frontmatter**

Find:
```
description: Use when the user describes a product idea and docs/spp/pipeline-state.md does not exist - starts the SPP pipeline by capturing an idea brief through a one-question-at-a-time interview
```
Replace with:
```
description: Use when the user describes a product idea, OR directly asks to capture or write up a product idea brief - captures an idea brief through a one-question-at-a-time interview. Runnable standalone; if docs/spp/pipeline-state.md is absent it starts a fresh journal, if present it appends.
```

- [ ] **Step 2: Append the next-step block** (`<next-skill>` = `product-discovery`), using the Conventions template verbatim with `product-discovery` filled in.

- [ ] **Step 3: Verify**

Run: `grep -c "does not exist" skills/idea-intake/SKILL.md`
Expected: `0`

Run: `grep -c "Next step" skills/idea-intake/SKILL.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add skills/idea-intake/SKILL.md
git commit -m "feat(idea-intake): standalone-триггер и next-step подсказка"
```

---

### Task 4: `release-fixation` — trigger + demo self-check + next-step

**Files:**
- Modify: `skills/release-fixation/SKILL.md`

- [ ] **Step 1: Read the file** to locate where it invokes `finishing-a-development-branch`.

- [ ] **Step 2: Replace the description frontmatter**

Find:
```
description: Use when the acceptance demo is approved (phase 6 approved in docs/spp/pipeline-state.md) - verifies the work, finishes the branch on the agent's own decision, fixes a semver version and writes owner-language release notes
```
Replace with:
```
description: Use when a development branch is complete and ready to become a release, OR when the user directly asks to fix a version, write release notes, or finish the branch - verifies the work, finishes the branch on the agent's own decision, fixes a semver version and writes owner-language release notes. Self-checks on disk for a passed acceptance demo first.
```

- [ ] **Step 3: Add the demo self-check** immediately before the step that invokes `finishing-a-development-branch`:

```markdown
## Pre-release self-check

Before finishing the branch, check ON DISK:

- Does `docs/spp/06-acceptance-demo.md` exist and record the demo as approved?
- If NO: warn the user plainly — there is no passed acceptance demo, so merging or
  releasing risks shipping something broken or leaky. Ask for an explicit "yes,
  release anyway" before continuing. Do not proceed silently.
- If YES: proceed.

This reads the file directly, not pipeline-state.md.
```

- [ ] **Step 4: Append the next-step block** (`<next-skill>` = `deploy-strategy`).

- [ ] **Step 5: Verify**

Run: `grep -c "phase 6 approved" skills/release-fixation/SKILL.md`
Expected: `0`

Run: `grep -c "06-acceptance-demo.md" skills/release-fixation/SKILL.md`
Expected: `≥ 1`

Run: `grep -c "Next step" skills/release-fixation/SKILL.md`
Expected: `1`

- [ ] **Step 6: Commit**

```bash
git add skills/release-fixation/SKILL.md
git commit -m "feat(release-fixation): standalone-триггер, самопроверка demo на диске, next-step"
```

---

### Task 5: `deploy-strategy` — trigger + version self-check + next-step

**Files:**
- Modify: `skills/deploy-strategy/SKILL.md`

- [ ] **Step 1: Replace the description frontmatter**

Find:
```
description: Use when a release version is fixed (phase 7 approved in docs/spp/pipeline-state.md) - chooses a deploy strategy with the owner in cost-and-consequence terms, then executes it into a repeatable runbook
```
Replace with:
```
description: Use when a product is ready to ship, OR when the user directly asks how or where to deploy or to write a deploy runbook - chooses a deploy strategy with the owner in cost-and-consequence terms, then executes it into a repeatable runbook. Self-checks on disk for a fixed release version first.
```

- [ ] **Step 2: Add the version self-check** at the start of the skill's work:

```markdown
## Pre-deploy self-check

Before choosing a strategy, check ON DISK:

- Is there a fixed release version? (`docs/spp/07-release-notes.md` exists with a
  semver version recorded.)
- If NO: warn the user — deploying without a fixed version means not knowing what
  exactly is being shipped. Offer to fix the version first via `release-fixation`.
  Proceed only on the user's explicit choice.
- If YES: proceed.

This reads the file directly, not pipeline-state.md.
```

- [ ] **Step 3: Append the next-step block** (`<next-skill>` = `post-release`).

- [ ] **Step 4: Verify**

Run: `grep -c "phase 7 approved" skills/deploy-strategy/SKILL.md`
Expected: `0`

Run: `grep -c "07-release-notes.md" skills/deploy-strategy/SKILL.md`
Expected: `≥ 1`

Run: `grep -c "Next step" skills/deploy-strategy/SKILL.md`
Expected: `1`

- [ ] **Step 5: Commit**

```bash
git add skills/deploy-strategy/SKILL.md
git commit -m "feat(deploy-strategy): standalone-триггер, самопроверка версии, next-step"
```

---

### Task 6: `post-release` — trigger + next-step

**Files:**
- Modify: `skills/post-release/SKILL.md`

- [ ] **Step 1: Replace the description frontmatter**

Find:
```
description: Use when the deploy gate is approved (phase 8 approved in docs/spp/pipeline-state.md) - sets up minimal monitoring and a feedback channel, then closes the loop back into the pipeline
```
Replace with:
```
description: Use when a product is deployed or about to be, OR when the user directly asks to set up monitoring or a feedback channel after release - sets up minimal monitoring and a feedback channel, then closes the loop back to new ideas.
```

- [ ] **Step 2: Append the next-step block.** For post-release, `<next-skill>` is not a phase — write the block so it tells the user the route is complete and the next logical step is a fresh `idea-intake` for the next idea or iteration.

- [ ] **Step 3: Verify**

Run: `grep -c "phase 8 approved" skills/post-release/SKILL.md`
Expected: `0`

Run: `grep -c "Next step" skills/post-release/SKILL.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add skills/post-release/SKILL.md
git commit -m "feat(post-release): standalone-триггер и завершающая next-step подсказка"
```

---

### Task 7: `UPSTREAM.md` — record the divergence

**Files:**
- Modify: `UPSTREAM.md`

- [ ] **Step 1: Read `UPSTREAM.md`** to find where per-skill modifications from obra/superpowers are tracked.

- [ ] **Step 2: Add an entry** describing this divergence:

```markdown
### Freeform dispatch (2026-07-06)

SPP diverges further from obra/superpowers: the enforcing pipeline state-machine in
`using-super-puper-powers` was reworked into a context router. Cross-phase order is a
recommendation, not enforced; `pipeline-state.md` is an optional cross-chat journal,
not a gate; phase-6 safety checks read on-disk artifacts instead of state-file phase
status. All phase skills carry standalone triggers and end with a next-step hint.
A future upstream merge of the orchestrator skill will conflict heavily — this is
intentional.
```

- [ ] **Step 3: Verify**

Run: `grep -c "Freeform dispatch" UPSTREAM.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add UPSTREAM.md
git commit -m "docs(upstream): зафиксировать переход на диспетчер-роутер"
```

---

## WAVE 2 — cosmetics (next-step everywhere + trigger polish)

### Task 8: Middle-phase skills — next-step + trigger check

**Files:**
- Modify: `skills/product-discovery/SKILL.md`
- Modify: `skills/mvp-scoping/SKILL.md`
- Modify: `skills/stack-selection/SKILL.md`
- Modify: `skills/spec-writing/SKILL.md`
- Modify: `skills/plan-writing/SKILL.md`

- [ ] **Step 1: Confirm each already has a standalone trigger.** These five already carry "OR when the user directly asks". For each, verify the description also names an artifact rather than only "phase N approved". If it still says "phase N approved in pipeline-state.md" as the sole precondition, reword the pipeline half to name the input artifact (e.g. product-discovery input = `docs/spp/00-idea-brief.md`).

- [ ] **Step 2: Append the next-step block to each** with these `<next-skill>` values:
  - `product-discovery` → `mvp-scoping`
  - `mvp-scoping` → `stack-selection`
  - `stack-selection` → `spec-writing`
  - `spec-writing` → `plan-writing` (note in the block: spec-review and cross-spec-review run automatically before planning)
  - `plan-writing` → `subagent-driven-development` (phase 6 build)

- [ ] **Step 3: Verify**

Run: `for f in product-discovery mvp-scoping stack-selection spec-writing plan-writing; do grep -c "Next step" skills/$f/SKILL.md; done`
Expected: `1` for each (five lines of `1`).

- [ ] **Step 4: Commit**

```bash
git add skills/product-discovery/SKILL.md skills/mvp-scoping/SKILL.md skills/stack-selection/SKILL.md skills/spec-writing/SKILL.md skills/plan-writing/SKILL.md
git commit -m "feat(skills): next-step подсказки на middle-фазах"
```

---

### Task 9: Review skills — next-step

**Files:**
- Modify: `skills/spec-review/SKILL.md`
- Modify: `skills/cross-spec-review/SKILL.md`
- Modify: `skills/plan-review/SKILL.md`

- [ ] **Step 1: Append the next-step block to each** with these `<next-skill>` values:
  - `spec-review` → `cross-spec-review` if `docs/spp/04-specs/` holds more than one spec, otherwise `plan-writing` (state both branches in the block)
  - `cross-spec-review` → `plan-writing`
  - `plan-review` → `subagent-driven-development` (phase 6 build)

- [ ] **Step 2: Verify**

Run: `for f in spec-review cross-spec-review plan-review; do grep -c "Next step" skills/$f/SKILL.md; done`
Expected: three lines of `1`.

- [ ] **Step 3: Commit**

```bash
git add skills/spec-review/SKILL.md skills/cross-spec-review/SKILL.md skills/plan-review/SKILL.md
git commit -m "feat(skills): next-step подсказки на review-скиллах"
```

---

### Task 10: Phase-6 checkpoint skills — next-step

**Files:**
- Modify: `skills/data-boundaries/SKILL.md`
- Modify: `skills/pre-show-audit/SKILL.md`

Note: `subagent-driven-development` is vendored discipline — do NOT add a next-step to it; the phase-6 → release-fixation handoff lives in the orchestrator (Task 1).

- [ ] **Step 1: Append the next-step block to each:**
  - `data-boundaries` → `pre-show-audit`
  - `pre-show-audit` → acceptance demo (orchestrator continues) then `release-fixation`. Since these two are also standalone-runnable, phrase the block so that in standalone use it simply says the checkpoint is done.

- [ ] **Step 2: Verify**

Run: `for f in data-boundaries pre-show-audit; do grep -c "Next step" skills/$f/SKILL.md; done`
Expected: two lines of `1`.

- [ ] **Step 3: Commit**

```bash
git add skills/data-boundaries/SKILL.md skills/pre-show-audit/SKILL.md
git commit -m "feat(skills): next-step подсказки на checkpoint-скиллах фазы 6"
```

---

### Task 11: CHANGELOG

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Read `CHANGELOG.md`** to match the existing Keep-a-Changelog format and current version heading.

- [ ] **Step 2: Add an entry** under a new `Unreleased`/next-version section (Russian, Keep a Changelog):

```markdown
### Изменено
- SPP работает как набор свободно вызываемых скиллов: любой скилл можно вызвать в
  любой момент, диспетчер `using-super-puper-powers` роутит по контексту. Порядок
  фаз стал рекомендацией, а не жёсткой последовательностью.
- `pipeline-state.md` теперь необязательный журнал-память между чатами, а не
  блокирующий стейт.
- Защиты фазы 6 (acceptance demo перед релизом, data-boundaries и pre-show-audit
  перед демо) переехали внутрь скиллов и проверяют артефакты на диске.
- Каждый фазовый скилл в конце подсказывает следующий логичный шаг.
```

- [ ] **Step 3: Verify**

Run: `grep -c "свободно вызываемых" CHANGELOG.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): переход SPP на свободный вызов скиллов"
```

---

## Self-review notes

- **Spec coverage:** Component 1 (router) → Task 1, 2. Component 2 (journal) → Task 1 (state-machine removal). Component 3 (phase-6 self-checks) → Task 1 (orchestrator gates), Task 4 (release-fixation demo check), Task 5 (deploy version check). Component 4 (standalone triggers) → Tasks 3-6, 8. Component 5 (next-step) → Tasks 3, 4, 5, 6, 8, 9, 10. UPSTREAM/CHANGELOG → Tasks 7, 11. All five components covered.
- **Placeholder scan:** every insert gives exact text; `<next-skill>` is a named fill-in resolved per task, not a placeholder.
- **Ordering:** Wave 1 (Tasks 1-7) is self-contained and shippable; Wave 2 (Tasks 8-11) is additive polish. Either wave leaves the plugin working.
```

