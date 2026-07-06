# SPP course-coverage skills — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use super-puper-powers:subagent-driven-development (recommended) or super-puper-powers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 8 SPP-original skills (2 phase-6 checkpoints + 6 standalone helpers) so the course can rely on SPP for its whole spine, and wire the two checkpoints into the phase-6 orchestration.

**Architecture:** Two phase checkpoints (`data-boundaries`, `pre-show-audit`) run inside phase-6 completion, after the final whole-branch review and before the acceptance demo, orchestrator-owned, no phase renumbering. Six helper skills are standalone, outside the state machine, invoked by their own description triggers. Methodology is distilled from existing course content in `apps/course`.

**Tech Stack:** Markdown SKILL.md files with YAML frontmatter; no code, no automated test suite (SPP has none). Verification is structural: valid frontmatter, orchestrator awareness, dry-run of the phase-6 sequence.

**Spec:** `docs/superpowers/specs/2026-07-06-spp-course-coverage-skills-design.md`

**Source content (read-only, other repo):** `/Users/sergeytovarov/work/popovstech/apps/course/src/content/course/`
- modules `modules/13-data-boundaries/`, `modules/14-quality-audit/`
- quests `quests/{data-boundaries-sidequest,accessibility,mobile-version,test-runner-setup,seo-baseline,geo-optimization,ux-copywriting}.md`

**Spec deltas found during planning (apply these, they override the spec):**
- UPSTREAM.md needs no new "SPP-original" section — line 23 already declares original skills intentionally absent from the vendoring table. Only optionally extend that parenthetical. (Spec §6 revised.)
- README has no literal skill counter to bump; skills are documented per-phase. Drop the "22 → 30" counter edit. (Spec §7 revised.)
- hooks/`plugin.json` do not enumerate skills; `session-start` reads only the orchestrator. No changes there. (Spec §8 confirmed.)

**Conventions to follow (verified in repo):**
- Original SPP skills carry NO obra attribution header (see `skills/release-fixation/SKILL.md`). Only vendored skills do.
- Frontmatter is exactly `name:` and `description:` (single-line description with the trigger baked in).
- Phase skills read/write `docs/spp/pipeline-state.md`; helpers do not touch it.
- One commit per skill/edit. Commit messages: Conventional Commits, Russian description.

---

## Task 1: `data-boundaries` phase-checkpoint skill

**Files:**
- Create: `skills/data-boundaries/SKILL.md`
- Source: `apps/course/.../modules/13-data-boundaries/{concept.md,practice.md}`, `apps/course/.../quests/data-boundaries-sidequest.md`

- [ ] **Step 1: Read the source content**

Run:
```bash
sed -n '1,220p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/modules/13-data-boundaries/concept.md
sed -n '1,220p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/modules/13-data-boundaries/practice.md
sed -n '1,140p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/quests/data-boundaries-sidequest.md
```
Extract the *agent action*: make storage explicit, verify export, list boundary risks, name the next growth layer. Ignore pedagogy/story framing.

- [ ] **Step 2: Write `skills/data-boundaries/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: data-boundaries
description: Use during phase 6, after implementation's final whole-branch review and before the acceptance demo (orchestrator-driven) - makes data storage explicit, verifies export, and checks storage boundaries and risks, writing docs/spp/06-data-boundaries.md; also runnable standalone when asked where a product's data lives or whether its storage and export are sound
---
```
Required body sections:
- `## Overview` — this is a phase-6 checkpoint, not a numbered phase; runs after subagent-driven-development's whole-branch review, before the acceptance demo; findings become fix-tasks, no separate human gate.
- `## When this runs` — orchestrator-driven inside phase 6, and standalone by the trigger above.
- `## Process` — numbered steps: (0) read `docs/spp/pipeline-state.md`; (1) locate where data physically lives; (2) confirm the storage decision from `03-stack.md`/`04-specs/` — if it was left implicit, fix it explicitly here; (3) verify export works and contains no leaked/extra fields; (4) list boundary risks and the next growth layer; (5) write the artifact; (6) set `data_boundaries_checked: true` with the artifact path in `pipeline-state.md`.
- `## Artifact` — `docs/spp/06-data-boundaries.md`: storage map + boundary findings table (risk → blocker? → fix/defer).
- `## Done` — storage decision explicitly recorded; export verified; every boundary risk marked fixed or deferred-with-reason; state field set.

Voice: SPP skill voice (English SKILL.md, imperative, like `release-fixation`). No obra attribution header.

- [ ] **Step 3: Verify frontmatter**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/data-boundaries/SKILL.md
```
Expected: valid `---`/`name:`/`description:`/`---` block, name is `data-boundaries`.

- [ ] **Step 4: Commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers
git add skills/data-boundaries/SKILL.md
git commit -m "feat(skills): добавить фазовый чекпоинт data-boundaries"
```

---

## Task 2: `pre-show-audit` phase-checkpoint skill

**Files:**
- Create: `skills/pre-show-audit/SKILL.md`
- Source: `apps/course/.../modules/14-quality-audit/{concept.md,practice.md}`

- [ ] **Step 1: Read the source content**

Run:
```bash
sed -n '1,160p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/modules/14-quality-audit/concept.md
sed -n '1,200p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/modules/14-quality-audit/practice.md
```
Extract the *agent action*: audit hidden pre-show risks + minimal security, fix only what blocks a normal first show.

- [ ] **Step 2: Write `skills/pre-show-audit/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: pre-show-audit
description: Use during phase 6, after data-boundaries and before the acceptance demo (orchestrator-driven) - audits a built product for hidden pre-show risks (broken mobile, failing build, stray debug text, leaky export, input that breaks the UI) plus minimal security, writes docs/spp/06-pre-show-audit.md and turns blockers into fix-tasks; also runnable standalone when asked to check a product before showing it
---
```
Required body sections:
- `## Overview` — phase-6 checkpoint after `data-boundaries`, before the acceptance demo; agent-run, findings become fix-tasks, no separate human gate (the acceptance demo is the human gate).
- `## When this runs` — orchestrator-driven inside phase 6, and standalone by the trigger.
- `## Process` — numbered: (0) read `pipeline-state.md`, confirm `data_boundaries_checked: true`; (1) audit categories — title/meta, mobile break, build health, stray debug text, export JSON leaking extra data, inputs that break the UI; (2) minimal security — data leakage, input handling; (3) classify each finding severity + blocker?; (4) fix blockers (or record explicit defer-with-reason); (5) write the artifact; (6) set `pre_show_audit_checked: true` with path in `pipeline-state.md`.
- `## Artifact` — `docs/spp/06-pre-show-audit.md`: audit report (risk → severity → blocker? → fix).
- `## Done` — audit report produced; all blockers fixed or explicitly deferred with reason; state field set.

No obra attribution header.

- [ ] **Step 3: Verify frontmatter**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/pre-show-audit/SKILL.md
```
Expected: valid block, name is `pre-show-audit`.

- [ ] **Step 4: Commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers
git add skills/pre-show-audit/SKILL.md
git commit -m "feat(skills): добавить фазовый чекпоинт pre-show-audit"
```

---

## Task 3: Wire both checkpoints into the orchestrator

**Files:**
- Modify: `skills/using-super-puper-powers/SKILL.md` (section "Phase 6 Gate Ownership")

- [ ] **Step 1: Read the current Phase 6 Gate Ownership section**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers && grep -n "Phase 6 Gate Ownership" skills/using-super-puper-powers/SKILL.md
```
Then read that section and the following ~30 lines to find the sentence that runs the acceptance demo "After subagent-driven-development's final whole-branch review completes, the orchestrator runs the **acceptance demo**…".

- [ ] **Step 2: Insert the two checkpoints before the acceptance demo**

Edit that sentence so the sequence becomes: after the final whole-branch review, the orchestrator runs `data-boundaries`, then `pre-show-audit`, THEN the acceptance demo. Add a paragraph:

> After the final whole-branch review and before the acceptance demo, the orchestrator runs two checkpoint skills in order: `super-puper-powers:data-boundaries`, then `super-puper-powers:pre-show-audit`. Each writes its artifact (`docs/spp/06-data-boundaries.md`, `docs/spp/06-pre-show-audit.md`) and sets its state field (`data_boundaries_checked`, `pre_show_audit_checked`). Their findings are fix-tasks, not human gates — the acceptance demo remains the only human-facing gate of phase 6. The acceptance demo MUST NOT start until both state fields are `true`.

- [ ] **Step 3: Add the state fields to the state-machine description**

In the same file, find where `pipeline-state.md` fields are described (near "State Machine" / "Phase 6 Execution Profile"). Add `data_boundaries_checked` and `pre_show_audit_checked` (boolean + artifact path) to the recorded fields, with one line: both must be `true` before the acceptance demo runs, machine-checked, not recalled.

- [ ] **Step 4: Add a Red-Flags row**

In the "Red Flags" table of the orchestrator, add a row:

| "I'll go straight to the acceptance demo, the build looks clean" | data-boundaries and pre-show-audit run first. Machine-check `data_boundaries_checked` and `pre_show_audit_checked` are `true` in pipeline-state.md before the demo. |

- [ ] **Step 5: Verify the edit reads coherently**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers && grep -n "data-boundaries\|pre-show-audit\|acceptance demo" skills/using-super-puper-powers/SKILL.md
```
Expected: checkpoints appear before the acceptance-demo run sentence; both state fields referenced.

- [ ] **Step 6: Commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers
git add skills/using-super-puper-powers/SKILL.md
git commit -m "feat(orchestrator): встроить чекпоинты фазы 6 перед acceptance demo"
```

---

## Task 4: Helper skill `accessibility`

**Files:**
- Create: `skills/accessibility/SKILL.md`
- Source: `apps/course/.../quests/accessibility.md`

- [ ] **Step 1: Read source**

Run: `sed -n '1,140p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/quests/accessibility.md`

- [ ] **Step 2: Write `skills/accessibility/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: accessibility
description: Use when asked to check or fix basic accessibility (a11y) of an MVP's UI - runs a baseline audit of keyboard navigation, contrast, visible focus, form labels, error clarity and basic screen-reader support, then applies or lists fixes without expanding scope
---
```
Body: `## Overview` (standalone helper, not part of the state machine, no pipeline-state writes), `## Checklist` (the baseline items from source), `## Process` (audit → fix/list → report), `## Scope guard` (design-only, no new features). No obra header.

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/accessibility/SKILL.md
git add skills/accessibility/SKILL.md
git commit -m "feat(skills): добавить helper-скил accessibility"
```

---

## Task 5: Helper skill `mobile-version`

**Files:**
- Create: `skills/mobile-version/SKILL.md`
- Source: `apps/course/.../quests/mobile-version.md`

- [ ] **Step 1: Read source**

Run: `sed -n '1,90p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/quests/mobile-version.md`

- [ ] **Step 2: Write `skills/mobile-version/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: mobile-version
description: Use when asked to make an MVP work on phones or check it on a narrow screen - a design-only responsive pass that stops the existing desktop UI from breaking on mobile (overflow, tap targets, forms) without touching the data model, features or scope
---
```
Body: `## Overview` (standalone helper), `## Process` (narrow-screen pass: overflow, tap targets, forms), `## Scope guard` (design-only: no data model, no features, no scope). No obra header.

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/mobile-version/SKILL.md
git add skills/mobile-version/SKILL.md
git commit -m "feat(skills): добавить helper-скил mobile-version"
```

---

## Task 6: Helper skill `test-runner-setup`

**Files:**
- Create: `skills/test-runner-setup/SKILL.md`
- Source: `apps/course/.../quests/test-runner-setup.md`

- [ ] **Step 1: Read source**

Run: `sed -n '1,90p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/quests/test-runner-setup.md`

- [ ] **Step 2: Write `skills/test-runner-setup/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: test-runner-setup
description: Use when asked to set up tests or a test runner for a project that has none - installs a test runner and one smoke test so behavior checks become a command, without requiring full coverage
---
```
Body: `## Overview` (standalone helper; feeds the TDD phase by making "behavior check" a command), `## Process` (pick runner for the stack → install → one smoke test → run it), `## Scope guard` (working runner + one smoke test, not full coverage). No obra header.

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/test-runner-setup/SKILL.md
git add skills/test-runner-setup/SKILL.md
git commit -m "feat(skills): добавить helper-скил test-runner-setup"
```

---

## Task 7: Helper skill `seo-baseline`

**Files:**
- Create: `skills/seo-baseline/SKILL.md`
- Source: `apps/course/.../quests/seo-baseline.md`

- [ ] **Step 1: Read source**

Run: `sed -n '1,130p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/quests/seo-baseline.md`

- [ ] **Step 2: Write `skills/seo-baseline/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: seo-baseline
description: Use when asked for SEO baseline or to make a public page shareable - adds the technical page packaging (title, description, favicon, Open Graph preview, robots, sitemap, page structure) so links and previews look intentional
---
```
Body: `## Overview` (standalone helper), `## Checklist` (title, description, favicon, OG, robots, sitemap, structure), `## Process`, `## Scope guard` (technical packaging, not ranking campaigns). No obra header.

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/seo-baseline/SKILL.md
git add skills/seo-baseline/SKILL.md
git commit -m "feat(skills): добавить helper-скил seo-baseline"
```

---

## Task 8: Helper skill `geo-optimization`

**Files:**
- Create: `skills/geo-optimization/SKILL.md`
- Source: `apps/course/.../quests/geo-optimization.md`

- [ ] **Step 1: Read source**

Run: `sed -n '1,110p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/quests/geo-optimization.md`

- [ ] **Step 2: Write `skills/geo-optimization/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: geo-optimization
description: Use when asked about GEO (generative engine optimization) or making a product understandable to AI assistants - packages a public page so AI and summary tools grasp what the product does, for whom, its limits and where the facts are; sibling of seo-baseline, does not duplicate search-engine packaging
---
```
Body: `## Overview` (standalone helper; sibling of `seo-baseline`, explicitly does not duplicate search-engine packaging), `## Process` (state what/for-whom/limits/facts clearly on the public page), `## Scope guard`. No obra header.

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/geo-optimization/SKILL.md
git add skills/geo-optimization/SKILL.md
git commit -m "feat(skills): добавить helper-скил geo-optimization"
```

---

## Task 9: Helper skill `ux-copywriting`

**Files:**
- Create: `skills/ux-copywriting/SKILL.md`
- Source: `apps/course/.../quests/ux-copywriting.md`

- [ ] **Step 1: Read source**

Run: `sed -n '1,204p' /Users/sergeytovarov/work/popovstech/apps/course/src/content/course/quests/ux-copywriting.md`

- [ ] **Step 2: Write `skills/ux-copywriting/SKILL.md`**

Frontmatter (exact):
```yaml
---
name: ux-copywriting
description: Use when asked to write or improve UI text or microcopy - produces interface copy and states (empty, error, loading) from screen context, state and user action, scoped to the current scenario
---
```
Body: `## Overview` (standalone helper), `## Inputs` (screen context, state, user action), `## Process` (produce copy + the empty/error/loading states), `## Scope guard` (current scenario only, no new screens). No obra header.

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers && head -4 skills/ux-copywriting/SKILL.md
git add skills/ux-copywriting/SKILL.md
git commit -m "feat(skills): добавить helper-скил ux-copywriting"
```

---

## Task 10: Orchestrator — On-demand helpers section

**Files:**
- Modify: `skills/using-super-puper-powers/SKILL.md`

- [ ] **Step 1: Add an "On-demand helpers" section**

After the "Skill Priority" section, add:

```markdown
## On-demand helpers

Six standalone helper skills sit outside the state machine and do not touch `pipeline-state.md`. Invoke them by their own triggers when the work calls for it — usually during phase 6, and `seo-baseline`/`geo-optimization` also around phase 8:

- `super-puper-powers:accessibility` — baseline a11y audit and fixes.
- `super-puper-powers:mobile-version` — design-only responsive pass.
- `super-puper-powers:test-runner-setup` — test runner + one smoke test.
- `super-puper-powers:seo-baseline` — technical page packaging for shareable links.
- `super-puper-powers:geo-optimization` — public-page packaging for AI assistants.
- `super-puper-powers:ux-copywriting` — UI microcopy and states.

None of these expand product scope: they are design-only, packaging, or verification actions over work already built.
```

- [ ] **Step 2: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers && grep -n "On-demand helpers" skills/using-super-puper-powers/SKILL.md
git add skills/using-super-puper-powers/SKILL.md
git commit -m "docs(orchestrator): добавить раздел On-demand helpers"
```

---

## Task 11: README + README.en — phase-6 checkpoints and helpers

**Files:**
- Modify: `README.md`, `README.en.md`

- [ ] **Step 1: Add the two checkpoints to the phase-6 description**

In `README.md` find `### Фаза 6: реализация` (line ~291) and the phase-6 summary at line ~125. Add, in Russian, that after the whole-branch review and before the acceptance demo the orchestrator runs `data-boundaries` (границы хранения, экспорт) and `pre-show-audit` (риски перед показом + минимальная безопасность), findings become fix-tasks, human gate stays the acceptance demo.

- [ ] **Step 2: Add an on-demand helpers subsection to README**

After `### Фазы 7–9` add a short subsection listing the six helpers with one line each (as in Task 10), noting they are standalone and do not expand scope.

- [ ] **Step 3: Mirror both edits in `README.en.md`**

Same two additions, English, matching the file's existing structure and headings.

- [ ] **Step 4: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers
grep -n "data-boundaries\|pre-show-audit\|accessibility" README.md README.en.md | head
git add README.md README.en.md
git commit -m "docs(readme): описать чекпоинты фазы 6 и helper-скилы"
```

---

## Task 12: Design docs + UPSTREAM housekeeping

**Files:**
- Modify: `docs/super-puper-powers-spec.md`, `docs/super-puper-powers-pipeline.md`, `UPSTREAM.md`

- [ ] **Step 1: Note the phase-6 checkpoints in the design docs**

In `docs/super-puper-powers-pipeline.md` and `docs/super-puper-powers-spec.md`, add a short note that phase 6 now has two orchestrator-owned checkpoints (`data-boundaries`, `pre-show-audit`) before the acceptance demo, and that six standalone helper skills exist. Keep it brief — these are design docs, not the source of truth for the skills themselves.

- [ ] **Step 2: Extend the UPSTREAM.md line-23 parenthetical**

Find line 23 ("Files that are original SPP work … are intentionally absent from this table"). Extend its parenthetical to mention the course-coverage skills so a future reader knows they are original, e.g. add "the phase-6 checkpoint skills and the on-demand helper skills" to the examples list. Do NOT add a vendoring-table row for them.

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sergeytovarov/work/superpuperpowers
grep -n "data-boundaries\|helper\|checkpoint\|чекпоинт" docs/super-puper-powers-pipeline.md docs/super-puper-powers-spec.md UPSTREAM.md | head
git add docs/super-puper-powers-pipeline.md docs/super-puper-powers-spec.md UPSTREAM.md
git commit -m "docs(spp): отметить чекпоинты фазы 6 и helper-скилы в дизайн-доках"
```

---

## Task 13: Final verification pass

**Files:** none (verification only)

- [ ] **Step 1: All 8 SKILL.md exist with valid frontmatter**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers
for s in data-boundaries pre-show-audit accessibility mobile-version test-runner-setup seo-baseline geo-optimization ux-copywriting; do echo "== $s =="; head -4 skills/$s/SKILL.md; done
```
Expected: each prints a valid `---`/`name:`/`description:`/`---` block with the matching name.

- [ ] **Step 2: No stray obra attribution header on originals**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers
grep -L "Vendored from" skills/{data-boundaries,pre-show-audit,accessibility,mobile-version,test-runner-setup,seo-baseline,geo-optimization,ux-copywriting}/SKILL.md
```
Expected: all 8 paths listed (grep -L = files WITHOUT the vendored header), confirming none carry it.

- [ ] **Step 3: Orchestrator wiring present**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers
grep -c "data_boundaries_checked\|pre_show_audit_checked" skills/using-super-puper-powers/SKILL.md
grep -c "On-demand helpers" skills/using-super-puper-powers/SKILL.md
```
Expected: state fields referenced (≥2), On-demand helpers section present (≥1).

- [ ] **Step 4: Dry-run reasoning of the phase-6 sequence**

Read the edited "Phase 6 Gate Ownership" section end to end and confirm the order reads: whole-branch review → `data-boundaries` → `pre-show-audit` → acceptance demo, with the "both fields true before the demo" guard. No code to run; this is a read-through check.

- [ ] **Step 5: Confirm clean tree**

Run:
```bash
cd /Users/sergeytovarov/work/superpuperpowers && git status --short && git log --oneline -13
```
Expected: clean working tree; ~12 feature commits on `feat/course-coverage-skills` plus the spec commit.
