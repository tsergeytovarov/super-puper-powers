---
name: idea-intake
description: Use when the user describes a product idea and docs/spp/pipeline-state.md does not exist - starts the SPP pipeline by capturing an idea brief through a one-question-at-a-time interview
---

## Overview

This is phase 0 of the SPP pipeline — the entry point. A non-developer describes a product idea; this skill turns it into a written brief and a resumable state file, then hands off to discovery. Everything downstream reads the state file this skill creates, so get the fields right the first time.

The person you're interviewing has no development background. One question per message, multiple choice where you can offer it. Never batch questions, never use technical jargon in anything the user has to answer.

## Process

### 0. Confirm the trigger

Check `docs/spp/pipeline-state.md`. If it already exists, this skill does not apply — the pipeline is already past phase 0; follow the orchestrator's state machine instead. Proceed only when the file is absent and the user is describing a product idea.

### 1. Interview — one question per message

Ask in this order. Wait for an answer before asking the next one. Offer multiple-choice options where the question has a natural small set of answers; leave it open where it doesn't.

1. **Problem** — what problem does this solve, for whom, today?
2. **Who it's for** — who exactly uses this? (get a concrete person/group, not "everyone")
3. **Differentiation** — how is this different from what already exists? What do people do today instead?
4. **Success criterion** — what does "this worked" look like, concretely?
5. **Budget** — what can this cost to build and run, roughly?
6. **Timeline** — what's the timeframe — days, weeks, months?
7. **Jurisdiction — users** — what country/region are the users in?
8. **Jurisdiction — author** — what country/region are *you* in?
9. **Artifacts language** — what language should the working documents (briefs, specs, plans) be written in? The conversation itself stays in whatever language the user is already using — this question is only about the documents.

Jurisdiction is two separate questions with two separate answers, never one. Users and author are frequently in different countries, and downstream phases (discovery's legal-risk check, deploy's data-residency check) need both independently. Do not merge them into "where are you and your users" as a single question — that produces one muddy answer where two clean ones are needed.

### 2. Set up the product repository

Check whether the current directory is a git repository. If it is not:

1. Create a project directory named after a slug of the idea (lowercase, hyphens, no special characters).
2. Run `git init` inside it.

Tell the user about this in one plain sentence before doing it — product language, no git terminology: "I'm setting up the project folder for this." Never say "repository," "git," "init," or "version control" in anything the user reads. Do this before writing any artifact or state file — both belong inside the project directory.

If the current directory is already a git repository, use it as-is; skip this step.

### 3. Write the artifact

Write `docs/spp/00-idea-brief.md`: a structured brief from the nine answers above. One section per answer, plain language, no invented content — if an answer was vague, keep it vague in the brief rather than papering over it with assumption.

### 4. Create the state file

Write `docs/spp/pipeline-state.md` with the YAML block below, filled from the interview answers. Match this shape exactly — every downstream skill and the orchestrator parse these field names literally:

```yaml
project: <slug>
artifacts_language: ru | en | …
jurisdiction:
  users: <country/region of the users>
  author: <country/region of the author>
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

Leave `discovery_mode`, `product_type`, `stack`, `subproject_order`, and `deploy_target` as `null` — later phases own them. `phases_skipped` starts empty — this skill always runs phase 0 from scratch, it never skips into the pipeline midway.

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
| "I'll ask problem + audience together, saves a round trip" | One question per message, always. Batching loses answers and confuses a non-technical user about what's being asked. |
| "Users and author are basically in the same place, one jurisdiction question is enough" | Two separate fields, two separate questions. Downstream legal-risk and data-residency checks need both independently — collapsing them loses information you can't recover later. |
| "I'll mention `git init` so the user understands what's happening" | Zero git terminology in anything the user reads. Say "setting up the project folder," not "initializing a repository." |
| "The brief seems obvious, I'll skip the playback gate" | No artifact is approved without the user confirming it in their own gate. Skipping it means phase 1 builds on an unconfirmed brief. |
| "I'll fill in a plausible answer for the vague one" | If the user's answer was vague, the brief stays vague. Inventing specificity fabricates a brief the user never actually approved. |
| "Discovery will need the product type, I'll guess it now" | Not this skill's job — `product_type` stays `null`. Guessing here just means someone downstream has to un-guess it. |
