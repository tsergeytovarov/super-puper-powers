# Super Puper Powers — имплементационная спецификация

> **Спека для реализации.** Самодостаточна: контекст обсуждения не требуется. Дизайн-обоснование — в `super-puper-powers-pipeline.md` (рядом), читать при конфликтах трактовок.
>
> **Для агента-исполнителя:** это спека, а не план. Следующий шаг — implementation plan (если установлен superpowers — через `writing-plans`), затем реализация.

## 1. Цель

Claude Code плагин `super-puper-powers` (далее SPP): pipeline из 10 фаз, доводящий идею до задеплоенного продукта силами человека **без навыков разработчика**. Реализационное ядро — vendored-скиллы из `obra/superpowers` v6.1.1 (MIT); фазы до кода (discovery, MVP, стек) и после (deploy, post-release) — новые.

Ключевые принципы (нарушение любого = дефект):

1. Все гейты с человеком — на языке продукта: сценарии, демо, деньги. Никогда diff или архитектура.
2. Технические решения агент принимает сам и фиксирует письменно с обоснованием.
3. Каждая фаза производит артефакт-документ и завершается гейтом.
4. Pipeline возобновляем: состояние в `docs/spp/pipeline-state.md`, любая сессия начинается с его чтения.
5. Вся атрибуция upstream — явная (см. §6).

## 2. Структура репозитория

```
super-puper-powers/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json       # marketplace-манифест: установка из репо/локальной директории
├── README.md                  # что это, установка, секции Compatibility и Attribution
├── LICENSE                    # MIT (свой)
├── LICENSE.superpowers        # копия LICENSE из obra/superpowers
├── UPSTREAM.md                # версия-источник, список vendored-файлов, процедура sync
├── hooks/
│   ├── hooks.json             # регистрация SessionStart-хука (matcher: startup|clear|compact), копия upstream
│   ├── run-hook.cmd           # polyglot-обёртка для Windows, копия upstream
│   └── session-start          # инжект using-super-puper-powers (адаптация upstream, правки — в §5.0)
├── commands/
│   └── spp.md                 # /spp — явный запуск/продолжение pipeline (поведение — в §5.0)
└── skills/
    # Вспомогательные файлы скиллов (references/, scripts/, *-prompt.md и пр.) в дереве
    # опущены — их состав определяется §5 и UPSTREAM.md.
    # оркестрация (переработка upstream using-superpowers)
    ├── using-super-puper-powers/
    # новые фазы (0–3)
    ├── idea-intake/
    ├── product-discovery/
    ├── mvp-scoping/
    ├── stack-selection/
    # переработки upstream (фазы 4–5)
    ├── spec-writing/          # ← переработка upstream brainstorming
    ├── plan-writing/          # ← переработка upstream writing-plans
    # новые ревью-скиллы (фазы 4–5)
    ├── spec-review/
    ├── cross-spec-review/
    ├── plan-review/
    # vendored upstream с минимальными правками (фаза 6 + поддержка)
    ├── subagent-driven-development/
    ├── test-driven-development/
    ├── verification-before-completion/
    ├── using-git-worktrees/
    ├── requesting-code-review/
    ├── receiving-code-review/
    ├── systematic-debugging/
    ├── dispatching-parallel-agents/
    ├── finishing-a-development-branch/
    # новые фазы (7–9)
    ├── release-fixation/
    ├── deploy-strategy/
    │   └── references/
    │       ├── web-apps.md
    │       ├── packages-and-plugins.md
    │       └── telegram-bots.md
    └── post-release/
```

`plugin.json` (все поля обязательны): `name: super-puper-powers`, `version: 0.1.0`, `description` упоминает «based on obra/superpowers v6.1.1», `author`, `homepage` и `repository` (URL репозитория SPP), `license: MIT`.

`marketplace.json`: один plugin-entry `super-puper-powers` с `source: "./"` (по образцу upstream) — обеспечивает установку через `/plugin marketplace add <репо|путь>` + `/plugin install`.

README, секция Compatibility: у SPP и установленного рядом obra/superpowers будут скиллы с одинаковыми именами и почти одинаковыми description (неймспейсы плагинов разные, но триггеринг по description может сработать на любой из двух). Рекомендация в README: на время работы SPP-pipeline отключить плагин superpowers (`/plugin disable`).

## 3. Конвенции для всех скиллов

- Формат SKILL.md — как в upstream: YAML frontmatter `name` + `description`, тело со структурой Overview / Process / Red Flags (фиксированная структура SPP; шаблон upstream `writing-skills` — справочный, при расхождении приоритет у этой спеки).
- Frontmatter: `name` — только строчные буквы/цифры/дефисы, совпадает с именем директории; `description` — третье лицо, начинается с «Use when …» и описывает условие срабатывания, а не содержание скилла; весь frontmatter ≤1024 символов. Пример:

  ```yaml
  ---
  name: idea-intake
  description: Use when the user describes a product idea and no docs/spp/pipeline-state.md exists - starts the SPP pipeline by capturing the idea brief through one-question-at-a-time interview
  ---
  ```

- **«Переработка upstream X»** везде в этой спеке означает: скопировать файл из upstream v6.1.1 и внести перечисленные в соответствующем разделе правки, сохранив остальной текст as-is; статус файла в UPSTREAM.md — `modified`. Не «написать заново по мотивам».
- Язык SKILL.md — английский (консистентно с upstream, надёжнее триггерится). Диалог с пользователем — на языке пользователя. Язык артефактов — из `pipeline-state.md` (поле `artifacts_language`, спрашивается один раз в idea-intake).
- Каждый фазовый скилл обязан: (a) прочитать `pipeline-state.md` перед работой; (b) записать артефакт в `docs/spp/`; (c) обновить state-файл после гейта; (d) явно назвать следующий скилл.
- Вопросы пользователю — по одному за сообщение, multiple choice где возможно (паттерн upstream brainstorming).
- Research-субагенты никогда не наследуют контекст сессии — им собирается точный контекст (паттерн upstream SDD).

## 4. State-файл

Путь: `docs/spp/pipeline-state.md` (в репозитории продукта, не плагина). Создаётся в idea-intake. Формат — markdown с YAML-блоком:

```yaml
project: <slug>
artifacts_language: ru | en | …
jurisdiction:
  users: <страна/регион пользователей>
  author: <страна/регион автора>
current_phase: 0..9 | done
phase_status: in_progress | gate_pending | approved | stopped
phases_skipped: []            # номера фаз, пропущенных по явному решению пользователя (§5.0)
pipeline_profile: full | lite | null   # церемония фазы 6; lite для крошечных планов (§5.8, §5.10)
discovery_mode: quick | deep | null
product_type: web | package | tg-bot | mixed | null
stack: <утверждённый стек | null>
subproject_order: null        # список slug'ов под-проектов; пишет cross-spec-review (§5.7)
deploy_target: <утверждённая стратегия | null>
deploy_status: executed | deferred | null   # deferred = стратегия+runbook приняты, деплой отложен (§5.12)
```

- **`pipeline_profile`** (v0.2): `plan-writing` оценивает размер плана; если план ≤ 3 задач и суммарно ≤ ~150 строк — рекомендует `lite`. В `lite` фаза 6 использует облегчённый путь (один имплементер на план + одно финальное whole-branch ревью, без per-task fresh-субагента и per-task review); spec-review/plan-review сохраняются. Иначе `full`. Протокол lite описан в оркестраторе (§5.0), не в vendored SDD.
- **`deploy_status`** (v0.2): `deploy-strategy` (§5.12) закрывает гейт в одном из режимов — `executed` (реальный деплой + прод-смоук с evidence) или `deferred` (стратегия выбрана, runbook готов, деплой отложен, live-evidence не требуется). При `deferred` `post-release` (§5.13) не считает продукт живым и пишет памятку в режиме «когда задеплоишь».

Плюс секции: `## Decisions log` (дата, фаза, решение, кем принято) и `## Artifacts` (ссылки на файлы фаз). Каждый гейт добавляет запись в Decisions log.

**Жизненный цикл (конечный автомат):**

1. Скилл фазы N при старте работы пишет `current_phase: N`, `phase_status: in_progress`.
2. При выдаче гейт-вопроса пользователю — `phase_status: gate_pending`.
3. После подтверждения пользователя — `phase_status: approved` + запись в Decisions log. `current_phase` при этом НЕ инкрементируется — его меняет скилл следующей фазы (шаг 1).
4. Оркестратор при старте сессии читает файл: `(N, in_progress | gate_pending)` → продолжить фазу N (при `gate_pending` — повторно задать гейт-вопрос); `(N, approved)` → запустить скилл фазы N+1.
5. Терминальные состояния: `phase_status: stopped` (осознанная остановка pipeline, сейчас единственная точка — гейт discovery, §5.2) и `current_phase: done` (фаза 9 завершена, §5.13). Из них оркестратор pipeline не продолжает.

## 5. Скиллы — требования по каждому

### 5.0. `using-super-puper-powers` (оркестратор)

Переработка upstream `using-superpowers` (шапка атрибуции по §6), дополнительно:

- Таблица фаз 0–9 → скилл → артефакт → гейт (машиночитаемая карта pipeline).
- При старте сессии: если существует `docs/spp/pipeline-state.md` — прочитать, объявить «Pipeline на фазе N, продолжаю с …»; если нет и пользователь описывает продуктовую идею — предложить запустить pipeline с фазы 0.
- Правило перехода: фаза N+1 не начинается, пока гейт фазы N не `approved` в state-файле. Hard gate, формулировка в стиле upstream `<HARD-GATE>`.
- **Оркестратор — владелец гейта фазы 6** (единственная фаза, чей рабочий скилл — vendored SDD — про state не знает):
  - после того как SDD завершил финальное whole-branch ревью, оркестратор проводит **acceptance-демо** (§5.10) и пишет артефакт `docs/spp/06-acceptance-demo.md`: перечень must-сценариев из MVP-scope, для каждого — как продемонстрирован и результат;
  - `<HARD-GATE>`: `finishing-a-development-branch` не вызывается, пока acceptance-демо не `approved` в state (vendored SDD ведёт в finishing напрямую — оркестратор обязан перехватить этот переход; на время демо `phase_status: gate_pending`);
  - после `approved` оркестратор передаёт управление в `release-fixation` (фаза 7), которая и вызывает finishing (§5.11).
- Разрешён вход с середины: пользователь может явно сказать «у меня уже есть MVP-scope» — тогда оркестратор создаёт state-файл, пишет номера пропущенных фаз в `phases_skipped`, фиксирует решение в Decisions log и стартует с указанной фазы.
- Инжектится через session-start hook. Механика — копия upstream `hooks/` (hooks.json + run-hook.cmd + session-start) со следующими правками session-start: путь чтения → `skills/using-super-puper-powers/SKILL.md`; текст-обёртка инжекта → имя SPP-скилла; ветки других платформ (Cursor/Copilot и пр.) — удалить; matcher `startup|clear|compact` сохранить. Из переработанного `using-super-puper-powers/SKILL.md` удалить upstream-секцию Platform Adaptation и ссылки на `references/*-tools.md` (эти файлы не vendorятся).
- `commands/spp.md` — явная команда `/spp`, дублирующая вход в оркестратор: читает state-файл и продолжает с текущей фазы; если state нет — предлагает начать с фазы 0. Аргументов в v0.1 нет. Frontmatter команды: `description` одной строкой.

### 5.1. `idea-intake` (фаза 0)

- **Триггер:** пользователь описывает продуктовую идею; нет state-файла.
- **Процесс:** по одному вопросу: проблема; для кого; чем отличается от существующего; критерий успеха; бюджет; сроки; **юрисдикция** (обязательно два ответа: где пользователи, где автор — раздельные поля в state); язык артефактов.
- **Репозиторий продукта:** если текущая директория — не git-репозиторий, скилл до записи state создаёт каталог проекта (slug идеи) и делает `git init`; пользователю это объясняется одной фразой на языке продукта («завожу папку проекта»), без git-терминологии в гейтах.
- **Артефакт:** `docs/spp/00-idea-brief.md` + создание `pipeline-state.md`.
- **Гейт:** пересказ идеи своими словами → «Я правильно понял?» → правки → approved.
- **Следующий скилл:** `product-discovery`.

### 5.2. `product-discovery` (фаза 1)

- **Вход:** утверждённый idea brief.
- **Первый вопрос:** режим `quick` (~30 мин, один research-субагент) или `deep` (часы, параллельные субагенты). Записать в state.
- **Deep — четыре параллельных субагента** (паттерн upstream `dispatching-parallel-agents`), каждому — точный контекст из brief:
  1. конкуренты и аналоги: кто уже решает проблему, чем плохи, где ниша;
  2. юридические риски **под юрисдикцию из brief**: персональные данные, лицензирование, платежи, возрастные ограничения;
  3. рынок и спрос: размер, тренды, готовность платить;
  4. осуществимость: реализуемо ли соло-агентом, порядок стоимости эксплуатации/мес.
- **Quick:** один субагент, пункты 1 + 2 (только очевидные стопы) + 4 грубо.
- После свода — adversarial-проверка (**только в deep-режиме**): отдельный субагент проверяет 3–5 ключевых утверждений отчёта по первоисточникам. В quick adversarial-этапа нет — это цена скорости, и отчёт обязан это оговорить.
- Конкурентный анализ (субагент 1 в deep, единственный субагент в quick) обязан явно сверить дифференциатор из brief с тем, что реально делают конкуренты, и выдать вердикт: **выжил** / **слаб** / **убит**. Вердикт «слаб»/«убит» не блокирует отчёт сам по себе, но обязан быть назван прямо, а не растворён в общем описании конкурентов.
- **Артефакт:** `docs/spp/01-discovery-report.md`; обязательные разделы: «Убийцы идеи» (или явное «не найдены»), **вердикт по дифференциатору** (выжил/слаб/убит с обоснованием), рекомендация go / pivot / no-go с обоснованием.
- **Гейт:** решение go / pivot / stop. При pivot — возврат в `idea-intake` с правками brief: `current_phase: 0`, `phase_status: in_progress`, запись pivot в Decisions log. При stop — pipeline корректно завершается: `phase_status: stopped` + запись причины в Decisions log; это **успешный** исход, скилл обязан это проговорить.
- **Следующий скилл:** `mvp-scoping`.

### 5.3. `mvp-scoping` (фаза 2)

- **Вход:** brief + discovery report.
- **Процесс:** полный список фич → приоритизация must / later / never (по одному спорному пункту за вопрос) → walking skeleton: минимальный сквозной пользовательский сценарий, доказывающий ценность → метрики успеха MVP → явный раздел «Чего в MVP НЕ будет».
- Приоритизация сверяет и заявленный дифференциатор из brief, и вердикт discovery по нему. Вердикт «слаб»/«убит» не решается перекладыванием пункта между must/later/never — это отдельный явный вопрос владельцу на гейте: жив ли смысл MVP как есть, или дифференциатор нужно переосмыслить (сигнал к pivot).
- **Артефакт:** `docs/spp/02-mvp-scope.md`. Сценарии — в формате «пользователь делает X → происходит Y».
- **Гейт:** утверждение списка сценариев (не фич).
- **Следующий скилл:** `stack-selection`.

### 5.4. `stack-selection` (фаза 3)

- **Вход:** MVP-scope, ограничения из brief.
- **Процесс:** определить тип продукта (web / package / tg-bot / mixed → в state) → 2–3 варианта стека. Критерии, в порядке приоритета:
  1. сопровождаемость агентом: мейнстрим с большим корпусом примеров > экзотика;
  2. стоимость и простота эксплуатации: хостинг $/мес, free tier, сложность обновления;
  3. скорость до MVP;
  4. совместимость с реалистичными вариантами деплоя (не загонять в дорогую инфраструктуру).
- Trade-offs формулируются на языке последствий для владельца: «вариант А: бесплатный хостинг, обновление одной командой; вариант Б: гибче, но ~$20/мес». Технические термины — допустимы, но каждый с последствием.
- **Артефакт:** `docs/spp/03-stack.md` — выбранный стек и отвергнутые варианты с причинами. Стек → state.
- **Гейт:** выбор варианта пользователем.
- **Следующий скилл:** `spec-writing`.

### 5.5. `spec-writing` (фаза 4)

Переработка upstream `brainstorming` (см. §6 про атрибуцию модификаций). Отличия от upstream:

- Вход — утверждённые MVP-scope и стек: не переспрашивать то, что уже решено; вопросы пользователю только про продуктовое поведение (UX, тексты, edge-cases сценариев). Архитектуру, схему данных, обработку ошибок агент решает сам и фиксирует с обоснованием.
- **Убрать upstream-шаг показа дизайна пользователю.** В upstream brainstorming есть шаг «present the design» с посекционным одобрением, где среди секций — architecture / data flow / error handling. Это прямо противоречит предыдущему пункту и принципу §1.1. При переработке: технические секции агент фиксирует в спеке (не выносит на одобрение), а пользователю показывается только продуктовое резюме (ниже). Соответственно вычистить чеклист-пункт и узел графа про «user approves design sections».
- Спеки писать в `docs/spp/04-specs/` (вместо upstream-пути).
- Декомпозиция на под-проекты — как в upstream (multiple subsystems → отдельные спеки).
- **Visual companion удалён полностью** (см. §8): из upstream-текста убрать пункт чеклиста про companion, секцию Visual Companion и все ссылки на `visual-companion.md` и его `scripts/`; сами файлы не vendorятся.
- **Cross-plugin ссылки на невендоренные скиллы — вырезать.** Upstream brainstorming ссылается на `elements-of-style:writing-clearly-and-concisely` (сторонний плагин, в SPP не входит). Такие ссылки на скиллы вне SPP-дерева §2 у пользователя не резолвятся — заменить прозой без имени скилла (общее правило для любой переработки, не только этой; grep §7.9 ловит только `superpowers:` и потому такие ссылки пропускает).
- **Замена терминального перехода:** после self-review вместо user review + `writing-plans` идёт: `spec-review` → (если спек несколько) `cross-spec-review` → продуктовое резюме → гейт → `plan-writing`.
- **Продуктовое резюме для гейта:** отдельная секция или файл `04-specs/summary-for-review.md` — сценарии «пользователь делает X → происходит Y», описание экранов/команд словами, что произойдёт при типовых ошибках. Пользователь утверждает резюме; полную спеку читать не обязан.

### 5.6. `spec-review` (новый)

- **Триггер:** spec-writing завершил спеку (после self-review автора).
- **Процесс:** субагент с чистым контекстом (получает только: спеку, MVP-scope, stack-файл — не сессию). Проверяет: полноту относительно MVP-scope (каждый must-сценарий покрыт), противоречия, неоднозначности (трактуется двумя способами = дефект), нереализуемость на выбранном стеке, плейсхолдеры.
- **Выход:** findings с severity Critical / Important / Minor. Critical и Important чинятся до гейта; цикл ревью повторяется до чистого прохода (паттерн upstream task review loop).
- Носитель findings — отчёт субагента в сессии (файл не создаётся); итог цикла (сколько раундов, чем закончился) — записью в Decisions log, чтобы resumability не зависела от обрыва посреди ревью.
- Промпт ревьюера — файл `spec-reviewer.md` в директории скилла (паттерн upstream `requesting-code-review/code-reviewer.md`). За основу взять upstream `brainstorming/spec-document-reviewer-prompt.md` (в v6.1.1 он существует, но из SKILL.md не вызывается — сирота от прежней версии механизма) с атрибуцией по §6.

### 5.7. `cross-spec-review` (новый)

- **Триггер:** спек больше одной.
- **Процесс:** субагент получает все спеки разом. Проверяет: согласованность интерфейсов между под-проектами (имена, типы, контракты), дыры на стыках (сценарий проходит через два под-проекта — покрыт ли переход), противоречия, порядок сборки (граф зависимостей, что строить первым).
- **Выход:** findings + рекомендованный порядок реализации под-проектов → поле `subproject_order` в state-файле (потребители: `plan-writing` — порядок планов, оркестратор фазы 6 — порядок исполнения).
- Цикл починки — как в §5.6: Critical/Important чинятся, re-review до чистого прохода; итог цикла — в Decisions log.

### 5.8. `plan-writing` (фаза 5)

Переработка upstream `writing-plans`. Отличия:

- Планы в `docs/spp/05-plans/`. При нескольких под-проектах порядок планов — из `subproject_order` в state.
- **Шапка генерируемых планов**: upstream-шаблон обязывает начинать план с «REQUIRED SUB-SKILL: … superpowers:subagent-driven-development … or superpowers:executing-plans». В переработке шапка указывает только на SPP-имя SDD (`super-puper-powers:subagent-driven-development`), без альтернативы executing-plans.
- После self-review — обязательный `plan-review` (ниже).
- Execution handoff не спрашивает пользователя про subagent-driven vs inline: SPP всегда использует subagent-driven (пользователь — не разработчик, выбор для него бессмысленен). Спросить только «стартуем?» с оценкой числа задач.

### 5.9. `plan-review` (новый)

- Субагент с чистым контекстом: план + спека. Проверяет: покрытие спеки (каждое требование → задача), типовую согласованность между задачами (сигнатуры/имена в Task N совпадают с Task M), плейсхолдеры по списку upstream «No Placeholders», выполнимость шагов (команды существуют, пути реальны).
- Findings → чинятся → re-review до чистого прохода; носитель findings и запись итога — как в §5.6. Промпт — `plan-reviewer.md`; за основу взять upstream `writing-plans/plan-document-reviewer-prompt.md` (сирота в v6.1.1, аналогично §5.6) с атрибуцией по §6.

### 5.10. Фаза 6 — vendored с минимальными правками

`subagent-driven-development`, `test-driven-development`, `verification-before-completion`, `using-git-worktrees`, `requesting-code-review`, `receiving-code-review`, `systematic-debugging`, `dispatching-parallel-agents`, `finishing-a-development-branch` — **директории копируются из upstream v6.1.1 целиком**, со всеми вспомогательными файлами (`implementer-prompt.md`, `task-reviewer-prompt.md`, `code-reviewer.md`, `scripts/review-package`, `scripts/task-brief`, `scripts/sdd-workspace`, references-файлы systematic-debugging и TDD и пр. — перечисленное здесь контрольный список, а не исчерпывающий; полный состав фиксируется в UPSTREAM.md). Не копируются только файлы, на которые SKILL.md не ссылается (тест-артефакты вроде `CREATION-LOG.md`, `test-pressure-*.md` — решение фиксируется в UPSTREAM.md). Категория в UPSTREAM.md: SKILL.md — `modified` (шапка атрибуции — уже модификация); вспомогательные файлы — `modified` только при фактических правках, иначе `vendored as-is`.

Разрешённые правки vendored-файлов (каждая фиксируется в шапке §6):

1. Шапка атрибуции (§6).
2. Замена ссылок `superpowers:skill-name` и plain-name упоминаний по таблице маппинга:

   | upstream | SPP |
   |---|---|
   | `using-superpowers` | `using-super-puper-powers` |
   | `brainstorming` | `spec-writing` |
   | `writing-plans` | `plan-writing` |
   | `executing-plans` | аналога нет — см. п. 3 |
   | остальные vendored | то же имя, префикс `super-puper-powers:` |

3. **`executing-plans` не vendorится** (SPP всегда subagent-driven, §5.8): из `subagent-driven-development/SKILL.md` вырезать альтернативу executing-plans — узлы графа When to Use, секцию «vs. Executing Plans» и ссылку в Integration.
4. Замена upstream-путей на SPP-пути: рабочая директория SDD `.superpowers/sdd/` → `.spp/sdd/` (и в `scripts/*`), примеры путей `docs/superpowers/plans/…` → `docs/spp/05-plans/…`.
5. Замена остаточных упоминаний бренда «Superpowers», не покрытых п.2 и п.4: голое слово-бренд в прозе → «Super-Puper-Powers»; произвольный сегмент пути `superpowers/` в примерах (не `.superpowers/` и не `docs/superpowers/`) → SPP-эквивалент. Цитата источника в шапке атрибуции (`obra/superpowers`, §6) и имя файла `LICENSE.superpowers` не трогаются.

**Дополнение к фазе 6 (в оркестраторе, не в vendored-файлах; владение гейтом и HARD-GATE — в §5.0):** после финального whole-branch ревью и перед `finishing-a-development-branch` — **acceptance-демо**: агент запускает продукт (dev-сервер / установка пакета / бот в тестовом режиме), даёт пользователю адрес/команду и проводит по каждому must-сценарию из MVP-scope. Гейт: «каждый сценарий работает у меня на глазах». Провал сценария → задача на исправление → повтор демо. Артефакт фазы — `docs/spp/06-acceptance-demo.md` (протокол: сценарий → как показан → результат), его пишет оркестратор (§5.0).

### 5.11. `release-fixation` (фаза 7)

- **Вход:** acceptance-демо пройдено (`06-acceptance-demo.md` approved).
- **Процесс:** `verification-before-completion` (vendored) → `finishing-a-development-branch` (vendored, **обёрнут**: его гейт «merge / PR / keep / discard» — технический, пользователю не показывается; выбор способа интеграции агент делает сам — дефолт merge в основную ветку локально — и фиксирует в Decisions log) → semver-версия (первый релиз = 0.1.0) → changelog на `artifacts_language` (что теперь умеет продукт, не список коммитов) → git tag.
- **Артефакт:** `docs/spp/07-release-notes.md`.
- **Гейт:** «фиксируем версию X?»
- **Следующий скилл:** `deploy-strategy`.

### 5.12. `deploy-strategy` (фаза 8)

Два шага, главная ценность — первый.

**Шаг 1 — выбор стратегии:**
- Собрать вводные: тип продукта и стек из state; бюджет из brief; **существующие аккаунты и инфраструктура пользователя** (спросить — ничего не предполагать); требования юрисдикции к размещению данных.
- Предложить 2–3 варианта с trade-offs на языке владельца: $/мес сейчас и при росте, сложность обновления (одна команда vs ритуал), привязка к вендору, что ломается при наплыве пользователей.
- Гейт: выбор варианта → `deploy_target` в state.

**Шаг 2 — исполнение:**
- Плейбуки в `references/` — справочный материал, не жёсткий рецепт: `web-apps.md` (managed-платформы vs VPS; env/секреты; домен; HTTPS), `packages-and-plugins.md` (npm / PyPI / Claude plugin marketplace; манифесты; проверка установкой «с нуля»), `telegram-bots.md` (BotFather; long polling vs webhook — когда что; хостинг; секрет-токен).
- Инварианты (нарушение = дефект): секреты не в git никогда; деплой повторяем — скрипт/конфиг в репо; после деплоя обязательный smoke-тест must-сценариев на проде с evidence (verification-дисциплина распространяется на прод).
- **Артефакт:** `docs/spp/08-deploy-runbook.md`: как задеплоено, как обновить, как откатить, сколько стоит/мес, где лежат секреты (описание, не значения).
- **Гейт:** «продукт доступен по адресу X, сценарии на проде проверены — принимаешь?»

### 5.13. `post-release` (фаза 9)

- **Процесс:** минимальный мониторинг в рамках выбранной стратегии (uptime-пинг, доставка ошибок — конкретика зависит от deploy_target, не навязывать платные сервисы) → канал обратной связи (форма, e-mail, команда боту — по типу продукта) → петля: фидбек → новый idea brief → фаза 0 или 2.
- **Артефакт:** `docs/spp/09-operations.md`: что мониторится, куда смотреть, что делать при инциденте (на языке владельца: «если бот молчит — сделай A, B, потом напиши агенту»).
- **Гейт:** финальный: «pipeline завершён, продукт в проде, вот твоя операционная памятка». `current_phase: done`.

Нумерация артефактов = номер фазы (00–09); у фазы 6 артефакт — протокол acceptance-демо (§5.10), поэтому пропусков в нумерации нет.

## 6. Vendoring и атрибуция

- Источник: `https://github.com/obra/superpowers`, tag/версия **v6.1.1**, commit **`d884ae04edebef577e82ff7c4e143debd0bbec99`** (тег annotated — в шапках и UPSTREAM.md фиксировать именно commit SHA, не SHA тег-объекта `c984ea2…`).
- `UPSTREAM.md`: версия и SHA источника; таблица «файл → vendored as-is | modified | заменён | не копируется (причина)»; дата последнего sync; процедура обновления (diff upstream-версий → перенос осмысленных изменений вручную → обновить шапки и UPSTREAM.md).
- Шапка в каждом vendored/переработанном SKILL.md сразу после frontmatter (оркестратор `using-super-puper-powers` — тоже переработка, шапка обязательна):
  ```markdown
  > Vendored from [obra/superpowers](https://github.com/obra/superpowers) v6.1.1 (commit d884ae04), MIT.
  > Modifications: none | <краткий список>
  ```
- Вспомогательные vendored-файлы не-SKILL.md (`*-prompt.md`, `code-reviewer.md`, `scripts/*`, references) шапкой не снабжаются — их атрибуция только строками в таблице UPSTREAM.md.
- README: секция Attribution — «Основано на obra/superpowers v6.1.1 (MIT), автор Jesse Vincent; реализационное ядро vendored, фазы discovery/MVP/stack/deploy/post-release — оригинальные».
- `LICENSE.superpowers` — копия upstream LICENSE. Собственный `LICENSE` — MIT.

## 7. Критерии приёмки

1. Плагин устанавливается в Claude Code через `/plugin marketplace add` (репо или локальный путь — работает за счёт `.claude-plugin/marketplace.json`) + `/plugin install` без ошибок; SessionStart-хук (зарегистрированный в `hooks/hooks.json`) инжектит оркестратор.
2. Сквозной тест на игрушечной идее (например, «tg-бот-напоминалка»): pipeline проходит фазы 0–5 с корректными артефактами в `docs/spp/` и записями в state-файле; каждый гейт сформулирован на языке продукта (проверка: в тексте гейта нет слов diff/архитектура/рефакторинг и просьб читать код).
3. Resumability: прервать сессию на фазе 2, начать новую — оркестратор читает state и продолжает с фазы 2 без повторных вопросов.
4. `spec-review` ловит подложенный дефект: в тестовую спеку внесено противоречие → ревьюер находит (Critical/Important).
5. `cross-spec-review` ловит подложенное рассогласование: в двух тестовых спеках имя/контракт общего интерфейса намеренно расходится → ревьюер находит.
6. `plan-review` ловит подложенный плейсхолдер («add appropriate error handling») → находит.
7. Discovery-стоп: на идее с очевидным юр-убийцей quick-режим находит стоп и корректно завершает pipeline как успех (`phase_status: stopped`).
8. Фазы 6–9 на игрушечном проекте: acceptance-демо предъявляет каждый must-сценарий и пишет `06-acceptance-demo.md`; `finishing-a-development-branch` не вызывается до approve демо; артефакты `07-release-notes.md`, `08-deploy-runbook.md` (deploy_target — локальный/бесплатный), `09-operations.md` созданы; гейты — на языке продукта.
9. Все vendored/переработанные SKILL.md имеют шапку атрибуции; `UPSTREAM.md` и `LICENSE.superpowers` существуют; grep по `superpowers:` внутри `skills/` даёт 0 совпадений вне шапок атрибуции; grep по `executing-plans` и plain-name упоминаниям заменённых имён (`writing-plans`, `brainstorming`, `using-superpowers` как имена скиллов) внутри `skills/` даёт 0 совпадений вне шапок и UPSTREAM.md; grep по слову `superpowers` (границы слова, без учёта регистра) внутри `skills/` даёт 0 совпадений вне шапок атрибуции и цитаты `obra/superpowers`.
10. Каждый SKILL.md проходит проверяемое подмножество чеклиста upstream `writing-skills` (источник — клон upstream по SHA из UPSTREAM.md): frontmatter только `name` + `description`, ≤1024 символов; `name` из строчных букв/цифр/дефисов и равен имени директории; `description` в третьем лице, начинается с «Use when» и описывает условие срабатывания. Полный upstream-процесс писания скиллов (TDD для скиллов, baseline-тесты) на v0.1 не распространяется.

## 8. Вне скоупа v0.1

- Автоматический sync с upstream (только ручная процедура из UPSTREAM.md).
- Поддержка не-Claude-Code харнессов (Codex, OpenCode и пр. — у upstream есть, мы нет).
- Deploy-плейбуки за пределами web / packages / tg-боты (мобильные — later).
- Visual companion из upstream brainstorming (браузерные мокапы) — не vendorится в v0.1.
- Биллинг/платёжные интеграции в discovery — только как юр-риск, без имплементации.
