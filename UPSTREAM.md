# Upstream Provenance

This file tracks what was vendored from `obra/superpowers` into super-puper-powers (SPP), what was changed, what was deliberately left out, and how to bring future upstream changes in.

## Source

- Repository: https://github.com/obra/superpowers
- Tag: `v6.1.1`
- Commit: `d884ae04edebef577e82ff7c4e143debd0bbec99`

  The tag is annotated, so the tag object itself has its own SHA (`c984ea2…`). We pin the **commit** the tag points to, not the tag-object SHA — every reference in this file and in SKILL.md attribution headers is the commit SHA above.
- Last sync: 2026-07-05

## File inventory

Generated from `git ls-files skills/ LICENSE.superpowers` (22 tracked paths). Status values:

- `vendored as-is` — byte-identical copy from upstream, no edits.
- `modified` — copied from upstream and edited; see Note for what changed.
- `not copied (reason)` — exists upstream, deliberately not brought in.

| Path | Status | Note |
|---|---|---|
| `LICENSE.superpowers` | vendored as-is | copy of upstream `LICENSE` |
| `skills/dispatching-parallel-agents/SKILL.md` | modified | attribution header only |
| `skills/finishing-a-development-branch/SKILL.md` | modified | attribution header only |
| `skills/receiving-code-review/SKILL.md` | modified | attribution header only |
| `skills/requesting-code-review/SKILL.md` | modified | attribution header; inline-execution subsection removed; example plan paths updated to `docs/spp/05-plans` |
| `skills/requesting-code-review/code-reviewer.md` | vendored as-is | reviewer prompt, not edited |
| `skills/subagent-driven-development/SKILL.md` | modified | attribution header; skill links renamed to SPP names; inline-execution alternative removed (SPP is always subagent-driven, no `executing-plans` analog); SDD workdir renamed to `.spp/sdd`; example plan paths updated to `docs/spp/05-plans` |
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
