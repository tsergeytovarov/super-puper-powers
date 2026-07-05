---
name: stack-selection
description: Use when MVP scope is approved (phase 2 approved in docs/spp/pipeline-state.md) - picks the tech stack from 2-3 options judged by agent maintainability, running cost and time to MVP, explained in owner consequences
---

## Overview

This is phase 3 of the SPP pipeline — the last phase before spec-writing. The MVP scope is approved; before any spec gets written, this skill picks what the product is actually built with.

The stack is chosen explicitly, here, once — not implicitly during design, not re-litigated later. Two people live with this decision and neither is a traditional developer's peer group: the agent has to write and maintain the code for years of iteration, and the owner has to pay for it and keep it running without engineering help. That's why agent maintainability outranks raw technical flexibility in the criteria below — a stack the agent handles fluently, with a large corpus of examples to draw on, produces fewer bugs and faster fixes than a stack that's more elegant on paper but exotic in practice. The owner never sees that trade-off in those terms, though: the gate presents options as cost, update effort, and time to a working product, because those are the only terms a non-developer can actually evaluate.

## Process

### 0. Confirm the trigger and read state

Read `docs/spp/pipeline-state.md`. This skill applies only when `current_phase: 2` and `phase_status: approved` — the MVP scope is confirmed. Read the inputs before doing anything else:

- `docs/spp/02-mvp-scope.md` — the walking skeleton and must-have scenarios; the stack has to actually run these.
- `docs/spp/00-idea-brief.md` — budget, timeline, and jurisdiction constraints from the original brief.

On starting work, write `current_phase: 3`, `phase_status: in_progress`.

### 1. Determine the product type

Classify the product as one of `web`, `package`, `tg-bot`, or `mixed`, based on the walking skeleton in the MVP scope — how does the user actually reach the product (browser, install command, chat client), and does the scenario span more than one of those. Write the answer to `product_type` in the state file. This isn't a question to the user; it's a read of what the approved scope already implies.

### 2. Propose 2-3 stack options

Draft two or three candidate stacks that could deliver the walking skeleton. Judge every candidate against these criteria, in this priority order — a candidate that wins on a lower-priority criterion never beats one that wins on a higher-priority one:

1. **Agent maintainability** — mainstream, with a large corpus of examples and prior art, beats exotic. The agent is the one writing and fixing this code for the life of the product; a mainstream choice means more correct code on the first try and faster fixes when something breaks. This is the top criterion, deliberately ranked above raw flexibility.
2. **Cost and simplicity of operation** — hosting $/month, whether a free tier covers the MVP, how much ritual an update requires.
3. **Speed to MVP** — how fast this candidate gets the walking skeleton actually running.
4. **Compatibility with realistic deploy options** — don't pick a stack that locks the product into expensive or narrow infrastructure later; check it against the deploy approaches phase 8 (`deploy-strategy`) will realistically offer for this `product_type`.

### 3. Phrase every trade-off in owner consequences

For each candidate, and for the comparison between candidates, state the trade-off in terms of what the owner experiences — not what the technology is. Technical terms are allowed, but every one of them must carry a consequence a non-developer can feel: a price, an action they'd have to take, a thing that would break.

For example: "option A: free hosting, update with one command; option B: more flexible, but costs about $20/month and updates need a short manual step." Not: "option A uses a serverless architecture; option B uses a traditional VPS."

If a candidate is exotic or clever from a technical standpoint but wins mainly on flexibility, say plainly what that flexibility would cost the owner in practice (slower agent fixes, a smaller community to draw fixes from) — don't let a technical strength stand in for an owner-facing one.

### 4. Write the artifact

Write `docs/spp/03-stack.md` with:

- The `product_type` determination and the reasoning behind it.
- Each candidate stack, with its trade-offs stated in owner consequences per step 3.
- The chosen stack, clearly marked, with the reasoning that leads to it against the four criteria in priority order.
- The rejected options, each with the specific reason it lost — not just "not chosen," but which criterion it lost on and why that mattered more than what it won on.

### 5. Gate

Present the options to the user in owner-consequence terms — cost, update effort, time to a working product — and ask them to pick one. This is a business decision about money and maintenance, not a technical one: no architecture, no framework comparison on its own technical merits, no diff. The user picks based on what they'd pay and what they'd have to do, never on jargon alone. While the question is outstanding, `phase_status: gate_pending`.

- **On a pick:** write the chosen stack to `stack` in the state file, set `phase_status: approved`, log the decision in the Decisions log (date, phase 3, the chosen stack, who picked it).
- **On requested changes:** if the user wants a trade-off explained differently or a criterion weighed differently, revise the options and re-ask. If the request implies a candidate outside what was proposed, evaluate it against the same four criteria before adding it.

### 6. Hand off

State the next step explicitly: **"Next: the `super-puper-powers:spec-writing` skill."** Do not start spec work yourself — this skill's job ends at a chosen, recorded stack.

## Red Flags

| Thought | Reality |
|---|---|
| "This exotic framework is technically the best fit, I'll recommend it" | Agent maintainability is the top-ranked criterion, above raw flexibility, precisely because the agent — not a human team — writes and fixes this code long-term. A mainstream stack with a large corpus of examples beats a cleverer exotic one even when the exotic one wins on paper. |
| "I'll describe option A as 'serverless with edge functions' and option B as 'a traditional VPS setup'" | Every trade-off must be phrased in owner consequences — price, update effort, what breaks — not tech properties. Technical terms are allowed but each one needs a consequence attached; a framework name alone tells a non-developer nothing they can decide on. |
| "The chosen stack is obvious, I don't need to write up what I rejected" | The artifact requires the rejected options with reasons, not just the winner. Without it, the decision is unreviewable later and the next person (or a future re-evaluation) can't tell whether an alternative was actually considered or just skipped. |
| "This stack is cheap to start with, that's enough — I don't need to check where it deploys" | Criterion 4 exists because a stack can look fine at MVP size and still lock the product into a narrow or expensive deploy path once it needs to scale or move. Check compatibility with realistic deploy options now, not after phase 8 discovers the trap. |
| "I'll let the user choose between the frameworks by name and let them ask if they want details" | The gate must present consequences up front — cost, update effort, time to MVP — not names the user then has to interrogate. A gate that requires the user to ask "what does that mean for me" has already failed at being product-language. |
| "Two options is basically the same as three, I'll just present the one I'd pick plus a strawman" | The process calls for genuine 2-3 candidates evaluated on the same criteria, not a preferred pick and a deliberately weak foil. A strawman option isn't a real trade-off and gives the user a false choice. |
