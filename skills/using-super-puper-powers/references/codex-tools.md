> Adapted from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT.
> Modifications: skill names kept (they are SPP's own); references retargeted to SPP.

# Codex platform notes

Read this when running Super Puper Powers under OpenAI Codex (App or CLI) rather than Claude Code.
Codex has no SessionStart hook, so the orchestrator is not injected automatically — start or
continue the pipeline by invoking `super-puper-powers:using-super-puper-powers` directly, or (thanks
to the standalone triggers) by asking for a single phase skill by name.

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait_agent`, and `close_agent` for skills like
`dispatching-parallel-agents` and `subagent-driven-development` (the phase-6 core, and the
clean-context reviewers behind `spec-review` / `plan-review`). When using
`subagent-driven-development`, always close implementer and reviewer subagents once they have
finished all their work.

## Environment detection

Skills that create worktrees or finish branches should detect their environment with read-only git
commands before proceeding:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)

See `using-git-worktrees` Step 0 and `finishing-a-development-branch` Step 1 for how each skill uses
these signals. This matters for phase 6 (implementation) and phase 7 (release-fixation), where SPP
already degrades git steps honestly when git-write is unavailable.

## Codex App finishing

When the sandbox blocks branch/push operations (detached HEAD in an externally managed worktree),
the agent commits all work and informs the user to use the App's native controls:

- **"Create branch"** — names the branch, then commit/push/PR via App UI
- **"Hand off to local"** — transfers work to the user's local checkout

The agent can still run tests, stage files, and output suggested branch names, commit messages, and
PR descriptions for the user to copy. In SPP this sits inside `release-fixation` (phase 7), whose
gate to the owner stays product-language ("fix version X?") regardless of how the branch is finished.
