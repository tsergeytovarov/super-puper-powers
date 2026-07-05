---
name: product-discovery
description: Use when the idea brief is approved (phase 0 approved in docs/spp/pipeline-state.md) - researches competitors, legal risks, market and feasibility before any scoping, with an explicit right to stop the project
---

## Overview

This is phase 1 of the SPP pipeline. The idea brief is approved; before anyone scopes an MVP, this skill asks the one question that matters: is this idea worth building at all? Competitors, legal risk, market size, feasibility — checked now, before a single feature gets prioritized.

This is the only phase in the pipeline where stopping outright is a designed, celebrated outcome. If the research turns up an idea killer — a legal wall, a market that doesn't exist, a niche already saturated by something better — recommending "stop" here saves the person months of work on something that was never going to land. Do not treat that outcome as a failure to route around. It is the win condition for this phase.

Research runs in subagents with fresh context, never session history — you construct exactly what each one needs from the brief.

Some environments (sandboxed, headless) give a research subagent no web-search tools at all. That is not a reason to stop or to let the subagent quietly improvise — see the fallback in step 1.5.

## Process

### 0. Confirm the trigger and read state

Read `docs/spp/pipeline-state.md`. This skill applies only when `current_phase: 0` and `phase_status: approved` — the idea brief is confirmed and nothing later has started. Read `docs/spp/00-idea-brief.md` for the brief content, including the two jurisdiction fields (`jurisdiction.users`, `jurisdiction.author`) — the legal-risk research depends on both.

On starting work, write `current_phase: 1`, `phase_status: in_progress`.

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

1. **Competitors and alternatives** — who already solves this problem, what's weak about their solutions, where the gap or niche actually is.
2. **Legal risks under the jurisdiction from the brief** — personal data handling, licensing, payments, age restrictions. Use both jurisdiction fields: rules can differ between where the users are and where the author is, and both apply.
3. **Market and demand** — rough size, trends, evidence people would actually pay or switch.
4. **Feasibility** — buildable by a solo agent in the timeframe and budget from the brief; order-of-magnitude monthly running cost once live.

Each subagent prompt must stand alone: the relevant brief fields, the specific question, and what to return. Do not paste the conversation — construct the context.

### 3. Quick mode — one subagent

Dispatch a single subagent covering:

- Item 1 (competitors and alternatives) — same depth as deep mode.
- Item 2 (legal risks) — obvious stoppers only, not an exhaustive survey.
- Item 4 (feasibility) — a rough pass, not order-of-magnitude precision.

Market and demand (item 3) is skipped entirely in quick mode — say so plainly in the report rather than silently omitting it.

### 4. Synthesize

Combine the subagent output(s) into a single report. Don't just concatenate — reconcile overlaps and contradictions between subagents yourself. If any subagent used the no-web-tools fallback from step 1.5, carry its "not verified against primary sources" marks through into the synthesized text on the specific claims they cover — synthesis must not smooth an unverified claim into a confident-sounding sentence that loses the mark.

### 5. Adversarial check — deep mode only

In deep mode, dispatch one more subagent, separate from the four research subagents, to verify 3-5 of the report's key claims against primary sources (not just re-reading the research subagents' own output). Fold corrections into the report before writing the artifact.

**Quick mode has no adversarial step.** This is the deliberate cost of the 30-minute budget, not an oversight — the artifact must say so explicitly, so the person reading it knows the report's claims are unverified and weighs the recommendation accordingly.

### 6. Write the artifact

Write `docs/spp/01-discovery-report.md`. Mandatory sections:

- **Idea killers** — every legal, market, or competitive dealbreaker found, or an explicit "none found" if the research turned up nothing disqualifying. This section may not be omitted or left implicit.
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

On **go** only: state the next step explicitly — **"Next: the `super-puper-powers:mvp-scoping` skill."** Do not start scoping work yourself.

On pivot or stop, there is no "next skill" to hand off to in this phase — pivot re-enters `idea-intake`, stop ends the pipeline.

## Red Flags

| Thought | Reality |
|---|---|
| "Quick mode is basically deep mode minus one subagent, I'll run the adversarial check anyway for safety" | Adversarial verification is deep-only. Running it in quick mode breaks the time budget the user picked and contradicts what the report says it did. |
| "The recommendation is 'stop,' I should frame this gently since the pipeline is ending in failure" | Stop is not a failure. It's the phase working as designed — say plainly that it just saved the user months. Softening it into an apology misrepresents the outcome. |
| "I'll just tell the research subagents about the idea from what I already know" | Subagents never inherit session context. Construct a precise brief for each from `00-idea-brief.md` — an assumed-context subagent researches the wrong thing or misses jurisdiction-specific detail. |
| "Competitors and feasibility look fine, I'll skip writing an explicit 'Idea killers' section" | The section is mandatory even when empty. Write "none found" — an absent section reads as "not checked," not "checked, clean." |
| "Legal risk only needs the users' jurisdiction, the author's country doesn't build the product" | Both jurisdiction fields apply — the author's country can impose its own licensing, tax, or data-handling obligations regardless of where users sit. Checking one and skipping the other leaves a real risk unresearched. |
| "The gate is basically approve/reject, I can phrase it as ship-it-or-not on the tech" | Gate is go/pivot/stop in product terms — market and legal reality, not implementation. Framing it around code or architecture asks the user to evaluate something they can't. |
| "No web tools for this subagent — I'll answer confidently from what I know and skip the caveat" | Model-knowledge answers are legal, but every conclusion they produce must be marked "not verified against primary sources." Dropping the mark makes an unverified guess look like a researched finding. |
| "I don't have a real source for this claim but I need one to look credible, I'll cite a plausible-sounding one" | Never invent a URL or source name. No web access means no citations — a fabricated one is worse than an honest "not verified" mark, because it actively misleads whoever checks it. |
| "Quick mode already says market/demand wasn't researched, that covers the go-decision risk too" | The 'not researched' caveat describes what didn't happen; the mandatory warning at the gate names the consequence for the decision itself. Quick mode requires both — one doesn't substitute for the other. |
