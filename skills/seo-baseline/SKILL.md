---
name: seo-baseline
description: Use when asked for SEO baseline or to make a public page shareable - adds the technical page packaging (title, description, favicon, Open Graph preview, robots, sitemap, page structure) so links and previews look intentional
---

## Overview

This is a standalone helper skill. It sits outside the SPP pipeline state machine — it does not read or write `docs/spp/pipeline-state.md`, and it is not a numbered phase or a phase checkpoint. It runs whenever asked, triggered by its own description, independent of any pipeline in progress.

SEO for a first MVP is not an attempt to rank on Google in a week. It's the basic technical packaging of a page: a link isn't embarrassing to share, a search engine can parse the page, and a preview in a messenger doesn't look like random junk.

This skill covers technical packaging for search engines and messengers only. Making a product legible to AI-assisted search (Generative Engine Optimization) is a separate concern, covered by the sibling `geo-optimization` skill — don't duplicate its checklist here and don't reach into it.

## Checklist

Baseline items to check on a public page:

- **Title** — a concrete, specific page title, not a generic framework default.
- **Meta description** — one to two sentences describing the product, no slogans.
- **Canonical URL** — the primary address declared, so duplicate URLs don't split signal.
- **Favicon** — a real icon set (ico/svg/apple-touch/192/512), not the framework's default icon.
- **Open Graph preview** — title, description, and image set, so Telegram/Slack/social previews render correctly.
- **Twitter card** — preview metadata for X/Twitter.
- **robots.txt** — states what's indexable; if the page isn't ready for public search, it's `noindex` on purpose, not by accident.
- **sitemap.xml** — lists the public pages, present when the project is meant to be indexed.
- **Page structure** — exactly one H1, semantic HTML for links and buttons (not clickable divs), meaningful alt text on significant images.

This is not about ranking magic. It's about the absence of technical sloppiness.

## Process

### 1. Decide indexability

Before touching metadata, decide whether the page should be indexed at all:

- A raw prototype shown to a handful of people is more honest closed to indexing: `noindex` via meta tag or `robots.txt`.
- Full SEO — sitemap, canonical, open indexing — is for a product ready for public entry.
- Canonical URL is worth setting either way: it names the primary address when a page is reachable via more than one URL.

### 2. Audit

Walk the target page and check every item in the Checklist against it:

- Read the current title and description as a stranger would — do they say what the product is, or are they a template placeholder?
- Check the favicon files present against the ico/svg/apple-touch/192/512 set.
- Check Open Graph and Twitter card metadata — title, description, image, dimensions.
- Check `robots.txt` and `sitemap.xml` presence and content against the indexability decision from step 1.
- Count H1 elements on the page; check that links use `<a>` and actions use `<button>`.
- Spot-check alt text on the significant images (not decorative ones).

Produce findings only in this step. Don't fix anything yet.

### 3. Fix or list

For each finding, decide fix now vs. list for later:

- **Fix now** if it's a minimal, in-scope metadata or markup change: set a title, write a description, add a favicon file, fill Open Graph fields, add a missing alt, swap a div for a semantic element.
- **List, don't fix** if it needs a design asset that doesn't exist yet (a real OG image), a domain/hosting decision (canonical URL, sitemap generation setup), or a call on whether the page should be indexed at all. Record it instead of guessing.

Keep fixes minimal. Don't add marketing pages, new routes, or content beyond what's needed to fill the checklist.

### 4. Report

Report back:

- What was checked.
- What was fixed, with a one-line description of each fix and which files it touched.
- What was found but not fixed, and why (missing asset, needs a decision, out of scope).

## Scope guard

This is technical packaging, not a ranking campaign:

- No keyword research, no content strategy, no link-building, no marketing copywriting.
- No new pages created to "help SEO" — package the pages that already exist.
- No promises the MVP doesn't keep — description and OG copy describe what the product actually does today.
- No Generative Engine Optimization work here — AI-assistant/answer-engine packaging belongs to the sibling `geo-optimization` skill.
- If the page isn't meant to be public yet, the correct fix is `noindex`, not a full SEO pass.
