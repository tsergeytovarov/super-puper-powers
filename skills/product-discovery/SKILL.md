---
name: product-discovery
description: Use when the idea brief is approved (phase 0 approved in docs/spp/pipeline-state.md) OR when the user directly asks to check an idea for competitors, legal risk, or whether it is worth building, outside a running pipeline (e.g. "check this idea for competitors / legal risk / whether it is worth building") - researches competitors, legal risks, market and feasibility before any scoping, with an explicit right to stop the project
---

## Overview

This is phase 1 of the SPP pipeline. The idea brief is approved; before anyone scopes an MVP, this skill asks the one question that matters: is this idea worth building at all? Competitors, legal risk, market size, feasibility — checked now, before a single feature gets prioritized.

This is the only phase in the pipeline where stopping outright is a designed, celebrated outcome. If the research turns up an idea killer — a legal wall, a market that doesn't exist, a niche already saturated by something better — recommending "stop" here saves the person months of work on something that was never going to land. Do not treat that outcome as a failure to route around. It is the win condition for this phase.

Research runs in subagents with fresh context, never session history — you construct exactly what each one needs from the brief.

Some environments (sandboxed, headless) give a research subagent no web-search tools at all. That is not a reason to stop or to let the subagent quietly improvise — see the fallback in step 1.5.

## Process

### 0. Confirm the trigger and read state

Read `docs/spp/pipeline-state.md`. This is the recommended phase after phase 0 (idea brief approved), but it also runs standalone on a direct request — it does not require a pipeline or an approved prior phase. If a journal exists at `current_phase: 0` and `phase_status: approved`, read `docs/spp/00-idea-brief.md` for the brief content; otherwise work from the user's request directly (see step 0.5).

On starting work, write `current_phase: 1`, `phase_status: in_progress`.

### 0.2. Establish the target market (jurisdiction)

`idea-intake` deliberately does not ask about jurisdiction — this is the phase that needs it, so this is where it gets asked. Check `jurisdiction.users` and `jurisdiction.author` in the state file. If either is `null` or missing, ask the user now, before dispatching legal-risk research — this is the "which market are we building for" question, framed in plain product language, not "what is your jurisdiction":

- **Target market** — which country or region are the intended users in? This fills `jurisdiction.users`.
- **Author's country** — only ask this as a short follow-up if it plausibly changes the legal picture (licensing, tax, payment handling can be governed by where the author operates, not just where users are). If it obviously doesn't matter for this idea, default `jurisdiction.author` to the same region and move on rather than asking a second dumb question.

Write the answers back into the state file's `jurisdiction` fields. From here on, the legal-risk research uses both fields exactly as before. If both fields already carry real values (e.g. an older brief or a standalone caller supplied them), skip this step.

### 0.5. Standalone use (no pipeline running)

If there is no `docs/spp/pipeline-state.md`, or it exists but isn't at phase 0 approved, and the user asked directly for a discovery pass on an idea (e.g. "check this idea for competitors" or "is this worth building"): do not demand an approved phase 0 or an idea brief that doesn't exist. Instead, gather the minimum directly from the user in this message exchange — what the idea is, who it's for, and both jurisdiction fields (`jurisdiction.users`, `jurisdiction.author`), since legal-risk research needs both. Skip reading or writing `pipeline-state.md` entirely; don't fabricate a state file you don't own.

Run steps 1 through 6 as normal against that gathered context, and still write the artifact to `docs/spp/01-discovery-report.md` — it's a real, reusable document regardless of how it was triggered. Still run the gate in step 7 (go/pivot/stop is the right shape for this decision even standalone), but do not write `current_phase`/`phase_status` transitions and do not log to a Decisions log that belongs to a pipeline that isn't running.

After the gate, do not hand off automatically per step 8. Instead, mention that this research can continue into the full pipeline if the user wants — name `super-puper-powers:mvp-scoping` as the next skill, as an option, not a mandate.

### 1. Ask: quick or deep

First question to the user, multiple choice:

- **Quick** (~30 minutes): one research subagent covers competitors, obvious legal stoppers, and a rough feasibility read. Faster, shallower, no adversarial fact-check.
- **Deep** (a few hours): four research subagents run in parallel, each covering one domain in depth, followed by an adversarial check that verifies the report's key claims against primary sources.

Record the answer in `discovery_mode` in the state file before dispatching any research.

### 1.5. Fallback when a research subagent has no web tools

Before dispatching, and again if a dispatched subagent reports back that it had no web-search tools available: this happens in sandboxed or headless environments where the subagent literally cannot reach the web. It is not a reason to stop discovery, and it is not license for the subagent to quietly wing it as if it had searched.

Instruct every research subagent explicitly, in its prompt, to follow this fallback when web tools are unavailable to it:

- Answer from the model's own knowledge instead of search results.
- Mark every conclusion that rests on that knowledge as **"not verified against primary sources"** — not a vague hedge once at the top, but attached to the specific claims it covers.
- Never invent a URL, a source name, or a citation to make an unverified answer look sourced. No web access means no citations, not fabricated ones.

This applies per-subagent in deep mode (some subagents may have web tools while others don't, in principle) and to the single subagent in quick mode. Whenever any subagent's contribution used this fallback, carry that mark into the synthesized report in step 4 and into the artifact in step 6 — a downstream reader must be able to tell which parts of the report are search-backed and which are model-knowledge-only.

### 2. Deep mode — four parallel subagents

Dispatch four subagents in a single response so they run concurrently (the `dispatching-parallel-agents` pattern). None of them inherits this session's context — each gets a constructed brief built from `00-idea-brief.md`, containing only what that subagent needs:

1. **Competitors and alternatives** — who already solves this problem, what's weak about their solutions, where the gap or niche actually is. This subagent also owns the **differentiator verdict** (see step 3.5): it must check the brief's claimed differentiator against what competitors actually do, not just survey the competitive landscape in general.
2. **Legal risks under the jurisdiction from the brief** — personal data handling, licensing, payments, age restrictions. Use both jurisdiction fields: rules can differ between where the users are and where the author is, and both apply.
3. **Market and demand** — rough size, trends, evidence people would actually pay or switch.
4. **Feasibility** — buildable by a solo agent in the timeframe and budget from the brief; order-of-magnitude monthly running cost once live.

Each subagent prompt must stand alone: the relevant brief fields, the specific question, and what to return. Do not paste the conversation — construct the context.

### 3. Quick mode — one subagent

Dispatch a single subagent covering:

- Item 1 (competitors and alternatives) — same depth as deep mode, including the differentiator verdict from step 3.5.
- Item 2 (legal risks) — obvious stoppers only, not an exhaustive survey.
- Item 4 (feasibility) — a rough pass, not order-of-magnitude precision.

Market and demand (item 3) is skipped entirely in quick mode — say so plainly in the report rather than silently omitting it.

### 3.5. Evaluate the claimed differentiator

The brief's "how it differs" answer (`00-idea-brief.md`) is a claim, not a fact. The competitor research — subagent 1 in deep mode, the single subagent's competitor pass in quick mode — must explicitly test that claim against what competitors actually do, and land one of three verdicts:

- **Survives** — the differentiator is real and defensible; competitors don't cover it, or cover it meaningfully worse.
- **Weak** — competitors mostly already cover it; what's left is a thin edge, not a real gap.
- **Killed** — competitors already do exactly this; it is not actually a differentiator.

This is a distinct instruction to the subagent, not something that falls out of a general competitor survey — a subagent asked only to "research competitors" will describe the landscape without ever comparing it back to the specific claim in the brief. Tell it explicitly: state the brief's differentiator, then say which of the three verdicts it earns and why, citing what competitors actually do.

A `weak` or `killed` verdict is not automatically an idea killer and does not by itself force a "no-go" recommendation in step 6 — plenty of products succeed without a durable moat. But it must be stated plainly, not folded into general competitor commentary where a reader could miss it, because `mvp-scoping` and the product owner both need this verdict to decide what happens next.

### 4. Synthesize

Combine the subagent output(s) into a single report. Don't just concatenate — reconcile overlaps and contradictions between subagents yourself. If any subagent used the no-web-tools fallback from step 1.5, carry its "not verified against primary sources" marks through into the synthesized text on the specific claims they cover — synthesis must not smooth an unverified claim into a confident-sounding sentence that loses the mark. Carry the differentiator verdict from step 3.5 through unchanged — synthesis reconciles competitive findings, but it does not soften "weak" or "killed" into vaguer language on the way into the report.

### 5. Adversarial check — deep mode only

In deep mode, dispatch one more subagent, separate from the four research subagents, to verify 3-5 of the report's key claims against primary sources (not just re-reading the research subagents' own output). Fold corrections into the report before writing the artifact.

**Quick mode has no adversarial step.** This is the deliberate cost of the 30-minute budget, not an oversight — the artifact must say so explicitly, so the person reading it knows the report's claims are unverified and weighs the recommendation accordingly.

### 6. Write the artifact

Write `docs/spp/01-discovery-report.md`. Mandatory sections:

- **Idea killers** — every legal, market, or competitive dealbreaker found, or an explicit "none found" if the research turned up nothing disqualifying. This section may not be omitted or left implicit.
- **Differentiator verdict** — the brief's claimed differentiator, stated plainly, followed by the verdict from step 3.5: **survives**, **weak**, or **killed**, with the competitive reasoning behind it. Mandatory in both modes, same as idea killers — a `weak` or `killed` verdict is not itself a stopper, but it must be a named, unmissable element of the report, not a sentence buried inside general competitor commentary.
- **Recommendation: go / pivot / no-go** — one of the three, with the reasoning that leads to it. "No-go" here is the report's recommendation going into the gate; the gate itself offers the user go / pivot / stop (below) — this section is what backs that gate's stop option, not a separate decision, so word it as the case *for* stopping, not a vague warning.
- If any part of the report relied on the no-web-tools fallback (step 1.5): the "not verified against primary sources" mark on every affected claim, carried through from synthesis — not summarized away as a single footnote that loses which claims it covers.
- If quick mode: a plain statement that no adversarial verification ran and market/demand wasn't researched.
- If quick mode: the mandatory owner warning from step 7 below — it belongs in this artifact, not only spoken at the gate, so the record shows the owner was told before deciding.

### 7. Gate

Present the recommendation and ask the user to decide: **go**, **pivot**, or **stop**. This is a business call about whether to keep going, not a technical one — no diff, no architecture, no code. While the question is outstanding, `phase_status: gate_pending`.

**In quick mode, before asking for the decision**, state this warning to the user plainly, next to the recommendation — this is mandatory, not optional context they can miss by skimming: **"Go is being decided WITHOUT demand data; if demand is uncertain, go back and run deep."** This sits alongside the existing quick-mode caveats (no adversarial check, market/demand not researched) — it exists because those caveats describe what wasn't checked, while this one names the actual consequence for the decision the user is about to make. Do not fold it silently into the general disclaimer text; it must read as a warning attached to the go option specifically, since "go" is the choice it's warning about.

- **Go:** the idea clears discovery. Set `phase_status: approved`, log the decision in the Decisions log (date, phase 1, "go", who decided). In quick mode, log that the owner was warned about missing demand data alongside the decision.
- **Pivot:** the brief itself needs to change — a different angle, a narrower audience, a different problem. Go back to `idea-intake`: set `current_phase: 0`, `phase_status: in_progress`, and log the pivot and its reason in the Decisions log. `idea-intake` re-runs the interview for the fields that changed, editing the existing brief rather than starting from nothing.
- **Stop:** the pipeline ends here, on purpose. Set `phase_status: stopped` and log the reason in the Decisions log. Say this out loud to the user in plain terms: this is a successful outcome — the research just saved them months of work on an idea that wasn't going to pay off. Do not apologize for the recommendation or soften it into a failure.

### 8. Hand off

On **go** only: follow the `## Next step` section below to tell the user what comes next. Do not start scoping work yourself.

On pivot or stop, there is no "next skill" to hand off to in this phase — pivot re-enters `idea-intake`, stop ends the pipeline.

## Red Flags

| Thought | Reality |
|---|---|
| "Quick mode is basically deep mode minus one subagent, I'll run the adversarial check anyway for safety" | Adversarial verification is deep-only. Running it in quick mode breaks the time budget the user picked and contradicts what the report says it did. |
| "The recommendation is 'stop,' I should frame this gently since the pipeline is ending in failure" | Stop is not a failure. It's the phase working as designed — say plainly that it just saved the user months. Softening it into an apology misrepresents the outcome. |
| "I'll just tell the research subagents about the idea from what I already know" | Subagents never inherit session context. Construct a precise brief for each from `00-idea-brief.md` — an assumed-context subagent researches the wrong thing or misses jurisdiction-specific detail. |
| "Competitors and feasibility look fine, I'll skip writing an explicit 'Idea killers' section" | The section is mandatory even when empty. Write "none found" — an absent section reads as "not checked," not "checked, clean." |
| "The competitor research covered the landscape, that's close enough to a differentiator verdict" | A general competitor survey and an explicit verdict on the brief's specific claim are different questions. Without the dedicated step 3.5 instruction, the subagent describes competitors without ever comparing them back to the brief's differentiation answer — the report ends up with competitor notes and no verdict at all. |
| "The differentiator looks weak, but that's not an idea killer, so I won't call it out separately" | Weak/killed doesn't have to be a stopper to be mandatory to state. It's a named section regardless of severity — burying it inside general commentary is exactly how it failed to reach mvp-scoping before this check existed. |
| "Legal risk only needs the users' jurisdiction, the author's country doesn't build the product" | Both jurisdiction fields apply — the author's country can impose its own licensing, tax, or data-handling obligations regardless of where users sit. Checking one and skipping the other leaves a real risk unresearched. |
| "The gate is basically approve/reject, I can phrase it as ship-it-or-not on the tech" | Gate is go/pivot/stop in product terms — market and legal reality, not implementation. Framing it around code or architecture asks the user to evaluate something they can't. |
| "No web tools for this subagent — I'll answer confidently from what I know and skip the caveat" | Model-knowledge answers are legal, but every conclusion they produce must be marked "not verified against primary sources." Dropping the mark makes an unverified guess look like a researched finding. |
| "I don't have a real source for this claim but I need one to look credible, I'll cite a plausible-sounding one" | Never invent a URL or source name. No web access means no citations — a fabricated one is worse than an honest "not verified" mark, because it actively misleads whoever checks it. |
| "Quick mode already says market/demand wasn't researched, that covers the go-decision risk too" | The 'not researched' caveat describes what didn't happen; the mandatory warning at the gate names the consequence for the decision itself. Quick mode requires both — one doesn't substitute for the other. |
| "The user just asked me to check this idea, but there's no approved phase 0 in pipeline-state.md, so I can't run" | Standalone invocation doesn't need an approved pipeline phase. Gather the idea and jurisdiction fields directly from the user and run the research — don't block a one-off request on an artifact that was never going to exist. |

## Next step

When this stage is complete, tell the user in their own language that:
- this stage is done;
- the next logical step is the `mvp-scoping` skill;
- they should start it in a fresh chat so that skill gets clean context.

Do not auto-invoke the next skill. The user drives the transition — offer, do not proceed.
