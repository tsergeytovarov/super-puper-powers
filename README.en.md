# super-puper-powers

A Claude Code plugin that runs a 10-phase pipeline from a product idea to a deployed product — for people **without developer skills**.

Every phase produces one artifact and ends in one gate. Every gate is asked in product language: scenarios, demos, money. Never a diff, never architecture, never "go read the code." Technical decisions (architecture, data model, error handling, stack trade-offs) are made and recorded by the agent — the human only ever approves outcomes they can actually judge.

## What is this

SPP (Super Puper Powers) takes a person from "I have an idea" to "it's live and I know how to keep it running," entirely through conversation. It is built on top of [obra/superpowers](https://github.com/obra/superpowers): the implementation core (spec writing, planning, subagent-driven development, debugging, code review) is vendored from that project. The phases before code (discovery, MVP scoping, stack selection) and after code (release, deploy, post-release) are original to SPP.

The pipeline is resumable. State lives in `docs/spp/pipeline-state.md` inside the product's own repository, and any new session picks up exactly where the last one left off.

### The ten phases

| Phase | Skill | What happens | The gate |
|---|---|---|---|
| 0 | `idea-intake` | Interview: problem, audience, differentiation, success criteria, budget, timeline, jurisdiction | "Did I get the idea right?" |
| 1 | `product-discovery` | Research competitors, legal risk, market demand, feasibility (quick or deep mode) | go / pivot / stop |
| 2 | `mvp-scoping` | Prioritize features, define the walking skeleton, cut scope | Approve the scenario list |
| 3 | `stack-selection` | Propose 2-3 stack options with cost/maintainability trade-offs | Pick a stack |
| 4 | `spec-writing` (+ `spec-review`, `cross-spec-review`) | Write the technical spec; reviewed for completeness and, for multi-part products, cross-checked between specs | Approve a product-language summary |
| 5 | `plan-writing` (+ `plan-review`) | Turn the spec into an implementation plan; reviewed for coverage and placeholders | "N tasks, start?" |
| 6 | `subagent-driven-development` (gate owned by orchestrator) | Implement, test, and review the code; orchestrator runs an acceptance demo | Every must-scenario demonstrated working, live |
| 7 | `release-fixation` | Version, changelog, tag | "Fix version X?" |
| 8 | `deploy-strategy` | Choose and execute a deploy plan; smoke-test on production | "Live at X, scenarios verified — accept?" |
| 9 | `post-release` | Minimal monitoring, a feedback channel, and a loop back to a new idea | Final: operations handbook accepted |

Phase 6 is the exception: its worker skill is vendored as-is from upstream and knows nothing about SPP's state file, so the orchestrator itself owns that phase's gate — it intercepts the handoff to `finishing-a-development-branch` and runs the acceptance demo first.

Full phase-to-skill-to-artifact map: `skills/using-super-puper-powers/SKILL.md`.

## Install under Claude Code

From GitHub:

```
/plugin marketplace add tsergeytovarov/super-puper-powers
/plugin install super-puper-powers@super-puper-powers-marketplace
```

From a local checkout instead:

```
/plugin marketplace add /path/to/super-puper-powers
/plugin install super-puper-powers@super-puper-powers-marketplace
```

Either form works because `.claude-plugin/marketplace.json` declares the marketplace `super-puper-powers-marketplace` with a single plugin entry, `super-puper-powers`, sourced from `./`. The `@super-puper-powers-marketplace` suffix on `install` is required — Claude Code's `/plugin install` always needs `plugin-name@marketplace-name`, there is no bare-name shorthand.

After install, start a new Claude Code session. A `SessionStart` hook injects the pipeline orchestrator (`using-super-puper-powers`) automatically — describe your product idea and it takes over. If you'd rather trigger it explicitly, run `/spp`: it reads `docs/spp/pipeline-state.md` and either resumes the pipeline or offers to start phase 0.

## Install under Codex

The repo also ships a Codex manifest (`.codex-plugin/plugin.json`) — SPP is usable under OpenAI Codex, not just Claude Code. The skills live in `./skills/`, which Codex reads.

Publishing to the official Codex plugin marketplace (openai/plugins) is a separate, external process and isn't done yet. For local use, wire the skills in as Codex personal skills: symlink each `skills/<name>` into `~/.agents/skills/<name>` (a symlink keeps the repo as the source of truth), then restart Codex.

One thing about orchestration: Codex has no `SessionStart` hook, so the orchestrator is not injected for you. Start the pipeline explicitly — describe your idea and invoke `super-puper-powers:using-super-puper-powers`, or jump straight to a phase skill by name (the phase skills carry standalone triggers for exactly this). The multi-agent config and environment detection Codex needs are in `skills/using-super-puper-powers/references/codex-tools.md`.

## SPP and obra/superpowers: keep one plugin

SPP is an extended replacement for obra/superpowers, not an add-on to it. All of the upstream
implementation core (TDD, systematic debugging, code review, subagent-driven development,
worktrees, parallel agents) is vendored inside SPP — same skills, same commands, working
exactly the same. On top of that, SPP adds the whole pipeline: discovery, MVP, stack, spec,
deploy, operations.

So **you don't need both plugins, and having both hurts.** If you already have obra/superpowers
and you want the pipeline, just swap one for the other:

```
/plugin uninstall superpowers@<marketplace-name>
/plugin marketplace add tsergeytovarov/super-puper-powers
/plugin install super-puper-powers@super-puper-powers-marketplace
```

You lose nothing from superpowers — its whole core now lives inside SPP and updates with it, one
plugin instead of two — and you gain the idea-to-deploy layer on top.

Why replace rather than run side by side: each plugin installs its own `SessionStart` hook, and
with both active both fire — the system prompt then carries two large orchestrator blocks
(`using-superpowers` and `using-super-puper-powers`) at once. That's wasted always-on context,
and SPP can't cancel another plugin's hook — only you can, by removing one of the plugins. (If
you do keep both for your own reasons, SPP's hook notices and appends a note that the pipeline is
driven by it, so the wrong orchestrator doesn't take over — but there's no clean fix here other
than "keep one plugin.")

## Attribution

Based on [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (MIT), author Jesse Vincent. The implementation core (spec writing, planning, subagent-driven development, debugging, code review, and supporting skills) is vendored from that project, in most cases with only an attribution header and SPP-specific renames changed. The discovery, MVP scoping, stack selection, deploy strategy, and post-release phases are original to SPP.

Every vendored or reworked skill carries an attribution header naming what changed. Full provenance — source commit, per-file vendoring status, and the manual sync procedure — is in [`UPSTREAM.md`](./UPSTREAM.md).

## License

SPP's own code is [MIT](./LICENSE), Copyright (c) 2026 Sergey Tovarov.

The vendored upstream material remains under its original [MIT license](./LICENSE.superpowers), Copyright (c) 2025 Jesse Vincent.
