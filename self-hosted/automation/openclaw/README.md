# OpenClaw

A production-shaped, self-hosted OpenClaw gateway (agentic automation) — clone, push, and Bzync
Cloud builds this `Dockerfile` as-is, same as any other template. Unlike `data-stores/*`, there's
no managed Bzync equivalent to fall back on: this deployment **is** your OpenClaw gateway, and its
`/home/node/.openclaw` and `/home/node/.config/openclaw` volumes hold real, non-reproducible data
(agent workspace files and gateway/model-provider configuration).

**Default port:** `18789`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Leave `OPENCLAW_GATEWAY_TOKEN=changeme` as-is — the platform replaces any literal `changeme`
   value with a generated random secret on first deploy. This token is the gateway's only login
   credential (no separate admin account) — find it in the dashboard's Variables tab after deploy.
2. The container starts with `--allow-unconfigured` and no TTY (`OPENCLAW_SKIP_ONBOARDING=1`), so
   configure your model provider from the gateway's web UI at your app's URL after first boot,
   rather than through OpenClaw's normal interactive onboarding.
3. `OPENCLAW_SANDBOX=1` is on by default — recommended, since it sandboxes commands the agent
   runs. Only disable it if you understand the exposure.

### Deploy strategy: Standard only

Set this project's deploy strategy under Project → Settings → Deploy Strategy, and leave it on
**Standard**. Unlike most other templates in this catalog, OpenClaw has no database to link and no
option to externalize its state — the agent workspace and gateway config under
`/home/node/.openclaw` and `/home/node/.config/openclaw` only ever exist as local files on one
instance. **Blue-Green and Rolling** briefly run a new instance alongside the old one against those
same volumes, which two independent gateway processes reading/writing the same workspace files were
never designed for — expect corrupted or inconsistent agent state, not a clean failure. **Do not
scale replicas or use multi-node HA** for the same reason: there is no way to run more than one
OpenClaw instance against the same state today.

## Run locally

```bash
docker build -t bzync-openclaw-dev .
docker run -d --name openclaw-dev -p 18789:18789 --env-file .env.example bzync-openclaw-dev
```

Visit `http://localhost:18789` and configure your model provider from the gateway's web UI.

## Backups

Everything that matters lives under `/home/node/.openclaw` (agent workspace) and
`/home/node/.config/openclaw` (gateway/model-provider config). Losing either volume loses the
instance's state — there's no export/dump command of OpenClaw's own to rely on instead.
