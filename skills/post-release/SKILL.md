---
name: post-release
description: Use when the deploy gate is approved (phase 8 approved in docs/spp/pipeline-state.md) - sets up minimal monitoring and a feedback channel, then closes the loop back into the pipeline
---

## Overview

This is phase 9 of the SPP pipeline — the last one. The product is live and the deploy's must-scenarios are verified. What's left is not more building: it's making sure the owner finds out when something breaks, making sure their users have a way to say what's wrong or what's missing, and making sure that feedback has somewhere to go. This phase doesn't end the relationship between the owner and the product — it ends the pipeline's first pass through it and opens the door back in.

Two things this phase must not do. First, it must not turn "minimal monitoring" into a sales pitch for paid observability tooling — the owner is not a devops team, and a $49/month error-tracking subscription is not "minimal" just because it's popular. Second, it must not write the operations handbook the way an engineer would write a runbook for another engineer — the owner is the one who will read `09-operations.md` at 2am when something is wrong, and jargon at that moment is worse than useless.

The gate that closes this phase is also the terminal state of the whole pipeline's state machine: `current_phase: done`. There is no phase 10, and this skill does not hand off to another skill the way every prior phase did. Instead, it describes the loop — feedback becomes a new idea brief, and a new idea brief restarts the pipeline at `idea-intake` or `mvp-scoping`, whichever fits what the feedback actually is.

## Process

### 0. Confirm the trigger and read state

Read `docs/spp/pipeline-state.md`. This skill applies only when `current_phase: 8` and `phase_status: approved` — the deploy gate passed (`docs/spp/08-deploy-runbook.md` exists and is approved, meaning production is live and its must-scenarios are verified). Read the inputs before doing anything else:

- `deploy_target` from the state file — what the product runs on, which bounds what monitoring is even available.
- `product_type` — what kind of product this is, which shapes what a feedback channel should look like.
- `docs/spp/08-deploy-runbook.md` — how the product is actually deployed, so monitoring proposals match reality instead of a generic template.

On starting work, write `current_phase: 9`, `phase_status: in_progress`.

### 1. Set up minimal monitoring within the deploy strategy

Look at what the chosen `deploy_target` already offers before proposing anything new. Most managed platforms (the kind an owner without a devops budget ends up on) ship a dashboard, basic uptime checks, or log access for free — the job here is to turn those on and point the owner at them, not to introduce a new vendor.

Two things to cover, at minimum:

- **Uptime** — some way to know the product went down. An uptime ping (many free tiers exist, and some platforms include this natively) or, at minimum, telling the owner how to manually check "is it up" in under a minute.
- **Errors** — some way errors surface instead of vanishing into a log nobody reads. This can be as light as "platform X emails you when the process crashes" — it does not have to be a dedicated error-tracking product.

**Do not push a paid service on a non-technical owner.** If the deploy target has no free monitoring option at all, say so plainly and offer the cheapest or free-tier option that exists — never present a paid tool as the default without first checking whether the free path covers it. The specifics depend entirely on `deploy_target`; a `tg-bot` on a free-tier host, a `web` app on a managed platform, and a `package` published to a registry each need a different answer, and none of those answers should default to a subscription.

### 2. Set up a feedback channel by product type

Give the product's users — and the owner — a way to say what's wrong or what's missing. The shape depends on `product_type`:

- **`web`** — a feedback form, or a visible contact email.
- **`tg-bot`** — a bot command (for example `/feedback`) that forwards the message somewhere the owner reads, or a direct contact the bot points users to.
- **`package`** — an issues link (repository issue tracker) or a contact email in the package's own documentation.
- **`mixed`** — pick per component, the same way `deploy-strategy` split its playbook per component.

Pick the lightest mechanism that actually reaches the owner. This does not need infrastructure of its own — a plain email address the owner already checks beats a fancy in-app form the owner forgets exists.

### 3. Describe the feedback loop

State, in the artifact and to the owner, how feedback turns into pipeline work: a piece of feedback becomes a new idea brief, and a new idea brief re-enters the pipeline — at `idea-intake` (phase 0) if it's a new idea or a significant change in direction, or at `mvp-scoping` (phase 2) if it's a new feature request that fits the existing product's discovery and stack decisions and doesn't need to be re-validated from scratch. Which entry point fits is a judgment call made when the feedback actually arrives, not something to pre-decide now — this step just needs to make the mechanism itself explicit so the owner knows what to do with feedback once it shows up.

### 4. Write the artifact

Write `docs/spp/09-operations.md` in `artifacts_language` from the state file. This is the operations handbook — write it for the owner reading it under stress, not for another engineer. Practical incident guidance, not devops jargon: "if the bot goes silent, do A, then B, then message the agent" is the register to aim for, not "check the process supervisor logs for a non-zero exit code."

Cover:

- **What's monitored** — uptime, errors, in plain terms, from step 1.
- **Where to look** — the actual dashboard, email, or command the owner checks, with enough detail to find it without help.
- **What to do when something's wrong** — a short, concrete sequence per likely failure mode (for example: product unreachable → check X → if still down, do Y → if that doesn't fix it, message the agent with Z). Concrete steps the owner can follow, not a diagnosis they'd need engineering judgment to perform.
- **The feedback channel** — where it is and how it reaches the owner, from step 2.
- **The feedback loop** — what happens to feedback once it arrives, from step 3.

### 5. Gate

Ask the owner, in product language only: **"Pipeline complete, the product is live in production — here's your operations handbook. Accept?"** Show them where `09-operations.md` lives and walk through it briefly rather than just linking it — this is the one document they need without an agent present. While the question is outstanding, `phase_status: gate_pending`.

- **On acceptance:** set `phase_status: approved`, log the decision in the Decisions log (date, phase 9, "pipeline complete," who accepted it) — then set `current_phase: done`. This is the pipeline's terminal state; nothing downstream reads past it as an active phase.
- **On requested changes:** if the owner wants the incident steps clarified, the monitoring adjusted, or the feedback channel changed, revise `09-operations.md` (and the actual monitoring or channel setup, if that's what changed) and re-ask. Do not set `current_phase: done` until the gate is actually accepted.

### 6. Hand off — there is no next skill

Do not name a next skill; there isn't one. State plainly instead that the pipeline has finished its first pass, and that new feedback restarts it: a new idea brief goes back through `super-puper-powers:idea-intake` (new idea or a real change in direction) or `super-puper-powers:mvp-scoping` (a new feature fitting the existing product). Do not begin that next cycle yourself in this session unless the owner explicitly asks to start it now — this skill's job ends at a closed loop, not an opened one.

## Red Flags

| Thought | Reality |
|---|---|
| "I'll set them up with a proper paid monitoring stack, free tiers are toys" | The owner is not a devops team and did not budget for a subscription. Check what the `deploy_target` already gives for free first; only mention paid options if no free path exists, and never present them as the default. |
| "I'll write the handbook the way I'd write a runbook for another engineer" | The owner reads this alone, under stress, with no agent present. "Check the process supervisor logs" is useless to them; "if the bot goes silent, do A, then B, then message the agent" is the register this document needs. |
| "Monitoring is the real work here, the feedback channel is an afterthought" | Both are required. A product with perfect uptime alerts and no way for users to say what's broken or missing is still not closing the loop this phase exists to close. |
| "I'll skip stating the feedback loop explicitly, it's obvious that feedback leads to more work" | It's obvious to the agent, not to the owner mid-incident six months from now with no memory of this conversation. The artifact has to say, in writing, that feedback becomes a new idea brief and where that brief re-enters the pipeline. |
| "I'll leave `current_phase` as 9 since the gate is basically done" | The gate isn't done until the owner accepts it, and once they do, `current_phase` must be set to `done` — the pipeline's terminal state. Leaving it at 9 hangs the pipeline in a state nothing downstream recognizes as finished. |
| "I'll pick web-app-style monitoring regardless of product_type, it's the most common case" | The feedback channel and monitoring specifics both depend on what's actually deployed. A `tg-bot` needs a bot command, not a web contact form; a `package` needs an issues link, not an uptime ping. Match the mechanism to `product_type` and `deploy_target`, not to whichever pattern is most familiar. |
