---
name: plan-writing
description: Use when specs are approved (phase 4 approved in docs/spp/pipeline-state.md) OR when the user directly asks to turn a spec into an implementation plan outside a running pipeline (e.g. "turn this spec into an implementation plan") - writes implementation plans as bite-sized tasks to docs/spp/05-plans/ for subagent-driven execution
---

> Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT.
> Modifications: reworked from the upstream planning skill; plans path docs/spp/05-plans/; plan header points to SPP SDD only; mandatory plan-review; execution handoff without inline option; body restructured to the fixed Overview/Process/Red Flags skeleton; reframed self-review as a placeholder-and-coverage scan rather than a logic-catching step; added a plan-size estimate step that recommends pipeline_profile (full/lite) for the orchestrator's phase 6; added a per-task verification-type field (unit/acceptance/manual) to the task template; added explicit git-write degradation for the per-task commit step; standalone invocation supported outside the pipeline

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD where the stack supports it. Frequent commits when git-write is available.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the plan-writing skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `super-puper-powers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/spp/05-plans/YYYY-MM-DD-<feature-name>.md` (user preferences for plan location override this default). When there are multiple sub-projects, plan order comes from the `subproject_order` field in `docs/spp/pipeline-state.md`.

**Remember throughout:** exact file paths always; complete code in every step — if a step changes code, show the code; exact commands with expected output; DRY, YAGNI, TDD where the stack supports it, frequent commits when git is available.

## Process

### 1. Scope check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during spec-writing. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

### 1.5. Standalone use (no pipeline running)

If there is no `docs/spp/pipeline-state.md` at phase 4 approved, and the user asked directly to turn a spec into a plan (e.g. "turn this spec into an implementation plan"): do not demand an approved phase 4 or a pipeline-tracked spec. Skip reading and writing `pipeline-state.md` entirely, including `subproject_order` — if there are multiple specs and no pipeline state to order them, ask the user directly which one to build first.

Take the spec from wherever the user points — a file on disk, or a spec they paste or describe directly — instead of insisting it live under `docs/spp/04-specs/`. If it does live there, read it normally. Everything else in this skill runs unchanged: map the file structure, right-size the tasks, write the plan header and each task exactly as steps 2 through 5 describe, and run self-review and plan-review exactly as steps 7 and 8 describe — none of that rigor is pipeline-specific.

Still write the plan to `docs/spp/05-plans/YYYY-MM-DD-<feature-name>.md` per the skill's default — it's a real, reusable document regardless of how it was triggered. Do not write `current_phase`/`phase_status` transitions and do not log to a Decisions log that belongs to a pipeline that isn't running.

After plan-review comes back clean, the execution handoff in step 9 still applies as written — subagent-driven-development is the right way to execute any plan, standalone or not. Just don't frame it as advancing a pipeline phase if none is running.

### 2. Map the file structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design **deep modules** first: substantial behavior behind a small public interface at a clean seam. When a new interface or seam is required, use the `codebase-design` skill before fixing the file map.
- File count is not architecture. Do not create pass-through wrappers or scatter one behavior across many tiny files merely to make each file look focused. Apply the deletion test: if removing a proposed module only moves its complexity into callers, it was shallow.
- After the module interfaces are clear, split their implementations where doing so improves locality and keeps code reviewable. Files that change together should live together; split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure — but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

### 3. Right-size the tasks

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. When drawing task boundaries: fold setup, configuration, scaffolding, and documentation steps into the task whose deliverable needs them; split only where a reviewer could meaningfully reject one task while approving its neighbor. Each task ends with an independently testable deliverable.

**Bite-sized step granularity within a task — each step is one action (2-5 minutes):**
- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

### 4. Write the plan document header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use super-puper-powers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

### 5. Write each task

Every task declares a **verification type** — this is a required field, not optional metadata:

- `unit` — TDD as the default: a failing test written first, then the minimal implementation, then a passing run. Use this whenever the stack can run a unit test for the behavior in question.
- `acceptance` — the task is proven by a demo scenario instead of a unit test (e.g. a stack with no test runner, per `03-stack.md`). No unit test is required, but the task must name the exact demo scenario that proves it, in the same "user does X → Y happens" form used elsewhere in the pipeline.
- `manual` — proven by an explicit manual checklist the implementer runs and records, when neither an automated unit test nor a scripted acceptance demo is practical.

A task without a unit test is legal **only** when marked `acceptance` or `manual`, and only with a justification tied to the stack (e.g. "no-build stack per `03-stack.md`, no test runner available for DOM assembly") — not a convenience call. Do NOT weaken TDD by marking a task `acceptance` or `manual` where the stack can in fact run a unit test; check `03-stack.md`'s test-runner section before defaulting away from `unit`.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Verification:** unit | acceptance | manual
[If acceptance or manual: one line naming the stack constraint that justifies it, e.g. "no test runner in this stack per 03-stack.md — acceptance demo: user does X → Y happens."]

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test** (unit tasks) — or **Step 1: Write the acceptance/manual check** (acceptance/manual tasks)

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes** (unit) — or **run the acceptance demo / manual checklist and record the result** (acceptance/manual)

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```

**If git-write is unavailable in this environment:** execute the task without this step — no `git add`/`git commit` — and record the fact in the task's own execution record (what ran, what passed, and "git step not executed (no-git-write environment)"), the same place progress against this task is otherwise tracked during execution. Never fabricate a commit result. Commit discipline as shown above stays the default whenever git-write IS available; this degradation only applies when it genuinely isn't.
````

**No Placeholders.** Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

### 6. Estimate plan size and recommend a pipeline profile

Once the plan is fully drafted, estimate its size: count the tasks, and get a rough total line count for the plan document. If the plan has **≤ 3 tasks AND a rough total of ≤ ~150 lines**, recommend `pipeline_profile: lite`; otherwise recommend `full`. Write the recommendation to `pipeline_profile` in `docs/spp/pipeline-state.md`.

This step only sizes and records the recommendation — the lite execution protocol itself (what phase 6 actually does differently under `lite`) lives in the orchestrator, `super-puper-powers:using-super-puper-powers`, not here. Do not describe or implement lite-mode execution mechanics in this skill; that's out of scope for plan-writing.

### 7. Self-review — a scan, not a logic check

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch — and it is a **placeholder-and-coverage scan**, not a claim to catch logic defects. Catching real defects (missed requirements that only show up under scrutiny, subtle type mismatches, infeasible steps) is the external `plan-review` subagent's job, run with a genuinely fresh context. Do not rely on this step as a substitute for that external review — in practice, an author's own self-review catches close to zero real defects, because the same context that wrote the plan is checking it.

What this step DOES cover:

1. **Spec coverage:** skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.
2. **Placeholder scan:** search your plan for red flags — any of the patterns from the "No Placeholders" list in step 5 above. Fix them.
3. **Type consistency:** do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.
4. **Verification-type sanity:** does every task marked `acceptance` or `manual` carry a justification tied to the stack, and does `03-stack.md` actually support that claim? A task marked `acceptance` just because it's easier to skip the test is not covered here — that's a defect, not a scan pass.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

### 8. plan-review

After the self-review passes, invoke `super-puper-powers:plan-review`. It dispatches a clean-context subagent that checks the plan against the spec: every requirement mapped to a task, type/signature consistency across tasks, no placeholders from the "No Placeholders" list in step 5, that every step is actually executable (commands exist, paths are real), and that verification-type choices are justified rather than convenient. This is where actual defects get caught — self-review in step 7 does not substitute for it. Fix every Critical and Important finding, then re-invoke plan-review. Repeat until it comes back clean.

### 9. Execution handoff

SPP always executes plans with a fresh subagent per task — there is no alternative execution mode to choose between, so don't offer one. Once plan-review comes back clean, hand off with a task-count estimate and a single go/no-go question:

**"Plan complete and saved to `docs/spp/05-plans/<filename>.md`. `<N>` tasks — start?"**

On confirmation:
- **REQUIRED SUB-SKILL:** Use super-puper-powers:subagent-driven-development
- Fresh subagent per task + two-stage review

## Red Flags

| Thought | Reality |
|---|---|
| "Self-review passed, the plan is logically sound" | Self-review is a placeholder-and-coverage scan, not a logic check — the same context that wrote the plan rarely catches its own gaps or type mismatches. Only the external plan-review subagent, with a genuinely fresh context, is positioned to catch real defects. Don't skip it because self-review looked clean. |
| "This task is annoying to unit-test, I'll mark it acceptance" | `acceptance`/`manual` require a justification tied to the stack (check `03-stack.md`'s test-runner section first), not convenience. Weakening TDD where a unit test is actually possible is exactly the failure mode this field exists to prevent. |
| "The plan is small, I'll skip the size estimate and just start" | The size estimate is a required step — it's what feeds `pipeline_profile` into state for the orchestrator's phase 6 to consume. Skipping it silently defaults everything to full ceremony even when lite would apply. |
| "Lite mode applies, I'll describe the lite execution protocol here" | The lite execution protocol lives in the orchestrator (`using-super-puper-powers`), not in plan-writing. This skill only sizes the plan and records the recommendation. |
| "Git-write isn't available, I'll just say the task was committed" | Never fabricate a commit result. If git-write is unavailable, execute the task without the commit step and record "git step not executed (no-git-write environment)" in the task's own execution record. |
| "Git is available for some tasks but I skipped a commit anyway to save time" | Commit discipline is the default whenever git-write is available — the degradation path only applies when git-write genuinely isn't there, not as a shortcut. |
| "Task N is basically like Task M, I'll just say 'same as Task N'" | "Similar to Task N" is a banned placeholder — the engineer may read tasks out of order and needs the actual code repeated, not a cross-reference. |
| "The spec doesn't say how to handle this edge case, I'll write 'add appropriate error handling'" | That's a plan failure, not a placeholder-safe shorthand. Every step needs the actual content an engineer would need — go back to the spec (or spec-review) if the behavior genuinely isn't defined yet. |
| "The user handed me a spec directly but there's no approved phase 4 in pipeline-state.md, so I can't plan it" | Standalone invocation doesn't require the spec to be pipeline-tracked. Take the spec from wherever the user points, run the same file-mapping, task-writing, self-review, and plan-review rigor, and skip only the pipeline-state bookkeeping — don't block a one-off request on a phase that was never run. |

## Next step

There is no fresh-chat handoff here. Once the plan is written and reviewed, the build
begins in THIS session by design: this skill's final step hands the plan to
`subagent-driven-development`, which executes it task by task. Tell the user the plan
is ready and that execution is starting — plan-writing and the build run continuously
in one session, not as a new chat.
