---
name: mobile-version
description: Use when asked to make an MVP work on phones or check it on a narrow screen - a design-only responsive pass that stops the existing desktop UI from breaking on mobile (overflow, tap targets, forms) without touching the data model, features or scope
---

## Overview

This is a standalone helper skill. It sits outside the SPP pipeline state machine — it does not read or write `docs/spp/pipeline-state.md`, and it is not a numbered phase or a phase checkpoint. It runs whenever asked, triggered by its own description, independent of any pipeline in progress.

Most first views of an MVP happen on a phone, not a wide monitor. Mobile is not a second product and not a separate build — it's the same screen adapted to a narrower width. If text overflows, a form breaks, or a button can't be tapped, the product reads as broken even when the logic underneath works fine.

This skill takes a screen that already works on desktop and makes it hold up on a narrow screen. It does not design a mobile-specific experience and does not introduce new interaction patterns.

## Process

### 1. Check on a narrow screen

Three ways, fastest to most honest:

- **DevTools device mode** — open browser dev tools, toggle device mode, pick a common phone width. Fastest check, start here.
- **Narrow the browser window** — drag the window edge down to a narrow width. Crude but immediately shows where layout breaks.
- **Real phone** — open the dev server over local network, or the public URL after deploy, from an actual phone. The only honest check for tap targets.

### 2. Look for the typical breakage

Check these three first, in this order:

- **Overflow** — a long title or link pushes past the edge and causes horizontal scroll of the whole screen. Horizontal scroll on the page is almost always a bug.
- **Forms and lists** — form fields overlap, list items compress into unreadable mush, status and next-step text stop being legible.
- **Tap targets** — buttons and links that are easy to click with a mouse are too small to hit with a finger.

### 3. Fix with one or two breakpoints

Pick the minimum number of breakpoints needed for the main scenario to hold up narrow — usually one, sometimes two. Don't add more than that for a first pass.

At each breakpoint, fix only what's broken:

- Remove horizontal scroll of the whole screen.
- Make the form and list readable at the narrow width.
- Make buttons and links large enough to hit with a finger.

### 4. Report

Report back:

- Which widths were checked and how (DevTools, window resize, real phone).
- Which breakpoint(s) were introduced.
- What was fixed: overflow, form/list layout, tap targets — one line each.
- Confirmation that the main scenario has no horizontal scroll, a readable form/list, and finger-sized tap targets at the narrow width.

## Scope guard

This is a design-only responsive pass, not a feature or data pass:

- No data model changes.
- No new features, no scope expansion beyond making the existing screen work narrow.
- Touch only layout and styles of the existing screen — don't touch the logic behind it.
- If a fix seems to require a new component, a new interaction pattern, or a decision beyond adjusting the existing layout, stop and flag it instead of building it — that's a separate, explicitly-scoped task.
