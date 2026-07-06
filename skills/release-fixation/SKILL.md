---
name: release-fixation
description: Use when a development branch is complete and ready to become a release, OR when the user directly asks to fix a version, write release notes, or finish the branch - verifies the work, finishes the branch on the agent's own decision, fixes a semver version and writes owner-language release notes. Self-checks on disk for a passed acceptance demo first — it warns and asks for confirmation, it does not block.
---

## Overview

This is phase 7 of the SPP pipeline, but it can also be invoked standalone whenever a development branch is complete and ready to become a release, or whenever the user directly asks to fix a version, write release notes, or finish the branch. What was a branch of work now has to become a release: verified, integrated, versioned, and described in terms the owner can read without touching a diff.

Two vendored skills do the technical heavy lifting here, `verification-before-completion` and `finishing-a-development-branch`. The second one carries a twist. Upstream, it ends by showing the human a menu: merge locally, push and open a PR, keep the branch, or discard the work. That's a sane question for a developer and a meaningless one for the owner this pipeline serves — they can't evaluate "PR vs local merge" any more than they can evaluate a diff, and principle 1 of the pipeline says exactly that: every human-facing gate speaks in product language, never git. So this skill wraps that menu instead of forwarding it: the agent picks the integration method itself, defaults to merging into the main branch locally, and writes the choice into the Decisions log with its reasoning. The owner never sees "merge or PR" — they see "fix version 0.1.0?"

## Process

### 0. Confirm the trigger

This skill runs whenever a development branch is complete and ready to become a release, or whenever the user directly asks to fix a version, write release notes, or finish the branch — no pipeline gate required to start. If `docs/spp/pipeline-state.md` exists and is being tracked, write `current_phase: 7`, `phase_status: in_progress` on starting work; if it doesn't exist (standalone invocation), skip this and proceed. The actual safety check for a passed acceptance demo happens later, on disk, immediately before the branch gets finished (see "Pre-release self-check" below) — not here.

### 1. Verify the work

Run `super-puper-powers:verification-before-completion` (vendored). Fresh evidence, not a recollection of the acceptance demo — the demo proved the product behaves correctly in front of the owner; this step proves the underlying commands (tests, build, lint) still say so right now, on this exact tree, before anything gets merged or tagged. Do not skip this because the demo already looked convincing — the demo is owner-facing behavior, this is engineering evidence, and a release needs both.

**If command execution is unavailable in this environment** — no way to actually run tests, build, or lint — this step cannot produce the fresh evidence `verification-before-completion` requires, and no amount of care substitutes for that. Do not run a partial check and round it up, and do not report a pass from memory of an earlier run. Record honestly in `docs/spp/07-release-notes.md` (step 6): "verification not executed (restricted environment, no command execution available)." This is a legal, documented outcome — a release fixed without a verification claim attached to it is honest; a release that claims a green run nobody actually observed is the fabrication the verification hard-gate exists to prevent.

### 1.5. Pre-release self-check

Run this after step 1 and before step 2 (Finish the branch). Check ON DISK:

- Does `docs/spp/06-acceptance-demo.md` exist and record the demo as approved?
- If NO: warn the user plainly — there is no passed acceptance demo, so merging or
  releasing risks shipping something broken or leaky. Ask for an explicit "yes,
  release anyway" before continuing. Do not proceed silently.
- If YES: proceed.

This reads the file directly, not pipeline-state.md.

### 2. Finish the branch — agent decides, owner doesn't see the menu

Run `super-puper-powers:finishing-a-development-branch` (vendored) with its human-facing menu wrapped:

- The skill's Step 4 normally presents the owner a 4-option choice (merge locally / push and PR / keep as-is / discard). **Do not show this menu to the user.** It's a git-integration decision, not a product decision, and the owner has no basis to answer it beyond guessing at unfamiliar words.
- The agent makes the choice itself. **Default: merge into the main branch locally.** Depart from the default only when there's a concrete reason (for example: the owner is mid-review on a separate collaboration channel that expects a PR, or a prior Decisions log entry already committed to a different flow) — and if you depart, the reasoning has to be as sound as the default would need to be, not weaker.
- Run the rest of the vendored skill's steps for the chosen option normally (test verification, environment detection, execution, cleanup) — only the menu-presentation step is intercepted; the mechanics behind whichever option gets chosen are unchanged.
- Log the decision in the Decisions log: date, phase 7, which integration method was used, and the reasoning, attributed to the agent (this is the one decision in this phase the owner did not make).

**If git-write is unavailable in this environment** — no way to actually merge, push, or delete a branch — `finishing-a-development-branch`'s mechanics cannot run at all, not even for the chosen option. Work by files on disk instead: the implementation stays on whatever branch or worktree it's already in, and you record honestly in `docs/spp/07-release-notes.md` (step 6) that branch finishing was not executed and why ("finishing not executed (restricted environment, no git-write available)") — never report a merge, a push, or a branch deletion that didn't actually happen. This does not block the rest of this phase: the version still gets fixed, the changelog still gets written, and the release notes still get produced as an honest artifact — just one that says plainly what git state it does and doesn't reflect.

### 3. Fix the semver version

Determine the version number. The first release of a product is `0.1.0`. For subsequent passes through this phase (a later cycle from `post-release` feedback), bump according to standard semver against what actually changed since the last tagged release: patch for fixes, minor for backward-compatible new capability, major for breaking change to how the owner or their users interact with the product. State which one applies and why — a version bump is a claim about the nature of the change, not a counter that increments itself.

### 4. Write the changelog in owner language

Write the changelog entry in `artifacts_language` from the state file — the language chosen once in idea-intake for artifacts, which may differ from whatever language the current chat session happens to be in. Check the field; don't assume it matches the conversation.

The changelog describes what the product can now **do** — capabilities visible to the person using it — not what changed in the code. "You can now reset your password by email" belongs in it. "Refactored the auth module" does not; the owner never touches the auth module and a commit-list changelog tells them nothing they can act on. If a phase-7 pass follows a bug-fix cycle, describe the user-visible symptom that's now resolved, not the internal cause.

### 5. Tag the release

Create a git tag for the version fixed in step 3, pointing at the commit the finished branch now sits on (post-merge, if that's the chosen integration method).

**If git-write is unavailable in this environment**, there is no commit to point a tag at in the first place, and no `git tag` command that can succeed. Do not fabricate a tag name and present it as created. Record honestly in `docs/spp/07-release-notes.md` (step 6): "tag not executed (restricted environment, no git-write available)" — the version number from step 3 still stands as the fixed version; it's the git artifact recording that version that's missing, not the version decision itself.

### 6. Write the artifact

Write `docs/spp/07-release-notes.md` with:

- The version number and the semver reasoning from step 3.
- The changelog from step 4, in `artifacts_language`.
- A brief record of the integration method chosen in step 2 and why (this mirrors the Decisions log entry; the artifact is what a future reader opens without digging through the log).
- **An execution-status line for verification, branch finishing, and the tag** — three short statements, one per mechanism: each either confirms it ran with evidence (verification output, the merge/PR outcome, the tag name) or states plainly that it was not executed and why, using the exact wording from steps 1, 2, and 5 ("not executed (restricted environment, ...)"). This is the artifact's honesty checkpoint: the release is fixed either way, but what actually happened in git and in the verification commands has to be stated, not implied or left for the reader to assume from silence.

### 7. Gate

Ask the owner, in product language only: **"Fix version X?"** (substituting the actual version number). Nothing about merge, PR, branches, or diffs belongs in this question or in anything leading up to it — the git-integration decision was already made and logged in step 2, not something still open for the owner to weigh in on. Do not let this question imply a git operation or a verification run that didn't actually happen — if any of them were skipped per steps 1, 2, or 5, the version is still real and fixable; the gate question doesn't change, but the artifact behind it has to carry the honest execution-status line. While the question is outstanding, `phase_status: gate_pending`.

- **On confirmation:** set `phase_status: approved`, log the decision in the Decisions log (date, phase 7, "release vX.Y.Z fixed," who approved it).
- **On requested changes:** if the owner wants the changelog wording adjusted (more detail, different emphasis, a capability described differently), revise `07-release-notes.md` and re-ask. The version number itself is not really negotiable — semver reasoning follows from what changed — but if the owner's feedback reveals the changelog was scoped wrong (missed a capability, described the wrong thing as new), that can also mean revisiting step 3's determination before re-asking.

### 8. Hand off

See the closing section of this file for how to hand off. Do not start deploy planning yourself — this skill's job ends at a fixed, tagged, described release.

## Red Flags

| Thought | Reality |
|---|---|
| "I'll show the owner the merge / PR / keep / discard menu so they feel in control" | That menu is a git-integration decision the owner cannot meaningfully evaluate — it's exactly the kind of technical gate principle 1 forbids surfacing. The agent decides, defaults to local merge, and logs the reasoning; the owner only ever sees the version-fixing question. |
| "I'll write the changelog as a list of what I committed" | The changelog describes capabilities the product now has, in owner language — what a user can do that they couldn't before. A commit list is an engineering artifact; it tells the owner nothing they can act on or feel good about. |
| "The chat's in Russian right now, I'll write the changelog in Russian" | Changelog language is `artifacts_language` from the state file, fixed once in idea-intake — not whatever language the current conversation happens to be in. Check the field before writing; the two can diverge. |
| "The acceptance demo already proved it works, I can skip verification-before-completion" | The demo is owner-facing behavior at one point in time; verification-before-completion is fresh engineering evidence on the current tree right before it gets merged and tagged. One doesn't substitute for the other — run it. |
| "Merge vs PR is basically the same choice, I'll just ask which one they'd prefer" | Asking "which one" still puts a git decision in front of someone who can't evaluate it — the fix isn't picking a friendlier way to ask, it's not asking at all. Default to local merge, depart only for a concrete logged reason. |
| "First release, I'll pick whatever version feels right" | First release is always 0.1.0 — that's fixed, not a judgment call. Later passes need actual semver reasoning (patch/minor/major) tied to what changed, stated explicitly, not a version bumped by feel. |
| "I can't actually run the tests here, but they probably still pass — I'll write 'verification passed'" | That's a fabricated result, exactly what the verification hard-gate forbids. If command execution genuinely isn't available, the honest record is "verification not executed (restricted environment)" — a documented gap, not a fabricated green run. |
| "Git-write isn't available, but I already know the merge would have gone cleanly — I'll write it up as merged" | A merge that didn't happen isn't a merge. Record "finishing not executed (restricted environment)" and leave the branch state as it actually is — never describe a git operation you didn't perform. |
| "No git-write, so I'll skip the tag but not mention it — the version number in the release notes covers it" | The absence of a tag has to be stated, not left for the reader to infer from a document that otherwise reads like everything succeeded. Silence about a skipped step reads as an oversight or, worse, as a claim that it happened; say "tag not executed (restricted environment)" explicitly. |
| "The environment is restricted, so I'll just skip this whole phase and let the owner know 'release isn't possible here'" | Restricted execution degrades specific mechanisms (verification, branch finishing, the tag) — it doesn't cancel the phase. The version still gets fixed, the changelog still gets written, and the release notes still get produced; what's honest is naming exactly which git/execution steps didn't run, not abandoning the phase because some of it can't. |

## Next step

When this stage is complete, tell the user in their own language that:
- this stage is done;
- the next logical step is the `deploy-strategy` skill;
- they should start it in a fresh chat so that skill gets clean context.

Do not auto-invoke the next skill. The user drives the transition — offer, do not proceed.
