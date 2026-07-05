---
name: using-super-puper-powers
description: Use when starting any conversation - orchestrates the SPP pipeline that turns a product idea into a deployed product, resuming from docs/spp/pipeline-state.md or offering phase 0 when the user describes a product idea
---

> Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT.
> Modifications: reworked from the upstream orchestrator skill; platform adaptation section removed; SPP pipeline map, state machine and phase-6 gate ownership added

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before any product work:** read `docs/spp/pipeline-state.md` and follow the pipeline map below.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Pipeline Map

The SPP pipeline turns a product idea into a deployed product across ten phases, 0 through 9. Every phase has exactly one worker skill, writes exactly one artifact under `docs/spp/`, and ends in exactly one gate. Skill names below are plain phase-map identifiers — invoke the skill matching that name (e.g. "invoke the idea-intake skill").

| Phase | Skill | Artifact | Gate |
|---|---|---|---|
| 0 | idea-intake | docs/spp/00-idea-brief.md | "Did I get the idea right?" |
| 1 | product-discovery | docs/spp/01-discovery-report.md | go / pivot / stop |
| 2 | mvp-scoping | docs/spp/02-mvp-scope.md | approve scenario list |
| 3 | stack-selection | docs/spp/03-stack.md | pick stack option |
| 4 | spec-writing (+spec-review, cross-spec-review) | docs/spp/04-specs/ | approve product summary |
| 5 | plan-writing (+plan-review) | docs/spp/05-plans/ | "N tasks, start?" |
| 6 | subagent-driven-development (gate owned by orchestrator) | docs/spp/06-acceptance-demo.md | acceptance demo: every must-scenario works |
| 7 | release-fixation | docs/spp/07-release-notes.md | "fix version X?" |
| 8 | deploy-strategy | docs/spp/08-deploy-runbook.md | "product live at X, accept?" |
| 9 | post-release | docs/spp/09-operations.md | final: ops handbook accepted |

## Session Start Protocol

At the start of every session, before responding to anything product-related:

1. Check whether `docs/spp/pipeline-state.md` exists.
2. **It exists:** read it in full. Announce "Pipeline on phase N, continuing with `<skill>`." Then act per the State Machine below — it tells you exactly which skill to launch and whether to re-ask a pending gate.
3. **It does not exist, and the user is describing a product idea:** offer to start the pipeline at phase 0 — invoke the idea-intake skill.
4. **It does not exist, and the user is not describing a product idea:** this skill does not apply yet. Fall through to whatever other skill matches the actual request.

## State Machine

The state file's life cycle, condensed from the spec:

1. The phase-N skill, on starting work, writes `current_phase: N`, `phase_status: in_progress`.
2. When it presents the gate question to the user → `phase_status: gate_pending`.
3. After the user approves → `phase_status: approved` + a new entry in the Decisions log. `current_phase` is **not** incremented here — the next phase's skill sets it when it starts.
4. Orchestrator behavior on session start, read directly off `(current_phase, phase_status)`:
   - `(N, in_progress)` or `(N, gate_pending)` → continue phase N. If `gate_pending`, re-ask the gate question verbatim — do not re-run the phase's work.
   - `(N, approved)` → launch phase N+1's skill.
   - `phase_status: stopped` or `current_phase: done` → the pipeline is terminal. Do not continue it. `stopped` is a deliberate, successful stop (e.g. a discovery kill-shot) — report that outcome, don't treat it as a failure to route around.

<HARD-GATE>Phase N+1 MUST NOT start until phase N's gate is approved in docs/spp/pipeline-state.md.</HARD-GATE>

## Phase 6 Gate Ownership

Phase 6 is different: its worker skill is the vendored subagent-driven-development skill, which knows nothing about `pipeline-state.md` and, left alone, walks straight from its final whole-branch review into `finishing-a-development-branch`. The orchestrator — not the worker skill — owns this phase's gate and must intercept that transition.

- If the plan spans multiple sub-projects, execute their plans in the `subproject_order` recorded in state, not in file-listing order or arrival order.
- After subagent-driven-development's final whole-branch review completes, the orchestrator runs the **acceptance demo**: for every must-scenario recorded in the MVP scope, demonstrate it running live and record the result. Write the outcome to `docs/spp/06-acceptance-demo.md` as scenario → how demonstrated → result.
- While the demo is in progress, `phase_status` is `gate_pending`. A failed scenario is not a gate failure to negotiate around — it's a task: fix it, then re-run the demo for that scenario.

<HARD-GATE>finishing-a-development-branch MUST NOT be invoked until the acceptance demo is approved in docs/spp/pipeline-state.md (phase_status: gate_pending during the demo).</HARD-GATE>

After approval, hand off to the release-fixation skill (phase 7) — release-fixation is what actually invokes finishing-a-development-branch, wrapped so its merge/PR/keep/discard menu never reaches the user as a gate.

## Mid-Pipeline Entry

The user may already have an artifact from outside the pipeline — "I already have an MVP scope," a discovery report from a previous exploration, and so on. When that happens:

1. Create `docs/spp/pipeline-state.md` if it doesn't exist yet.
2. Record the phase numbers being skipped in `phases_skipped`.
3. Log the decision — what was skipped and why — in the Decisions log.
4. Start the pipeline at the named phase, not phase 0.

Do not silently accept an artifact at face value just because the user says it exists — the phase's own skill still validates it as part of starting that phase's work.

## Gate Language

<HARD-GATE>Every gate question is in product language: scenarios, demos, money. Never diff, architecture or refactoring. Never ask the user to read code or specs.</HARD-GATE>

The user running this pipeline is explicitly assumed not to be a developer. A gate phrased in implementation terms is not a shortcut — it's a gate the user cannot actually evaluate, which makes the approval meaningless.

## Skill Priority

When multiple skills apply, the pipeline map above sets the approach — it tells you which phase skill governs right now — and implementation skills (frontend-design, etc.) carry it out within that phase.

- "I have a product idea" → super-puper-powers:idea-intake first, then whatever phase 0 needs.
- "Fix this bug" (inside phase 6 implementation work) → super-puper-powers:systematic-debugging first, then domain skills.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |
| "The user is technical, I can show the diff" | Gates are product-language. Always. |
| "Spec looks fine, skip spec-review" | The review loop is mandatory. |
| "I'll start phase N+1, the gate is obviously fine" | approved in the state file, or it didn't happen. |

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
