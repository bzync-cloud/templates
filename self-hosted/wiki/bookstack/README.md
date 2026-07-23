# BookStack

A deployable BookStack template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. BookStack is a self-hosted wiki/documentation platform organized
around a Books → Chapters → Pages hierarchy, with WYSIWYG and Markdown editing. There's no
managed Bzync equivalent to fall back on — this deployment **is** your wiki instance.

**Supported version:** `latest` (default) — set `BOOKSTACK_VERSION` as a build arg to pin one
**Default port:** `80` (HTTP)

## Database (required — no SQLite fallback)

BookStack needs a real MySQL or MariaDB database to start at all. Deploy
`data-stores/relational/mariadb` from this catalog as its own app first, then set `DB_HOST` /
`DB_PORT` / `DB_DATABASE` / `DB_USERNAME` / `DB_PASSWORD` in the dashboard (see `.env.example`)
from the values that deployment gives you — there's no dashboard "link" step on this tier.
Postgres isn't supported by BookStack; it has to be MySQL/MariaDB.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Deploy MariaDB (above) and set the `DB_*` vars.
2. Generate a real `APP_KEY` — BookStack (Laravel) needs `base64:<32 random bytes>`, not the
   repo-standard "changeme" placeholder (see `.env.example` for the generation command). Unlike
   `SECRET_KEY`-style vars elsewhere in this repo, this one can't rely on the platform's generic
   "changeme" substitution — the format has to match exactly.
3. Once you have a domain, set `APP_URL` — BookStack bakes it into every link it generates (page
   URLs, image URLs, email links), so this needs to be right before real content accumulates.

### The default admin account — change this immediately

BookStack ships with a fixed, publicly-documented first admin account created by its own DB
migrations: **`admin@admin.com` / `password`**. There's no env var to override this (unlike the
bootstrap-account pattern used by other templates in this repo) — log in with it once, then
either change the email/password from **Edit Profile** in the UI, or run BookStack's own CLI
command to reset it non-interactively before anyone else gets a chance to log in first:

```bash
docker exec <container> php /app/www/artisan bookstack:create-admin \
  --email="admin@your-domain.example.com" --name="Admin" --password="a-strong-password" --initial
```

`--initial` targets the existing default admin instead of creating a second one. Treat a freshly
deployed, not-yet-secured instance as compromised until you've done this — the default credentials
are public knowledge and this app has no bootstrap-env-var alternative.

## Run locally

Needs a reachable MariaDB on the same Docker network — `.env.example` defaults `DB_HOST` to `db`,
matching a companion container aliased that way:

```bash
docker network create bookstack-dev-net
docker run -d --name bookstack-dev-db --network bookstack-dev-net --network-alias db \
  -e MARIADB_DATABASE=app -e MARIADB_USER=app -e MARIADB_PASSWORD=changeme \
  -e MARIADB_ROOT_PASSWORD=changeme mariadb:11

docker build -t bzync-bookstack-dev .
docker run -d --name bookstack-dev --network bookstack-dev-net -p 80:80 \
  --env-file .env.example bzync-bookstack-dev
```

Visit `http://localhost` and log in with the default admin account above, then secure it.

## Backups

Uploaded images/attachments and BookStack's own config cache live under `/config` (the volume
this template persists) — everything else (books, pages, users, permissions) lives in MariaDB.
Back up both; losing either loses real content.
