# GitLab CE

A production-shaped, self-hosted GitLab Community Edition instance — clone, push, and Bzync
Cloud builds this `Dockerfile` as-is, same as any other template. This is the heaviest template
in this repo by far: the official `gitlab-ce` image is an all-in-one "omnibus" package that
bundles its own Postgres, Redis, Puma, Sidekiq, Gitaly, and about a dozen other supervised
services inside one container. Unlike `database/*`, there is no managed Bzync equivalent to fall
back on — this deployment **is** your GitLab instance, and `/etc/gitlab`, `/var/opt/gitlab`, and
`/var/log/gitlab` hold real, non-reproducible data.

**Supported versions:** `17.5.2-ce.0` (default) — set `GITLAB_VERSION` as a build arg for
others; GitLab CE tags follow `<version>-ce.0`
**Default port:** `80` (HTTP — see "About SSH and HTTPS" below for git-over-SSH)

## Before you deploy this: resource requirements

GitLab's own docs put the floor at **4 vCPU / 4 GB RAM** for a reference-architecture instance,
and in practice omnibus will crash-loop through its first-boot `reconfigure` on anything smaller
— Puma and Sidekiq workers get OOM-killed mid-migration, reconfigure re-runs from the top, repeat.
If the environment this deploys into can't offer that, expect either a very long first boot or a
container stuck restarting. `GITLAB_OMNIBUS_CONFIG` (below) can trim some of this — disabling
Prometheus/Grafana monitoring and the container registry saves real memory — but there's a floor
under an all-in-one GitLab that no config trims away. Gitea, Forgejo, or Gogs in this same
`version-control/` directory are the right choice if you don't specifically need GitLab CE's
feature set (built-in CI/CD, container registry, more mature RBAC) and want something that boots
in seconds on modest hardware instead of minutes on a lot of it.

**First boot is slow.** Even on adequate hardware, expect **2–5 minutes** before `/-/health`
answers — omnibus is running database migrations, compiling assets, and starting every bundled
service in sequence. The `HEALTHCHECK` in `Dockerfile` uses a 600s `start-period` to match; if
you're watching a deploy in the dashboard and it looks stuck at "starting," that's normal, not a
hang. Give it the full window before assuming something's wrong.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live, set
`GITLAB_OMNIBUS_CONFIG` in the dashboard (see `.env.example`) — at minimum an `external_url` so
GitLab generates correct clone URLs and links:

```
GITLAB_OMNIBUS_CONFIG=external_url 'https://your-domain.example.com';
```

It's not baked into the `Dockerfile` itself: `GITLAB_OMNIBUS_CONFIG` is a semicolon-separated
Ruby snippet, and a multi-statement quoted string doesn't survive Dockerfile `ENV` escaping
reliably — set it at deploy time (dashboard or `.env`) instead.

### Logging in the first time

`GITLAB_ROOT_PASSWORD` is deliberately **not** set anywhere in this template (see the comment in
`Dockerfile` for why "changeme" specifically doesn't work here). Leaving it unset is GitLab's own
documented default: it generates a random 32-character root password on first boot and writes it
to a file inside the container, valid for the first 24 hours:

```bash
docker exec <container> cat /etc/gitlab/initial_root_password
```

Log in as `root` with that password, then either keep it (it's already strong) or change it from
the admin UI. If you'd rather set a specific password up front, add
`gitlab_rails['initial_root_password'] = '...'` to `GITLAB_OMNIBUS_CONFIG` — GitLab's own
password-strength check still applies, so it needs to be genuinely strong, not just 8+ characters.

### Deploy strategy: Standard vs. Blue-Green/Rolling

Set this project's deploy strategy under Project → Settings → Deploy Strategy.

**Standard** works out of the box with no extra configuration — it always destroys the old
container before starting the new one, so only one GitLab instance ever touches `/var/opt/gitlab`
at a time.

**Blue-Green and Rolling** briefly run the new instance alongside the old one against the *same*
`/etc/gitlab`, `/var/opt/gitlab`, and `/var/log/gitlab` volumes — that overlap is the entire point
of both strategies (zero-downtime cutover). Out of the box this fails harder than it does for
Gitea/Forgejo/Gogs: GitLab's bundled Postgres keeps its data directory under `/var/opt/gitlab`,
and Postgres takes an exclusive `postmaster.pid` lock on that directory at startup. The new
instance's bundled Postgres can't acquire it while the old one is still running and crash-loops
through `reconfigure` until the deploy times out and rolls back — you'll see `health check timed
out` in the build log with no other explanation, likely several minutes in given GitLab's already-
slow first boot (see "first boot is slow" above).

Unlike Gitea's queue backend, there's no single `GITLAB_OMNIBUS_CONFIG` line that fixes this:
GitLab's bundled Postgres *and* Redis would both need to move out of the container entirely
(`postgresql['enable'] = false` / `redis['enable'] = false` plus `gitlab_rails['db_host']` /
`gitlab_rails['redis_host']` pointed at instances deployed elsewhere) before two omnibus containers
could safely share a deploy window — a materially bigger reconfiguration than this template ships
with today. Until that's set up, use **Standard** for this template; Blue-Green/Rolling are not
safe here as-is.

### About SSH and HTTPS

The image only exposes port `80`. Bzync Cloud's ingress and health checks target the
lowest-numbered `EXPOSE`d port in the built image, and the upstream `gitlab-ce` image bakes in
ports `22`, `80`, and `443` — since `22` is lowest, leaving all three would silently route HTTP
traffic to the SSH port instead of the web server. This Dockerfile rebuilds from `scratch` on top
of the upstream filesystem specifically to drop `22` and `443` (see the comment in `Dockerfile`).
`443` is dropped for a second reason too: there's no TLS certificate configured inside the
container in this deployment shape, so nothing would answer on it anyway — terminate TLS at
whatever sits in front of this (the platform's own edge, once a domain is attached). None of that
affects the feature below — dropping the image's own `EXPOSE 22`/`443` only affects Traefik's
port autodetection for HTTP, not whether SSH can be reached.

Real `git@host:owner/repo.git` clones need the project's **"Enable Git SSH access"** toggle
(Project → Git SSH in the dashboard — requires a plan with that feature). Enabling it allocates a
dedicated port and binds it straight to the container's built-in `gitlab-shell` SSH daemon,
bypassing the HTTP(S) ingress entirely. Once enabled, the dashboard shows the exact command:

```bash
git clone ssh://git@your-app.app.bzync.cloud:20005/owner/repo.git
```

Also append `gitlab_rails['gitlab_shell_ssh_port'] = 20005;` to `GITLAB_OMNIBUS_CONFIG` (see
`.env.example`) with the same port shown there — without it, GitLab's own generated clone URLs
(shown in its web UI) still advertise the default port `22`, even though the SSH connection
itself works on the allocated port. HTTPS clone always works regardless, with or without this
toggle:

```bash
git clone https://your-domain.example.com/owner/repo.git
```

## Run locally

```bash
docker build -t bzync-gitlab-dev .
docker run -d --name gitlab-dev -p 80:80 \
  -v gitlab-config:/etc/gitlab -v gitlab-data:/var/opt/gitlab -v gitlab-logs:/var/log/gitlab \
  --shm-size 256m \
  bzync-gitlab-dev
```

`--shm-size 256m` isn't optional — GitLab's bundled Postgres and several other services use
shared memory more aggressively than Docker's tiny 64 MB default allows, and boot fails or
degrades without it. Then wait (see "first boot is slow" above), fetch the root password, and
visit `http://localhost/`.

## Backups

```bash
docker exec <container> gitlab-backup create
```

writes a timestamped archive under `/var/opt/gitlab/backups`, covering the database, repos, and
uploads — but **not** `/etc/gitlab/gitlab-secrets.json` or the rest of `/etc/gitlab`, which holds
the encryption keys needed to actually restore that archive. Back up `/etc/gitlab` separately
(it's small); losing it makes the backup archive undecryptable even if the archive itself is
intact.
