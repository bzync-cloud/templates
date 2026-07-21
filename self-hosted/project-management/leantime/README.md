# Leantime

A production-shaped, self-hosted Leantime instance — clone, push, and Bzync Cloud builds this
`Dockerfile` as-is, same as any other template. Unlike `database/*`, there's no managed Bzync
equivalent to fall back on: this deployment **is** your Leantime instance. Unlike the other
project-management templates here (Vikunja, Focalboard), Leantime has no SQLite fallback — it
needs a real MySQL/MariaDB database to start at all, and won't serve anything without one.

**Supported versions:** `latest` (default) — set `LEANTIME_VERSION` as a build arg to pin one
**Default port:** `8080`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard.

1. Deploy `database/mysql` or `database/mariadb` from this catalog as its own app. Set the
   `LEAN_DB_*` vars in `.env.example` from the values you configured there (no dashboard linking
   on this tier) — the container won't come up without them.
2. Set `LEAN_APP_URL` to your real domain once one is attached.
3. Complete the first-run setup at `/install` to create your admin account.

Everything except uploaded file attachments (`/var/www/html/userfiles`, which this Dockerfile
declares as a volume) lives in the linked database — losing that database loses the instance;
losing the volume just loses attachments.

## Run locally

Leantime needs a real database from the start — bring one up alongside it:

```bash
docker network create leantime-dev
docker run -d --name db --network leantime-dev \
  -e MARIADB_DATABASE=leantime -e MARIADB_USER=leantime \
  -e MARIADB_PASSWORD=change-me -e MARIADB_ROOT_PASSWORD=change-me \
  mariadb:11
docker build -t bzync-leantime-dev .
docker run -d --name leantime-dev --network leantime-dev \
  -p 8080:8080 --env-file .env.example bzync-leantime-dev
```

Visit `http://localhost:8080` and complete the first-run setup.

## Mail

Notifications and invite emails need SMTP configured — see the commented-out `LEAN_EMAIL_*`
block in `.env.example`. Without it, Leantime still works, just silently skips sending anything.
