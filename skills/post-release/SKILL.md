---
name: post-release
description: Use when a product is deployed or about to be, OR when the user directly asks to set up monitoring or a feedback channel after release - sets up minimal monitoring and a feedback channel, then closes the loop back to new ideas.
---

## Overview

This is phase 9 of the SPP pipeline — the last one, but it can also be invoked standalone whenever a product is deployed or the user asks to set up monitoring or a feedback channel. Ordinarily the product is live and the deploy's must-scenarios are verified, and what's left is not more building: it's making sure the owner finds out when something breaks, making sure their users have a way to say what's wrong or what's missing, and making sure that feedback has somewhere to go. This phase doesn't end the relationship between the owner and the product — it ends the pipeline's first pass through it and opens the door back in.

That's the `deploy_status: executed` case. When phase 8 closed with `deploy_status: deferred` instead, none of that has happened yet — there is no live product, no production must-scenarios verified, nothing currently running for anyone to monitor. This phase still runs, but everything in it shifts tense: monitoring and the feedback channel get written as instructions for when the owner deploys, not descriptions of a running system. Treating a deferred deploy as if it were live — writing "the product is monitored at X" when X doesn't exist yet — is the exact dishonesty the pipeline's verification discipline exists to prevent, just relocated to phase 9.

Two things this phase must not do. First, it must not turn "minimal monitoring" into a sales pitch for paid observability tooling — the owner is not a devops team, and a $49/month error-tracking subscription is not "minimal" just because it's popular. Second, it must not write the operations handbook the way an engineer would write a runbook for another engineer — the owner is the one who will read `09-operations.md` at 2am when something is wrong, and jargon at that moment is worse than useless.

When a pipeline journal exists, the gate that closes this phase writes the journal's final entry: `current_phase: done`. There is no phase 10, and this skill does not hand off to another skill the way every prior phase did — see `## Next step` at the end of this document for what to tell the owner instead.

## Process

### 0. Confirm the trigger and read available context

This skill runs whenever a product is deployed or about to be, or the user directly asks to set up monitoring or a feedback channel after release — no pipeline state is required to start. What "the deploy gate passed" means depends on `deploy_status`, when known: `executed` means production is live and its must-scenarios are verified; `deferred` means the strategy and runbook are approved but nothing is deployed yet. Gather the inputs before doing anything else:

- **`deploy_status`** — `executed` or `deferred`. If `docs/spp/pipeline-state.md` exists, read it from there; otherwise ask the owner or infer it from context. This decides the tense of everything this skill writes: settle it first, before drafting anything.
- `deploy_target` — what the product runs on (or will run on), which bounds what monitoring is even available. From the state file if it exists, otherwise from the owner.
- `product_type` — what kind of product this is, which shapes what a feedback channel should look like.
- `docs/spp/08-deploy-runbook.md` — how the product is actually deployed (or will be), so monitoring proposals match reality instead of a generic template. Use it if it exists; if there is no such runbook (standalone invocation with no prior pipeline run), work from what the owner tells you about the deploy instead.

If `docs/spp/pipeline-state.md` exists, on starting work write `current_phase: 9`, `phase_status: in_progress`. If it doesn't exist, skip this — there is no pipeline journal to update.

### 1. Set up minimal monitoring within the deploy strategy

**If `deploy_status: executed`**, set this up now, live. Look at what the chosen `deploy_target` already offers before proposing anything new. Most managed platforms (the kind an owner without a devops budget ends up on) ship a dashboard, basic uptime checks, or log access for free — the job here is to turn those on and point the owner at them, not to introduce a new vendor.

Two things to cover, at minimum:

- **Uptime** — some way to know the product went down. An uptime ping (many free tiers exist, and some platforms include this natively) or, at minimum, telling the owner how to manually check "is it up" in under a minute.
- **Errors** — some way errors surface instead of vanishing into a log nobody reads. This can be as light as "platform X emails you when the process crashes" — it does not have to be a dedicated error-tracking product.

**Do not push a paid service on a non-technical owner.** If the deploy target has no free monitoring option at all, say so plainly and offer the cheapest or free-tier option that exists — never present a paid tool as the default without first checking whether the free path covers it. The specifics depend entirely on `deploy_target`; a `tg-bot` on a free-tier host, a `web` app on a managed platform, and a `package` published to a registry each need a different answer, and none of those answers should default to a subscription.

**For a `web` product that's static** (no backend, no server-side code that can throw a runtime error) — monitoring degrades to just two things: the deploy status the hosting platform already reports (did the last publish succeed) and, optionally, a free uptime ping. There is no server-errors channel to set up, because there's no server producing errors — this isn't an oversight to apologize for or work around, it's a correct consequence of the architecture. Don't invent an error-monitoring story for a product that structurally can't produce the errors it would monitor.

**If `deploy_status: deferred`**, there is nothing live to monitor yet. Do not set anything up now. Instead, write the monitoring section of the artifact (step 4) as setup instructions the owner follows at the moment they actually deploy — which dashboard to check, which free tier to enable, phrased as "when you deploy, do X" rather than "X is running."

### 2. Set up a feedback channel by product type

**If `deploy_status: executed`**, set this up now. Give the product's users — and the owner — a way to say what's wrong or what's missing. The shape depends on `product_type`:

- **`web`** — a feedback form, or a visible contact email.
- **`tg-bot`** — a bot command (for example `/feedback`) that forwards the message somewhere the owner reads, or a direct contact the bot points users to.
- **`package`** — an issues link (repository issue tracker) or a contact email in the package's own documentation.
- **`mixed`** — pick per component, the same way `deploy-strategy` split its playbook per component.

Pick the lightest mechanism that actually reaches the owner. This does not need infrastructure of its own — a plain email address the owner already checks beats a fancy in-app form the owner forgets exists.

**If `deploy_status: deferred`**, most of these mechanisms depend on the product actually running (a bot command needs a running bot; an in-app form needs a deployed app) — write the same product-type mapping above into the artifact as setup-at-deploy-time instructions rather than configuring anything now. The one exception: a plain contact email the owner already has doesn't depend on deployment at all and can be named as the feedback channel immediately if the owner wants one in place from day one — but don't invent infrastructure-dependent mechanisms to set up early just to avoid saying "later."

### 3. Describe the feedback loop

State, in the artifact and to the owner, how feedback turns into pipeline work: a piece of feedback becomes a new idea brief, and a new idea brief re-enters the pipeline — at `idea-intake` (phase 0) if it's a new idea or a significant change in direction, or at `mvp-scoping` (phase 2) if it's a new feature request that fits the existing product's discovery and stack decisions and doesn't need to be re-validated from scratch. Which entry point fits is a judgment call made when the feedback actually arrives, not something to pre-decide now — this step just needs to make the mechanism itself explicit so the owner knows what to do with feedback once it shows up.

### 4. Write the artifact

Write `docs/spp/09-operations.md` in `artifacts_language` from the state file. This is the operations handbook — write it for the owner reading it under stress, not for another engineer. Practical incident guidance, not devops jargon: "if the bot goes silent, do A, then B, then message the agent" is the register to aim for, not "check the process supervisor logs for a non-zero exit code."

**If `deploy_status: executed`**, cover the product as a running thing:

- **What's monitored** — uptime, errors, in plain terms, from step 1.
- **Where to look** — the actual dashboard, email, or command the owner checks, with enough detail to find it without help.
- **What to do when something's wrong** — a short, concrete sequence per likely failure mode (for example: product unreachable → check X → if still down, do Y → if that doesn't fix it, message the agent with Z). Concrete steps the owner can follow, not a diagnosis they'd need engineering judgment to perform.
- **The feedback channel** — where it is and how it reaches the owner, from step 2.
- **The feedback loop** — what happens to feedback once it arrives, from step 3.

**If `deploy_status: deferred`**, title the document's opening line something like "when you deploy" so the owner immediately understands the register — this is not a description of a running system, it's instructions for a future moment:

- **What you'll monitor, once live** — the same uptime/errors content from step 1, phrased as setup steps to perform at deploy time, not things currently happening.
- **Where you'll look, once live** — the dashboard, email, or command, with enough detail that the owner (or a future agent) can find it without re-deriving the deploy-strategy decision from scratch.
- **What to do when something's wrong, once live** — the same concrete-sequence format as `executed`, still written for the future moment.
- **The feedback channel, once live** (or now, for the email exception from step 2) — from step 2.
- **The feedback loop** — from step 3; this part doesn't depend on deploy status and reads the same either way.
- **A plain statement that the product is not currently live** — do not let the rest of the document's instructional tone leave that ambiguous. State it once, clearly, near the top.

### 5. Gate

The question depends on `deploy_status`:

**If `executed`:** ask the owner, in product language only: **"Pipeline complete, the product is live in production — here's your operations handbook. Accept?"**

**If `deferred`:** ask instead: **"Pipeline complete, the deploy strategy is locked in and documented — here's your handbook for when you deploy. Accept?"** Do not say "the product is live" here — it isn't.

Either way, show them where `09-operations.md` lives and walk through it briefly rather than just linking it — this is the one document they need without an agent present. While the question is outstanding, `phase_status: gate_pending`.

- **On acceptance:** if `docs/spp/pipeline-state.md` exists, set `phase_status: approved`, log the decision in the Decisions log (date, phase 9, "pipeline complete," the `deploy_status` at closure, who accepted it) — then set `current_phase: done`. This is the pipeline's terminal state; nothing downstream reads past it as an active phase, regardless of whether the underlying product is live or the deploy is still pending. If there is no pipeline journal (standalone invocation), there is nothing to update — proceed straight to the next step below.
- **On requested changes:** if the owner wants the incident steps clarified, the monitoring adjusted, or the feedback channel changed, revise `09-operations.md` (and the actual monitoring or channel setup, if that's what changed and `deploy_status` is `executed`) and re-ask. If a pipeline journal exists, do not set `current_phase: done` until the gate is actually accepted.

### 6. Hand off

See `## Next step` at the end of this document for what to tell the owner once the gate is accepted.

## Red Flags

| Thought | Reality |
|---|---|
| "I'll set them up with a proper paid monitoring stack, free tiers are toys" | The owner is not a devops team and did not budget for a subscription. Check what the `deploy_target` already gives for free first; only mention paid options if no free path exists, and never present them as the default. |
| "I'll write the handbook the way I'd write a runbook for another engineer" | The owner reads this alone, under stress, with no agent present. "Check the process supervisor logs" is useless to them; "if the bot goes silent, do A, then B, then message the agent" is the register this document needs. |
| "Monitoring is the real work here, the feedback channel is an afterthought" | Both are required. A product with perfect uptime alerts and no way for users to say what's broken or missing is still not closing the loop this phase exists to close. |
| "I'll skip stating the feedback loop explicitly, it's obvious that feedback leads to more work" | It's obvious to the agent, not to the owner mid-incident six months from now with no memory of this conversation. The artifact has to say, in writing, that feedback becomes a new idea brief and where that brief re-enters the pipeline. |
| "I'll leave `current_phase` as 9 since the gate is basically done" | The gate isn't done until the owner accepts it, and once they do, `current_phase` must be set to `done` — the pipeline's terminal state. Leaving it at 9 hangs the pipeline in a state nothing downstream recognizes as finished. |
| "I'll pick web-app-style monitoring regardless of product_type, it's the most common case" | The feedback channel and monitoring specifics both depend on what's actually deployed. A `tg-bot` needs a bot command, not a web contact form; a `package` needs an issues link, not an uptime ping. Match the mechanism to `product_type` and `deploy_target`, not to whichever pattern is most familiar. |
| "`deploy_status` is deferred, but I'll still say 'the product is live' at the gate to make the pipeline feel finished" | It isn't live, and saying so is a false claim about production — the exact thing the pipeline's verification discipline forbids everywhere else. Deferred gets its own gate question that says "when you deploy," never "is live." |
| "I'll set up real monitoring now even though deploy is deferred, so it's ready to go" | There's nothing live to monitor — configuring a dashboard against a deployment that doesn't exist yet either fails outright or silently monitors the wrong thing. Write it as setup-at-deploy-time instructions instead; don't perform the setup early. |
| "It's a static site, I'll add an error-tracking service anyway just to be thorough" | A static `web` product with no backend can't produce server errors — inventing an error-monitoring channel for it isn't thoroughness, it's fabricating a problem the architecture doesn't have. Monitoring degrades to deploy-status plus an optional uptime ping; that's the complete, correct answer, not a shortcut. |

## Next step

This is the last phase of the recommended route — the product is deployed and has
minimal monitoring and a feedback channel. Tell the user in their own language that:
- the route is complete;
- from here, real usage and feedback drive what comes next;
- when they have the next idea or a new iteration, the natural starting point is the
  `idea-intake` skill in a fresh chat.

Do not auto-invoke anything. The user drives what happens next.
