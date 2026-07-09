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

`node/express` · `node/fastify` · `node/koa` · `node/hono` · `node/nextjs` · `node/nuxt` · `node/sveltekit` · `node/remix` · `node/gatsby` · `node/nestjs` · `node/adonisjs` · `node/strapi` · `node/keystone` · `node/directus` · `node/medusajs` · `node/bullmq-worker` · `node/plain`

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

### Databases (local dev reference)

`db/postgres` · `db/mysql` · `db/mariadb` · `db/mongodb` · `db/redis` · `db/couchbase`

Unlike the templates above, these aren't deployable apps — they're `Dockerfile`s matching the
exact engine/version Bzync Cloud Managed Databases (MDB) provisions in production, so you can run
a matching database locally before linking the real managed instance from the dashboard. See each
directory's `README.md` for supported versions, injected connection variables, and connection
snippets.

---

## What's in Each Template

| File | Purpose |
|------|---------|
| Source code | Minimal working app with `/` and `/health` endpoints |
| `BZYNC_CLOUD` | Tells the platform your runtime, framework, and version |
| `.env.example` | All environment variables, documented |
| `.env.production.example` | Production-specific overrides |
| `.env.staging.example` | Staging-specific overrides |
| `.env.development.example` | Development-specific overrides |
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

The `version` field is optional — the platform picks a sensible default if omitted. If you supply your own `Dockerfile`, it is used as-is and `BZYNC_CLOUD` is ignored for that service.

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
