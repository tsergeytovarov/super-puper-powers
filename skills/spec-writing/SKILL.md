---
name: spec-writing
description: Use when stack is approved (phase 3 approved in docs/spp/pipeline-state.md) and specs are not yet written - designs the product through product-behavior questions only and writes implementation specs to docs/spp/04-specs/
---

> Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT.
> Modifications: reworked from the upstream design-dialogue skill; input is approved MVP scope and stack; user questions restricted to product behavior; visual companion offer removed; terminal transition replaced with SPP review chain; design-presentation-to-user step removed; cross-plugin reference dropped; body restructured to the fixed Overview/Process/Red Flags skeleton; added a mandatory domain decisions checklist the author fills before self-review; reframed self-review as a placeholder-and-coverage scan rather than a logic-catching step; added explicit git-write degradation for the design-doc commit

<HARD-GATE>
Do NOT invoke any implementation skill (including plan-writing), write any code, scaffold any project, or take any implementation action until the user has approved the product-behavior summary (docs/spp/04-specs/summary-for-review.md). The user approves product behavior — scenarios, UX, copy — never architecture or design internals. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue. Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, confirm the product behavior with the user and write the spec.

**Every project goes through this process** — a todo list, a single-function utility, a config change, all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST still confirm the product behavior with the user and get their approval on the summary. "This is too simple to need a design" is never a reason to skip it.

**Two audiences, kept apart.** What you check with the USER is product behavior only: scenarios, UX, screens/commands, copy/text, what happens on typical errors from the user's point of view. Architecture, components, data flow, data schema, and internal error handling are the AGENT's to decide — you document them in the spec with a justification, you do NOT hand them to the user for per-section sign-off (the user is assumed not to be a developer; an approval they cannot evaluate is meaningless).

**Key principles:** one question at a time; multiple choice preferred over open-ended when possible; YAGNI ruthlessly — remove unnecessary features from every design; always propose 2-3 approaches before settling; validate product behavior incrementally rather than all at once at the end; be flexible — go back and clarify when something doesn't make sense.

**The terminal state is invoking `super-puper-powers:plan-writing`.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after spec-writing is plan-writing.

## Process

You MUST create a task for each of the numbered steps below and complete them in order.

### 1. Explore project context

Read `docs/spp/pipeline-state.md`, `docs/spp/02-mvp-scope.md`, and `docs/spp/03-stack.md` before asking anything, plus relevant project files/docs/recent commits. These carry the approved scope, scenarios, and stack — do not re-ask what they already answer.

### 2. Ask clarifying questions (product behavior only)

- User questions are restricted to product behavior only: UX, copy/text, and scenario edge-cases (what happens when the user does something unexpected). Never ask the user about architecture, data schema, or error handling — decide those yourself and record the decision in the spec with a justification (per the SPP principle that technical decisions are the agent's to make and document, not the user's to be asked).
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea. Prefer multiple choice questions when possible, but open-ended is fine too. Only one question per message — if a topic needs more exploration, break it into multiple questions.
- Focus on understanding: product behavior, constraints already fixed by the MVP scope and stack, success criteria.

### 3. Propose 2-3 approaches

Propose 2-3 different approaches with trade-offs. Present options conversationally with your recommendation and reasoning. Lead with your recommended option and explain why.

### 4. Work out the design (confirm behavior with the user)

- Once you believe you understand what you're building, work out the design. Walk the user through product behavior in plain language and confirm it as you go — this is where the design dialogue lives.
- Document architecture, components, data flow, data schema, and internal error handling in the spec yourself, with a justification. Scale each part to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced.
- **Design for isolation and clarity:** break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently. For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on? Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work. Smaller, well-bounded units are also easier for you to work with — you reason better about code you can hold in context at once, and your edits are more reliable when files are focused.
- **Working in existing codebases:** explore the current structure before proposing changes, follow existing patterns. Where existing code has problems that affect the work (a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design — the way a good developer improves code they're working in. Don't propose unrelated refactoring; stay focused on what serves the current goal.
- Be ready to go back and clarify if something doesn't make sense. Repeat this step until product behavior is confirmed.

### 5. Fill in the domain decisions checklist

Before writing the design doc, and again before self-review, explicitly fill in every axis below that applies to this spec. This is exactly what spec-review otherwise spends 5-6 rounds catching — front-loading it here means the author, not the external reviewer, makes these calls the first time:

- **Money** — exact display format, rounding rule, and decimal/thousands separator for every amount shown to the user.
- **Lists** — sort order (and tie-break) and what the empty state looks like, in copy, not just "empty list."
- **User input** — parsing rule and validation rule for every field that accepts input, including what happens on invalid input.
- **Floating-point values** — the invariant that must hold in integer terms (e.g. cents, not dollars) so rounding and comparison behave predictably.
- **State texts** — the exact copy for every branch of every stateful flow: success, error, and empty, word for word, not "show an error message."

An axis that doesn't apply to this spec (e.g. no money involved) is skipped, not silently omitted — say so in the spec so a reviewer doesn't have to guess whether it was considered. Record the filled-in checklist in the design doc itself, next to or inside the relevant sections — it's a required part of the spec, not a side artifact.

### 6. Write the design doc

- Write the validated design (spec) to `docs/spp/04-specs/YYYY-MM-DD-<topic>-design.md` (user preferences for spec location override this default). Write clearly and concisely.
- Commit the design document to git. **If git-write is unavailable in this environment:** work on the file on disk as normal, and record a note in the design doc — "git step not executed (no-git-write environment)" — instead of a commit. Never fabricate a commit result. This commit is best-effort, not a blocking step of this phase; if it can't happen now, it can happen later (e.g. at release-fixation) — do not stall the phase on it.

### 7. Spec self-review — a scan, not a logic check

After writing the spec document, look at it with fresh eyes. This step is a **placeholder-and-coverage scan**, not a claim to catch logic defects — catching contradictions, infeasibility, and subtle logic errors is the external `spec-review` subagent's job, run with a genuinely fresh context. Do not treat this step as a substitute for that external review; in practice it catches near-zero real logic defects precisely because the same context that wrote the spec is checking it.

What this step DOES cover:

1. **Placeholder scan:** any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Domain checklist coverage:** does every applicable axis from step 5 have an explicit, recorded decision in the spec? Anything missing, go fill it in now — don't let self-review pass with a gap that step 5 should have closed.
3. **Completeness vs. must-scenarios:** does the spec cover every must-have scenario from `02-mvp-scope.md`? List any gaps and fix them.
4. **Internal consistency (surface-level):** do any sections obviously contradict each other, e.g. the architecture section not matching a feature description? Fix what you can see; don't spend effort hunting for subtle logic issues — that's spec-review's job next.
5. **Scope check:** is this focused enough for a single implementation plan, or does it need decomposition?
6. **Ambiguity check (surface-level):** could a requirement be read two different ways at a glance? If so, pick one and make it explicit.

Fix any issues inline. No need to re-review — just fix and move on.

### 8. spec-review

After the self-review passes, invoke `super-puper-powers:spec-review`. It dispatches a clean-context subagent that checks the spec against the MVP scope: every must-scenario covered, no contradictions, no ambiguity (an interpretation that could go two ways is a defect), nothing infeasible on the chosen stack, no placeholders. This is where actual logic defects get caught — self-review in step 7 does not substitute for it. Fix every Critical and Important finding, then re-invoke spec-review. Repeat until it comes back clean.

### 9. cross-spec-review (if more than one spec)

If the project decomposed into more than one spec, invoke `super-puper-powers:cross-spec-review` once every spec has passed its own spec-review. It checks interface consistency across sub-projects, seam gaps, contradictions, and build order. Fix Critical and Important findings, re-invoke, repeat until clean. It also records the recommended sub-project build order (`subproject_order`) for plan-writing and phase 6 to consume — don't skip it if there's more than one spec.

### 10. Write and get approval on the product summary

Once spec-review (and cross-spec-review, if applicable) passes clean, write `docs/spp/04-specs/summary-for-review.md` in product language, not spec language:

- Scenarios as "user does X → Y happens"
- Screens or commands described in words, not diagrams or code
- What happens on typical errors

Then ask the user to approve the summary — not the full spec:

> "Here's what the product will do: `<path to summary-for-review.md>`. Take a look and let me know if this matches what you want before we move to planning. You don't need to read the full spec — the summary covers what matters to you."

Wait for the user's response. If they request changes, make them in the spec, re-run spec-review (and cross-spec-review) as needed, update the summary, and ask again. Only proceed once the user approves the summary.

### 11. Transition to implementation

Invoke `super-puper-powers:plan-writing` to create a detailed implementation plan. Do NOT invoke any other skill — plan-writing is the next step.

## Red Flags

| Thought | Reality |
|---|---|
| "This is too simple to need a design" | Every project goes through this process. Simple projects are exactly where unexamined assumptions waste the most work later. |
| "I'll ask the user about the data schema / error handling so they feel involved" | Architecture, schema, and internal error handling are the agent's to decide and document with a justification — an approval the user can't evaluate is meaningless, and it burns a question slot that should go to product behavior. |
| "Money/rounding/sorting isn't explicitly asked for, I'll leave it implicit" | That's exactly what the domain decisions checklist (step 5) exists to force explicit — an implicit format is what spec-review otherwise spends 5-6 rounds dragging out of the spec. |
| "Self-review passed, the spec is logically sound" | Self-review is a placeholder-and-coverage scan, not a logic check — the same context that wrote the spec rarely catches its own contradictions. Only the external spec-review subagent, with a genuinely fresh context, is positioned to catch real logic defects. Don't skip it because self-review looked clean. |
| "Git-write isn't available, I'll just say the design doc is committed" | Never fabricate a git result. If git-write is unavailable, record "git step not executed (no-git-write environment)" in the design doc and move on — the commit is best-effort here, not a blocking step. |
| "The commit failed, I should stop and fix the git environment before continuing" | Committing the design doc is not a blocking step of this phase. Record the note and continue; the commit can happen later (e.g. at release-fixation) if git-write becomes available. |
| "The user is technical, I'll show them the architecture section for sign-off" | Gates in this phase are product behavior only, regardless of the user's technical background — architecture sign-off from someone not building the thing is meaningless approval theater. |
| "I'll present the whole spec for approval, it's more thorough than a summary" | The user approves `summary-for-review.md` in product language, not the full spec. Asking them to read spec language defeats the purpose of the summary gate. |
