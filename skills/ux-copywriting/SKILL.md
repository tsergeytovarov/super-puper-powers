---
name: ux-copywriting
description: Use when asked to write or improve UI text or microcopy - produces interface copy and states (empty, error, loading) from screen context, state and user action, scoped to the current scenario
---

## Overview

This is a standalone helper skill. It sits outside the SPP pipeline state machine — it does not read or write `docs/spp/pipeline-state.md`, and it is not a numbered phase or a phase checkpoint. It runs whenever asked, triggered by its own description, independent of any pipeline in progress.

UI text only works with context. "Write nice copy for the product" produces marketing filler — "unlock your dream career", "reach new heights". A working screen doesn't need that; a user landed there to finish a task, understand a status, or see why something failed. This skill asks for the screen, the state, and the user's action first, and writes text that answers that specific situation.

## Inputs

Before writing any copy, gather:

- **Screen context** — what screen or flow this is, what the user is trying to do there.
- **State** — which state the text belongs to: empty, error, success, loading, warning before a destructive action, field hint, validation, confirmation, disabled, tooltip.
- **User action** — what the user just did or is about to do (submit a form, delete an item, wait for a save, open an empty list for the first time).

If any of the three is missing, ask for it rather than guessing — a plausible-sounding generic text is worse than no text.

## Process

### 1. Confirm the state set

List which states actually apply to this screen. Not every screen needs every state — a synchronous local-storage save has no meaningful loading state; a read-only view has no destructive-action warning. Don't invent states nothing in the scenario needs.

### 2. Write copy per state

For each state that applies, write text that:

- Names what happened or what's here, in concrete terms — not "success!", but what changed.
- For errors: says what failed and what to do next. A screen-level error ("Couldn't save the job listing. Check the required fields.") is not the same as a field-level error ("Job title is required.") — keep them separate, don't collapse one into the other.
- For empty states: says what will appear here and the first action to take.
- For loading: says what's currently happening, only where an actual wait exists.
- For warnings before a destructive action: names the concrete consequence (what gets deleted or changed), not just "are you sure?".
- Stays short enough for the space it renders in — a tooltip is not a paragraph.
- Never reaches for landing-page language ("unlock", "empower", "your journey starts here") in a working interface.

### 3. Check against the anti-patterns

Reject and rewrite any candidate that:

- Is a marketing slogan disguised as UI text.
- States an outcome without naming what changed ("Success!", "Something went wrong").
- Gives an error without a next step.
- Repeats the field label back as its own hint.

## Scope guard

This is a copy pass for the current scenario, not a content or IA project:

- Write copy only for the screen, state, and action given — don't extend to adjacent screens or flows not asked about.
- Don't invent new screens, new states, or new UI elements to hold the copy. If a state needs a component that doesn't exist yet, say so and stop — that's a design/build decision, not a copy decision.
- Don't restructure existing copy elsewhere in the product "while you're at it." Flag inconsistencies you notice, but fix only what was asked.
