---
name: using-super-puper-powers
description: Use when starting any conversation - orchestrates the SPP pipeline that turns a product idea into a deployed product, resuming from docs/spp/pipeline-state.md or offering phase 0 when the user describes a product idea
---

> Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT.
> Modifications: reworked from the upstream orchestrator skill; platform adaptation section removed; SPP pipeline map, state machine and phase-6 gate ownership added; added a phase-6 execution profile section describing the lite path over vendored subagent-driven-development; strengthened the phase-6 finishing-a-development-branch hard-gate into a mandatory machine-check of pipeline-state.md; pipeline map and phase-8 gate description updated for the deploy-strategy executed/deferred modes; added Codex platform notes pointing to a Codex-tools reference; reworked the enforcing state-machine into a context router — cross-phase order is now a recommendation, pipeline-state.md is an optional journal, and phase-6 safety gates read on-disk artifacts instead of state-file phase status

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

**Before any product work:** if `docs/spp/pipeline-state.md` exists, read it as memory for context, then route to the skill that matches the request. The pipeline map below is a recommended order, not a gate.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Recommended Route

The SPP route turns a product idea into a deployed product across ten phases, 0-9.
This is a **recommended order, not an enforced one.** Every phase has one worker
skill and writes one artifact under `docs/spp/`. You may enter at any phase, run a
single skill standalone, or skip phases — the dispatcher never blocks you on order.
Each phase skill ends by suggesting the next one; you decide when to take it.

Skill names below are plain phase-map identifiers — invoke the skill matching that name (e.g. "invoke the idea-intake skill").

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
| 8 | deploy-strategy | docs/spp/08-deploy-runbook.md | two modes — see below |
| 9 | post-release | docs/spp/09-operations.md | final: ops handbook accepted |

Phase 8's gate has two modes, recorded as `deploy_status` in state: `executed` — a real deploy with a production smoke test and evidence, gated on the product being live and verified — or `deferred` — a deploy strategy is chosen and the runbook is ready, but the deploy itself is postponed, gated on accepting the strategy and runbook with no live-evidence requirement. The exact gate wording for each mode lives in `deploy-strategy`; this map only names the two modes. `deploy-strategy` (phase 8) owns the choice between the two; `post-release` (phase 9) reads `deploy_status` and, when it's `deferred`, does not treat the product as live.

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

## Phase 6 Gate Ownership

Phase 6 is different: its worker skill is the vendored subagent-driven-development skill, which knows nothing about the SPP route and, left alone, walks straight from its final whole-branch review into `finishing-a-development-branch`. The orchestrator — not the worker skill — owns this phase's safety checks and must intercept that transition. These checks are decoupled from any phase status in `pipeline-state.md`: they read the artifacts ON DISK.

- If the plan spans multiple sub-projects, execute their plans in the `subproject_order` recorded in the journal, not in file-listing order or arrival order.
- After subagent-driven-development's final whole-branch review completes and before the acceptance demo, the orchestrator runs two checkpoint skills in order: `super-puper-powers:data-boundaries`, then `super-puper-powers:pre-show-audit`. Each writes its artifact (`docs/spp/06-data-boundaries.md`, `docs/spp/06-pre-show-audit.md`). Their findings are fix-tasks, not human gates — the acceptance demo remains the only human-facing gate of phase 6. The acceptance demo must not start until both artifacts exist on disk.
- Once both checkpoints are done, the orchestrator runs the **acceptance demo**: for every must-scenario recorded in the MVP scope, demonstrate it running live and record the result. Write the outcome to `docs/spp/06-acceptance-demo.md` as scenario → how demonstrated → result, and record it as approved once the owner accepts it.
- A failed scenario is not a gate failure to negotiate around — it's a task: fix it, then re-run the demo for that scenario.

Both checkpoint artifacts (`docs/spp/06-data-boundaries.md`, `docs/spp/06-pre-show-audit.md`) must exist on disk before the acceptance demo starts — machine-checked by opening the files, not recalled from memory and not inferred from `pipeline-state.md`.

<HARD-GATE>
Before starting the acceptance demo, machine-check the artifacts ON DISK: confirm
`docs/spp/06-data-boundaries.md` and `docs/spp/06-pre-show-audit.md` both exist and
record their check as done. If either is missing, STOP and run the missing checkpoint
skill (`data-boundaries`, then `pre-show-audit`) before the demo. Read the files; do
not rely on memory or on pipeline-state.md.
</HARD-GATE>

<SAFETY-GATE kind="warn-and-confirm">
Before ANY invocation of finishing-a-development-branch — including one arriving from
inside subagent-driven-development — machine-check ON DISK that
`docs/spp/06-acceptance-demo.md` exists and records the demo as approved. If it does
not, do NOT proceed silently: warn the user plainly that the product has no passed
acceptance demo and that merging or releasing it is risky, and get an explicit
"yes, proceed anyway" first. This is deliberately NOT a `<HARD-GATE>`: unlike the
checkpoint gate above, it does not block the owner — the mandatory part is the warning
and the informed, explicit decision, not a stop. This reads the file directly, not
pipeline-state.md.
</SAFETY-GATE>

The vendored subagent-driven-development skill walks straight from its final whole-branch review into finishing-a-development-branch with no awareness of this check — that gap is what these two gates exist to close from the orchestrator side. (A corresponding guard inside the vendored skills themselves is tracked separately; this rule does not depend on that guard existing, and does not weaken if it doesn't.)

After approval, hand off to the release-fixation skill (phase 7) — release-fixation is what actually invokes finishing-a-development-branch, wrapped so its merge/PR/keep/discard menu never reaches the user as a gate.

## Phase 6 Execution Profile

`plan-writing` (phase 5) estimates the plan's size and writes a recommendation to `pipeline_profile` in state: `lite` if the plan is ≤ 3 tasks and roughly ≤ 150 lines total, `full` otherwise. Read `pipeline_profile` from state before launching phase 6 — it decides which execution path phase 6 actually runs.

This is an orchestrator-level protocol layered **over** vendored subagent-driven-development, not a rewrite of it. The vendored skill itself stays as-is; the switch below decides how much of it gets invoked.

**`pipeline_profile: full` (or `null`)** — the standard path. Run subagent-driven-development exactly as vendored: a fresh implementer subagent per task, a task review after each task, git-worktree isolation via `using-git-worktrees`, and the final whole-branch review.

**`pipeline_profile: lite`** — a lightweight path for plans small enough that the standard machinery is pure overhead relative to the work:

- Dispatch **one** implementer subagent for the entire plan, not one per task. Give it the whole plan document (it's small enough to hand over directly) instead of extracting per-task briefs.
- Skip per-task fresh-subagent dispatch and skip per-task review — there is no task-by-task review loop in lite.
- Skip git-worktree isolation — work happens in the current workspace rather than standing up an isolated worktree via `using-git-worktrees`.
- Run **one** final review at the end: a single whole-branch review over everything the implementer produced, using the same final-review mechanism the full path uses (`super-puper-powers:requesting-code-review`'s reviewer template). This review is not optional and not skipped — it's the only review lite gets, so it carries the full weight the per-task reviews would otherwise share.
- `spec-review`, `cross-spec-review`, and `plan-review` (phases 4-5) still run regardless of profile. They're cheap relative to phase 6 and catch defects before any code is written — lite only thins phase 6's execution machinery, never the upstream review gates that precede it.

The size threshold that decides `full` vs `lite` is set once, in `plan-writing`'s size-estimate step (phase 5) — this skill only reads and acts on the recommendation; it does not re-derive or second-guess the threshold here.

## Mid-Pipeline Entry

The user may already have an artifact from outside the route — "I already have an MVP scope," a discovery report from a previous exploration, and so on. Entering the route in the middle is normal, not an exception — the dispatcher routes straight to the matching phase skill. If you keep a journal:

1. Create `docs/spp/pipeline-state.md` if it doesn't exist yet.
2. Record which phases were skipped, and note in the Decisions log what was skipped and why.
3. Route to the named phase's skill directly.

Do not silently accept an artifact at face value just because the user says it exists — the phase's own skill still validates it as part of starting that phase's work.

## Gate Language

<HARD-GATE>Every gate question is in product language: scenarios, demos, money. Never diff, architecture or refactoring. Never ask the user to read code or specs.</HARD-GATE>

The user running this pipeline is explicitly assumed not to be a developer. A gate phrased in implementation terms is not a shortcut — it's a gate the user cannot actually evaluate, which makes the approval meaningless.

## Skill Priority

When multiple skills apply, the pipeline map above sets the approach — it tells you which phase skill governs right now — and implementation skills (frontend-design, etc.) carry it out within that phase.

- "I have a product idea" → super-puper-powers:idea-intake first, then whatever phase 0 needs.
- "Fix this bug" (inside phase 6 implementation work) → super-puper-powers:systematic-debugging first, then domain skills.

## On-demand helpers

Six standalone helper skills sit outside the state machine and do not touch `pipeline-state.md`. Invoke them by their own triggers when the work calls for it — usually during phase 6, and `seo-baseline`/`geo-optimization` also around phase 8:

- `super-puper-powers:accessibility` — baseline a11y audit and fixes.
- `super-puper-powers:mobile-version` — design-only responsive pass.
- `super-puper-powers:test-runner-setup` — test runner + one smoke test.
- `super-puper-powers:seo-baseline` — technical page packaging for shareable links.
- `super-puper-powers:geo-optimization` — public-page packaging for AI assistants.
- `super-puper-powers:ux-copywriting` — UI microcopy and states.

None of these expand product scope: they are design-only, packaging, or verification actions over work already built.

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
| "I remember the acceptance demo passed, I'll go straight to finishing-a-development-branch" | Memory is not the check. Machine-check the on-disk artifact `docs/spp/06-acceptance-demo.md` for the demo recorded as approved, every single time, even (especially) after a context compaction that erased the memory of running the demo. |
| "The plan is tiny, I'll skip straight to lite without checking `pipeline_profile`" | `pipeline_profile` is set by `plan-writing`'s size estimate, not by eyeballing the plan in phase 6. Read the field; don't re-derive the threshold here. |
| "Lite mode means we can also skip plan-review since the plan is small" | Lite only thins phase 6 execution machinery. `spec-review`, `cross-spec-review`, and `plan-review` run regardless of profile — they're cheap and they catch defects before code exists. |
| "I'll go straight to the acceptance demo, the build looks clean" | data-boundaries and pre-show-audit run first. Machine-check the on-disk artifacts `docs/spp/06-data-boundaries.md` and `docs/spp/06-pre-show-audit.md` both exist before the demo. |

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.

## Platform notes

Under Claude Code this orchestrator is injected automatically by a SessionStart hook. **Under OpenAI Codex there is no SessionStart hook** — nothing injects the orchestrator for you. Start or resume the pipeline by invoking `super-puper-powers:using-super-puper-powers` directly, or jump to a single phase by naming its skill (the phase skills carry standalone triggers for exactly this). When running under Codex, read `references/codex-tools.md` for the multi-agent config (`spawn_agent`/`wait_agent`/`close_agent`) and the git environment detection that the vendored phase-6 and phase-7 skills rely on.
