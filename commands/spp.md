---
description: Start or route the Super Puper Powers skills
---

Invoke the `super-puper-powers:using-super-puper-powers` skill (the dispatcher) first.

- If the user named a skill or task, the dispatcher routes to it directly — no
  pipeline position required.
- If `docs/spp/pipeline-state.md` exists, the dispatcher reads it as memory and
  reminds the user where they left off, without forcing the next phase.
- If the user is describing a fresh product idea and no journal exists, offer to
  start at phase 0 with `idea-intake`.

The route 0→9 is a recommendation, not an enforced sequence. Any skill is callable
at any time.
