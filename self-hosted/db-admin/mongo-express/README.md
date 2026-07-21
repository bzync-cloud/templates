# mongo-express

A MongoDB GUI — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same as any other
template. mongo-express holds no state of its own and needs no volume, but unlike Adminer or
phpMyAdmin it can't serve its login page without a reachable MongoDB: the upstream image's own
entrypoint blocks on a TCP connection to Mongo before starting the app at all.

**Supported versions:** `1.0.2` (default) — set `MONGO_EXPRESS_VERSION` as a build arg for others
**Default port:** `8081`
**Supports:** MongoDB only (not MySQL/Postgres — see `db-admin/phpmyadmin` or `db-admin/pgadmin`
for those)

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard.

1. Deploy `database/mongodb` from this catalog as its own app, then set `DB_HOST`, `DB_PORT`,
   `DB_NAME`, `DB_USER`, and `DB_PASSWORD` here from the values you configured there (no
   dashboard linking on this tier); `start.sh` (baked into the image as the entrypoint)
   translates these to mongo-express's native `ME_CONFIG_MONGODB_*` variables automatically.
2. Leave `ME_CONFIG_BASICAUTH_PASSWORD=changeme` as-is — the platform replaces any literal
   `changeme` value with a generated random secret on first deploy.

### Restrict access before going live

`ME_CONFIG_BASICAUTH=true` by default, protecting the mongo-express UI itself with the
username/password pair in `.env.example` — separate from, and in addition to, the actual
MongoDB credentials. That's mongo-express's *only* login layer; unlike Adminer or phpMyAdmin it
doesn't ask for fresh database credentials per visit, so anyone who gets past basic auth has
full access to whatever the linked Mongo user can see (`ME_CONFIG_MONGODB_ENABLE_ADMIN=true` by
default — every database, not just one). Don't set `ME_CONFIG_BASICAUTH=false` on a public
domain without another layer in front (e.g. Bzync Cloud's environment-level access control under
Settings → Access).

## Run locally

Without a linked database, `docker run` alone won't work — the image's baked-in default
(`ME_CONFIG_MONGODB_URL=mongodb://mongo:27017`) expects a container literally named `mongo` on
the same Docker network:

```bash
docker network create mongo-express-dev
docker run -d --name mongo --network mongo-express-dev mongo:7
docker build -t bzync-mongo-express-dev .
docker run -d --name mongo-express-dev --network mongo-express-dev \
  -p 8081:8081 --env-file .env.example bzync-mongo-express-dev
```

Visit `http://localhost:8081` and log in with `admin` / the password you set for
`ME_CONFIG_BASICAUTH_PASSWORD`.

## How the database connection works

`start.sh` is this image's entrypoint (wrapping the upstream one — see `Dockerfile`). When
`DB_HOST` is set (pointing at a `database/mongodb` deployment), it exports
`ME_CONFIG_MONGODB_SERVER`,
`ME_CONFIG_MONGODB_PORT`, `ME_CONFIG_MONGODB_AUTH_DATABASE`, `ME_CONFIG_MONGODB_AUTH_USERNAME`,
and `ME_CONFIG_MONGODB_AUTH_PASSWORD` before handing off to the upstream `docker-entrypoint.sh`.
Without a linked database, none of these are set and the image's own defaults apply — pointing
at a `mongo` host that doesn't exist unless you provide one, same as `docker-compose`-based
mongo-express setups typically do.
