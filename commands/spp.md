---
description: Route to a single Super Puper Powers skill, or run the full pipeline with "pipeline"
---

Invoke the `super-puper-powers:using-super-puper-powers` skill (the dispatcher) first.

It runs in two modes:

- **Default — single skill.** If the user named a skill or described a task, the
  dispatcher routes to that one skill, runs it, and stops. No pipeline, no phase
  sequence, no chaining. `docs/spp/pipeline-state.md` is read as memory at most, never
  as a reason to continue a phase.
- **Pipeline — explicit only.** If the invocation includes "pipeline" (`/spp pipeline`,
  "запусти пайплайн", "run the full pipeline"), the dispatcher runs the full 0→9 route
  with its mandatory artifacts, gates, and hand-offs.

Nothing but an explicit "pipeline" request starts the pipeline — not a product idea,
not an existing artifact on disk, not `pipeline-state.md` existing.
