# Super Puper Powers Plugin v0.1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Собрать Claude Code плагин `super-puper-powers` (SPP) по спеке `docs/super-puper-powers-spec.md`: 10-фазный pipeline от идеи до задеплоенного продукта, ядро — vendored-скиллы obra/superpowers v6.1.1.

**Architecture:** Плагин = манифесты (`.claude-plugin/`), SessionStart-хук, команда `/spp`, 22 скилла: 1 оркестратор (переработка `using-superpowers`), 9 vendored с минимальными правками, 2 переработки (`brainstorming`→`spec-writing`, `writing-plans`→`plan-writing`), 10 новых. Никакого исполняемого кода кроме bash-хука и vendored-скриптов — «тесты» здесь = проверочные команды (grep/jq/bash) с ожидаемым выводом, финальная приёмка — §7 спеки.

**Tech Stack:** Markdown (SKILL.md с YAML frontmatter), bash, JSON-манифесты Claude Code plugin.

**Источник правды:** `docs/super-puper-powers-spec.md` (далее «спека», разделы §N). Исполнитель каждой задачи ОБЯЗАН прочитать указанные в задаче разделы спеки перед работой. При конфликте план ← спека: побеждает спека, конфликт эскалируется оркестратору сессии.

**Upstream-клон:** переменная окружения задачи:

```bash
VENDOR_SRC="/private/tmp/claude-501/-Users-sergeytovarov-work-superpuperpowers/c789e17f-a7e8-4ddf-a66b-231e93583216/scratchpad/upstream-superpowers"
# Если директории нет или SHA не тот — переклонировать:
if [ ! -d "$VENDOR_SRC" ] || [ "$(git -C "$VENDOR_SRC" rev-parse HEAD)" != "d884ae04edebef577e82ff7c4e143debd0bbec99" ]; then
  rm -rf "$VENDOR_SRC"
  git clone --quiet --depth 1 --branch v6.1.1 https://github.com/obra/superpowers "$VENDOR_SRC"
fi
git -C "$VENDOR_SRC" rev-parse HEAD   # ожидаемо: d884ae04edebef577e82ff7c4e143debd0bbec99
```

---

## Карта файлов

| Файл | Задача | Происхождение |
|---|---|---|
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `LICENSE` | T1 | новое |
| `LICENSE.superpowers`, `skills/<9 vendored>/**` | T2 | upstream as-is |
| правки ссылок/путей в vendored | T3 | modification |
| шапки атрибуции в 9 vendored SKILL.md | T4 | modification |
| `UPSTREAM.md` | T5 | новое |
| `skills/using-super-puper-powers/SKILL.md` | T6 | переработка upstream |
| `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start` | T7 | копия+копия+адаптация |
| `commands/spp.md` | T8 | новое |
| `skills/{idea-intake,product-discovery,mvp-scoping,stack-selection}/SKILL.md` | T9–T12 | новое |
| `skills/spec-writing/SKILL.md` | T13 | переработка upstream |
| `skills/spec-review/{SKILL.md,spec-reviewer.md}` | T14 | новое (+основа orphan-промпта) |
| `skills/cross-spec-review/SKILL.md` | T15 | новое |
| `skills/plan-writing/SKILL.md` | T16 | переработка upstream |
| `skills/plan-review/{SKILL.md,plan-reviewer.md}` | T17 | новое (+основа orphan-промпта) |
| `skills/release-fixation/SKILL.md` | T18 | новое |
| `skills/deploy-strategy/{SKILL.md,references/*.md}` | T19 | новое |
| `skills/post-release/SKILL.md` | T20 | новое |
| `README.md` | T21 | новое |
| финальная приёмка | T22 | — |

Задачи T9–T12 и T18–T20 независимы по содержимому (можно параллелить работу субагентов); коммиты при этом сериализовать — параллельные `git commit` в одном worktree столкнутся на index.lock. Всё остальное — строго по порядку.

## Конвенции для всех задач (из §3 спеки)

- SKILL.md на английском; frontmatter ровно `name` + `description`, ≤1024 символов; `name` = имя директории, только `[a-z0-9-]`; `description` в третьем лице, начинается с «Use when», описывает условие срабатывания.
- Тело нового скилла: секции `## Overview`, `## Process`, `## Red Flags` (таблица «Thought → Reality», 3–6 строк). Плюс обязательные для фазовых скиллов элементы Process: (1) read `docs/spp/pipeline-state.md` first; (2) write artifact to `docs/spp/`; (3) state update по конечному автомату §4; (4) явное «Next skill: …».
- Гейт-вопросы пользователю — ТОЛЬКО на языке продукта: сценарии/демо/деньги. Слова diff/архитектура/рефакторинг в гейтах запрещены (§7.2).
- Коммит после каждой задачи. Формат: `<type>(<scope>): <русское описание в императиве, ≤72 симв., без точки>`.

---

### Task 1: Ветка уже создана; манифесты и LICENSE

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `LICENSE`

- [ ] **Step 1: Убедиться, что мы на ветке `feat/plugin-v0.1`**

Run: `git branch --show-current` → ожидаемо `feat/plugin-v0.1`.

- [ ] **Step 2: Создать `.claude-plugin/plugin.json`** (точное содержимое):

```json
{
  "name": "super-puper-powers",
  "version": "0.1.0",
  "description": "SPP: a 10-phase pipeline from idea to deployed product for non-developers. Based on obra/superpowers v6.1.1.",
  "author": {
    "name": "Sergey Tovarov"
  },
  "homepage": "https://github.com/tsergeytovarov/super-puper-powers",
  "repository": "https://github.com/tsergeytovarov/super-puper-powers",
  "license": "MIT",
  "keywords": ["pipeline", "product", "mvp", "discovery", "deploy", "skills"]
}
```

- [ ] **Step 3: Создать `.claude-plugin/marketplace.json`** (точное содержимое):

```json
{
  "name": "super-puper-powers-marketplace",
  "description": "Marketplace manifest for installing super-puper-powers from this repo",
  "owner": {
    "name": "Sergey Tovarov"
  },
  "plugins": [
    {
      "name": "super-puper-powers",
      "description": "SPP: a 10-phase pipeline from idea to deployed product for non-developers. Based on obra/superpowers v6.1.1.",
      "version": "0.1.0",
      "source": "./",
      "author": {
        "name": "Sergey Tovarov"
      }
    }
  ]
}
```

- [ ] **Step 4: Создать `LICENSE`** — стандартный текст MIT, строка копирайта: `Copyright (c) 2026 Sergey Tovarov`.

- [ ] **Step 5: Проверить**

Run: `jq -e '.name=="super-puper-powers" and .version=="0.1.0"' .claude-plugin/plugin.json && jq -e '.plugins[0].source=="./"' .claude-plugin/marketplace.json`
Expected: `true` дважды, exit 0.

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin LICENSE
git commit -m "feat(plugin): добавить манифесты плагина и лицензию MIT"
```

---

### Task 2: Vendoring — сырое копирование из upstream v6.1.1

**Files:**
- Create: `LICENSE.superpowers`
- Create: `skills/{subagent-driven-development,test-driven-development,verification-before-completion,using-git-worktrees,requesting-code-review,receiving-code-review,systematic-debugging,dispatching-parallel-agents,finishing-a-development-branch}/**` — директории целиком

- [ ] **Step 1: Подготовить `VENDOR_SRC`** (блок из шапки плана), проверить SHA `d884ae04…`.

- [ ] **Step 2: Скопировать LICENSE и 9 директорий целиком**

```bash
cp "$VENDOR_SRC/LICENSE" LICENSE.superpowers
mkdir -p skills
for d in subagent-driven-development test-driven-development verification-before-completion \
         using-git-worktrees requesting-code-review receiving-code-review \
         systematic-debugging dispatching-parallel-agents finishing-a-development-branch; do
  cp -R "$VENDOR_SRC/skills/$d" "skills/$d"
done
```

- [ ] **Step 3: Удалить тест-артефакты systematic-debugging, не референсящиеся из SKILL.md** (§5.10; решение фиксируется в UPSTREAM.md в T5):

```bash
rm skills/systematic-debugging/CREATION-LOG.md \
   skills/systematic-debugging/test-academic.md \
   skills/systematic-debugging/test-pressure-1.md \
   skills/systematic-debugging/test-pressure-2.md \
   skills/systematic-debugging/test-pressure-3.md
```

- [ ] **Step 4: Проверить состав**

Run: `for d in subagent-driven-development test-driven-development verification-before-completion using-git-worktrees requesting-code-review receiving-code-review systematic-debugging dispatching-parallel-agents finishing-a-development-branch; do test -f "skills/$d/SKILL.md" || echo "MISSING $d"; done; ls skills/systematic-debugging/ | grep -c "test-pressure"`
Expected: ни одного `MISSING`, счётчик `0`.

Run: `test -f skills/subagent-driven-development/implementer-prompt.md && test -f skills/subagent-driven-development/task-reviewer-prompt.md && test -f skills/subagent-driven-development/scripts/task-brief && test -f skills/requesting-code-review/code-reviewer.md && echo aux-ok`
Expected: `aux-ok`.

- [ ] **Step 5: Commit**

```bash
git add LICENSE.superpowers skills
git commit -m "chore(vendor): скопировать 9 скиллов obra/superpowers v6.1.1 (d884ae04)"
```

---

### Task 3: Vendored — замена ссылок, вырезание executing-plans, пути

Прочитать перед работой: спека §5.10 (таблица маппинга и 4 разрешённые правки).

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/subagent-driven-development/scripts/{task-brief,review-package,sdd-workspace}`
- Modify: `skills/requesting-code-review/SKILL.md`
- Modify: остальные vendored SKILL.md — только там, где grep найдёт `superpowers:`

- [ ] **Step 1: Массовая замена префиксованных ссылок** (кроме executing-plans — его вырезаем, и кроме writing-plans → plan-writing):

```bash
grep -rln 'superpowers:' skills/ | while read -r f; do
  sed -i '' \
    -e 's/superpowers:writing-plans/super-puper-powers:plan-writing/g' \
    -e 's/superpowers:brainstorming/super-puper-powers:spec-writing/g' \
    -e 's/superpowers:using-superpowers/super-puper-powers:using-super-puper-powers/g' \
    "$f"
done
# оставшиеся superpowers:<vendored-name> — той же командой вторым проходом:
grep -rln 'superpowers:' skills/ | while read -r f; do
  sed -i '' -E 's/superpowers:(subagent-driven-development|test-driven-development|verification-before-completion|using-git-worktrees|requesting-code-review|receiving-code-review|systematic-debugging|dispatching-parallel-agents|finishing-a-development-branch)/super-puper-powers:\1/g' "$f"
done
```

- [ ] **Step 2: Вырезать альтернативу executing-plans** — руками, ищи по содержимому (номера строк upstream ориентировочные). В `skills/subagent-driven-development/SKILL.md` — ЧЕТЫРЕ зоны:

1. Граф «When to Use» — удалить узлы/ветки про executing-plans (упоминания «Executing Plans» как альтернативы), оставив subagent-driven как единственный режим.
2. Блок «**vs. Executing Plans (parallel session):**» сразу после графа — удалить целиком.
3. Секцию «**vs. Executing Plans:**» в Advantages — удалить целиком (заголовок и тело).
4. В Integration/футере — строку со ссылкой `superpowers:executing-plans` (после Step 1 она осталась нетронутой, т.к. в sed её нет) — удалить строку/пункт целиком.

Плюс в `skills/requesting-code-review/SKILL.md` — подсекцию «**Executing Plans:**» в Integration with Workflows удалить целиком.

- [ ] **Step 3: Пути SDD** (§5.10 п.4):

```bash
for f in skills/subagent-driven-development/SKILL.md \
         skills/subagent-driven-development/scripts/task-brief \
         skills/subagent-driven-development/scripts/review-package \
         skills/subagent-driven-development/scripts/sdd-workspace; do
  sed -i '' -e 's|\.superpowers/sdd|.spp/sdd|g' "$f"
done
sed -i '' -e 's|docs/superpowers/plans|docs/spp/05-plans|g' skills/subagent-driven-development/SKILL.md
sed -i '' -e 's|docs/superpowers/plans|docs/spp/05-plans|g' skills/requesting-code-review/SKILL.md
grep -rn 'docs/superpowers' skills/ || true   # если нашлись ещё — заменить тем же способом
```

- [ ] **Step 4: Проверить (критерий §7.9, без учёта шапок — их ещё нет)**

Run: `grep -rn 'superpowers:' skills/ ; echo "exit=$?"`
Expected: пусто, `exit=1`.

Run: `grep -rniE 'executing[- ]plans' skills/ ; echo "exit=$?"`
Expected: пусто, `exit=1`.

Run: `grep -rn '\.superpowers/' skills/ ; echo "exit=$?"`
Expected: пусто, `exit=1`.

- [ ] **Step 5: Commit**

```bash
git add skills
git commit -m "refactor(vendor): заменить upstream-ссылки и пути на имена SPP"
```

---

### Task 4: Vendored — шапки атрибуции

Прочитать: спека §6 (формат шапки).

**Files:** Modify: все 9 vendored `skills/*/SKILL.md`.

- [ ] **Step 1: Вставить шапку сразу после закрывающего `---` frontmatter** в каждый из 9 SKILL.md. Формат (вторая строка — по файлу, см. Step 2):

```markdown
> Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT.
> Modifications: <список>
```

Вставка скриптом (awk: после второй строки `---`):

```bash
insert_header() {  # $1=file $2=modifications text
  awk -v mods="$2" 'BEGIN{n=0}
    {print}
    /^---$/{n++; if(n==2){print ""; print "> Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT."; print "> Modifications: " mods}}' \
    "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
```

- [ ] **Step 2: Тексты `Modifications:` по файлам:**

Тексты Modifications намеренно НЕ содержат литеральных upstream-строк (`superpowers:`, `.superpowers/`, `docs/superpowers`, `executing-plans`) — иначе grep-проверки T22 ловили бы собственные шапки:

| Файл | Modifications |
|---|---|
| subagent-driven-development | `attribution header; skill links renamed to SPP names; inline-execution alternative removed; SDD workdir renamed to .spp/sdd; example plan paths updated to docs/spp/05-plans` |
| requesting-code-review | `attribution header; inline-execution subsection removed; example plan paths updated to docs/spp/05-plans` (Task 3 не переименовывал ссылки в этом файле — только путь и вырезание подсекции) |
| остальные 7 | `attribution header; skill links renamed to SPP names` — а если grep по файлу показывает, что ссылок в нём не было, то просто `attribution header` |

- [ ] **Step 3: Проверить**

Run: `grep -rl "Vendored from" skills/*/SKILL.md | wc -l`
Expected: `9`.

Run: `for f in skills/*/SKILL.md; do echo "== $f"; awk 'n==2{print; if(++c==3) exit} /^---$/{n++}' "$f"; done`
Expected: у каждого из 9 файлов три строки после закрывающего `---` frontmatter: пустая, `> Vendored from …`, `> Modifications: …` (визуально проверить, что шапка не попала внутрь frontmatter).

- [ ] **Step 4: Commit**

```bash
git add skills
git commit -m "docs(vendor): добавить шапки атрибуции во все vendored-скиллы"
```

---

### Task 5: UPSTREAM.md

Прочитать: спека §6.

**Files:** Create: `UPSTREAM.md`.

**Внимание:** на момент T5 существуют только vendored-скиллы и LICENSE.superpowers. Задача создаёт КАРКАС с инвентарём текущего состава; строки для hooks/, переработок (T6/T13/T16) и ревью-промптов (T14/T17) добавляет T22 Step 0.

- [ ] **Step 1: Написать `UPSTREAM.md`** со структурой:

1. **Source**: repo URL, tag `v6.1.1`, commit `d884ae04edebef577e82ff7c4e143debd0bbec99` (пояснение: тег annotated, фиксируем commit SHA), дата sync (дата исполнения задачи).
2. **File inventory** — таблица «путь → статус → примечание». Статусы: `vendored as-is` (LICENSE.superpowers, вспомогательные файлы без правок — уточнение к §5.10: `modified` обязателен только при фактических правках, для aux-файлов без правок корректен `as-is`, см. §5.10/§6), `modified` (9 SKILL.md, scripts с правкой путей), `not copied (reason)` (executing-plans — SPP always subagent-driven; writing-skills — dev-time only, checked from upstream clone; brainstorming visual companion files — out of scope v0.1; systematic-debugging test artifacts — not referenced by SKILL.md; platform dirs .codex-plugin etc. — Claude Code only). Инвентарь генерировать из фактического состава: `git ls-files skills/ LICENSE.superpowers`.
3. **Sync procedure**: diff тегов upstream → ручной перенос осмысленных изменений → обновить шапки и этот файл. Дословно из §6 спеки.

- [ ] **Step 2: Проверить**: каждая строка `git ls-files skills/ LICENSE.superpowers` присутствует в таблице (spot-check: `git ls-files skills/ | wc -l` vs число строк таблицы; допустимо группировать `references/*` одной строкой с пометкой).

- [ ] **Step 3: Commit**

```bash
git add UPSTREAM.md
git commit -m "docs(vendor): добавить UPSTREAM.md с инвентарём и процедурой sync"
```

---

### Task 6: Оркестратор `using-super-puper-powers`

Прочитать: спека §4 (конечный автомат), §5.0 (все обязанности), §5.10 (acceptance-демо). Образец: `$VENDOR_SRC/skills/using-superpowers/SKILL.md`.

**Files:** Create: `skills/using-super-puper-powers/SKILL.md`.

- [ ] **Step 1: Написать SKILL.md.** Frontmatter (точно):

```yaml
---
name: using-super-puper-powers
description: Use when starting any conversation - orchestrates the SPP pipeline that turns a product idea into a deployed product, resuming from docs/spp/pipeline-state.md or offering phase 0 when the user describes a product idea
---
```

Далее шапка атрибуции (§6): `> Vendored from … v6.1.1 (commit d884ae04), MIT.` / `> Modifications: reworked from the upstream orchestrator skill; platform adaptation section removed; SPP pipeline map, state machine and phase-6 gate ownership added` (без литерала «using-superpowers:» — иначе grep T22 ловит шапку).

Структура тела (сохранить из upstream: `<SUBAGENT-STOP>`, `<EXTREMELY-IMPORTANT>` про 1% chance, The Rule, Red Flags-таблицу, User Instructions; УДАЛИТЬ: Platform Adaptation и ссылки на `references/*-tools.md`, Skill Priority-примеры про brainstorming; В The Rule строку «Before entering plan mode: … invoke the brainstorming skill first» ЗАМЕНИТЬ на «Before any product work: read docs/spp/pipeline-state.md and follow the pipeline map below»; примеры Skill Priority заменить на SPP-примеры: «"I have a product idea" → super-puper-powers:idea-intake first»; ДОБАВИТЬ следующие секции):

1. `## Pipeline Map` — таблица (машиночитаемая карта, §5.0):

| Phase | Skill | Artifact | Gate |
|---|---|---|---|
| 0 | idea-intake | docs/spp/00-idea-brief.md | "Did I get the idea right?" |
| 1 | product-discovery | docs/spp/01-discovery-report.md | go / pivot / stop |
| 2 | mvp-scoping | docs/spp/02-mvp-scope.md | approve scenario list |
| 3 | stack-selection | docs/spp/03-stack.md | pick stack option |
| 4 | spec-writing (+spec-review, cross-spec-review) | docs/spp/04-specs/ | approve product summary |
| 5 | plan-writing (+plan-review) | docs/spp/05-plans/ | "N tasks, start?" |
| 6 | subagent-driven-development (gate owned by orchestrator) | docs/spp/06-acceptance-demo.md | acceptance demo: every must-scenario works |
| 7 | release-fixation | docs/spp/07-release-notes.md | "fix version X?" |
| 8 | deploy-strategy | docs/spp/08-deploy-runbook.md | "product live at X, accept?" |
| 9 | post-release | docs/spp/09-operations.md | final: ops handbook accepted |

2. `## Session Start Protocol` — state есть → прочитать, объявить «Pipeline on phase N, continuing with …», действовать по конечному автомату §4 (in_progress/gate_pending → продолжить фазу N, повторив гейт-вопрос при gate_pending; approved → запустить скилл фазы N+1; stopped/done → pipeline завершён, не продолжать). State нет + пользователь описывает продуктовую идею → предложить фазу 0 (skill idea-intake).
3. `## State Machine` — конспект §4: кто и когда пишет current_phase/phase_status; `<HARD-GATE>Phase N+1 MUST NOT start until phase N gate is approved in pipeline-state.md.</HARD-GATE>`.
4. `## Phase 6 Gate Ownership` — §5.0 дословно по смыслу: при нескольких под-проектах исполнять планы в порядке `subproject_order` из state; после финального whole-branch ревью SDD оркестратор проводит acceptance-демо по каждому must-сценарию MVP-scope, пишет `docs/spp/06-acceptance-demo.md` (scenario → how demonstrated → result); `<HARD-GATE>finishing-a-development-branch MUST NOT be invoked until the acceptance demo is approved in pipeline-state.md (phase_status: gate_pending during the demo).</HARD-GATE>`; после approve — передать в release-fixation, который и вызывает finishing.
5. `## Mid-Pipeline Entry` — пользователь заявляет готовый артефакт («у меня уже есть MVP-scope») → создать state, записать пропущенные фазы в `phases_skipped`, решение в Decisions log, стартовать с указанной фазы.
6. `## Gate Language` — `<HARD-GATE>Every gate question is in product language: scenarios, demos, money. Never diff, architecture or refactoring. Never ask the user to read code or specs.</HARD-GATE>`
7. Red Flags — адаптировать upstream-таблицу + добавить SPP-строки: «"The user is technical, I can show the diff" → Gates are product-language. Always.»; «"Spec looks fine, skip spec-review" → Review loop is mandatory.»; «"I'll start phase N+1, the gate is obviously fine" → approved in state file or it didn't happen.»

- [ ] **Step 2: Проверить**

Run: `head -5 skills/using-super-puper-powers/SKILL.md` → frontmatter точно как в Step 1.
Run: `grep -c "HARD-GATE" skills/using-super-puper-powers/SKILL.md` → `>= 3` (три HARD-GATE-блока: переходы фаз, фаза 6, язык гейтов).
Run: `grep -n "references/" skills/using-super-puper-powers/SKILL.md; echo "exit=$?"` → пусто, exit=1.

- [ ] **Step 3: Commit**

```bash
git add skills/using-super-puper-powers
git commit -m "feat(orchestrator): добавить оркестратор pipeline using-super-puper-powers"
```

---

### Task 7: hooks/

Прочитать: спека §5.0 (правки session-start). Образцы в `$VENDOR_SRC/hooks/`.

**Files:**
- Create: `hooks/hooks.json` — побайтная копия upstream.
- Create: `hooks/run-hook.cmd` — побайтная копия upstream.
- Create: `hooks/session-start` — адаптация.

- [ ] **Step 1: Копии**

```bash
mkdir -p hooks
cp "$VENDOR_SRC/hooks/hooks.json" hooks/hooks.json
cp "$VENDOR_SRC/hooks/run-hook.cmd" hooks/run-hook.cmd
chmod +x hooks/run-hook.cmd
```

(`hooks-cursor.json` НЕ копировать — другие платформы вне скоупа, §8.)

- [ ] **Step 2: Создать `hooks/session-start`** (точное содержимое; отличия от upstream: имя скилла/путь, текст обёртки, только Claude Code ветка вывода):

```bash
#!/usr/bin/env bash
# SessionStart hook for super-puper-powers plugin.
# Adapted from obra/superpowers v6.1.1 (commit d884ae04), MIT.
# Modifications: skill path and injection text renamed to SPP; Cursor/Copilot branches removed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

content=$(cat "${PLUGIN_ROOT}/skills/using-super-puper-powers/SKILL.md" 2>&1 || echo "Error reading using-super-puper-powers skill")

# Escape string for JSON embedding using bash parameter substitution.
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

escaped=$(escape_for_json "$content")
session_context="<EXTREMELY_IMPORTANT>\nYou have super puper powers.\n\n**Below is the full content of your 'super-puper-powers:using-super-puper-powers' skill - the SPP pipeline orchestrator. For all other skills, use the 'Skill' tool:**\n\n${escaped}\n</EXTREMELY_IMPORTANT>"

# Claude Code hook output format.
# printf instead of heredoc: bash 5.3+ heredoc hang, see obra/superpowers#571.
printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$session_context" | cat

exit 0
```

```bash
chmod +x hooks/session-start
```

- [ ] **Step 3: Проверить smoke-тестом**

Run: `bash hooks/session-start | python3 -c 'import json,sys; d=json.load(sys.stdin); c=d["hookSpecificOutput"]["additionalContext"]; assert "super-puper-powers:using-super-puper-powers" in c and "Pipeline Map" in c; print("hook-ok")'`
Expected: `hook-ok`.

Run: `cmp hooks/hooks.json "$VENDOR_SRC/hooks/hooks.json" && cmp hooks/run-hook.cmd "$VENDOR_SRC/hooks/run-hook.cmd" && echo copies-ok`
Expected: `copies-ok`.

- [ ] **Step 4: Commit**

```bash
git add hooks
git commit -m "feat(hooks): добавить SessionStart-хук с инжектом оркестратора"
```

---

### Task 8: commands/spp.md

Прочитать: спека §5.0 (последний пункт).

**Files:** Create: `commands/spp.md` (точное содержимое):

- [ ] **Step 1: Создать файл**

```markdown
---
description: Start or resume the Super Puper Powers pipeline
---

Read `docs/spp/pipeline-state.md`.

- If it exists: announce "Pipeline on phase N, continuing with <skill>" and continue
  from `current_phase` according to the state machine in the
  super-puper-powers:using-super-puper-powers skill (invoke it via the Skill tool first).
- If it does not exist: tell the user this project has no SPP pipeline yet and offer
  to start phase 0 by invoking the super-puper-powers:idea-intake skill. Ask them to
  describe the product idea in a couple of sentences.

Takes no arguments in v0.1.
```

- [ ] **Step 2: Commit**

```bash
git add commands
git commit -m "feat(commands): добавить команду /spp для запуска pipeline"
```

---

### Задачи T9–T12: фазовые скиллы 0–3 (независимы, можно параллелить)

Общее для T9–T12: «Конвенции для всех задач» выше + соответствующий раздел спеки. Каждый скилл — один файл `skills/<name>/SKILL.md`, новый (шапка атрибуции НЕ нужна — это не vendored/переработка). Проверка для каждого: frontmatter-чек (см. T22 Step 2, можно прогнать для одного файла), гейт-текст без запрещённых слов. Коммит на задачу.

### Task 9: `idea-intake`

Прочитать: спека §5.1, §4 (какие поля state создаются).

- [ ] **Step 1: Написать `skills/idea-intake/SKILL.md`.** Frontmatter:

```yaml
---
name: idea-intake
description: Use when the user describes a product idea and docs/spp/pipeline-state.md does not exist - starts the SPP pipeline by capturing an idea brief through a one-question-at-a-time interview
---
```

Process (обязательные пункты из §5.1): вопросы строго по одному, multiple choice где возможно: проблема → для кого → отличие от существующего → критерий успеха → бюджет → сроки → юрисдикция (ДВА отдельных вопроса или один с двумя полями: где пользователи, где автор) → язык артефактов. Если cwd не git-репозиторий: создать каталог по slug идеи + `git init`, объяснив пользователю одной фразой без git-терминов («завожу папку проекта»). Артефакт `docs/spp/00-idea-brief.md`; создать `docs/spp/pipeline-state.md` по схеме §4 (YAML-блок процитировать в скилле). Гейт: пересказ идеи своими словами → «Did I get the idea right?» → правки → approved. State: конечный автомат §4 (in_progress при старте, gate_pending на гейте, approved после подтверждения + Decisions log). Next skill: `super-puper-powers:product-discovery`.

- [ ] **Step 2: Commit** — `feat(skills): добавить idea-intake (фаза 0)`

### Task 10: `product-discovery`

Прочитать: спека §5.2.

- [ ] **Step 1: Написать `skills/product-discovery/SKILL.md`.** Frontmatter:

```yaml
---
name: product-discovery
description: Use when the idea brief is approved (phase 0 approved in docs/spp/pipeline-state.md) - researches competitors, legal risks, market and feasibility before any scoping, with an explicit right to stop the project
---
```

Process (из §5.2): первый вопрос — режим quick (~30 мин, один research-субагент: конкуренты + очевидные юр-стопы + осуществимость грубо) или deep (часы, 4 параллельных субагента: (1) конкуренты/ниши, (2) юр-риски под юрисдикцию из brief — persональные данные, лицензирование, платежи, возрастные ограничения, (3) рынок/спрос/готовность платить, (4) осуществимость соло-агентом + стоимость эксплуатации/мес). Режим → state (`discovery_mode`). Субагентам — точный контекст из brief, НЕ историю сессии. Adversarial-проверка 3–5 ключевых утверждений по первоисточникам — ТОЛЬКО в deep; в quick отчёт обязан оговорить её отсутствие. Артефакт `docs/spp/01-discovery-report.md` с обязательными разделами «Idea killers» (или явное «none found») и рекомендацией go/pivot/no-go с обоснованием. Гейт: go / pivot / stop; pivot → `current_phase: 0, in_progress` + Decisions log, возврат в idea-intake; stop → `phase_status: stopped` + причина в Decisions log, проговорить, что это УСПЕШНЫЙ исход (сэкономленные месяцы). Next skill: `super-puper-powers:mvp-scoping`.

Red Flags добавить: «"Research says it's fine, skipping the killers section" → The section is mandatory, "none found" is a valid entry.»

- [ ] **Step 2: Commit** — `feat(skills): добавить product-discovery (фаза 1)`

### Task 11: `mvp-scoping`

Прочитать: спека §5.3.

- [ ] **Step 1: Написать `skills/mvp-scoping/SKILL.md`.** Frontmatter:

```yaml
---
name: mvp-scoping
description: Use when discovery is approved with a go decision (phase 1 approved in docs/spp/pipeline-state.md) - turns the brief and discovery report into a prioritized MVP scope built around a walking skeleton scenario
---
```

Process (§5.3): полный список фич из brief+discovery → приоритизация must/later/never (по одному спорному пункту за вопрос) → walking skeleton: минимальный сквозной пользовательский сценарий, доказывающий ценность → метрики успеха MVP → явный раздел «What the MVP will NOT do». Сценарии в формате «user does X → Y happens». Артефакт `docs/spp/02-mvp-scope.md`. Гейт: утверждение СПИСКА СЦЕНАРИЕВ (не фич). State по §4. Next skill: `super-puper-powers:stack-selection`.

- [ ] **Step 2: Commit** — `feat(skills): добавить mvp-scoping (фаза 2)`

### Task 12: `stack-selection`

Прочитать: спека §5.4.

- [ ] **Step 1: Написать `skills/stack-selection/SKILL.md`.** Frontmatter:

```yaml
---
name: stack-selection
description: Use when MVP scope is approved (phase 2 approved in docs/spp/pipeline-state.md) - picks the tech stack from 2-3 options judged by agent maintainability, running cost and time to MVP, explained in owner consequences
---
```

Process (§5.4): определить product_type (web/package/tg-bot/mixed) → state. 2–3 варианта стека; критерии в порядке приоритета: (1) сопровождаемость агентом (мейнстрим > экзотика), (2) стоимость/простота эксплуатации ($/мес, free tier, сложность обновления), (3) скорость до MVP, (4) совместимость с реалистичным деплоем. Trade-offs — языком последствий для владельца («вариант А: бесплатный хостинг, обновление одной командой; Б: гибче, но ~$20/мес»); технические термины допустимы, но каждый с последствием. Артефакт `docs/spp/03-stack.md` (выбранный + отвергнутые с причинами). Стек → state (`stack`). Гейт: выбор варианта пользователем. Next skill: `super-puper-powers:spec-writing`.

- [ ] **Step 2: Commit** — `feat(skills): добавить stack-selection (фаза 3)`

---

### Task 13: `spec-writing` (переработка brainstorming)

Прочитать: спека §3 (определение «переработки»), §5.5. Источник: `$VENDOR_SRC/skills/brainstorming/SKILL.md`.

**Files:** Create: `skills/spec-writing/SKILL.md` (копия upstream + правки). Файлы `spec-document-reviewer-prompt.md`, `visual-companion.md`, `scripts/` из upstream brainstorming НЕ копировать (reviewer-промпт заберёт T14 в свой скилл).

- [ ] **Step 1: Скопировать и прогнать sed-замены из T3 Step 1** (копия делается ПОСЛЕ массовой замены T3, поэтому оба sed-прохода T3 Step 1 обязательны повторно для этого файла):

```bash
mkdir -p skills/spec-writing
cp "$VENDOR_SRC/skills/brainstorming/SKILL.md" skills/spec-writing/SKILL.md
# оба sed-прохода из T3 Step 1 по файлу skills/spec-writing/SKILL.md
```

- [ ] **Step 2: Внести правки** (каждая — из §5.5):

1. Frontmatter:

```yaml
---
name: spec-writing
description: Use when stack is approved (phase 3 approved in docs/spp/pipeline-state.md) and specs are not yet written - designs the product through product-behavior questions only and writes implementation specs to docs/spp/04-specs/
---
```

2. Шапка атрибуции: `> Modifications: reworked from the upstream design-dialogue skill; input is approved MVP scope and stack; user questions restricted to product behavior; visual companion offer removed; terminal transition replaced with SPP review chain` (без литерала «brainstorming:»).
3. Вход: прочитать `pipeline-state.md`, `02-mvp-scope.md`, `03-stack.md`; НЕ переспрашивать решённое; вопросы пользователю только про продуктовое поведение (UX, тексты, edge-cases сценариев); архитектуру/схему данных/обработку ошибок агент решает сам и фиксирует письменно с обоснованием в спеке.
4. Пути спек: upstream `docs/superpowers/specs/` → `docs/spp/04-specs/`.
5. Visual companion: удалить пункт чеклиста про companion, секцию Visual Companion, все ссылки на `visual-companion.md`/scripts.
6. Терминальный переход: вместо «self-review → user review → writing-plans» → «self-review → `super-puper-powers:spec-review` → (если спек >1) `super-puper-powers:cross-spec-review` → продуктовое резюме `04-specs/summary-for-review.md` (сценарии "user does X → Y happens", экраны/команды словами, поведение при типовых ошибках) → гейт: пользователь утверждает РЕЗЮМЕ (полную спеку читать не обязан) → `super-puper-powers:plan-writing`». State по §4.
7. Plain-name упоминания «writing-plans» по всему телу (чеклист, Process Flow-граф, «The terminal state is invoking writing-plans», финальный блок) — заменить на новую цепочку из п.6 либо на `plan-writing`; после правки `grep -n 'writing-plans' skills/spec-writing/SKILL.md` находит только `plan-writing`.

- [ ] **Step 3: Проверить**: `grep -niE 'visual[- ]companion|superpowers/specs' skills/spec-writing/SKILL.md | grep -v 'Modifications:'; echo exit=$?` → пусто, exit=1. `grep -c 'spec-review' skills/spec-writing/SKILL.md` → ≥1. `grep -nE '\bwriting-plans' skills/spec-writing/SKILL.md | grep -v 'plan-writing'; echo exit=$?` → пусто, exit=1.

- [ ] **Step 4: Commit** — `feat(skills): добавить spec-writing на основе brainstorming (фаза 4)`

---

### Task 14: `spec-review` + `spec-reviewer.md`

Прочитать: спека §5.6. Основа промпта: `$VENDOR_SRC/skills/brainstorming/spec-document-reviewer-prompt.md`.

**Files:**
- Create: `skills/spec-review/SKILL.md` (новый)
- Create: `skills/spec-review/spec-reviewer.md` (адаптация orphan-промпта, шапка НЕ нужна — атрибуция в UPSTREAM.md, статус `modified`; добавить строку в UPSTREAM.md)

- [ ] **Step 1: `skills/spec-review/SKILL.md`.** Frontmatter:

```yaml
---
name: spec-review
description: Use when spec-writing finished a spec after author self-review - dispatches a clean-context subagent to adversarially review the spec against MVP scope before any planning happens
---
```

Process (§5.6): субагент с чистым контекстом; получает ТОЛЬКО спеку + `02-mvp-scope.md` + `03-stack.md` (не сессию); промпт — из `spec-reviewer.md` (путь через `${CLAUDE_PLUGIN_ROOT}` или относительный). Проверяет: полноту относительно MVP-scope (каждый must-сценарий покрыт), противоречия, неоднозначности (двоякая трактовка = дефект), нереализуемость на выбранном стеке, плейсхолдеры. Findings: Critical/Important/Minor; Critical+Important чинятся автором → re-review → до чистого прохода. Носитель findings — отчёт субагента; итог цикла (раунды, результат) → Decisions log. Next: `cross-spec-review` если спек >1, иначе — продуктовое резюме и гейт (в spec-writing).

- [ ] **Step 2: `spec-reviewer.md`** — взять upstream orphan-промпт, адаптировать: входы (spec + mvp-scope + stack), критерии из §5.6, формат вывода findings с severity, upstream-пути `docs/superpowers/specs/` → `docs/spp/04-specs/` (в тексте «Dispatch after: …»). Строку инвентаря для UPSTREAM.md добавит T22 Step 0.

- [ ] **Step 3: Commit** — `feat(skills): добавить spec-review с промптом ревьюера`

---

### Task 15: `cross-spec-review`

Прочитать: спека §5.7.

**Files:** Create: `skills/cross-spec-review/SKILL.md`.

- [ ] **Step 1: Написать.** Frontmatter:

```yaml
---
name: cross-spec-review
description: Use when spec-review passed and docs/spp/04-specs/ contains more than one spec - reviews the whole spec set for interface consistency, seam gaps, contradictions and build order
---
```

Process (§5.7): один субагент, чистый контекст, ВСЕ спеки разом. Проверяет: согласованность интерфейсов (имена/типы/контракты), дыры на стыках (сценарий через два под-проекта — переход покрыт?), противоречия, порядок сборки (граф зависимостей). Выход: findings (цикл починки как в spec-review: Critical/Important → фикс → re-review до чистого) + рекомендованный порядок под-проектов → `subproject_order` в state (потребители: plan-writing, оркестратор фазы 6). Итог → Decisions log.

- [ ] **Step 2: Commit** — `feat(skills): добавить cross-spec-review`

---

### Task 16: `plan-writing` (переработка writing-plans)

Прочитать: спека §3, §5.8. Источник: `$VENDOR_SRC/skills/writing-plans/SKILL.md`.

**Files:** Create: `skills/plan-writing/SKILL.md` (копия + правки). `plan-document-reviewer-prompt.md` НЕ копировать сюда (его заберёт T17).

- [ ] **Step 1: Скопировать и прогнать sed-замены из T3 Step 1** (копия после массовой замены T3 — оба sed-прохода обязательны повторно; в частности, это заменит `superpowers:using-git-worktrees` в строке про worktree):

```bash
mkdir -p skills/plan-writing
cp "$VENDOR_SRC/skills/writing-plans/SKILL.md" skills/plan-writing/SKILL.md
# оба sed-прохода из T3 Step 1 по файлу skills/plan-writing/SKILL.md
```

- [ ] **Step 2: Правки:**

1. Frontmatter:

```yaml
---
name: plan-writing
description: Use when specs are approved (phase 4 approved in docs/spp/pipeline-state.md) - writes implementation plans as bite-sized tasks to docs/spp/05-plans/ for subagent-driven execution
---
```

2. Шапка атрибуции: `> Modifications: reworked from the upstream planning skill; plans path docs/spp/05-plans/; plan header points to SPP SDD only; mandatory plan-review; execution handoff without inline option` (без литерала «writing-plans:»).
3. Путь планов: → `docs/spp/05-plans/`; при нескольких под-проектах порядок — из `subproject_order` в state.
4. Обязательная шапка генерируемого плана: `> **For agentic workers:** REQUIRED SUB-SKILL: Use super-puper-powers:subagent-driven-development to implement this plan task-by-task.` — БЕЗ альтернативы executing-plans.
5. После self-review — обязательный `super-puper-powers:plan-review` (re-review до чистого прохода), только потом handoff.
6. Execution handoff: НЕ спрашивать subagent-driven vs inline; SPP всегда subagent-driven. Спросить только «стартуем?» с оценкой числа задач (гейт фазы 5). State по §4.
7. Plain-name упоминания: announce-строку «I'm using the writing-plans skill…» → «I'm using the plan-writing skill…»; «during brainstorming» в Scope Check → «during spec-writing»; остальные plain-«writing-plans»/«brainstorming» по телу → `plan-writing`/`spec-writing`.

- [ ] **Step 3: Проверить**: `grep -niE 'executing[- ]plans|superpowers/plans' skills/plan-writing/SKILL.md | grep -v 'Modifications:'; echo exit=$?` → пусто, exit=1. `grep -nE '\bwriting-plans|\bbrainstorming' skills/plan-writing/SKILL.md | grep -v 'plan-writing'; echo exit=$?` → пусто, exit=1.

- [ ] **Step 4: Commit** — `feat(skills): добавить plan-writing на основе writing-plans (фаза 5)`

---

### Task 17: `plan-review` + `plan-reviewer.md`

Прочитать: спека §5.9. Основа промпта: `$VENDOR_SRC/skills/writing-plans/plan-document-reviewer-prompt.md`.

**Files:**
- Create: `skills/plan-review/SKILL.md`
- Create: `skills/plan-review/plan-reviewer.md` (адаптация orphan-промпта; строка в UPSTREAM.md)

- [ ] **Step 1: SKILL.md.** Frontmatter:

```yaml
---
name: plan-review
description: Use when plan-writing finished a plan after author self-review - dispatches a clean-context subagent to verify spec coverage, cross-task consistency and absence of placeholders before execution
---
```

Process (§5.9): субагент, чистый контекст: план + спека. Проверяет: покрытие спеки (каждое требование → задача), типовую согласованность между задачами (сигнатуры/имена Task N == Task M), плейсхолдеры по upstream-списку «No Placeholders», выполнимость шагов (команды существуют, пути реальны). Цикл: findings → фикс → re-review до чистого; носитель и Decisions log — как в §5.6.

- [ ] **Step 2: `plan-reviewer.md`** — адаптировать orphan-промпт под §5.9. Строку инвентаря для UPSTREAM.md добавит T22 Step 0.

- [ ] **Step 3: Commit** — `feat(skills): добавить plan-review с промптом ревьюера`

---

### Задачи T18–T20: фазы 7–9 (независимы, можно параллелить)

### Task 18: `release-fixation`

Прочитать: спека §5.11.

**Files:** Create: `skills/release-fixation/SKILL.md`.

- [ ] **Step 1: Написать.** Frontmatter:

```yaml
---
name: release-fixation
description: Use when the acceptance demo is approved (phase 6 approved in docs/spp/pipeline-state.md) - verifies the work, finishes the branch on the agent's own decision, fixes a semver version and writes owner-language release notes
---
```

Process (§5.11): вход — `06-acceptance-demo.md` approved. Шаги: `super-puper-powers:verification-before-completion` → `super-puper-powers:finishing-a-development-branch`, но ОБЁРНУТ: его технический гейт «merge/PR/keep/discard» пользователю НЕ показывать; выбор делает агент (дефолт: merge в основную ветку локально), фиксирует в Decisions log → semver (первый релиз 0.1.0) → changelog на `artifacts_language` (что теперь умеет продукт, не коммиты) → git tag. Артефакт `docs/spp/07-release-notes.md`. Гейт: «фиксируем версию X?». Next skill: `super-puper-powers:deploy-strategy`.

Red Flags: «"The user should choose merge vs PR" → That's a git question. The agent decides and logs it.»

- [ ] **Step 2: Commit** — `feat(skills): добавить release-fixation (фаза 7)`

### Task 19: `deploy-strategy` + references

Прочитать: спека §5.12 (двухшаговая структура, инварианты).

**Files:**
- Create: `skills/deploy-strategy/SKILL.md`
- Create: `skills/deploy-strategy/references/web-apps.md`
- Create: `skills/deploy-strategy/references/packages-and-plugins.md`
- Create: `skills/deploy-strategy/references/telegram-bots.md`

- [ ] **Step 1: SKILL.md.** Frontmatter:

```yaml
---
name: deploy-strategy
description: Use when a release version is fixed (phase 7 approved in docs/spp/pipeline-state.md) - chooses a deploy strategy with the owner in cost-and-consequence terms, then executes it into a repeatable runbook
---
```

Шаг 1 — выбор: собрать вводные (product_type и stack из state; бюджет из brief; СУЩЕСТВУЮЩИЕ аккаунты/инфраструктура пользователя — спросить, не предполагать; требования юрисдикции к данным); 2–3 варианта с trade-offs на языке владельца ($/мес сейчас и при росте, обновление одной командой vs ритуал, вендор-лок, что ломается при наплыве); гейт: выбор → `deploy_target` в state. Шаг 2 — исполнение по reference-плейбуку (справочный материал, не жёсткий рецепт; выбирается по product_type). Инварианты (нарушение = дефект): секреты не в git никогда; деплой повторяем (скрипт/конфиг в репо); после деплоя smoke-тест must-сценариев на проде с evidence. Артефакт `docs/spp/08-deploy-runbook.md` (как задеплоено, как обновить, как откатить, $/мес, где лежат секреты — описание, не значения). Гейт: «продукт доступен по адресу X, сценарии на проде проверены — принимаешь?».

- [ ] **Step 2: references/** — три файла, каждый: варианты хостинга с trade-offs, шаги, чеклист проверки. Обязательное покрытие (§5.12):
  - `web-apps.md`: managed-платформы vs VPS (когда что); env/секреты; домен; HTTPS.
  - `packages-and-plugins.md`: npm / PyPI / Claude plugin marketplace; манифесты; обязательная проверка установкой «с нуля».
  - `telegram-bots.md`: BotFather; long polling vs webhook — когда что; варианты хостинга; секрет-токен.

- [ ] **Step 3: Commit** — `feat(skills): добавить deploy-strategy с плейбуками (фаза 8)`

### Task 20: `post-release`

Прочитать: спека §5.13.

**Files:** Create: `skills/post-release/SKILL.md`.

- [ ] **Step 1: Написать.** Frontmatter:

```yaml
---
name: post-release
description: Use when the deploy gate is approved (phase 8 approved in docs/spp/pipeline-state.md) - sets up minimal monitoring and a feedback channel, then closes the loop back into the pipeline
---
```

Process (§5.13): минимальный мониторинг в рамках deploy_target (uptime-пинг, доставка ошибок; не навязывать платные сервисы) → канал обратной связи по типу продукта (форма/e-mail/команда боту) → петля: фидбек → новый idea brief → фаза 0 или 2. Артефакт `docs/spp/09-operations.md` на языке владельца («если бот молчит — сделай A, B, потом напиши агенту»). Гейт финальный: «pipeline завершён, продукт в проде, вот операционная памятка» → `current_phase: done`.

- [ ] **Step 2: Commit** — `feat(skills): добавить post-release (фаза 9)`

---

### Task 21: README.md

Прочитать: спека §2 (README-требования), §6 (Attribution).

**Files:** Modify: `README.md` (сейчас нет — Create).

- [ ] **Step 1: Написать README.md** (на английском). Секции:

1. **What is this** — SPP: Claude Code plugin, 10-phase pipeline idea→deployed product for non-developers; product-language gates; таблица фаз (короткая версия Pipeline Map).
2. **Install** — `/plugin marketplace add tsergeytovarov/super-puper-powers` (или локальный путь) → `/plugin install super-puper-powers`; после установки — новая сессия, оркестратор инжектится SessionStart-хуком; или явный `/spp`.
3. **Compatibility** — конфликт с установленным obra/superpowers: одинаковые имена скиллов с почти одинаковыми description в двух плагинах; рекомендация `/plugin disable superpowers` на время работы SPP-pipeline.
4. **Attribution** — «Based on [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (MIT), author Jesse Vincent. The implementation core is vendored; discovery/MVP/stack/deploy/post-release phases are original.» + ссылка на UPSTREAM.md и LICENSE.superpowers.
5. **License** — MIT.

- [ ] **Step 2: Commit** — `docs(readme): добавить README с установкой и атрибуцией`

---

### Task 22: Финальная приёмка (автоматизируемая часть §7) и пуш

- [ ] **Step 0: Дополнить UPSTREAM.md** строками, появившимися после T5: `hooks/hooks.json | vendored as-is`, `hooks/run-hook.cmd | vendored as-is`, `hooks/session-start | modified | platform branches removed, SPP skill path`, `skills/using-super-puper-powers/SKILL.md | reworked | from using-superpowers`, `skills/spec-writing/SKILL.md | reworked | from brainstorming`, `skills/plan-writing/SKILL.md | reworked | from writing-plans`, `skills/spec-review/spec-reviewer.md | modified | adapted from brainstorming/spec-document-reviewer-prompt.md`, `skills/plan-review/plan-reviewer.md | modified | adapted from writing-plans/plan-document-reviewer-prompt.md`. Сверить полноту: каждая строка `git ls-files skills/ hooks/ LICENSE.superpowers` есть в таблице (группировка `references/*` допустима). Коммит: `docs(vendor): актуализировать инвентарь UPSTREAM.md`.

- [ ] **Step 1: grep-suite (§7.9).** Фильтр `grep -v 'Modifications:'` обязателен во всех — иначе грепы ловят собственные шапки атрибуции:

```bash
grep -rn 'superpowers:' skills/ | grep -v 'super-puper-powers:' | grep -v 'Vendored from' | grep -v 'Modifications:' ; echo "s1=$?"
grep -rniE 'executing[- ]plans' skills/ | grep -v 'Vendored from' | grep -v 'Modifications:' ; echo "s2=$?"
grep -rn '\.superpowers/' skills/ | grep -v 'Modifications:' ; echo "s3=$?"
grep -rn 'docs/superpowers' skills/ | grep -v 'Modifications:' ; echo "s4=$?"
grep -rniE '\b(writing-plans|brainstorming|using-superpowers)\b' skills/ | grep -viE 'plan-writing|spec-writing|super-puper-powers' | grep -v 'Vendored from' | grep -v 'Modifications:' ; echo "s5=$?"
grep -rniE '\bsuperpowers\b' skills/ | grep -viE 'super-puper-powers|obra/superpowers' | grep -v 'Vendored from' | grep -v 'Modifications:' ; echo "s6=$?"
```
Expected: все шесть пусто, `s1=1 s2=1 s3=1 s4=1 s5=1 s6=1`.

- [ ] **Step 2: frontmatter-чек всех SKILL.md (§7.10)**

```bash
python3 - <<'EOF'
import pathlib, re, sys
fail = 0
for p in sorted(pathlib.Path("skills").glob("*/SKILL.md")):
    text = p.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m: print(f"{p}: no frontmatter"); fail = 1; continue
    fm = m.group(0)
    if len(fm) > 1024: print(f"{p}: frontmatter {len(fm)} chars > 1024"); fail = 1
    body = m.group(1)
    keys = re.findall(r"^([a-zA-Z_-]+):", body, re.M)
    if set(keys) != {"name", "description"}: print(f"{p}: keys {keys}"); fail = 1
    name = re.search(r"^name:\s*(\S+)", body, re.M)
    if not name or name.group(1) != p.parent.name: print(f"{p}: name mismatch"); fail = 1
    if name and not re.fullmatch(r"[a-z0-9-]+", name.group(1)): print(f"{p}: bad name chars"); fail = 1
    desc = re.search(r"^description:\s*(.+)$", body, re.M)
    if not desc or not desc.group(1).strip().startswith("Use when"): print(f"{p}: description must start with 'Use when'"); fail = 1
print("FAIL" if fail else "OK: all SKILL.md frontmatter valid")
sys.exit(fail)
EOF
```
Expected: `OK: all SKILL.md frontmatter valid`.

- [ ] **Step 3: шапки атрибуции (§7.9)**

Run: `grep -rl "Vendored from" skills/*/SKILL.md | wc -l`
Expected: `12` (9 vendored + using-super-puper-powers + spec-writing + plan-writing).

- [ ] **Step 4: hooks smoke** — повторить проверку из T7 Step 3. Expected: `hook-ok`.

- [ ] **Step 5: манифесты** — `jq . .claude-plugin/plugin.json >/dev/null && jq . .claude-plugin/marketplace.json >/dev/null && jq . hooks/hooks.json >/dev/null && echo json-ok`. Expected: `json-ok`.

- [ ] **Step 6: гейт-язык (§7.2, статическая проверка)** — в новых фазовых скиллах формулировки гейтов не содержат diff/refactor:

Run: `grep -rniE '\bdiff\b|\brefactor|\barchitectur' skills/idea-intake skills/product-discovery skills/mvp-scoping skills/stack-selection skills/release-fixation skills/deploy-strategy skills/post-release ; echo exit=$?`
Expected: пусто, exit=1 (`\bdiff\b` с обеими границами — иначе ловит different/differs; паттерн покрывает все три запретных слова §7.2: diff, refactoring, architecture). У ревью-скиллов и оркестратора упоминания вне гейт-текстов допустимы — их корректность проверяется на финальном whole-branch ревью SDD.

- [ ] **Step 7: пуш ветки**

```bash
git push -u origin feat/plugin-v0.1
```

**Не автоматизируется в этой сессии (§7.1–7.8, интерактивная приёмка):** установка через `/plugin marketplace add` в живом Claude Code, сквозной прогон фаз 0–5 на игрушечной идее, resumability-тест, подложенные дефекты для spec-review/cross-spec-review/plan-review, discovery-стоп, прогон фаз 6–9. Это отдельная приёмочная сессия с пользователем; для подложенных дефектов допустим субагент-симулятор.
