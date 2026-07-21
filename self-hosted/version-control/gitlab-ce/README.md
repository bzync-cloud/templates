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
**Default port:** `80` (HTTP only — see "About SSH and HTTPS" below)

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

### About SSH and HTTPS

The image only exposes port `80`. Bzync Cloud's ingress and health checks target the
lowest-numbered `EXPOSE`d port in the built image, and the upstream `gitlab-ce` image bakes in
ports `22`, `80`, and `443` — since `22` is lowest, leaving all three would silently route HTTP
traffic to the SSH port instead of the web server. This Dockerfile rebuilds from `scratch` on top
of the upstream filesystem specifically to drop `22` and `443` (see the comment in `Dockerfile`).
`443` is dropped for a second reason too: there's no TLS certificate configured inside the
container in this deployment shape, so nothing would answer on it anyway — terminate TLS at
whatever sits in front of this (the platform's own edge, once a domain is attached).
Git-over-SSH still runs inside the container, just not reachable through Bzync Cloud's
HTTP(S)-only ingress — clone over HTTPS instead:

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
