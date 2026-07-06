# Upstream Provenance

This file tracks what was vendored from `obra/superpowers` into super-puper-powers (SPP), what was changed, what was deliberately left out, and how to bring future upstream changes in.

## Source

- Repository: https://github.com/obra/superpowers
- Tag: `v6.1.1`
- Commit: `d884ae04edebef577e82ff7c4e143debd0bbec99`

  The tag is annotated, so the tag object itself has its own SHA (`c984ea2…`). We pin the **commit** the tag points to, not the tag-object SHA — every reference in this file and in SKILL.md attribution headers is the commit SHA above.
- Last sync: 2026-07-05

## File inventory

Generated from `git ls-files skills/ hooks/ LICENSE.superpowers` (30 tracked paths). Status values:

- `vendored as-is` — byte-identical copy from upstream, no edits.
- `modified` — copied from upstream and edited; see Note for what changed.
- `reworked` — upstream skill used as a starting point but substantially rewritten (different flow, not just an attribution header or a few renames); see Note.
- `not copied (reason)` — exists upstream, deliberately not brought in.

Only vendored/modified/reworked files get a row. Files that are original SPP work (the new phase skills, review skills' own `SKILL.md`, `commands/spp.md`, `README.md`, `LICENSE`, `.claude-plugin/*.json`, etc.) are not vendoring artifacts and are intentionally absent from this table.

| Path | Status | Note |
|---|---|---|
| `LICENSE.superpowers` | vendored as-is | copy of upstream `LICENSE` |
| `hooks/hooks.json` | vendored as-is | copy of upstream `hooks/hooks.json` |
| `hooks/run-hook.cmd` | vendored as-is | copy of upstream `hooks/run-hook.cmd` |
| `hooks/session-start` | modified | adapted from upstream `hooks/session-start`; skill path and injection text renamed to SPP; Cursor/Copilot platform branches removed; v0.3.1 detects a co-active upstream superpowers via enabledPlugins and appends an orchestrator-precedence note |
| `skills/using-super-puper-powers/SKILL.md` | reworked | reworked from upstream `using-superpowers`; platform adaptation section removed; SPP pipeline map, state machine and phase-6 gate ownership added; v0.4 adds a Codex platform-notes section pointing to a Codex-tools reference |
| `.codex-plugin/plugin.json` | new (modeled on upstream) | SPP-original Codex manifest, shaped after upstream `.codex-plugin/plugin.json` (skills/hooks/interface fields) with SPP data |
| `skills/using-super-puper-powers/references/codex-tools.md` | modified | adapted from upstream `using-superpowers/references/codex-tools.md`; skill references retargeted to SPP |
| `skills/spec-writing/SKILL.md` | reworked | reworked from upstream `brainstorming`; input is approved MVP scope and stack; user questions restricted to product behavior; visual companion offer removed; terminal transition replaced with SPP review chain; design-presentation-to-user step removed; cross-plugin reference dropped |
| `skills/plan-writing/SKILL.md` | reworked | reworked from upstream `writing-plans`; plans path `docs/spp/05-plans/`; plan header points to SPP SDD only; mandatory plan-review; execution handoff without inline option |
| `skills/spec-review/spec-reviewer.md` | modified | adapted from upstream `brainstorming/spec-document-reviewer-prompt.md` |
| `skills/plan-review/plan-reviewer.md` | modified | adapted from upstream `writing-plans/plan-document-reviewer-prompt.md` |
| `skills/dispatching-parallel-agents/SKILL.md` | modified | attribution header only |
| `skills/finishing-a-development-branch/SKILL.md` | modified | attribution header only; v0.2 adds an SPP guard at the top of the body that machine-checks pipeline-state.md and stops before finishing if the phase-6 acceptance demo is not approved |
| `skills/receiving-code-review/SKILL.md` | modified | attribution header only |
| `skills/requesting-code-review/SKILL.md` | modified | attribution header; inline-execution subsection removed; example plan paths updated to `docs/spp/05-plans` |
| `skills/requesting-code-review/code-reviewer.md` | vendored as-is | reviewer prompt, not edited |
| `skills/subagent-driven-development/SKILL.md` | modified | attribution header; skill links renamed to SPP names; inline-execution alternative removed (SPP is always subagent-driven, no `executing-plans` analog); SDD workdir renamed to `.spp/sdd`; example plan paths updated to `docs/spp/05-plans`; v0.2 adds three SPP phase-gate guards: a lite-profile pointer near the top of the Process section, a machine-check guard before the finishing-a-development-branch handoff, and a short Git Degradation subsection for commit/worktree/review-package steps |
| `skills/subagent-driven-development/implementer-prompt.md` | vendored as-is | not edited |
| `skills/subagent-driven-development/task-reviewer-prompt.md` | vendored as-is | not edited |
| `skills/subagent-driven-development/scripts/task-brief` | modified | `.superpowers/sdd` → `.spp/sdd` |
| `skills/subagent-driven-development/scripts/review-package` | modified | `.superpowers/sdd` → `.spp/sdd` |
| `skills/subagent-driven-development/scripts/sdd-workspace` | modified | `.superpowers/sdd` → `.spp/sdd` |
| `skills/systematic-debugging/SKILL.md` | modified | attribution header; skill links renamed to SPP names |
| `skills/systematic-debugging/condition-based-waiting.md`, `defense-in-depth.md`, `root-cause-tracing.md` | vendored as-is | reference docs linked from SKILL.md, not edited |
| `skills/systematic-debugging/condition-based-waiting-example.ts` | vendored as-is | example file for `condition-based-waiting.md`, not edited |
| `skills/systematic-debugging/find-polluter.sh` | vendored as-is | bisection script referenced from `root-cause-tracing.md`, not edited |
| `skills/test-driven-development/SKILL.md` | modified | attribution header only |
| `skills/test-driven-development/testing-anti-patterns.md` | vendored as-is | reference doc linked from SKILL.md, not edited |
| `skills/using-git-worktrees/SKILL.md` | modified | attribution header only |
| `skills/verification-before-completion/SKILL.md` | modified | attribution header only |

Not copied from upstream v6.1.1:

- `executing-plans` — SPP is always subagent-driven (see spec §5.8); there is no scenario where the inline-execution alternative applies, so this skill has no SPP analog.
- `writing-skills` — a dev-time skill-authoring skill, consulted from the upstream clone when authoring SPP's own skills, not shipped as part of the plugin.
- `brainstorming`'s visual-companion files (browser-mockup companion and its scripts) — out of scope for v0.1 (spec §8).
- `systematic-debugging` test artifacts `CREATION-LOG.md`, `test-academic.md`, `test-pressure-1.md`, `test-pressure-2.md`, `test-pressure-3.md` — not referenced by `SKILL.md`, left behind as upstream test scaffolding.
- Upstream platform-adapter directories (`.codex-plugin`, `.cursor-plugin`, `.opencode`, and similar) — SPP targets Claude Code only.

## Sync procedure

1. Diff the current pinned commit against the target upstream tag (`git diff <old-sha>..<new-sha>` in a clone of `obra/superpowers`).
2. Manually review the diff and port meaningful changes into the corresponding SPP file, preserving the modifications already recorded in this table (do not blindly overwrite).
3. Update the attribution header (`Vendored from … Modifications: …`) in every touched `SKILL.md` to reflect the new modification list.
4. Update this file: new commit SHA, new sync date, and any changed rows in the file inventory above.
