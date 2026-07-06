---
name: geo-optimization
description: Use when asked about GEO (generative engine optimization) or making a product understandable to AI assistants - packages a public page so AI and summary tools grasp what the product does, for whom, its limits and where the facts are; sibling of seo-baseline, does not duplicate search-engine packaging
---

## Overview

This is a standalone helper skill. It sits outside the SPP pipeline state machine — it does not read or write `docs/spp/pipeline-state.md`, and it is not a numbered phase or a phase checkpoint. It runs whenever asked, triggered by its own description, independent of any pipeline in progress.

GEO here means Generative Engine Optimization. It is not geographic SEO, and it is not a trick to game a chatbot's ranking. It is packaging a public page so AI assistants, search copilots, and summary tools can correctly understand what the product does, who it's for, what it doesn't do yet, and where the facts live on the page.

Where SEO answers a search engine's question — what to index — GEO answers an assistant's question: how to honestly explain this product to a person. Technical packaging for search engines and messengers (title, meta description, Open Graph, robots.txt, sitemap, page structure) is a separate concern, covered by the sibling `seo-baseline` skill — don't duplicate that checklist here and don't reach into it.

## Process

### 1. Read the page as an AI summarizer would

Pull up the public page or doc and read it the way a summary tool would — no assumed context, no benefit of the doubt. Marketing language that says nothing concrete ("manage your dream career with an innovative tool") gives an AI nothing to extract. Concrete language does:

```text
JobTrack is a manual job-application tracker for active job seekers.
In the MVP, a user adds a listing, changes its status, writes the next step, and exports JSON.
There is no import from job boards, no auth, and no AI recommendations in this version.
```

### 2. Check that the page states, in plain text, each of

- **What** the product is — a short, hype-free description of what it actually does.
- **For whom** — the target user and the situation they're in.
- **The core scenario** — the main thing a user does with it, step by step.
- **What's in scope** — what the current MVP actually includes.
- **What's out of scope** — what it explicitly does not do yet, so an assistant doesn't invent features.
- **Where the facts are** — a privacy/data note (what data the user enters and where it's stored), an FAQ with direct answers, and changelog/release notes if they exist.
- **A feedback channel** — where a real question goes if the AI's summary isn't enough.
- **Clear headings** — H1/H2 that describe structure, not decorative headings that hide it.

### 3. Fix or list

- **Fix now** if it's a text/content gap: write the missing description, add an explicit MVP-scope line, add an FAQ entry, add a privacy/data note.
- **List, don't fix** if it needs a product decision (what actually is out of scope), a design placement decision (own page vs. a section in an existing one), or content ownership from someone else. Record it instead of guessing at the product's boundaries.

Don't invent scope or capabilities the product doesn't have to make the page sound more impressive to a summarizer — that produces a confident, wrong summary, which is worse than a vague one.

### 4. Report

Report back:

- What was checked against the list in step 2.
- What was fixed, with a one-line description of each fix and which files it touched.
- What was found but not fixed, and why (needs a product decision, needs placement decision, out of scope).

## Scope guard

This is making the product legible to AI, not search-engine technical packaging:

- No title tags, meta descriptions, Open Graph, robots.txt, sitemap, or page-structure markup work here — that's the sibling `seo-baseline` skill's job.
- No keyword research, no content strategy, no link-building.
- No promises the MVP doesn't keep — every claim on the page must be true today, since an AI summarizer will repeat it as fact.
- No new pages created "to help GEO" — package the pages and docs that already exist.
- If what's missing is a product-scope decision rather than a content gap, list it for the owner instead of guessing.
