# Bzync Cloud Starter Templates

Ready-to-deploy starter templates for [Bzync Cloud](https://cloud.bzync.com). Pick a template that matches your stack, clone it, and push — the platform builds and deploys it automatically.

## How It Works

1. **Pick a template** from the list below
2. **Clone and customise** — add your code, update env variables
3. **Push to GitHub** — connect your repo in the Bzync Cloud dashboard and deploy

Bzync Cloud reads your project files (`package.json`, `go.mod`, `composer.json`, etc.) and auto-generates a production Dockerfile. No Dockerfile required.

---

## Templates

### Node.js

`node/express` · `node/fastify` · `node/koa` · `node/hono` · `node/nextjs` · `node/nuxt` · `node/sveltekit` · `node/remix` · `node/gatsby` · `node/nestjs` · `node/adonisjs` · `node/strapi` · `node/keystone` · `node/directus` · `node/medusajs` · `node/bullmq-worker` · `node/n8n` · `node/openclaw` · `node/plain`

### Vite

`vite/react` · `vite/react-ts` · `vite/vue` · `vite/vue-ts` · `vite/svelte` · `vite/svelte-ts` · `vite/preact` · `vite/preact-ts` · `vite/solid` · `vite/solid-ts` · `vite/lit` · `vite/lit-ts` · `vite/vanilla` · `vite/vanilla-ts` · `vite/qwik` · `vite/qwik-ts`

### Python

`python/django` · `python/fastapi` · `python/flask` · `python/litestar` · `python/sanic` · `python/gradio` · `python/streamlit` · `python/reflex` · `python/odoo` · `python/celery-worker` · `python/plain`

### PHP

`php/laravel` · `php/lumen` · `php/symfony` · `php/codeigniter` · `php/cakephp` · `php/yii` · `php/slim` · `php/flight` · `php/mezzio` · `php/laminas` · `php/statamic` · `php/october-cms` · `php/wordpress` · `php/drupal` · `php/joomla` · `php/magento` · `php/plain`

### Ruby

`ruby/rails` · `ruby/sinatra` · `ruby/plain`

### Go

`go/gin` · `go/echo` · `go/fiber` · `go/chi` · `go/plain`

### Static Sites & Docs

`static/angular` · `static/astro` · `static/eleventy` · `static/hugo` · `static/jekyll` · `static/plain` · `docs/docusaurus` · `docs/mkdocs`

### Bun

`bun/elysia` · `bun/hono`

### Deno

`deno/fresh` · `deno/hono`

### Java / Kotlin

`java/spring-boot` · `kotlin/ktor`

### .NET

`dotnet/aspnetcore` · `dotnet/mvc`

### Rust

`rust/actix-web` · `rust/axum`

### Workers & Cron Jobs

`worker/node` · `worker/bun` · `worker/python` · `worker/ruby` · `worker/go` · `cron/node` · `cron/python` · `cron/ruby` · `cron/go`

### Full-Stack (multi-service)

`full-stack/nextjs-go` · `full-stack/nextjs-fastapi` · `full-stack/nextjs-laravel` · `full-stack/django-react` · `full-stack/fastapi-react` · `full-stack/sveltekit-fastapi` · `full-stack/vite-react-fastapi` · `full-stack/vite-react-laravel` · `full-stack/rails-react` · `full-stack/astro-strapi` · `full-stack/laravel-inertia-react` · `full-stack/laravel-inertia-vue` · `full-stack/laravel-inertia-svelte`

### Databases

`database/postgres` · `database/mysql` · `database/mariadb` · `database/mongodb` · `database/redis` · `database/couchbase`

Deployable like any other template — clone, push, and the platform builds the `Dockerfile` as-is.
Each one matches the exact engine/version Bzync Cloud's production Managed Databases (MDB)
provisions — but this tier has no managed database service of its own (mdb was removed here; see
the workspace root `README.md`), so a deployed instance here is the database, not a dev stand-in
for a linked managed one. See each directory's `README.md` for supported versions, the connection
variables to set on any other app that needs to reach it, and connection snippets.

### Version Control

`self-hosted/version-control/gitea` · `self-hosted/version-control/forgejo` · `self-hosted/version-control/gitlab-ce` · `self-hosted/version-control/cogs` (Gogs)

Self-hosted Git servers — deployable like any other template, each ships its own `Dockerfile`.
Like `database/*` on this tier, there's no managed Bzync equivalent to fall back on: these
deployments *are* the Git server, and their persistent volume holds real, non-reproducible data
(repos, issues, users). Each image is rebuilt from the upstream vendor image with the SSH port
deliberately dropped — Bzync Cloud's ingress and health checks target the lowest-numbered
`EXPOSE`d port in the image, and these upstream images all bake in port `22` alongside their HTTP
port, which would otherwise silently steal ingress traffic. Git-over-SSH still runs inside each
container, just not reachable through the platform's HTTP(S)-only ingress — use HTTPS remotes
instead. See each directory's `README.md` for first-boot admin account setup, resource
requirements (GitLab CE in particular needs considerably more than the other three), and
switching from the zero-config SQLite default to a separately deployed `database/postgres`
instance.

### Database Admin

`self-hosted/db-admin/adminer` · `self-hosted/db-admin/phpmyadmin` ·
`self-hosted/db-admin/mongo-express` · `self-hosted/db-admin/pgadmin`

GUIs for a database deployed elsewhere on this tier (e.g. from `database/*`) — Adminer and
phpMyAdmin are stateless pass-throughs (no login of their own, no volume; whatever DB credentials
you type in each visit are the whole auth story). mongo-express and pgAdmin do have their own
separate login on top of the target database's credentials, and use `DB_*` env vars you set
yourself to point at that deployment (no automatic linking on this tier) — see each directory's
`README.md` for exactly which vars, and how each one's access should be restricted before it's
reachable on a public domain.

### Project Management

`self-hosted/project-management/vikunja` · `self-hosted/project-management/focalboard` ·
`self-hosted/project-management/leantime` · `self-hosted/project-management/plane`

Self-hosted task/project trackers — deployable like any other template. Vikunja and Focalboard
default to an embedded SQLite database (no separate database needed for solo/small use, with a
documented path to a separately deployed Postgres/MySQL instance — from `database/*` on this
tier — for heavier use); Leantime has no SQLite fallback and needs a MySQL/MariaDB database from
the start. Plane's all-in-one image is the heaviest of the four: it needs Postgres, Redis, an
AMQP broker, and S3-compatible object storage all running before it starts at all —
`database/*` covers the first two on this tier, but the broker and object storage have no Bzync
template equivalent and need to come from elsewhere. See each directory's `README.md` for the
exact tradeoffs and setup steps.

---

## What's in Each Template

| File | Purpose |
|------|---------|
| Source code | Minimal working app with `/` and `/health` endpoints |
| `BZYNC_CLOUD` | Tells the platform your runtime, framework, and version |
| `.env.example` | All environment variables, documented |
| `.gitignore` | Sensible ignores for the stack |
| `.dockerignore` | Keeps images lean |

---

## The BZYNC_CLOUD File

Every template ships a `BZYNC_CLOUD` file that explicitly declares the stack. You can add one to any project to override auto-detection.

**Single service:**

```ini
path = .
runtime = node
framework = nextjs
version = 22
```

**Multiple services** (full-stack apps):

```ini
[api]
path = backend
runtime = go
version = 1.24

[web]
path = frontend
runtime = node
framework = nextjs
version = 22
```

The `version` field is optional — the platform picks a sensible default if omitted. If you supply your own `Dockerfile`, add `dockerfile = Dockerfile` (or the correct relative path) to `BZYNC_CLOUD` — a Dockerfile sitting in the repo is **not** picked up automatically just by being present; without that key the platform falls back to auto-detecting a runtime from `package.json`/`go.mod`/etc., which either fails outright (no such file) or silently builds a *different*, auto-generated Dockerfile instead of the one you shipped. Every template in this catalog that ships its own Dockerfile sets this key.

Only the **first** `[section]` in a multi-service `BZYNC_CLOUD` is currently built — the platform parses every section but only acts on the first one, so a two-service full-stack template deploys as a single service today, not two.

---

## Deploying Without a Template

Any standard project deploys without a template. The platform auto-detects your stack:

| Project file | Detected as |
|---|---|
| `go.mod` | Go |
| `package.json` | Node.js (framework inferred from dependencies) |
| `requirements.txt` / `Pipfile` | Python (framework inferred from contents) |
| `Gemfile` | Ruby (framework inferred from contents) |
| `composer.json` | PHP (framework inferred from contents) |
| `Cargo.toml` | Rust |
| `pom.xml` | Java / Maven |
| `build.gradle.kts` | Kotlin / Gradle |
| `*.csproj` | .NET |
| `wp-config.php` | WordPress |
| `deno.json` | Deno |
| `index.html` | Static site (served by nginx) |

---

## Supported Runtimes

| Runtime | Frameworks | Version format | Example versions |
|---------|-----------|----------------|-----------------|
| `go` | `gin`, `echo`, `fiber`, `chi`, `plain`, `cron`, `worker` | `major.minor` | `1.22`, `1.23`, `1.24` |
| `node` | `nextjs`, `nuxt`, `sveltekit`, `remix`, `gatsby`, `nestjs`, `adonisjs`, `strapi`, `keystone`, `directus`, `medusajs`, `docusaurus`, `hono`, `express`, `fastify`, `koa`, `bullmq-worker`, `cron`, `worker`, `plain` | `major` | `18`, `20`, `22` |
| `vite` | `react`, `react-ts`, `vue`, `vue-ts`, `svelte`, `svelte-ts`, `preact`, `preact-ts`, `solid`, `solid-ts`, `lit`, `lit-ts`, `vanilla`, `vanilla-ts`, `qwik`, `qwik-ts` | `major` | `20`, `22` |
| `python` | `django`, `fastapi`, `flask`, `litestar`, `sanic`, `gradio`, `streamlit`, `reflex`, `odoo`, `celery-worker`, `mkdocs`, `cron`, `worker`, `plain` | `major.minor` | `3.11`, `3.12`, `3.13` |
| `ruby` | `rails`, `sinatra`, `cron`, `worker`, `plain` | `major.minor` | `3.2`, `3.3`, `3.4` |
| `php` | `laravel`, `lumen`, `symfony`, `codeigniter`, `cakephp`, `yii`, `slim`, `flight`, `mezzio`, `laminas`, `statamic`, `october-cms`, `wordpress`, `drupal`, `joomla`, `magento`, `plain` | `major.minor` | `8.2`, `8.3`, `8.4` |
| `bun` | `elysia`, `hono`, `worker` | `major.minor` | `1.0`, `1.1` |
| `deno` | `fresh`, `hono` | `major.minor` | `1.46`, `2.0` |
| `java` | `spring-boot` | `major` | `21` |
| `kotlin` | `ktor` | `major.minor` | `2.0` |
| `dotnet` | `aspnetcore`, `mvc` | `major.minor` | `8.0`, `9.0` |
| `rust` | `actix-web`, `axum` | `major.minor` | `1.82` |
| `static` | `eleventy`, `hugo`, `jekyll`, `angular`, `astro`, `plain` | — | — |
# templates
