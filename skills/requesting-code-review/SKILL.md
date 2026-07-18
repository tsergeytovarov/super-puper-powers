---
name: requesting-code-review
description: Use after completing a task or major feature, before merging, or when the user asks to review a branch, PR, or work-in-progress diff. Run independent Standards and Spec reviews so clean code cannot hide the wrong behavior and correct behavior cannot hide broken standards.
---

> Adapted from [mattpocock/skills](https://github.com/mattpocock/skills), MIT.
> SPP additions: automatic fixed-point discovery, SPP spec locations, finding priorities, and integration with `receiving-code-review`.

Two-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec** — does the code faithfully implement the originating issue / PRD / spec?

Both axes run as **parallel sub-agents** with fresh, curated context so they don't pollute each other, then this skill aggregates their findings.

## Process

### 1. Pin the fixed point

Use the fixed point supplied by the user or the implementation task. If none was supplied, resolve the merge-base with the repository's default branch (`main` or `master`). Ask only when multiple plausible bases remain.

Choose the diff once and give the exact command to both reviewers:

- Clean worktree or committed branch/PR: `git diff <fixed-point>...HEAD`.
- Dirty worktree or WIP review: resolve `git merge-base <fixed-point> HEAD`, then use `git diff <merge-base-sha>` so committed, staged, and unstaged changes are all included.

Also note the list of commits via `git log <fixed-point>..HEAD --oneline` and the worktree status via `git status --short`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here — not inside two parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`, GitLab `!67`, etc.) — use the repository's configured tracker workflow when available.
2. A path the user passed as an argument.
3. A matching plan or spec under `docs/spp/04-specs/`, `docs/spp/05-plans/`, `docs/`, `specs/`, or `.scratch/`.
4. If nothing is found, do not block the review. Skip the **Spec** sub-agent, report "no spec available", and complete the Standards axis.

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, including `AGENTS.md`, `CLAUDE.md`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`, and relevant files under `docs/ai/`.

Every finding on either axis must carry one priority:

- **Critical** — security issue, data loss, destructive behavior, or the core requirement is wrong or absent.
- **Important** — user-visible bug, partial requirement, unsafe edge case, or a documented-standard breach that should block completion.
- **Minor** — bounded maintainability or clarity issue that does not change behavior and is not already enforced by tooling.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

Dispatch both reviews concurrently using the platform's sub-agent mechanism. Use fresh task-specific context for each; do not pass the parent conversation history.

Both reviews are read-only. Tell each sub-agent not to edit files, stage changes, move `HEAD`, switch branches, reset, merge, or rebase. It may only inspect the supplied diff, files, and history.

**Standards sub-agent prompt** — include:

- The full diff command and commit list.
- The list of standards-source files you found in step 3, **plus the smell baseline from step 3** pasted in full — the sub-agent has no other access to it.
- The Critical, Important, and Minor priority definitions from step 3.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Assign Critical, Important, or Minor using the supplied definitions. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** — include:

- The diff command and commit list.
- The path or fetched contents of the spec.
- The Critical, Important, and Minor priority definitions from step 3.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Assign Critical, Important, or Minor using the supplied definitions. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings — the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes — that's the reranking the separation exists to prevent.

Run `super-puper-powers:receiving-code-review` before implementing findings. Fix every Critical and Important finding before completion; evaluate Minor findings against YAGNI and the current scope.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
