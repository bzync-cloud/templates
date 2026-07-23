# Wiki.js

A deployable Wiki.js template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. Wiki.js is a modern, Node-based wiki with Markdown/WYSIWYG/AsciiDoc
editing, built-in page history, and pluggable auth/storage/search modules. There's no managed
Bzync equivalent to fall back on — this deployment **is** your wiki instance.

**Supported version:** `2` (default, tracks the current major) — set `WIKIJS_VERSION` as a build
arg to pin a specific one
**Default port:** `3000` (HTTP)

## Database (required — no embedded fallback)

Wiki.js needs a real Postgres database to start at all. Deploy `data-stores/relational/postgres`
from this catalog as its own app first, then set `DB_HOST` / `DB_NAME` / `DB_USER` / `DB_PASS` in
the dashboard (see `.env.example`) from the values that deployment gives you — there's no
dashboard "link" step on this tier.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Deploy Postgres (above)
and set the `DB_*` vars before your first visit — Wiki.js won't boot past its setup wizard without
a working database connection.

### First admin account — set up through the web wizard

Unlike other templates in this repo (which auto-create an admin from bootstrap env vars, or ship
a fixed default account), Wiki.js has **no env-var-driven admin bootstrap at all**. Visiting the
site for the first time on a fresh database drops you straight into its own setup wizard, where
you pick the site name, locale, and create the first admin account interactively. There's nothing
to configure ahead of time for this beyond having a working database connection — but it also
means an unsecured, freshly deployed instance is claimable by whoever visits it first, so don't
leave a fresh deploy publicly reachable before completing the wizard yourself.

## Run locally

Needs a reachable Postgres on the same Docker network — `.env.example` defaults `DB_HOST` to
`db`, matching a companion container aliased that way:

```bash
docker network create wikijs-dev-net
docker run -d --name wikijs-dev-db --network wikijs-dev-net --network-alias db \
  -e POSTGRES_DB=app -e POSTGRES_USER=app -e POSTGRES_PASSWORD=changeme postgres:16-alpine

docker build -t bzync-wikijs-dev .
docker run -d --name wikijs-dev --network wikijs-dev-net -p 3000:3000 \
  --env-file .env.example bzync-wikijs-dev
```

Visit `http://localhost:3000` and complete the setup wizard.

## Backups

Locally-stored uploads and any locally-cloned content repos live under `/wiki/data/content` (the
volume this template persists) — pages, users, and configuration live in Postgres. Back up both;
losing either loses real content.
