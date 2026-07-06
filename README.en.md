# super-puper-powers

> Русская версия: [README.md](./README.md)

A plugin for agentic coding tools — Claude Code and OpenAI Codex — that takes a person
from a raw idea to a deployed product in ten phases, built so that the person
**doesn't need to know how to code**.

Every phase ends in a question that the product owner can answer, not an
engineer: about scenarios, about money, about whether the demo actually works. Technical
decisions — architecture, data model, error handling, stack choice — the agent makes on
its own and records with reasoning. Not a single gate is phrased in the language of a
diff or an architecture.

The implementation core is taken from [obra/superpowers](https://github.com/obra/superpowers)
v6.1.1 (MIT, author Jesse Vincent). The phases before code (discovery, MVP, stack) and after
(release, deploy, operations) are original.

---

## Why this exists

There's a person with a product idea — a telegram bot, a small web service, a utility. They
don't write code. The usual path is closed to them: to reach a working product you have to make
dozens of technical decisions you can't judge, and at every step someone asks you about
something you don't understand.

SPP closes that gap. The agent runs the entire technical side, and only asks the human
what they can actually answer: what problem are we solving, for whom, which scenarios matter,
how much are they willing to pay for hosting, is this the right product on the demo. Everything
else is the agent's job, and it's recorded in documents you can reread
six months later.

## Why it works this way

Five principles. Breaking any one of them is a defect, not a style choice.

1. **Every gate with a human is phrased in product language.** Scenarios, demos, money. Never
   a diff, never architecture. If a gate asks the owner about a merge or a database schema —
   that's a broken gate.
2. **The agent makes technical decisions on its own** and records them in writing with
   reasoning. The human is only asked what they can actually answer.
3. **Every phase produces a document and ends in a gate.** Six months later it's clear
   why the product is built the way it is.
4. **The pipeline is resumable.** Cross-chat memory lives in an optional journal,
   `docs/spp/pipeline-state.md` — what the project is, what's been done, what was decided. A new
   session reads it for context, not as enforcing state: the journal gates nothing and forces no
   next phase. Interrupting work and coming back tomorrow is the normal case, not an incident.
5. **The right to say no-go.** Discovery can legitimately kill the project. Stopping on an idea
   that won't fly is a phase win, not a failure — months of work saved.

## What we build on and what we extend

obra/superpowers is a library of composable skills that make an agent follow
engineering discipline: TDD, systematic debugging, review after every task,
"evidence before assertions," subagents with clean context. All of this is a strong
core for **code implementation**, and it's taken as-is in full.

But upstream starts at technical design and ends at merge. It silently
assumes the idea is valid, the stack is already chosen, someone downstream will handle
deploy, and the human on the other side of the gates is a developer. SPP fills in what's
missing:

- **Before code** — discovery, MVP-scoping, and stack-selection phases, which upstream has
  none of.
- **Document review** — an independent check of the spec and the plan by a subagent with clean
  context (upstream reviews code, but not the spec or the plan — inconsistent).
- **After code** — release fixation, choosing and executing a deploy strategy, operations with
  a feedback loop.
- **A dispatcher-orchestrator and a journal** — route work by context and tie disparate skills
  into a pipeline with gates phrased in product language; the phase order is a recommendation,
  not enforced.

## How the pipeline works

Ten phases. Each one: input → agent's work → artifact document → gate with the human.

| Phase | Skill | Artifact | Gate |
|---|---|---|---|
| 0 | idea-intake | `00-idea-brief.md` | "Did I get the idea right?" |
| 1 | product-discovery | `01-discovery-report.md` | go / pivot / stop |
| 2 | mvp-scoping | `02-mvp-scope.md` | approval of the scenario list |
| 3 | stack-selection | `03-stack.md` | choice of stack option |
| 4 | spec-writing (+ spec-review, cross-spec-review) | `04-specs/` | approval of the product summary |
| 5 | plan-writing (+ plan-review) | `05-plans/` | "N tasks — shall we start?" |
| 6 | subagent-driven-development (gate owned by the orchestrator) | `06-acceptance-demo.md` | demo: every scenario works live |
| 7 | release-fixation | `07-release-notes.md` | "Fixing version X?" |
| 8 | deploy-strategy | `08-deploy-runbook.md` | "The product is live at X — do you accept it?" |
| 9 | post-release | `09-operations.md` | final: operations handbook accepted |

The 0→9 phase order is a recommended route, not a rigid sequence. The orchestrator is a
dispatcher: it routes by the context of the request (like upstream `using-superpowers`) rather
than marching the person through phases. Any skill can be invoked directly by name or request at
any time; there is no "phase N+1 doesn't start until phase N's gate is confirmed" rule. Each
phase skill ends by suggesting the next logical step and offering to start it in a fresh chat —
the person drives the transition, not automation (the one exception is plan-writing, which hands
off straight into subagent-driven-development in the same session).

The journal `docs/spp/pipeline-state.md` is optional: it's cross-chat memory and a decisions log
(what the project is, what's been done, jurisdiction, chosen stack), not a state machine. It
blocks no skill. At the start of a session the orchestrator reads it as context and reminds you
where you left off — but whether to continue from that phase or invoke something else is your
call. So the pipeline survives a restart, a context compaction, and a week-long pause.

## What each phase looks like from your side

What happens at each step and what's actually needed from you — a person with no developer
skills. The technical breakdown of each skill is in the next section; this one is the
practical angle. The order below is recommended: any skill can be invoked directly at any time,
and each phase ends by suggesting the next one and offering to open it in a fresh chat (except
the handoff to implementation — that runs on without a pause).

**Phase 0 — idea-intake.** You describe the idea in a couple of sentences. Then the agent asks
questions one at a time: what problem are we solving, for whom, how is it different, budget,
timeline, where do your users live. From you — answers in plain language, no technical detail.
Output: an idea brief; at the gate you confirm you were understood correctly.

**Phase 1 — product-discovery.** The agent goes off to research: competitors, legal risks,
demand, whether this can actually be built. You pick a mode — quick (half an hour) or deep
(hours). Nothing else is needed from you until the report arrives. Output: a report with an
"idea killers" section and a recommendation; at the gate you decide go / pivot / stop. Stopping
here is fine — it's months of work saved.

**Phase 2 — mvp-scoping.** The agent sorts features into "first version / later / never" and
assembles a minimal end-to-end scenario. From you — decisions on the disputed points, one at a
time. Output: a scenario list; at the gate you approve the scenarios themselves ("the user
does X → gets Y"), not the technology.

**Phase 3 — stack-selection.** The agent proposes 2–3 options to build on and explains them in
terms of consequences for you: cost, how to update. From you — a choice based on money and
convenience, not framework names. Output: a fixed stack.

**Phase 4 — spec-writing.** The agent designs the product and asks only about behavior: what the
user sees, what the copy says, what happens on errors. It decides the technical side itself.
An independent reviewer checks the spec. From you — answers about the product. Output: a spec;
at the gate you approve a short product summary, no need to read the full spec.

**Phase 5 — plan-writing.** The agent turns the spec into a plan of small tasks and runs it
through a separate reviewer. From you — almost nothing. Output: a plan; at the gate you answer
one question: "there are N tasks, shall we start?"

**Phase 6 — implementation.** The agent writes code from the plan: tests, review after every
task. Nothing from you until it's assembled. After the whole-branch review and before the demo,
the orchestrator runs two checkpoints — `data-boundaries` (where and how data is stored, what
can be exported) and `pre-show-audit` (risks before showing the product and minimal security).
Their findings become fix-tasks, not a separate gate. Then the agent brings the product up live
(dev server, bot in test mode) and walks you through every scenario. Output: working code; at
the gate you watch every scenario work in front of your eyes — still the only gate in phase 6
where the decision is yours.

**Phase 7 — release-fixation.** The agent fixes the version, writes up what the product can now
do (in your language, not a list of commits), tags it. From you — confirm the version. Output:
release notes.

**Phase 8 — deploy-strategy.** The agent proposes how to ship the product: 2–3 options with a
monthly price tag and update complexity, asks about your accounts and hosting (never guesses).
You choose, the agent deploys and verifies on production. Output: a runbook — how it's deployed,
how to update, how to roll back; at the gate you accept that the product is live at an address.

**Phase 9 — post-release.** The agent sets up minimal monitoring and a feedback channel, writes
an incident handbook in your language ("if the bot goes silent — do A, B, then message the
agent"). Output: an operations handbook. From here, feedback can start a new turn of the
pipeline.

## Skills — what each one does

For each skill: what it does, how it's triggered ("Trigger"), whether it can be invoked
standalone, outside the pipeline ("Standalone"), and its place in the handoff chain
("In the chain").

### Orchestration

- **using-super-puper-powers** — a dispatcher that routes by the context of the request (like
  upstream `using-superpowers`) rather than marching the person through phases. The 0→9 phase
  order is a recommendation to it, not enforcement: any skill is invoked directly regardless of
  position in the map. Owns the gate language (product only, never diff or architecture), its own
  phase 6 safety checks (which read artifacts on disk, not journal fields), and the choice of
  lite/full mode for phase 6 based on the estimate from plan-writing. It reads the
  `pipeline-state.md` journal as memory, not as an access switch.
  - *Trigger:* in Claude Code — automatically, via the `SessionStart` hook at the start of every
    session. Codex has no hook — the skill is invoked by direct reference at the start, or to
    resume the pipeline.
  - *Standalone:* this isn't a phase or a step in someone else's chain — it's the dispatcher
    that decides which skill to run. It has no separate "standalone mode" because it is itself
    the entry point into any pipeline work session.
  - *In the chain:* consumes and passes nothing as a phase — at start it reads the journal as
    context (if one exists) and routes by the request: into idea-intake, into the named phase
    skill directly, or into release-fixation after the phase 6 gate.

### Phases 0–3: from idea to stack (original skills)

- **idea-intake** (phase 0) — an interview, one question at a time: the problem, who it's for,
  how it's different, the success criterion, budget, timeline, jurisdiction (where the users
  are, where the author is), the artifact language. Doesn't re-ask what's already stated in the
  idea description. Writes the brief and creates the state file. Gate — retelling the idea in
  your own words.
  - *Trigger:* automatically, by its own description-trigger — when the user describes a
    product idea and `docs/spp/pipeline-state.md` doesn't exist yet.
  - *Standalone:* this is the start itself — the whole point of the skill is to be an entry
    point with no pipeline. There's no separate mode beyond this, because before idea-intake
    there simply is no pipeline.
  - *In the chain:* the first skill in the chain, consumes nothing. Creates `pipeline-state.md`
    and `00-idea-brief.md`, hands them to product-discovery.

- **product-discovery** (phase 1) — research before building anything: competitors and
  alternatives, legal risks for the jurisdiction from the brief, market and demand, feasibility
  for a solo agent. Two modes: quick (half an hour, one subagent) and deep (hours, parallel
  subagents plus fact-checking). A mandatory "idea killers" section and an explicit verdict on
  the differentiator — survived / weak / killed by competitors. The only phase where stopping
  is a normal outcome.
  - *Trigger:* by its own standalone trigger — a direct request like "check this idea for
    competitors / legal risks / whether it's worth building", and also as the recommended next
    step after phase 0 (idea-intake suggests it at the end but doesn't invoke it).
  - *Standalone:* yes. Without `pipeline-state.md`, gathers the problem, the audience, and both
    jurisdictions right in the conversation, writes `01-discovery-report.md` as a standalone
    document, the go/pivot/stop gate works the same way but doesn't touch state or the Decisions
    log. After the gate, names mvp-scoping as an option, not a mandatory next step.
  - *In the chain:* consumes `00-idea-brief.md` from idea-intake. On go — passes
    `01-discovery-report.md` (with the differentiator verdict and the "idea killers" section) to
    mvp-scoping. On pivot — returns to idea-intake. On stop — ends the pipeline.

- **mvp-scoping** (phase 2) — turns the brief and discovery into a prioritized scope: must /
  later / never, a walking skeleton (the minimal end-to-end scenario that proves value), an
  explicit "what's not in the MVP" section. The gate approves the scenario list, not the
  features. Checks that the differentiator made it into must, and raises a weak discovery
  verdict as a separate question to the owner.
  - *Trigger:* by its own standalone trigger — a direct request like "draft an MVP scope / what
    should the first version do", and also as the recommended next step after a go decision in
    discovery (which suggests it at the end but doesn't invoke it).
  - *Standalone:* yes. Without an approved phase 1, takes the problem, the audience, and the
    differentiation answer directly from the user; if there's no discovery report at all,
    explicitly notes in the artifact that prioritization happened without a competitor and
    legal-risk check. The scenario gate works the same way, doesn't touch state.
  - *In the chain:* consumes `00-idea-brief.md` and `01-discovery-report.md` (including the
    differentiator verdict). Passes `02-mvp-scope.md` with the scenario list and the walking
    skeleton to stack-selection.

- **stack-selection** (phase 3) — picks a stack from 2–3 options. The first criterion is
  agent-maintainability (mainstream tech with a large corpus of examples is easier for an
  agent to fix than something exotic), then operating cost, speed to MVP, deploy compatibility.
  Frames trade-offs as consequences for the owner ("free hosting, one-command updates" versus
  "more flexible, but 20 dollars a month"), not framework properties.
  - *Trigger:* by its own standalone trigger — a direct request like "pick a stack for this",
    and also as the recommended next step after phase 2 (mvp-scoping suggests it at the end but
    doesn't invoke it).
  - *Standalone:* yes. Without an approved MVP scope, takes from the user what the product does
    as an end-to-end scenario, plus budget/timeline/jurisdiction — and runs the same 2–3-option
    choice. Doesn't touch state.
  - *In the chain:* consumes `02-mvp-scope.md` (the walking skeleton) and `00-idea-brief.md`
    (budget, timeline, jurisdiction). Passes `03-stack.md` with the chosen stack and a section on
    the test runner to spec-writing.

### Phase 4: the spec and its review

- **spec-writing** (phase 4) — a technical spec through dialogue: the owner is only asked about
  product behavior (scenarios, copy, edge cases); the agent decides architecture and data model
  itself and records it in the spec with reasoning. Gate — a product summary, no need to read
  the full spec.
  - *Trigger:* by its own standalone trigger — a direct request like "write a spec for this
    feature/product", and also as the recommended next step after phase 3 (stack-selection
    suggests it at the end but doesn't invoke it).
  - *Standalone:* yes. Without an approved phase 3, takes from the user what the feature does
    and what it's built on (language, framework, constraints), instead of reading
    `02-mvp-scope.md` and `03-stack.md`. The HARD-GATE ("not a line of code before the summary
    is approved") applies unchanged — it isn't relaxed even outside the pipeline.
  - *In the chain:* consumes `02-mvp-scope.md` and `03-stack.md`. Internally — a terminal chain
    of self-review → spec-review → (if there's more than one spec) cross-spec-review → product
    summary → gate. The user doesn't invoke spec-review and cross-spec-review directly — they're
    internal steps of its own process. After the gate it suggests plan-writing as the next step
    in a fresh chat, but doesn't invoke it automatically.

- **spec-review** — an independent check of the spec by a subagent with clean context (gets only
  the spec, the MVP scope, and the stack — not the session history). Looks for: uncovered
  must-scenarios, contradictions, ambiguities, things not buildable on the stack, placeholders.
  Critical and Important issues are fixed before the gate, the cycle repeats until it's clean.
  - *Trigger:* automatically from spec-writing right after the author's self-review — not a
    phase gate, but a mandatory step inside phase 4.
  - *Standalone:* not invoked directly — part of the phase 4 cycle. The user doesn't ask for
    "do a spec-review," they get it as a built-in check when they ask for a spec to be written.
  - *In the chain:* consumes the spec, `02-mvp-scope.md`, `03-stack.md`. On a clean pass, returns
    control to spec-writing (to cross-spec-review, if there's more than one spec) — it doesn't
    decide the gate and doesn't move `current_phase` itself.

- **cross-spec-review** — if the product is split into sub-projects, checks the whole set of
  specs at once: interface consistency, seam gaps, contradictions, build order. Records the
  recommended implementation order in state.
  - *Trigger:* automatically, when spec-review passes and `docs/spp/04-specs/` has more than one
    spec.
  - *Standalone:* not invoked directly — part of the phase 4 cycle, and conditional besides: with
    a single spec it doesn't run at all.
  - *In the chain:* consumes the entire set of specs at once (as a single subagent, not one at a
    time). On a clean pass, writes `subproject_order` to state and returns control to
    spec-writing — this is the order that plan-writing and the phase 6 orchestrator later read.

### Phase 5: the plan and its review

- **plan-writing** (phase 5) — an implementation plan of small tasks (2–5 minutes each, with
  ready-made code) that the implementer doesn't need to hold context for. Every task declares a
  verification type (unit test / accept via demo / manual check) — TDD isn't forced where the
  stack can't support a unit test. Estimates the size of the plan and recommends a lighter mode
  for tiny ideas.
  - *Trigger:* by its own standalone trigger — a direct request like "turn this spec into an
    implementation plan", and also as the recommended next step after phase 4 (spec-writing
    suggests it at the end but doesn't invoke it).
  - *Standalone:* yes. Without an approved phase 4, takes the spec from wherever the user points
    — a file on disk, pasted text — instead of reading `docs/spp/04-specs/`. All the rigor
    (breaking into tasks, self-review, plan-review) runs unchanged; only state and the Decisions
    log aren't written.
  - *In the chain:* consumes the spec (and `subproject_order`, if there's more than one spec).
    Internally — self-review → plan-review → "N tasks, shall we start?" →
    subagent-driven-development. This is the one handoff that happens automatically in the same
    session, not as a suggestion into a fresh chat: after "shall we start?" the build runs
    continuously. Writes `pipeline_profile` (lite/full) to state — this decides how phase 6
    executes the plan.

- **plan-review** — an independent check of the plan by a subagent: is every spec requirement
  covered by a task, are names and signatures consistent across tasks, are there placeholders
  like "add appropriate error handling," are the steps actually doable. A cycle until it's
  clean.
  - *Trigger:* automatically from plan-writing right after the author's self-review, before the
    "N tasks — shall we start?" gate.
  - *Standalone:* not invoked directly — part of the phase 5 cycle. Like the phase 4 review
    skills, it's a built-in step, not a separate user request.
  - *In the chain:* consumes the plan and the spec it implements. On a clean pass, returns
    control to plan-writing, which goes on to the execution gate — plan-review itself doesn't
    move `current_phase` and doesn't invoke subagent-driven-development.

### Phase 6: implementation (obra/superpowers core, taken as-is)

These skills are vendored from upstream with minimal edits — only attribution,
renaming references to local names, and thin guards for SPP's gates. All nine are triggered
by their own shared description ("before writing any code," "on any bug") — meaning they fire
whenever the situation fits, not only inside phase 6. Inside the pipeline they're conducted by
subagent-driven-development; in ordinary code work (outside SPP entirely) they turn on by
themselves exactly the same way.

- **subagent-driven-development** — plan execution: a fresh subagent for every task, two reviews
  after each one (spec compliance, then code quality), a final review of the whole branch. This
  is the skill that conducts the other eight vendored skills during phase 6.
  - *Trigger:* by its own description-trigger — when an implementation plan with independent
    tasks is executed in the current session. Inside the pipeline this is the actual worker of
    phase 6.
  - *Standalone:* yes — works with any plan in this format, not only one that came from
    plan-writing. Not tied to `pipeline-state.md` as such.
  - *In the chain:* consumes the plan from plan-writing (or the lite profile from the
    orchestrator). Uses using-git-worktrees for isolation, test-driven-development inside every
    implementer subagent, requesting-code-review for the final branch review. Output: a branch
    ready for finishing-a-development-branch, but the orchestrator intercepts that handoff for
    the acceptance demo (see below).
- **test-driven-development** — a failing test first, then the code. No exceptions.
  - *Trigger:* by its own description-trigger — before writing code for any feature or fix.
  - *Standalone:* yes, in any development — it's a baseline discipline, not tied to SPP.
  - *In the chain:* inside phase 6 — mandatory practice for every implementer subagent
    dispatched by subagent-driven-development.
- **verification-before-completion** — you can't claim "done" or "tests pass" without fresh
  command output. Evidence before assertions.
  - *Trigger:* by its own description-trigger — before any claim of completion, before a commit
    or a PR.
  - *Standalone:* yes, in any development.
  - *In the chain:* inside the pipeline — a mandatory step in release-fixation (phase 7) before
    finishing the branch, and also a background discipline throughout phase 6.
- **using-git-worktrees** — an isolated workspace per branch, so tasks don't interfere with each
  other.
  - *Trigger:* by its own description-trigger — when starting work on a feature that needs
    isolation, or before executing a plan.
  - *Standalone:* yes, for any development branch outside SPP.
  - *In the chain:* invoked by subagent-driven-development before executing the plan (if the
    profile is `full`; in `lite` isolation is intentionally skipped).
- **requesting-code-review** / **receiving-code-review** — requesting a review and working with
  feedback: not blind agreement, but a technical check of every point.
  - *Trigger:* by its own description-trigger — on completing a task or a major feature, before
    a merge (requesting), and on receiving any review feedback (receiving).
  - *Standalone:* yes, both — an independent pair of disciplines for any development.
  - *In the chain:* requesting-code-review is the template subagent-driven-development uses for
    the review after every task and for the final review of the whole branch; receiving-code-
    review governs how the agent reacts to feedback in both cases.
- **systematic-debugging** — debugging by method (find the root cause, don't patch the symptom)
  before proposing a fix.
  - *Trigger:* by its own description-trigger — on any bug, failing test, or unexpected
    behavior.
  - *Standalone:* yes — fires at any point in development, inside SPP or outside it.
  - *In the chain:* inside phase 6 — what subagent-driven-development expects from subagents on
    a BLOCKED status or a failing test; outside the pipeline it turns on independently of any
    phase at all.
- **dispatching-parallel-agents** — parallel subagents for independent tasks.
  - *Trigger:* by its own description-trigger — when there are two or more independent tasks
    with no shared state.
  - *Standalone:* yes — a general parallelization pattern, not tied to SPP.
  - *In the chain:* this is the pattern product-discovery uses for four parallel research
    subagents in deep mode; the same pattern can be used by development inside phase 6 for
    independent tasks.
- **finishing-a-development-branch** — integrating a finished branch: merge / PR / leave it /
  discard it.
  - *Trigger:* by its own description-trigger — when implementation is complete and all tests
    pass; on the usual route this is the end of subagent-driven-development.
  - *Standalone:* yes, outside SPP — but inside SPP the orchestrator intercepts its call with a
    safety gate: before finishing the branch it machine-checks on disk that
    `docs/spp/06-acceptance-demo.md` exists and records the demo as approved. If it doesn't, it
    doesn't block silently — it plainly warns that the demo hasn't passed and the release is
    risky, and requires an explicit "yes, proceed anyway" (unlike the phase 6 checkpoints, this
    is a warning with the right to proceed, not an absolute stop). The check reads the file on
    disk, not a journal field.
  - *In the chain:* sits at the end of subagent-driven-development, but the actual pipeline call
    doesn't come from there directly — release-fixation (phase 7) invokes it itself, wrapping
    the technical merge/PR/leave/discard menu so the owner never sees it.

**The phase 6 gate is owned by the orchestrator, not by SDD itself.** After the final branch
review and before the acceptance demo, the orchestrator runs two checkpoints in order:
`data-boundaries` (data storage boundaries — where things live, what can be exported) and
`pre-show-audit` (risks before showing the product and minimal security). Each writes its own
artifact to disk (`docs/spp/06-data-boundaries.md`, `docs/spp/06-pre-show-audit.md`); checkpoint
findings are fix-tasks, not a human gate. Both files must exist on disk before the demo starts —
that's an absolute stop (`<HARD-GATE>`), and the orchestrator verifies it by opening the files,
not via the journal. Only then does the orchestrator run the acceptance demo — brings the
product up (dev server, package install, bot in test mode) and walks the owner through every
must-scenario. Gate: "every scenario works in front of my eyes" — the only human gate in phase 6
where the decision stays with the owner.

### Phases 7–9: release, deploy, operations (original skills)

- **release-fixation** (phase 7) — fixing the release: verification, finishing the branch (the
  agent chooses how), a semver version (first release — 0.1.0), a changelog in the owner's
  language (what the product can now do, not a list of commits), a git tag. Gate — "fixing
  version X?"
  - *Trigger:* by its own standalone trigger — a direct request like "fix a version / write
    release notes / finish the branch", and also as the recommended next step after an approved
    acceptance demo (the orchestrator hands control here, having checked on disk that
    `docs/spp/06-acceptance-demo.md` is recorded as approved).
  - *Standalone:* yes. Before finishing the branch, the skill self-checks on disk whether the
    acceptance demo has passed; if not, it warns and asks for confirmation, but doesn't block.
  - *In the chain:* consumes `06-acceptance-demo.md` (approved). Internally invokes
    verification-before-completion and finishing-a-development-branch (with the wrapped menu —
    the agent picks merge/PR, not the owner). Passes `07-release-notes.md` to deploy-strategy.
- **deploy-strategy** (phase 8) — the main value is in the choice, not in executing the recipe.
  First, 2–3 deploy options with trade-offs in the owner's language (cost per month now and at
  growth, update complexity, vendor lock-in, what breaks under load), then execution by playbook
  for web apps, packages, or telegram bots. Invariants: secrets never in git, deploy is
  repeatable, a smoke test on production with evidence. Two gate modes: an actual deploy with
  verification, or "strategy chosen, deploy deferred."
  - *Trigger:* by its own standalone trigger — a direct request like "how/where do I deploy this
    / write a deploy runbook", and also as the recommended next step after phase 7
    (release-fixation suggests it at the end but doesn't invoke it).
  - *Standalone:* yes. It self-checks on disk whether a release version is fixed; if not, it
    warns and offers to fix it, but doesn't block.
  - *In the chain:* consumes `product_type`, `stack`, budget, and jurisdiction from state and the
    brief. Writes `deploy_status` (executed/deferred) to state — post-release later reads this
    field to decide whether to treat the product as live. Passes `08-deploy-runbook.md` to
    post-release.
- **post-release** (phase 9) — minimal monitoring using the chosen hosting's own tools (without
  pushing paid services), a feedback channel matched to the product type, and a loop: feedback →
  new brief → back into the pipeline. The operations handbook is written for the owner in a
  stressful moment, not for an engineer ("if the bot goes silent — do A, B, then message the
  agent").
  - *Trigger:* by its own standalone trigger — a direct request like "set up monitoring / add a
    feedback channel after release", and also as the recommended next step after phase 8
    (deploy-strategy suggests it at the end but doesn't invoke it).
  - *Standalone:* yes. Reads `deploy_status` from the journal (if one exists) to decide whether
    to treat the product as live; on `deferred` it writes the handbook in a "once you deploy"
    mode.
  - *In the chain:* consumes `deploy_status`, `deploy_target`, `product_type`,
    `08-deploy-runbook.md`. The last skill in the chain — doesn't hand off further, but closes
    `current_phase: done` and describes how new feedback re-enters the pipeline through
    idea-intake or mvp-scoping.

### On-demand helpers

Six standalone skills sit outside the recommended route — they never touch the
`pipeline-state.md` journal and aren't part of any phase. They're invoked by their own trigger
when needed, usually around phase 6:

- **accessibility** — baseline a11y audit and fixes.
- **mobile-version** — a responsive pass, design only.
- **test-runner-setup** — test runner setup and one smoke test.
- **seo-baseline** — technical page packaging for shareable links.
- **geo-optimization** — public-page packaging for AI assistants.
- **ux-copywriting** — UI microcopy and states.

None of them expand product scope: they're design, packaging, or verification over work
already built.

## Install under Claude Code

From GitHub:

```
/plugin marketplace add tsergeytovarov/super-puper-powers
/plugin install super-puper-powers@super-puper-powers-marketplace
```

From a local copy:

```
/plugin marketplace add /path/to/super-puper-powers
/plugin install super-puper-powers@super-puper-powers-marketplace
```

The `@super-puper-powers-marketplace` suffix on `install` is required — Claude Code always
requires the form `plugin-name@marketplace-name`, there's no shorthand without it.

After installing, open a new Claude Code session. The startup hook injects the orchestrator —
describe your product idea, and it picks it up on its own. Or launch it explicitly with the
`/spp` command: it routes by context — if a `docs/spp/pipeline-state.md` journal already exists
it reads it as memory and reminds you where you left off, without forcing the next phase; any
skill can be invoked directly by name.

## Install under Codex

The repository also carries a Codex manifest (`.codex-plugin/plugin.json`) — SPP is ready to use
under OpenAI Codex, not just Claude Code. The skills live in `./skills/`, and Codex reads them
from there. There are two ways to install.

**Option 1 — via marketplace (recommended).** The official Codex Plugin Directory is still closed
(OpenAI: "coming soon"), so SPP ships as a repo marketplace — which is exactly how OpenAI
recommends distributing plugins right now. The repository carries
`.agents/plugins/marketplace.json`; add it and install the plugin:

```
codex plugin marketplace add tsergeytovarov/super-puper-powers
codex plugin add super-puper-powers@super-puper-powers
```

**Option 2 — as personal skills, via the script.** If you'd rather work from a clone of the
repository — editing skills, keeping the repo as the source of truth — the script symlinks the
skills into `~/.agents/skills`:

```
./scripts/install-codex.sh            # install/refresh symlinks in ~/.agents/skills
./scripts/install-codex.sh --uninstall # remove the symlinks the script created
```

The script is idempotent, never touches other folders in `~/.agents/skills`, and on uninstall
removes only its own symlinks. Restart Codex after installing.

One thing about orchestration: Codex has no SessionStart hook, so the orchestrator doesn't get
injected on its own. Launch the pipeline explicitly — describe the idea and invoke the
orchestrator `super-puper-powers:using-super-puper-powers`, or go straight to the phase skill you
need by name (phase skills have standalone triggers exactly for this). The multi-agent config and
environment detection for Codex is in
`skills/using-super-puper-powers/references/codex-tools.md`.

## SPP and obra/superpowers: keep one plugin

SPP is an extended replacement for obra/superpowers, not an addition to it. The entire
implementation core of upstream (TDD, systematic debugging, code review, subagent-driven
development, worktrees, parallel agents) is vendored inside SPP: the same skills, the same
commands, working exactly the same way. On top of that, SPP adds the whole pipeline — discovery,
MVP, stack, spec, deploy, operations.

That's why **keeping both plugins isn't just unnecessary — it's harmful.** If you have
obra/superpowers installed and want the pipeline — just replace one with the other:

```
/plugin uninstall superpowers@<marketplace-name>
/plugin marketplace add tsergeytovarov/super-puper-powers
/plugin install super-puper-powers@super-puper-powers-marketplace
```

You lose nothing from superpowers — its entire core is now inside SPP and updates along with it,
one plugin instead of two. And on top you get the layer from idea to deploy.

Why replace rather than run side by side: every plugin installs its own SessionStart hook, and
with both active both fire — the system prompt ends up with two large orchestrator blocks
(`using-superpowers` and `using-super-puper-powers`) at once. That's extra permanent context, and
SPP's hook can't cancel someone else's — only you can, by removing one of the plugins. (If you
do keep both for your own reasons, SPP's hook notices and appends a note that it is the one
driving the pipeline, so the other orchestrator doesn't take over — but there's no clean solution
here besides "keep one plugin.")

## Attribution

Based on [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (MIT), author
Jesse Vincent. The implementation core (subagent-driven development, TDD, debugging, code review,
worktrees, parallel agents) is vendored from that project — in most cases with only an
attribution header and renamed references. The discovery, MVP-scoping, stack-selection, deploy,
and post-release phases are original.

Every vendored or reworked skill carries an attribution header describing what changed. The full
provenance table — source, commit, status of every file, the manual sync procedure — is in
[`UPSTREAM.md`](./UPSTREAM.md).

## License

SPP's own code is [MIT](./LICENSE), Copyright (c) 2026 Sergey Tovarov.

Vendored material remains under its original [MIT license](./LICENSE.superpowers),
Copyright (c) 2025 Jesse Vincent.

## Versions

Changelog history is in [CHANGELOG.md](./CHANGELOG.md). Current version — 2.0.0: the switch to a
freely-callable-skills model — the enforcing state machine is replaced by a context-routing
dispatcher, the phase order became a recommendation, `pipeline-state.md` became an optional
memory journal, and phase-6 safety reads artifacts on disk. This is a behavior-contract change
(major): the phase order is no longer guaranteed. Behind it: the plugin build (0.1.0), refinements
from two dogfooding runs of the pipeline (0.2.0), the differentiator verdict in discovery (0.3.0),
auto-disambiguation for the orchestrator (0.3.1), positioning as a replacement for obra/superpowers,
standalone invocation of phase skills, and Codex readiness (0.4.0), the first stable release 1.0.0
— the skill public API plus pipeline state declared stable, and eight course-coverage skills — two
phase-6 checkpoints (`data-boundaries`, `pre-show-audit`) and six standalone helpers (1.1.0).
