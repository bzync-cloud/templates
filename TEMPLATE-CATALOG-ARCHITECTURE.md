# Bzync Cloud Template Catalog — Proposed Architecture

**Status:** Implemented. §4–§7 (the six-category reorg, naming standards, and the `.bzync-template.json`/`catalog.json` metadata layer from §6) are live in this repo — see git history starting at the "Reorganize template catalog into six top-level categories" commit. §8 (new templates for empty categories) is intentionally not implemented — those are recommendations for future contributions, not scaffolded placeholders beyond the empty category folders + `README.md` stubs. §9's migration plan describes the order this was actually done in, collapsed into fewer commits than originally phased.

---

## 1. Executive Summary

The current catalog (129 templates across 20 top-level folders) grew by adding a new sibling folder every time a new *kind* of thing showed up — a runtime, a bundler, a trigger mechanism, a data store, an app category — with no single organizing principle. That works at 129 templates. It will not work at 1,000, because there is no consistent answer to "where does a new template go," and the catalog has already started drifting from its own documentation as a result.

The core problem is **three different taxonomic axes are flattened into one list of top-level folders**:

1. *Runtime* (`node`, `python`, `go`, `php`, `ruby`, `rust`, `java`, `kotlin`, `dotnet`, `bun`, `deno`)
2. *Build tool / output shape* (`vite`, `static`, `docs`)
3. *Application category* (`self-hosted`, `database`, `caching`, `worker`, `cron`, `full-stack`)

A template's home currently depends on which axis whoever added it happened to be thinking about that day. That's why `wordpress`, `drupal`, and `joomla` live under `self-hosted/content-management/`, but their close sibling `magento` — verified below to have an identical `BZYNC_CLOUD` shape (`runtime = php`, `framework = magento`, a full deployable app, not a library you build on) — was left under `php/`. It's also why `worker/` and `cron/` are two separate top-level folders that both exist purely to hold the same five runtimes, differing only in *trigger*, and why `database/` and `caching/` are separate top-level folders holding the same conceptual thing (a stateful data store you deploy and point other apps at).

**Recommendation, in one sentence:** collapse the 20 top-level folders into 6 that each answer a single question ("is this code I write, a data store, a pre-built app, a static bundle, a multi-service starter, or a background task?"), and — more importantly — stop treating the directory tree as the marketplace taxonomy at all. Add a small per-template metadata file and a generated catalog index, so future category changes (adding a filter, splitting a category, renaming a label users see) are metadata edits, not mass file moves.

---

## 2. Problems Found

### 2.1 Mixed taxonomic axes at the top level (the root cause)
`node/`, `database/`, `vite/`, `self-hosted/`, and `worker/` are all siblings today, but they answer completely different questions (language, data-store type, bundler, application category, execution trigger). A new contributor has no rule to follow — they can defend putting a new template in at least two different places for most submissions.

### 2.2 Misplaced templates
- **`php/magento`** sits under the runtime folder alongside frameworks like `laravel` and `symfony`, but it's architecturally identical to `self-hosted/content-management/wordpress` (verified: same `runtime = php`, `framework = <app>` shape, both ship as complete deployable applications, not libraries). Magento should be a sibling of WordPress/Drupal/Joomla, not of Laravel.
- Conversely, **`self-hosted/content-management/{directus,keystone,strapi}`** are headless CMS *frameworks* you build a schema and admin panel on top of — much closer in kind to `node/nestjs` than to `wordpress`. Their current placement is defensible (they're commonly deployed as-is), but it means "self-hosted" currently mixes turnkey applications (WordPress: install and go) with developer frameworks (Keystone: you write a schema file), which will confuse the "self-hosted alternative to a SaaS product" mental model users bring to that category.

### 2.3 Duplicated category concepts
- **`worker/` and `cron/`** are two top-level folders, each containing the same runtimes (`node`, `python`, `ruby`, `go`, plus `bun` under worker only). The only real difference is trigger semantics (queue/long-running vs. scheduled), which is a *property* of a background-job template, not a reason for a separate top-level namespace.
- **`database/` and `caching/`** are two top-level folders for the same underlying concept: a stateful data-store server you deploy and hand connection strings to other apps. Splitting them by "the kind of persistence engine" is exactly the kind of split that won't scale once search engines, object storage, and message queues (see §2.6) are added — each would demand its own top-level folder under the current logic.
- **`vite/` and `static/` and `docs/`** all hold client-rendered, static-output templates. `docs/` (Docusaurus, MkDocs) holds two static-site generators; `static/` holds four *other* static-site generators (Hugo, Jekyll, Eleventy, Astro) plus Angular; `vite/` holds sixteen framework+bundler combinations that also produce static output. There is no principled reason Docusaurus is in its own top-level category while Hugo is one level down in `static/` — both are SSGs with the same deployment shape.

### 2.4 Runtime vs. framework vs. bundler confusion
`vite` is a build tool, not a runtime — it doesn't belong at the same tree level as `node`, `python`, `go`. Meanwhile several full SSR frameworks that also happen to use Vite under the hood (SvelteKit, Nuxt) are correctly filed under `node/`, while client-only apps that use Vite as a pure bundler (`vite/react`, `vite/vue`) are filed under a `vite/` category — so "React" and "Vue" as ecosystems are split across two unrelated top-level folders (`vite/vue` vs. `node/nuxt`) depending on whether the variant needs a server. A user browsing "Vue" has to know to check two different places.

### 2.5 Naming inconsistency
No consistent rule for singular vs. plural, or full word vs. abbreviation:
- `database` (singular) vs. `caching` (gerund) vs. `full-stack` (compound adjective) vs. `worker`/`cron` (singular nouns).
- Actual directory `self-hosted/database-administration/` vs. the catalog's own **README** calling it `self-hosted/db-admin/` — the README and the filesystem already disagree.
- `self-hosted/ai-automation/` bundles two unrelated concepts (AI tooling and generic workflow automation) under one gerund-ish compound; its only two current members (`n8n`, `openclaw`) are workflow-automation tools, not AI tools — there is no actual AI template (LLM inference, vector DB, RAG stack) in the catalog today despite the folder name.

### 2.6 Documentation drift (a symptom of the deeper problem)
The catalog's own `README.md` no longer matches the filesystem, which is exactly what happens when taxonomy lives only in folder paths with no generated source of truth:
- README lists `node/strapi`, `node/keystone`, `node/directus`, `node/medusajs`, `node/n8n`, `node/openclaw` — none of these exist under `node/`; they're all under `self-hosted/*`.
- README lists `php/statamic`, `php/october-cms`, `php/wordpress`, `php/drupal`, `php/joomla` under the PHP runtime table — all five actually live under `self-hosted/content-management/`.
- README lists `database/redis` — Redis is actually under `caching/redis`; `database/` has no Redis entry.
- README's "Database Admin" section says `self-hosted/db-admin/*` — the real path is `self-hosted/database-administration/*`.

This isn't a one-off typo; it's what happens whenever the marketplace-facing description of the catalog is hand-maintained prose instead of generated from the templates themselves. Any reorg that doesn't fix this generation gap will drift again.

### 2.7 No marketplace metadata layer
Every template ships a `BZYNC_CLOUD` file, but that file is purely **build configuration** (path, runtime, framework, version, dockerfile override) consumed by the platform's build step — it has no `category`, `tags`, `displayName`, `icon`, or `description` fields. Marketplace-facing taxonomy today *is* the physical directory path. That means the only way to change what a user sees in the marketplace is to move files on disk — which is the thing making every future reorg expensive and risky.

### 2.8 Category breadth mismatch inside `self-hosted/`
`self-hosted/` currently has five subcategories (`ai-automation`, `content-management`, `database-administration`, `project-management`, `version-control`). The prompt's own suggested list (git, project-management, cms, database-admin, monitoring, remote-access, mail, storage, identity, analytics, wiki, ai, automation, search) shows the catalog is covering roughly a third of the self-hosted application space a marketplace at this scale is expected to eventually carry — monitoring, identity, storage, wiki, mail, and analytics have zero templates today.

### 2.9 CI/tooling coupling to literal paths
`scripts/test-templates.sh` (invoked via `make test`) hardcodes exact template paths for special-case behavior, e.g.:
```sh
case ${1#"$ROOT"/} in
  php/laravel|full-stack/laravel-inertia-*) ... ;;
esac
case ${1#"$ROOT"/} in
  self-hosted/version-control/gitlab-ce) ... ;;
esac
```
Any directory reorganization must update this script in the *same* change, or these special cases (env vars Laravel needs to boot in a container; `--shm-size` GitLab CE needs to not hang) silently stop applying — the test would likely still "pass" in a degraded way rather than fail loudly, which is worse.

---

## 3. Design Principles Applied

The recommended taxonomy below is built to satisfy, directly:
- **One question per folder level.** Each top-level folder answers exactly one question about a template. No folder should require knowing two unrelated facts (e.g., "is it PHP" *and* "is it a turnkey app or a framework") to place something in it.
- **Directories organize maintainers; metadata organizes users.** The physical tree should be optimized for "where do I add a new template as a contributor." The marketplace UI should be optimized for "how do I find what I want as a user." These are different concerns and should not be forced to share one representation.
- **No category that requires a judgment call to avoid duplication.** `worker` vs. `cron`, `database` vs. `caching`, `vite` vs. `static` vs. `docs` are merged specifically because contributors were already guessing.
- **Room to grow without renaming.** Every top-level folder below can absorb 10x its current template count without needing to be re-split or renamed.

---

## 4. Recommended Taxonomy

### 4.1 Top level

```
templates/
    languages/        # backend runtimes + the frameworks that need a server process
    frontend/          # client-rendered / static-output apps (was vite/ + static/ + docs/)
    full-stack/         # curated multi-service starters (unchanged in concept)
    background-jobs/    # was worker/ + cron/, merged, trigger becomes a sub-level
    data-stores/         # was database/ + caching/, plus new: search, object-storage, message-queue
    self-hosted/         # turnkey applications you deploy as-is (expanded subcategories)
    scripts/            # tooling, unchanged — not part of the user-facing taxonomy
```

Six user-facing categories, each answering one distinct question:

| Category | Question it answers | Persona it serves first |
|---|---|---|
| `languages/` | "I'm writing code — give me a runtime + framework starter" | backend/frontend devs |
| `frontend/` | "I have a client-only app with static output" | frontend devs, agencies |
| `full-stack/` | "I want a pre-wired frontend+backend pair" | startup founders, agencies |
| `background-jobs/` | "I need something that runs without HTTP traffic" | backend devs, DevOps |
| `data-stores/` | "I need a stateful service my app talks to" | DevOps, backend devs |
| `self-hosted/` | "I want a finished product, not code to build on" | founders, agencies, enterprises |

### 4.2 `languages/` — runtimes and the frameworks that require them

```
languages/
    go/          plain, gin, echo, fiber, chi
    node/        plain, express, fastify, koa, hono, nestjs, adonisjs,
                 nextjs, nuxt, sveltekit, remix, gatsby
    python/      plain, django, flask, fastapi, litestar, sanic,
                 gradio, streamlit, reflex
    php/         plain, laravel, lumen, symfony, codeigniter, cakephp,
                 yii, slim, flight, mezzio, laminas
    ruby/        plain, rails, sinatra
    rust/        actix-web, axum
    java/        spring-boot
    kotlin/      ktor
    dotnet/      aspnetcore, mvc
    bun/         elysia, hono
    deno/        fresh, hono
```

**`php/magento` moves out of here** into `self-hosted/ecommerce/magento` (new subcategory — see §4.6). It's a deployable application, not a framework starter; nothing here is meant to be a finished product out of the box the way Magento is.

**Why frameworks stay nested under their runtime (not pulled out into their own top level):** a framework only exists in the context of the runtime that executes it — "give me a Laravel starter" is meaningless without also fixing "PHP." Splitting frameworks out into a `frameworks/` top-level (as some catalogs do) would just recreate axis-mixing, because you'd then need a second dimension ("but which runtime") to actually deploy it. Runtime-first nesting keeps one lookup, not two.

### 4.3 `frontend/` — client-rendered and static-output apps

Merges `vite/`, `static/`, and `docs/`. This resolves §2.3 and §2.4 directly: every template here shares one deployment shape (build once, serve static files), regardless of which bundler or generator produced them.

```
frontend/
    react/  react-ts/  vue/  vue-ts/  svelte/  svelte-ts/
    preact/  preact-ts/  solid/  solid-ts/  lit/  lit-ts/
    vanilla/  vanilla-ts/  qwik/  qwik-ts/          # was vite/*
    astro/  angular/  eleventy/  hugo/  jekyll/     # was static/* (minus "plain", see below)
    docusaurus/  mkdocs/                             # was docs/*
    plain/                                            # was static/plain
```

`docusaurus` and `mkdocs` are not split into a separate top-level category — they're static-site generators like Hugo and Jekyll, full stop. Documentation as a *use case* becomes a marketplace filter tag (`use-case: documentation`), not a directory, so a user browsing "documentation sites" still finds them via the metadata layer described in §6, without the catalog needing a category boundary that doesn't reflect any real deployment difference.

**On not splitting `frontend/` by bundler:** don't add a `bundler=vite` layer of nesting either — bundler choice is metadata (useful as a filter), not a category a human browses by. Nesting by framework identity (react, vue, svelte...) is what a user actually scans for.

### 4.4 `full-stack/` — unchanged in concept

```
full-stack/
    nextjs-go/  nextjs-fastapi/  nextjs-laravel/
    django-react/  fastapi-react/  sveltekit-fastapi/
    vite-react-fastapi/  vite-react-laravel/
    rails-react/  astro-strapi/
    laravel-inertia-react/  laravel-inertia-vue/  laravel-inertia-svelte/
```

This category is already well-named and internally consistent (`<frontend>-<backend>` slug, hyphenated, singular per-service names matching their `languages/`/`frontend/` counterparts). No structural change — just formalize the `<frontend>-<backend>` naming rule so future additions don't drift (see §5).

### 4.5 `background-jobs/` — merges `worker/` + `cron/`

```
background-jobs/
    worker/     node, bun, python, ruby, go
    cron/       node, python, ruby, go
```

Trigger type (`worker` = long-running/queue-driven, `cron` = scheduled) becomes the second path segment instead of the first, with runtime as the third. This keeps the useful distinction (a user does need to pick worker-vs-cron) while eliminating the duplicate top-level namespace. `bun` stays worker-only since that reflects the actual current catalog (no `cron/bun` exists).

### 4.6 `data-stores/` — merges `database/` + `caching/`, adds room for the missing infra primitives

```
data-stores/
    relational/       postgres, mysql, mariadb
    document/         mongodb, couchbase
    cache/             redis, valkey, keydb
    search/            (new — recommend: meilisearch, typesense)
    object-storage/    (new — recommend: minio)
    message-queue/     (new — recommend: rabbitmq, nats)
```

This is the most consequential merge: `database/` and `caching/` were already the same *kind* of category (a stateful backing service, not something end users visit), just split by which flavor of persistence. Framing the category as "data stores" instead of "databases" makes search engines, object storage, and message queues obvious future siblings instead of forcing another top-level folder each time one is added — which directly closes the gaps the prompt flags under "Missing Categories" (Search, Object Storage, Streaming/Messaging).

### 4.7 `self-hosted/` — turnkey applications, expanded subcategories

```
self-hosted/
    cms/                    directus, drupal, joomla, keystone, october-cms,
                            statamic, strapi, wordpress
    ecommerce/               magento                         (new — moved from php/)
    db-admin/                adminer, mongo-express, pgadmin, phpmyadmin
    project-management/      focalboard, leantime, plane, vikunja
    version-control/         cogs, forgejo, gitea, gitlab-ce
    automation/              n8n, openclaw                   (was ai-automation/)
    ai/                      (new, empty — recommend: ollama, open-webui, qdrant)
    monitoring/               (new, empty — recommend: uptime-kuma, netdata)
    identity/                (new, empty — recommend: authentik, keycloak)
    storage/                 (new, empty — recommend: nextcloud, seafile)
    wiki/                    (new, empty — recommend: wiki-js, bookstack)
    analytics/                (new, empty — recommend: umami, plausible)
    mail/                    (new, empty — recommend: mailu, listmonk)
    search/                   (new, empty — recommend: searxng)
```

Notes on the changes:
- **`content-management/` → `cms/`**: shorter, and matches how both technical and non-technical users actually search ("cms" gets far more marketplace search volume than "content management"). Keep `content management system` as a metadata alias (§6) so text search still matches either phrasing — the point of the metadata layer is that you don't have to choose only one.
- **`database-administration/` → `db-admin/`**: resolves the README-vs-filesystem drift noted in §2.6 by picking the shorter form the README already (incorrectly) assumed existed, rather than making the README match the longer form.
- **`ai-automation/` splits into `automation/` (workflow tools: n8n, OpenClaw) and `ai/` (model/vector-db tooling)**: these are different buyer intents — "automate my workflows" vs. "run an LLM/RAG stack" — and conflating them under one folder actively hid the fact the catalog has zero AI templates today.
- **New `ecommerce/` subcategory** exists specifically to give Magento a correct home alongside future entries (e.g., a headless commerce option) rather than stretching `cms/` to cover commerce platforms too.
- **`remote-access/`** (suggested in the prompt) is deliberately **not** added yet. Per the catalog's own README, upstream images that bundle SSH (port 22) alongside HTTP already require rebuilding to drop the SSH `EXPOSE` because the platform's ingress binds to the lowest-numbered exposed port. Most genuine remote-access tools (Guacamole, Tailscale-in-a-box) are TCP/SSH-first, not HTTP-first — they need platform-level ingress support for non-HTTP(S) protocols before they can be offered as templates at all. Track this as a platform capability gap, not a template gap (see §9 risk notes).

---

## 5. Naming Standards

| Element | Rule | Examples |
|---|---|---|
| Top-level category folder | kebab-case; plural when it names a collection of interchangeable items, singular/adjectival when it names a domain | `data-stores`, `background-jobs` (collections) vs. `self-hosted`, `full-stack`, `frontend` (domains) |
| Subcategory folder | kebab-case, plural if it's a collection of app types | `project-management`, `db-admin`, `cache` |
| Template leaf folder | kebab-case, singular, matches the upstream project's own canonical slug | `nextjs` not `next-js`; `postgres` not `postgresql`; `dotnet` not `dot-net` |
| TypeScript variants | `-ts` suffix on the base slug | `react` / `react-ts`, `vue` / `vue-ts` (already consistent — keep as-is) |
| Bare-runtime template | always named `plain` | `go/plain`, `php/plain`, `ruby/plain`, `frontend/plain` — never `starter`, `basic`, or `minimal`; `plain` is already used 5x in the current catalog, so this formalizes existing practice rather than introducing a new term |
| Multi-service (`full-stack`) slug | `<frontend-slug>-<backend-slug>`, both matching their canonical leaf names elsewhere in the catalog | `nextjs-go`, `vite-react-laravel` |
| Template ID (stable, metadata-only) | full path with `/` replaced by `-`, never shown to users, never reused after a template is removed | `self-hosted-cms-wordpress`, `data-stores-cache-redis` |
| Display name (metadata-only) | the proper product name, exact upstream capitalization | `"Next.js"`, `"PostgreSQL"`, `"WordPress"` — never derived from the folder slug |

**Resolving the specific examples the prompt raised:**
- `database` vs. `databases` → the merged category is `data-stores` (plural collection), sidestepping the singular/plural question for this name entirely.
- `worker` vs. `workers` → `background-jobs/worker/` (singular, since it's a job-type label under a plural parent, mirroring `background-jobs/cron/`).
- `static` vs. `static-sites` → folded into `frontend/`; not a standalone name to bikeshed anymore.
- `cron` vs. `scheduled-jobs` → keep `cron` — it's the term every runtime's own ecosystem uses (`node-cron`, Python's `croniter`, `django-crontab`), and it's already the term this catalog uses; don't introduce a synonym.
- `plain` vs. `starter` → `plain`, per above — already the incumbent, no reason to change.

---

## 6. The Missing Piece: A Metadata Layer

This is the highest-leverage recommendation in this document, independent of whether any directory is ever moved.

Today, marketplace taxonomy — what a user browsing the Bzync Cloud dashboard actually sees — **is** the directory path, because `BZYNC_CLOUD` is a build-config file (path/runtime/framework/version for the platform's build step) with no category, tags, or display fields, and there is no other index. That means every future taxonomy change (renaming a category label, adding a filter, tagging a template with more than one category) requires moving files on disk. That coupling is what makes reorganization expensive and risky, and it's the direct cause of the README drift in §2.6 — the README is hand-written prose trying to describe a tree that keeps moving underneath it.

**Recommendation:** add one new file per template, alongside (not replacing) `BZYNC_CLOUD`:

`.bzync-template.json`
```json
{
  "id": "self-hosted-cms-wordpress",
  "displayName": "WordPress",
  "category": "self-hosted",
  "subcategory": "cms",
  "aliases": ["content management system", "blog"],
  "tags": ["php", "mysql"],
  "requires": ["data-stores/relational/mysql"],
  "description": "The world's most popular CMS, self-hosted.",
  "docsPath": "README.md"
}
```

Then a small build script (`scripts/generate-catalog.sh`, sibling to the existing `test-templates.sh`) walks the tree, collects every `.bzync-template.json`, and emits a single `catalog.json` at the repo root. **The marketplace dashboard reads `catalog.json`, never the filesystem directly.** This is the same pattern used by comparably-scaled template marketplaces (Vercel, Railway) — the directory tree is a contributor-facing storage detail; the generated index is the only thing the product surface depends on.

Once this is in place:
- Any future directory reorganization is invisible to end users — the ID stays stable, only the path (an internal implementation detail) changes.
- A template can appear under more than one marketplace filter (e.g., WordPress tagged both `cms` and `php`) without being physically duplicated.
- The README can be *generated* from `catalog.json` instead of hand-maintained, eliminating the entire class of drift found in §2.6 permanently, not just fixing today's instance of it.

---

## 7. Directory Tree (Full Proposed Layout)

```text
templates/
├── languages/
│   ├── go/            {plain, gin, echo, fiber, chi}
│   ├── node/          {plain, express, fastify, koa, hono, nestjs, adonisjs,
│   │                    nextjs, nuxt, sveltekit, remix, gatsby}
│   ├── python/        {plain, django, flask, fastapi, litestar, sanic,
│   │                    gradio, streamlit, reflex}
│   ├── php/           {plain, laravel, lumen, symfony, codeigniter, cakephp,
│   │                    yii, slim, flight, mezzio, laminas}
│   ├── ruby/          {plain, rails, sinatra}
│   ├── rust/          {actix-web, axum}
│   ├── java/          {spring-boot}
│   ├── kotlin/        {ktor}
│   ├── dotnet/        {aspnetcore, mvc}
│   ├── bun/           {elysia, hono}
│   └── deno/          {fresh, hono}
│
├── frontend/
│   ├── react/  react-ts/  vue/  vue-ts/  svelte/  svelte-ts/
│   ├── preact/  preact-ts/  solid/  solid-ts/  lit/  lit-ts/
│   ├── vanilla/  vanilla-ts/  qwik/  qwik-ts/
│   ├── astro/  angular/  eleventy/  hugo/  jekyll/
│   ├── docusaurus/  mkdocs/
│   └── plain/
│
├── full-stack/
│   ├── nextjs-go/  nextjs-fastapi/  nextjs-laravel/
│   ├── django-react/  fastapi-react/  sveltekit-fastapi/
│   ├── vite-react-fastapi/  vite-react-laravel/
│   ├── rails-react/  astro-strapi/
│   └── laravel-inertia-react/  laravel-inertia-vue/  laravel-inertia-svelte/
│
├── background-jobs/
│   ├── worker/        {node, bun, python, ruby, go}
│   └── cron/          {node, python, ruby, go}
│
├── data-stores/
│   ├── relational/    {postgres, mysql, mariadb}
│   ├── document/      {mongodb, couchbase}
│   ├── cache/          {redis, valkey, keydb}
│   ├── search/          {meilisearch*, typesense*}
│   ├── object-storage/  {minio*}
│   └── message-queue/   {rabbitmq*, nats*}
│
├── self-hosted/
│   ├── cms/                 {directus, drupal, joomla, keystone,
│   │                          october-cms, statamic, strapi, wordpress}
│   ├── ecommerce/           {magento}
│   ├── db-admin/            {adminer, mongo-express, pgadmin, phpmyadmin}
│   ├── project-management/ {focalboard, leantime, plane, vikunja}
│   ├── version-control/     {cogs, forgejo, gitea, gitlab-ce}
│   ├── automation/          {n8n, openclaw}
│   ├── ai/                  {ollama*, open-webui*, qdrant*}
│   ├── monitoring/          {uptime-kuma*, netdata*}
│   ├── identity/            {authentik*, keycloak*}
│   ├── storage/             {nextcloud*, seafile*}
│   ├── wiki/                {wiki-js*, bookstack*}
│   ├── analytics/           {umami*, plausible*}
│   ├── mail/                {mailu*, listmonk*}
│   └── search/              {searxng*}
│
└── scripts/            (tooling — not part of the user-facing taxonomy)

  * = recommended new template, not yet in the catalog (§8)
```

---

## 8. Additional Template Ideas (Filling the Gaps)

Prioritized by how directly they close a gap this review found:

1. **`data-stores/search/meilisearch`** and **`typesense`** — closes the Search gap; both are simple single-binary deploys, good first entries.
2. **`data-stores/object-storage/minio`** — closes the Object Storage gap; also unblocks self-hosted apps that need S3-compatible storage (the README already flags this as a hard blocker for `self-hosted/project-management/plane`, which needs S3-compatible storage the catalog currently has no answer for).
3. **`data-stores/message-queue/rabbitmq`** — same README-flagged gap: Plane also needs an AMQP broker with no current template.
4. **`self-hosted/monitoring/uptime-kuma`** — lightweight, single-container, high user-demand self-hosted monitoring; good low-risk first entry in a currently-empty category.
5. **`self-hosted/identity/authentik`** — SSO/identity is one of the highest-demand self-hosted categories for agencies and enterprises evaluating a PaaS.
6. **`self-hosted/ai/ollama`** + **`open-webui`** — the catalog currently has zero AI templates despite AI being explicitly named in the prompt's "Missing Categories" list and being the single most-requested category in PaaS marketplaces today.
7. **`self-hosted/analytics/umami`** — simple, single-Postgres-dependency privacy-focused analytics; pairs naturally with `data-stores/relational/postgres`.
8. **`self-hosted/wiki/wiki-js`** — closes the Wiki gap; also Postgres-backed, reuses existing data-store templates.

None of these require any platform capability beyond what already exists (HTTP(S) ingress, volumes, env-var injection) — unlike `remote-access/`, which is deliberately deferred (§4.7).

---

## 9. Migration Plan

Ordered to minimize risk: metadata first (so the marketplace-facing surface stops depending on paths at all), then merges from lowest-risk to highest-risk, by number of directories touched.

| Phase | Change | Directories touched | Depends on |
|---|---|---|---|
| **0** | Add `.bzync-template.json` to all 129 existing templates *in place* (no moves). Write `scripts/generate-catalog.sh`. Point the marketplace UI at generated `catalog.json` instead of any hardcoded path list. | 0 moved | — |
| **1** | Fix README drift (§2.6) to match the *current* (pre-reorg) filesystem, or better, generate it from `catalog.json` from Phase 0. | 0 moved | Phase 0 |
| **2** | Merge `worker/` + `cron/` → `background-jobs/{worker,cron}/`. Update `scripts/test-templates.sh` path cases. | ~9 | Phase 0 |
| **3** | Merge `database/` + `caching/` → `data-stores/{relational,document,cache}/`. Update test script paths. | ~9 | Phase 0 |
| **4** | Merge `vite/` + `static/` + `docs/` → `frontend/`. Update test script paths (none currently special-cased, lowest script risk). | ~26 | Phase 0 |
| **5** | Move `php/magento` → `self-hosted/ecommerce/magento`. Small, but touches the one special-cased runtime file that's semantically miscategorized — do it as its own isolated PR for easy review/revert. | 1 | Phase 0 |
| **6** | Move `go/`, `node/`, `python/`, `php/`, `ruby/`, `rust/`, `java/`, `kotlin/`, `dotnet/`, `bun/`, `deno/` under `languages/`. Largest mechanical change (~80 dirs); do last, after Phase 0 means the marketplace UI already doesn't care. Update `test-templates.sh`'s `php/laravel` special case to `languages/php/laravel`. | ~80 | Phase 0 |
| **7** | Restructure `self-hosted/` subcategories: `content-management` → `cms`, `database-administration` → `db-admin`, split `ai-automation` → `automation` + empty `ai`. Add empty placeholder folders (with a short README pointing to §8) for `monitoring`, `identity`, `storage`, `wiki`, `analytics`, `mail`, `search`. | ~14 | Phase 0 |
| **8** | Populate new categories with the templates from §8, one PR per template. | 0 moved (additive) | Phases 3, 7 |

**Every phase must re-run `make test` (full `scripts/test-templates.sh` suite) before merging** — the smoke tests build and boot every template's container, which is the only automated check that a `git mv` didn't break a relative path inside a template (Dockerfile `COPY` paths, `.env.example` references, docker-compose volume paths).

---

## 10. Backward Compatibility Considerations

- **`git mv` preserves rename history** (`git log --follow` still works per-file), so nothing is lost at the git level regardless of how directories are reorganized.
- **The real compatibility risk is not git — it's anything holding a literal path string outside this repo.** Per project context, this `~/bzync/cloud` tree is a separate vendored deployment tier from the production `platform-cloud-control` repos, so this document has no visibility into whether a dashboard/marketplace picker elsewhere hardcodes template paths (e.g., a "Deploy from template" button pointing at `templates/node/nextjs`). **Before executing Phases 2–7, confirm with whoever owns the consuming dashboard UI whether it reads paths directly or through a data layer** — Phase 0's `catalog.json` is specifically designed to give that UI a stable, ID-based integration point so later phases don't require a coordinated cross-repo release.
- **`scripts/test-templates.sh`'s hardcoded path cases must move in the *same commit* as any `git mv` that affects them** (`php/laravel`, `full-stack/laravel-inertia-*`, `self-hosted/version-control/gitlab-ce`) — deferring this to a follow-up risks CI silently running without the special-case env vars/flags rather than failing loudly, which is a worse failure mode than an obvious break.
- **Tag a release/commit before Phase 2 begins**, so any external documentation or bookmarks referencing today's paths can pin to a known-good pre-reorg commit while downstream consumers update.
- **No symlink compatibility shims are recommended.** Directory symlinks in git are fragile across `git clone`/`git archive`/CI checkout behavior and would just relocate the coupling problem instead of solving it. The metadata layer (Phase 0) is the actual fix; symlinks are a workaround for not having done Phase 0 first.

---

## 11. Future-Proofing Recommendations

1. **Never add a 21st top-level category as a knee-jerk response to one new template.** Every top-level folder in §4 is designed to absorb the next order of magnitude of templates without a rename. If a genuinely new axis emerges (e.g., a "serverless functions" deploy target distinct from both `languages/` apps and `background-jobs/`), evaluate whether it's actually a new *category* or just a new *tag* on the metadata layer first — most apparent new categories turn out to be tags.
2. **Contributor-facing rule of thumb** (put this at the top of a `CONTRIBUTING.md` for the templates repo): *"Is this something a user writes code on top of? → `languages/`. Is it a finished product a user deploys as-is? → `self-hosted/`. Does it hold state for other templates? → `data-stores/`. Does it run without serving HTTP? → `background-jobs/`."* Four questions, mutually exclusive, covers the whole tree.
3. **Enforce the metadata file in CI.** Extend `scripts/test-templates.sh` (or add a cheap separate lint step) to fail if any template directory lacks a `.bzync-template.json`, and to fail `generate-catalog.sh` if two templates claim the same `id`. This is what prevents the README-drift failure mode (§2.6) from recurring in a different form.
4. **Treat `remote-access/` as a platform-capability-gated category**, not a permanently excluded one — revisit once/if the Compute Plane's ingress supports non-HTTP(S) protocols.

---

## 12. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Mass `git mv` breaks a relative path inside a template (Dockerfile `COPY`, compose volume path) | Medium (mechanical, ~130 dirs touched across all phases) | Medium — caught by CI, not silent | Run full `make test` after every phase, not just at the end |
| `test-templates.sh` special-case paths fall out of sync with a move | Medium — the script is not auto-derived from the tree | Medium — degraded test coverage (e.g., GitLab CE boots without adequate `shm-size`) rather than a hard CI failure, so it can go unnoticed | Update script path cases in the same commit as the corresponding `git mv`; consider deriving special cases from `.bzync-template.json` tags instead of literal paths as a follow-up |
| An external system (dashboard picker, marketing site, shared docs link) holds a literal old path | Unknown likelihood — this repo's consumers are outside this review's visibility (separate vendored tier per project context) | High if it exists — a broken "deploy from template" button is user-facing | Do Phase 0 (metadata/ID layer) before any directory move; confirm with the dashboard owner before Phase 2 |
| README/documentation drifts again after reorg | High, if left hand-maintained (it already drifted once) | Low individually, compounding over time | Generate README from `catalog.json` (Phase 1) instead of hand-writing it |
| Reorg PR becomes one giant diff that's hard to review/revert | High if done as a single change | Medium — harder rollback if something breaks | Follow the phased plan in §9; each phase is an independently revertible PR |

---

## Appendix: Verification Notes

- Confirmed via direct inspection: `php/magento/BZYNC_CLOUD` and `self-hosted/content-management/wordpress/BZYNC_CLOUD` have identical field shapes (`path = .`, `runtime = php`, `framework = <app>`, `version = 8.4`), supporting §2.2's claim that Magento is miscategorized relative to its closest sibling.
- Confirmed via `find`: `self-hosted/` currently has exactly 5 subcategories (`ai-automation`, `content-management`, `database-administration`, `project-management`, `version-control`) — 27 template directories total.
- Confirmed via `grep`/README read: at least 4 distinct instances of README-vs-filesystem drift (§2.6), all pointing to paths that were valid at some earlier point but have since moved without the README being updated.
- Confirmed via `cat scripts/test-templates.sh`: 2 literal path special-cases (`php/laravel|full-stack/laravel-inertia-*`, `self-hosted/version-control/gitlab-ce`) that any reorg must update in lockstep.
