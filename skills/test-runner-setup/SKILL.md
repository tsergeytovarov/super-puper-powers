---
name: test-runner-setup
description: Use when asked to set up tests or a test runner for a project that has none - installs a test runner and one smoke test so behavior checks become a command, without requiring full coverage
---

## Overview

This is a standalone helper skill. It sits outside the SPP pipeline state machine — it does not read or write `docs/spp/pipeline-state.md`, and it is not a numbered phase or a phase checkpoint. It runs whenever asked, triggered by its own description, independent of any pipeline in progress.

A project with no test runner has exactly one way to check behavior: read the code, run it by hand, and trust your own eyes. That's a real fallback, but it doesn't scale — every check has to be repeated by hand, and it's easy to skip "just this once." This skill closes that gap by turning "checked the behavior" into a command: install a runner, add one smoke test, get it green.

This feeds the TDD phase directly. Once a runner exists and one test passes, "behavior check" for the next slice can be an automated test instead of a documented manual walkthrough. That's the whole point — not full coverage, a working command.

## Process

### 1. Pick a runner for the stack

Check what's already in the project first — if a test runner is already a dependency, use it, don't add a second one.

If nothing is installed, pick the standard runner for the stack:

- JS/TS project (static frontend, Next.js, SPA + BaaS) — Vitest or Jest. Vitest is usually the faster path for a new project; some templates already ship with Jest wired in.
- Other stacks — use that ecosystem's standard runner (e.g. `pytest` for Python). Don't improvise a custom test harness when a standard one exists.

Versions and install commands drift — check the runner's current docs before installing rather than assuming last year's flags still apply.

### 2. Install

Add the runner as a dev dependency and wire up the run script so the project's standard test command (e.g. `npm test`) invokes it. Don't add configuration beyond what's needed to make that command work.

### 3. Add one smoke test

Write exactly one test — something trivial and fast, like a basic assertion or a render of the main component. Its only job is to prove the runner is wired correctly, not to validate application logic.

### 4. Run it

Run the project's test command and confirm a real green result — not "should pass," an actual passing output. A skipped test does not count as done.

If the run fails on runner configuration rather than on the test itself, fix only the configuration. Don't add more tests while chasing a setup problem.

## Scope guard

The deliverable is a working test runner plus one passing smoke test — nothing more:

- No coverage targets, no testing the rest of the app.
- No second runner if one already exists in the project.
- No test pyramid, no e2e/integration harness — that's a separate, explicitly-scoped task.
- If the runner can't be wired up cleanly right now (e.g. the project has no build shape yet), stop and say so rather than forcing an install — a documented manual check is a legitimate fallback until the project has enough shape for tests to be worth the setup cost.
