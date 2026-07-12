---
name: deploy-strategy
description: Use when a product is ready to ship, OR when the user directly asks how or where to deploy or to write a deploy runbook - chooses a deploy strategy with the owner in cost-and-consequence terms, then executes it into a repeatable runbook. Self-checks on disk for a fixed release version first — it warns and offers to fix it, it does not block.
---

## Overview

This is phase 8 of the SPP pipeline, but it can also be invoked standalone whenever a product is ready to ship or the owner directly asks how or where to deploy. The release is versioned, tagged, and described — now it has to actually go somewhere the owner's users can reach it. This is the one phase where SPP touches production, and the two steps are not equally weighted: choosing *how* to deploy this specific product is the real work; executing the choice is following a playbook.

Step 1 is deliberately not "pick a hosting provider." It's a decision about ongoing money and ongoing effort that the owner has to live with for the life of the product — same shape as `stack-selection` in phase 3, but now the stakes are real: this isn't a plan on paper, it's what happens when someone actually uses the thing. Options get framed the way `stack-selection` frames them — dollars, update effort, what breaks — never as infrastructure jargon on its own. Step 2 then executes against a reference playbook keyed to `product_type`, but "playbook" means reference material to draw on, not a rigid recipe to follow blind; the specific product still dictates specific choices within it.

Three invariants govern step 2 regardless of which playbook applies, and violating any of them is a defect, not a style preference: secrets never enter git, the deploy has to be repeatable from what's in the repo, and the must-scenarios get smoke-tested on production with evidence before the gate. That last one is the same verification discipline that has run through the whole pipeline — it doesn't stop at the branch boundary just because the target is now a live server instead of a laptop.

The phase's closing gate has two modes, and which one applies is a real decision, not a formality. **`executed`** is the mode described above: a real deploy, a production smoke test, evidence shown at the gate. **`deferred`** exists for exactly the case where the owner wants the strategy locked in and the runbook ready, but isn't deploying yet — a real, legitimate outcome, not a lesser one. Deferred does not require live evidence, because there is no live deployment yet to gather evidence from; what it does require is the same rigor in choosing and documenting the strategy as executed does. Whichever mode closes the gate gets written to `deploy_status` in state, and `post-release` (phase 9) reads it before deciding whether to treat the product as live.

## Process

### 0. Confirm the trigger and read state

This skill runs standalone: when a product is ready to ship, or when the owner directly asks how or where to deploy, or asks for a deploy runbook. No pipeline phase gate is required to start. If `docs/spp/pipeline-state.md` exists, read it for context and inputs:

- `product_type` and `stack` from the state file — what's being deployed and what it's built with.
- `docs/spp/00-idea-brief.md` — budget.
- The `jurisdiction` fields (`jurisdiction.users`, `jurisdiction.author`) from `pipeline-state.md`, filled by `product-discovery`, for data-residency constraints.

If the pipeline-state journal exists, write `current_phase: 8`, `phase_status: in_progress` on starting work. If it doesn't exist, skip the state update — this skill still runs standalone without it.

Steps 1-3 below are **Step 1 — choose the strategy** (the phase's main value); steps 4-8 are **Step 2 — execute**.

### 0.5. Pre-deploy self-check

Run this before choosing a strategy. Check ON DISK:

- Is there a fixed release version? (`docs/spp/07-release-notes.md` exists with a
  semver version recorded.)
- If NO: warn the user — deploying without a fixed version means not knowing what
  exactly is being shipped. Offer to fix the version first via `release-fixation`.
  Proceed only on the user's explicit choice.
- If YES: proceed.

This reads the file directly, not pipeline-state.md.

### 1. Gather inputs

Collect what the decision depends on:

- `product_type` and `stack` — already in state, read them, don't re-ask.
- Budget — already in the brief, read it, don't re-ask.
- **The owner's existing accounts and infrastructure.** Ask this directly — do they already have a hosting account, a domain, a server, a cloud subscription they're paying for and want to reuse? **Assume nothing here.** Defaulting to "they probably have nothing" or "they probably already have a VPS" are both guesses that can send the whole recommendation sideways; ask instead of picking one.
- **Jurisdiction's data-residency requirements** — from `jurisdiction.users` and `jurisdiction.author` in `pipeline-state.md` (filled by `product-discovery`). Some jurisdictions require user data to stay hosted within the users' region; check before proposing options, not after the owner has already picked one that turns out to be non-compliant.

### 2. Propose 2-3 options in owner language

Draft two or three concrete deploy options for this `product_type` and `stack`. For each, and for the comparison between them, state the trade-off the way the owner experiences it, not the way an engineer would describe it:

- **$/month now, and $/month at scale** — what it costs at MVP-sized traffic, and what happens to the bill if usage grows.
- **Update complexity** — is shipping a change one command, or a multi-step ritual the owner has to remember or pay someone to do?
- **Vendor lock-in** — how hard is it to leave this option later if it stops working out?
- **What breaks under a traffic spike** — does it fall over, get expensive, or just work?

Technical terms are allowed, but exactly as in `stack-selection`: every one needs a consequence attached. "A managed platform with autoscaling" is not an option description; "handles a traffic spike automatically, costs more per request when it does" is.

### 3. Gate

Present the options and ask the owner to pick one. This is a decision about money and ongoing maintenance, not a technical one — no infrastructure jargon without a consequence attached, no diff, nothing that requires the owner to already know what the words mean. Alongside the strategy pick, ask the second question this gate actually decides: deploy it now, or lock in the plan and runbook and hold off on going live? Both are legitimate answers — don't frame deferring as the lesser or incomplete option. While the question is outstanding, `phase_status: gate_pending`.

- **On a pick:** write the chosen strategy to `deploy_target` in the state file, log the decision in the Decisions log (date, phase 8, the chosen deploy target, who picked it, and whether the owner wants to deploy now or defer).
- **On requested changes:** if the owner wants a trade-off explained differently, or their answer to step 1 (existing accounts, budget) changes, revise the options and re-ask.

Steps 4-5 below apply either way — the playbook and the invariants shape the runbook regardless of whether the deploy happens now. Step 6 and the gate in step 7 branch on the owner's answer: executed if deploying now, deferred if not.

### 4. Follow the reference playbook for this product_type

Use the playbook matching `product_type` as reference material — a set of options and considerations to draw on, not a script to execute verbatim. The specific product, stack, and owner's existing infrastructure from step 1 still shape the actual choices made within it.

- `web` → `references/web-apps.md`
- `package` → `references/packages-and-plugins.md`
- `tg-bot` → `references/telegram-bots.md`
- `mixed` → consult whichever playbooks match the components actually being deployed; a mixed product might need more than one.

### 5. Hold the invariants

These are non-negotiable regardless of which playbook applies. Violating any one of them is a defect:

- **Secrets never go in git.** Not in a config file, not in a comment, not in a "temporary" commit meant to be reverted later. Use the mechanism the chosen platform provides for secrets (environment variables, a secrets manager, platform-level config) and reference it in the runbook by description, never by value.
- **The deploy is repeatable.** A script or a config file in the repo has to be able to reproduce this deploy from scratch. A deploy that only exists as a sequence of manual clicks the agent remembers is not repeatable, and the owner can't reproduce it either.
- **After deploy, a mandatory smoke test of the must-scenarios on production, with evidence.** This is the same verification discipline that governs the rest of the pipeline, applied to the live product. Pull the must-scenario list from `docs/spp/02-mvp-scope.md` and confirm each one against the actual production deployment — not the dev environment, not a recollection of the acceptance demo. Capture what you observed (output, screenshot, response) as evidence; "I deployed it, it should work" does not satisfy this step.

**When an invariant genuinely doesn't apply, mark it N/A with a stated reason — never silently skip it.** A secretless static product (no backend, no API keys, no user data at rest) has nothing for the secrets invariant to protect; write "secrets: N/A, this product has no secrets" in the runbook rather than leaving the section blank or, worse, inventing a secrets story to fill it. The same applies to any invariant that assumes state this specific product doesn't have. N/A is a documented judgment call, not a loophole — it requires the actual justification, not just the label. **Under `deploy_status: deferred`, the production smoke test does not run now** — there's no live deployment yet to test against — it moves to the moment the deploy actually happens; the runbook says so explicitly rather than pretending the invariant was satisfied early.

### 6. Write the artifact

Write `docs/spp/08-deploy-runbook.md`. What it contains depends on which mode step 3 landed on:

**If `executed`** (deploying now):

- How the product is deployed — the mechanism, not a jargon dump.
- How to update it — the actual steps or command for shipping a future change.
- How to roll back — what to do if a deploy goes wrong.
- $/month — the actual figure at current scale, from the chosen option in step 2.
- Where secrets live — a description of the mechanism and location (a named environment variable in the hosting platform's config panel, for example), never the secret values themselves — or the N/A justification from step 5 if this product has none.

**If `deferred`** (strategy chosen, deploy postponed):

- The chosen strategy and why, same content as the `executed` runbook's deployment-mechanism section, but written as instructions to follow **when** the deploy happens, not a record of what already happened.
- The exact steps to execute at deploy time — this is the runbook the owner or agent follows later; it has to be complete enough to act on without re-deriving the decision.
- $/month, expected — the figure from step 2, labeled as an estimate for when the deploy happens, not a bill already being paid.
- Where secrets will live — the mechanism and location, same as `executed`, described in advance of there being any actual secret value yet — or the N/A justification from step 5.
- **An explicit note that the production smoke test has not run and moves to actual-deploy time.** State this plainly; do not let the absence of a smoke test read as an oversight rather than a deliberate consequence of deferring.

### 7. Gate

The question and what it accepts depend on the mode from step 3:

**If `executed`:** ask the owner **"Product is live at [address/command] — production scenarios verified, here's the evidence — accept?"** Show the smoke-test evidence from step 5, not just the claim that it was done. On acceptance, write `deploy_status: executed` to state.

**If `deferred`:** ask the owner **"Strategy chosen, runbook ready — deploy is postponed for now. Accept the plan as-is?"** This gate requires no live evidence — there is nothing live yet to show evidence of — but it does require the runbook to be genuinely complete and actionable, not a placeholder for future work. On acceptance, write `deploy_status: deferred` to state.

<HARD-GATE>Do not present a `deferred` runbook as if it were `executed`, and do not ask the `executed` gate question ("product is live") when no deploy has actually happened. The gate question and the state written must match the actual mode chosen in step 3 — conflating them means the owner accepts a claim about production that isn't true.</HARD-GATE>

While either question is outstanding, `phase_status: gate_pending`.

- **On acceptance (either mode):** set `phase_status: approved`, log the decision in the Decisions log (date, phase 8, the mode, deploy accepted or deferred, the live address if executed, who accepted it).
- **On requested changes:** if `executed` and a must-scenario failed the smoke test, or the owner spots something wrong once they look at the live product — fix it, redeploy, re-run the smoke test, and re-ask. Do not soften the gate to "should be fine now" — re-verify with fresh evidence. If `deferred` and the owner wants the runbook adjusted, or actually wants to deploy now after all, revise accordingly (a `deferred` gate can flip to `executed` mid-conversation if the owner changes their mind — go back to step 4's playbook and step 5's live smoke-test requirement in that case) and re-ask.

### 8. Hand off

This skill's job ends at a release that's either deployed-and-verified (`executed`) or strategy-locked-and-documented (`deferred`). Do not start monitoring or feedback-loop setup yourself. Hand off `deploy_status` along with everything else — `post-release` reads it to decide whether the product is actually live. The explicit next-step transition for the owner is in the closing **Next step** section of this file.

## Red Flags

| Thought | Reality |
|---|---|
| "They're probably a solo hobbyist with nothing set up, I'll just recommend the free tier" | Existing accounts and infrastructure must be asked about, never assumed. Guessing wrong here means recommending a redundant new account, missing a compliance-relevant constraint the owner's current setup already handles, or ignoring money they're already spending. |
| "I'll drop the API key straight into the config file, it's just for now" | Secrets never go in git, full stop — there is no "just for now" exception. Use the platform's secrets mechanism and reference it in the runbook by description, not by value. |
| "I clicked through the hosting dashboard to set this up, it's live, good enough" | The deploy has to be repeatable from a script or config in the repo. A sequence of manual clicks that only exists in the agent's memory can't be reproduced by the owner or by the agent itself next time — that's a defect, not a shortcut. |
| "The acceptance demo already showed this works, I don't need to re-test on prod" | The smoke test after deploy is mandatory and separate from the acceptance demo — a working branch and a working production deployment are different claims. Verify the actual must-scenarios against the actual live deployment, with evidence, before the gate. |
| "I'll describe the options as 'serverless vs a VPS with a reverse proxy'" | Every option must be phrased in $/month, update effort, lock-in, and spike behavior — the same owner-consequence discipline as `stack-selection`. Infrastructure jargon without an attached consequence tells a non-developer nothing they can decide on. |
| "The playbook says to use provider X, so that's what we're using" | The reference playbooks are material to draw on, not a rigid recipe — the actual choice still depends on this product's stack, budget, and the owner's existing infrastructure from step 1. Following a playbook blindly can contradict what step 1 already established. |
| "We're deferring, but I'll phrase the gate as 'product is live' so the owner feels progress" | The gate question must match `deploy_status`. Asking "is it live" when nothing is deployed makes the owner accept a false claim about production — that's the exact dishonesty the verification discipline elsewhere in this pipeline exists to prevent. |
| "This product has secrets somewhere probably, I'll just write something plausible for the runbook's secrets section" | N/A requires a real, stated reason ("this product has no secrets") — never a filled-in placeholder to make the section look complete. If you're not sure whether the product has secrets, that's a reason to check, not a reason to guess and write it down. |
| "Deferred means we skip the smoke test entirely, no need to mention it again" | Deferred moves the smoke test to actual-deploy time — it doesn't cancel it. The runbook has to say so explicitly, so a future reader (owner or agent) knows the test is still owed, not silently waived. |

## Next step

When this stage is complete, tell the user in their own language that:
- this stage is done;
- the next logical step is the `post-release` skill;
- they should start it in a fresh chat so that skill gets clean context.

Do not auto-invoke the next skill. The user drives the transition — offer, do not proceed.
