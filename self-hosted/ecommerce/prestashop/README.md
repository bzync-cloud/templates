# PrestaShop

A deployable PrestaShop template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. PrestaShop is a full traditional storefront (catalog, cart, checkout,
back office admin) in one PHP application — unlike the headless `saleor` template elsewhere in
this catalog's `ecommerce` category, this one ships its own customer-facing frontend out of the
box. There's no managed Bzync equivalent to fall back on — this deployment **is** your store.

**Supported version:** `latest` (default) — set `PRESTASHOP_VERSION` as a build arg to pin one
**Default port:** `80` (HTTP)

## Database (required — no SQLite fallback)

PrestaShop needs a real MySQL or MariaDB database to start at all. Deploy
`data-stores/relational/mysql` (or `mariadb`) from this catalog as its own app first, then set
`DB_SERVER` / `DB_NAME` / `DB_USER` / `DB_PASSWD` in the dashboard (see `.env.example`) from the
values that deployment gives you — there's no dashboard "link" step on this tier.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Deploy MySQL/MariaDB (above) and set the `DB_*` vars.
2. Set `PS_DOMAIN` to your real domain **before first boot** — `PS_INSTALL_AUTO=1` (baked into
   the `Dockerfile`) runs PrestaShop's full installer non-interactively on first boot and bakes
   this domain into every generated link and asset URL. Changing it afterward means re-running
   the installer against a fresh `/var/www/html` volume, not just updating the env var.
3. Leave `ADMIN_PASSWD=changeme` as-is — the platform replaces any literal `changeme` value with
   a generated random secret on first deploy. The first admin (back office) account is created
   for you automatically from `ADMIN_MAIL`/`ADMIN_PASSWD` as part of the same auto-install; find
   the generated password in the dashboard's Variables tab after deploy.

## Run locally

Needs a reachable MySQL on the same Docker network — `.env.example` defaults `DB_SERVER` to `db`,
matching a companion container aliased that way:

```bash
docker network create prestashop-dev-net
docker run -d --name prestashop-dev-db --network prestashop-dev-net --network-alias db \
  -e MYSQL_DATABASE=app -e MYSQL_USER=app -e MYSQL_PASSWORD=changeme \
  -e MYSQL_RANDOM_ROOT_PASSWORD=yes mysql:8.0

docker build -t bzync-prestashop-dev .
docker run -d --name prestashop-dev --network prestashop-dev-net -p 80:80 \
  --env-file .env.example bzync-prestashop-dev
```

First boot runs the full installer (creates ~300 database tables) before the storefront is
usable — give it a minute or two. Visit `http://localhost` for the storefront, or
`http://localhost/admin-dev` (PrestaShop's default admin folder name — consider setting
`PS_FOLDER_ADMIN` to something less guessable for a real deployment) to log in with the admin
account above.

## Backups

Everything — uploaded product images, installed modules/themes, and the rendered
`app/config/parameters.php` — lives under `/var/www/html` (the volume this template persists), not
just a subset of it; PrestaShop's installer writes generated files directly into the webroot.
Product/order/customer data itself lives in MySQL/MariaDB. Back up both; losing either loses real,
non-reproducible data.
