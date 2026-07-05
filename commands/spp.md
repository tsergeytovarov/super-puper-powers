---
description: Start or resume the Super Puper Powers pipeline
---

Read `docs/spp/pipeline-state.md`.

- If it exists: announce "Pipeline on phase N, continuing with <skill>" and continue
  from `current_phase` according to the state machine in the
  super-puper-powers:using-super-puper-powers skill (invoke it via the Skill tool first).
- If it does not exist: tell the user this project has no SPP pipeline yet and offer
  to start phase 0 by invoking the super-puper-powers:idea-intake skill. Ask them to
  describe the product idea in a couple of sentences.

Takes no arguments in v0.1.
