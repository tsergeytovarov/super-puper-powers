---
name: accessibility
description: Use when asked to check or fix basic accessibility (a11y) of an MVP's UI - runs a baseline audit of keyboard navigation, contrast, visible focus, form labels, error clarity and basic screen-reader support, then applies or lists fixes without expanding scope
---

## Overview

This is a standalone helper skill. It sits outside the SPP pipeline state machine — it does not read or write `docs/spp/pipeline-state.md`, and it is not a numbered phase or a phase checkpoint. It runs whenever asked, triggered by its own description, independent of any pipeline in progress.

Minimal accessibility for an MVP is not a compliance exercise. It's basic sanitation: a person must be able to see it, read it, click it, understand its errors, and get through the main scenario without a mouse at a baseline level. Below that bar the product doesn't read as "early" — it reads as neglected.

This skill is not a full WCAG audit. It checks the handful of failures that actually block real use, and either fixes them or lists them — it does not turn into an open-ended design review.

## Checklist

Baseline items to check, one screen or flow at a time:

- **Labels** — every input has a real, visible label, not just a placeholder.
- **Focus** — the active element is visibly highlighted when tabbing through the UI.
- **Contrast** — body text and important UI elements are readable against their background.
- **Keyboard** — the main scenario can be completed with keyboard only, no mouse required.
- **Errors** — errors are described in text next to the field or action they belong to, not just a color change.
- **Color not only signal** — status, error, and success states are distinguishable by more than color alone.
- **Mobile / text overflow** — long text (long names, titles, descriptions) doesn't overflow the screen or cover buttons.
- **Tab order** — the order focus moves in matches the visual order of the screen.
- **Zoom** — the main scenario still works at 200% browser zoom.
- **No hover-only actions** — every important action is reachable without hover.

## Process

### 1. Audit

Walk the target screen or flow and check every item in the Checklist against it:

- Tab through the screen and note where focus disappears or jumps out of visual order.
- Confirm every input has a label, not only a placeholder.
- Trigger a validation error and read it the way a real user would — is there text, or just a red outline?
- Check contrast on body text, buttons, and status indicators.
- Resize to mobile width and check for overflow or covered controls.
- Paste an unusually long value into a title/name-style field and check layout.
- Zoom the browser to 200% and re-check the main scenario.
- Confirm status/error/success are distinguishable without relying on color.

Produce findings only in this step. Don't fix anything yet — mixing audit and fix invites scope creep and makes it easy to miss items.

### 2. Fix or list

For each finding, decide fix now vs. list for later:

- **Fix now** if the change is a minimal, in-scope UI fix: add a label, restore a focus outline, add error text, adjust a color pairing, fix an overflow.
- **List, don't fix** if it needs a larger redesign, a new component, or a decision outside this pass's scope (see Scope guard). Record it instead of touching it.

Keep fixes minimal. Don't restyle beyond what the specific finding requires.

### 3. Report

Report back:

- What was checked (which checklist items, on which screen/flow).
- What was fixed, with a one-line description of each fix.
- What was found but not fixed, and why (out of scope, needs a bigger decision, needs design input).

## Scope guard

This is a design/UI-polish pass, not a feature or architecture pass:

- No new features, no new components, no new dependencies.
- No visual redesign beyond what a specific finding requires (e.g. don't restyle a whole screen because one contrast pair failed).
- No screen-reader-specific ARIA rework beyond what's needed for the baseline items above — a deeper screen-reader pass is a separate, explicitly-scoped task.
- If the number of findings is large enough that fixing all of them would itself be a big change, stop and list them instead of pushing through — flag it back to whoever asked for the audit rather than silently expanding scope.
