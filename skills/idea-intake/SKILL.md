---
name: idea-intake
description: Use when the user describes a product idea, OR directly asks to capture or write up a product idea brief - captures an idea brief through a one-question-at-a-time interview. Runnable standalone; if docs/spp/pipeline-state.md is absent it starts a fresh journal, if present it appends.
---

## Overview

This is phase 0 of the SPP pipeline — the entry point. A non-developer describes a product idea; this skill turns it into a written brief and a resumable state file, then hands off to discovery. Everything downstream reads the state file this skill creates, so get the fields right the first time.

The person you're interviewing has no development background. For anything not already covered by their own description, one question per message, multiple choice where you can offer it. Never batch *questions*, never use technical jargon in anything the user has to answer.

## Process

### 0. Confirm the trigger

Check `docs/spp/pipeline-state.md`. If it is absent, this is a fresh start — you create the journal as part of this skill. If it already exists, read it as memory (the project may already carry earlier work and decisions) and append your brief rather than overwriting it. Either way, proceed with the interview when the user is describing a product idea or asking to capture one — this skill is runnable standalone and does not require an empty project.

### 1. Interview — extract what's already answered, then one question per message for the rest

The interview covers these six points, in this order:

1. **Problem** — what problem does this solve, for whom, today?
2. **Who it's for** — who exactly uses this? (get a concrete person/group, not "everyone")
3. **Differentiation** — how is this different from what already exists? What do people do today instead?
4. **Success criterion** — what does "this worked" look like, concretely?
5. **Budget** — what can this cost to build and run, roughly?
6. **Timeline** — what's the timeframe — days, weeks, months?

Do **not** ask about jurisdiction (which country the users or the author are in) or about which language the documents should be written in. These are not intake questions:

- **Target market / jurisdiction** is established later, at the moment it actually matters — `product-discovery` asks for it when it runs its legal-risk and competitor research. Asking a non-developer "what country are you in" at the very first step is a dumb question with no payoff yet; leave it to the phase that needs it.
- **Artifacts language** is inferred, never asked — set it automatically to the language the user is already writing to you in (see step 4). If they want the documents in a different language, they'll say so.

All six points must end up answered. How you get there depends on what the user already gave you:

1. **Extract first.** Re-read the user's opening description of the idea and identify which of the six points it already answers, even loosely. A point counts as "already answered" only if the description states it or makes it unambiguous — not if you'd have to guess or infer a specific value it never actually gave.
2. **Play back the extracted points in one message.** If one or more points were already answered, present all of them together, plainly labeled, in a single message: "Here's what I understood so far: [point] — [your answer], [point] — [your answer], … Did I get these right?" This is a confirmation, not a new question — the user corrects or confirms in one reply, they don't get interviewed on things they already told you.
3. **Fold in corrections.** If the user corrects any extracted point, update your understanding before moving on. Re-confirm only the corrected point if the correction itself is ambiguous; otherwise take the correction as settled.
4. **Ask one-at-a-time for the genuinely missing points only.** Whatever wasn't in the opening description — or was too vague to count as answered — goes through the normal one-question-per-message interview, in the numbered order above, skipping over points already confirmed in step 2. Wait for an answer before asking the next one. Offer multiple-choice options where the question has a natural small set of answers; leave it open where it doesn't.

If the user's opening description answers none of the six points with enough specificity, skip the batch playback entirely and run the full one-at-a-time interview from point 1 — the smart-skip only ever removes questions the user has already effectively answered, it never removes a topic from the six or turns an unclear answer into a settled one.

### 2. Set up the product repository

Check whether the current directory is a git repository. If it is not:

1. Create a project directory named after a slug of the idea (lowercase, hyphens, no special characters).
2. Run `git init` inside it.

Tell the user about this in one plain sentence before doing it — product language, no git terminology: "I'm setting up the project folder for this." Never say "repository," "git," "init," or "version control" in anything the user reads. Do this before writing any artifact or state file — both belong inside the project directory.

If the current directory is already a git repository, use it as-is; skip this step.

### 3. Write the artifact

Write `docs/spp/00-idea-brief.md`: a structured brief from the six answers above. One section per answer, plain language, no invented content — if an answer was vague, keep it vague in the brief rather than papering over it with assumption. The brief has no jurisdiction or language section — those are not gathered here.

### 4. Create the state file

Write `docs/spp/pipeline-state.md` with the YAML block below, filled from the interview answers. Match this shape exactly — every downstream skill and the orchestrator parse these field names literally:

```yaml
project: <slug>
artifacts_language: ru | en | …
jurisdiction:
  users: null
  author: null
current_phase: 0
phase_status: in_progress
phases_skipped: []
discovery_mode: null
product_type: null
stack: null
subproject_order: null
deploy_target: null
```

Followed by two sections:

```markdown
## Decisions log

## Artifacts
- docs/spp/00-idea-brief.md
```

Set `artifacts_language` automatically — do not ask. Use the language the user is writing to you in (Russian chat → `ru`, English chat → `en`). The user can override it later; this skill just infers a sensible default so downstream phases have the field.

Leave both `jurisdiction` fields as `null`. `product-discovery` fills them when it asks for the target market — that's the phase that first needs them. Leave `discovery_mode`, `product_type`, `stack`, `subproject_order`, and `deploy_target` as `null` too — later phases own them. `phases_skipped` starts empty — this skill always runs phase 0 from scratch, it never skips into the pipeline midway.

### 5. Gate

Play the idea back in your own words — plain product language, one paragraph, no jargon. Ask: **"Did I get the idea right?"**

- If the user corrects you, update the brief and re-ask. Repeat until confirmed.
- On approval:
  1. Set `phase_status: approved` in the state file.
  2. Append an entry to the Decisions log: date, phase 0, the decision ("idea brief approved"), who approved it (the user).

Before approval, while the question is outstanding, `phase_status` is `gate_pending` — set it when you ask the gate question, not only when you write the file next.

### 6. Hand off

State the next step explicitly: **"Next: the `super-puper-powers:product-discovery` skill."** Do not start discovery work yourself — that skill reads the approved brief and state file and takes it from there.

## Red Flags

| Thought | Reality |
|---|---|
| "I'll ask problem + audience together, saves a round trip" | One question per message, always, for anything not already answered. Batching *new* questions loses answers and confuses a non-technical user about what's being asked. |
| "The idea description sort of implies a budget, I'll count that as answered" | Extraction requires the description to state or unambiguously settle the point — a vague implication is not an answer. Treat it as missing and ask; inventing a specific value from a vague hint fabricates a brief the user never actually gave. |
| "I extracted the answered points, I'll fold the playback into casual conversation instead of a clear confirmation" | The extracted points go back to the user in one explicit message asking them to confirm or correct — not woven into narration they might skim past. An unconfirmed extraction is just a guess wearing a confident sentence. |
| "I'll ask what country the users/author are in — discovery will need it" | Not an intake question. `product-discovery` asks for the target market when it runs legal-risk research. Asking a non-developer their jurisdiction at step 0 is a dumb question with no payoff yet. Leave both fields `null`. |
| "I'll ask which language the documents should be in" | Never ask. Infer `artifacts_language` from the language the user is writing to you in. |
| "I'll mention `git init` so the user understands what's happening" | Zero git terminology in anything the user reads. Say "setting up the project folder," not "initializing a repository." |
| "The brief seems obvious, I'll skip the playback gate" | No artifact is approved without the user confirming it in their own gate. Skipping it means phase 1 builds on an unconfirmed brief. |
| "I'll fill in a plausible answer for the vague one" | If the user's answer was vague, the brief stays vague. Inventing specificity fabricates a brief the user never actually approved. |
| "Discovery will need the product type, I'll guess it now" | Not this skill's job — `product_type` stays `null`. Guessing here just means someone downstream has to un-guess it. |

## Next step

When this stage is complete, tell the user in their own language that:
- this stage is done;
- the next logical step is the `product-discovery` skill;
- they should start it in a fresh chat so that skill gets clean context.

Do not auto-invoke the next skill. The user drives the transition — offer, do not proceed.
