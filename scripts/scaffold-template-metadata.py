#!/usr/bin/env python3
"""Scaffold a .bzync-template.json for any template directory missing one.

A "template" is any directory containing a BZYNC_CLOUD file. This walks the
whole catalog (or a single path passed as argv[1]) and writes a starting
metadata file wherever one doesn't already exist — safe to re-run, it never
overwrites a .bzync-template.json that's already there (hand edits, once
made, stick).

See TEMPLATE-CATALOG-ARCHITECTURE.md §6 for why this file exists: it lets
the marketplace-facing category/tags/displayName live independently of
wherever a template physically sits in the tree, so future reorganizations
don't require touching this data at all.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Known-good display names where naive title-casing of the slug gets it
# wrong (product branding, acronyms, punctuation). Anything not listed here
# falls back to a generic title-case-the-words heuristic.
DISPLAY_NAMES = {
    "go": "Go", "node": "Node.js", "python": "Python", "php": "PHP",
    "ruby": "Ruby", "rust": "Rust", "java": "Java", "kotlin": "Kotlin",
    "dotnet": ".NET", "bun": "Bun", "deno": "Deno",
    "nextjs": "Next.js", "nuxt": "Nuxt", "sveltekit": "SvelteKit",
    "nestjs": "NestJS", "adonisjs": "AdonisJS", "medusajs": "Medusa",
    "bullmq-worker": "BullMQ Worker", "hono": "Hono",
    "fastapi": "FastAPI", "celery-worker": "Celery Worker",
    "cakephp": "CakePHP", "codeigniter": "CodeIgniter",
    "aspnetcore": "ASP.NET Core", "mvc": "ASP.NET MVC",
    "actix-web": "Actix Web", "vanilla-ts": "Vanilla (TypeScript)",
    "react-ts": "React (TypeScript)", "vue-ts": "Vue (TypeScript)",
    "svelte-ts": "Svelte (TypeScript)", "preact-ts": "Preact (TypeScript)",
    "solid-ts": "Solid (TypeScript)", "lit-ts": "Lit (TypeScript)",
    "qwik-ts": "Qwik (TypeScript)", "mkdocs": "MkDocs",
    "nextjs-go": "Next.js + Go", "nextjs-fastapi": "Next.js + FastAPI",
    "nextjs-laravel": "Next.js + Laravel", "django-react": "Django + React",
    "fastapi-react": "FastAPI + React",
    "sveltekit-fastapi": "SvelteKit + FastAPI",
    "vite-react-fastapi": "React (Vite) + FastAPI",
    "vite-react-laravel": "React (Vite) + Laravel",
    "rails-react": "Rails + React", "astro-strapi": "Astro + Strapi",
    "laravel-inertia-react": "Laravel + Inertia (React)",
    "laravel-inertia-vue": "Laravel + Inertia (Vue)",
    "laravel-inertia-svelte": "Laravel + Inertia (Svelte)",
    "postgres": "PostgreSQL", "mysql": "MySQL", "mariadb": "MariaDB",
    "mongodb": "MongoDB", "couchbase": "Couchbase", "redis": "Redis",
    "valkey": "Valkey", "keydb": "KeyDB",
    "wordpress": "WordPress", "drupal": "Drupal", "joomla": "Joomla",
    "october-cms": "OctoberCMS", "statamic": "Statamic", "strapi": "Strapi",
    "directus": "Directus", "keystone": "Keystone", "magento": "Magento",
    "adminer": "Adminer", "phpmyadmin": "phpMyAdmin",
    "mongo-express": "Mongo Express", "pgadmin": "pgAdmin",
    "vikunja": "Vikunja", "focalboard": "Focalboard", "leantime": "Leantime",
    "plane": "Plane", "gitea": "Gitea", "forgejo": "Forgejo",
    "gitlab-ce": "GitLab CE", "cogs": "Gogs", "n8n": "n8n",
    "openclaw": "OpenClaw", "spring-boot": "Spring Boot", "ktor": "Ktor",
    "docusaurus": "Docusaurus",
}

CATEGORY_DESCRIPTIONS = {
    "languages": "starter template",
    "frontend": "static-output starter template",
    "full-stack": "multi-service starter template",
    "background-jobs": "background job template",
    "data-stores": "data store",
    "self-hosted": "self-hosted application",
}


def display_name(slug: str) -> str:
    if slug in DISPLAY_NAMES:
        return DISPLAY_NAMES[slug]
    return " ".join(w.capitalize() for w in re.split(r"[-_]", slug))


def parse_bzync_cloud(path: Path) -> dict:
    fields = {}
    text = path.read_text(errors="replace")
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("["):
            continue
        if "=" in line:
            key, _, value = line.partition("=")
            fields[key.strip()] = value.strip()
    return fields


def classify(rel_parts: list[str]) -> tuple[str, str | None, str]:
    """Return (category, subcategory, leaf_name) from path segments under templates/."""
    category = rel_parts[0]
    if category == "languages":
        # languages/<lang>/<leaf>
        return category, rel_parts[1], rel_parts[-1]
    if category in ("frontend", "full-stack"):
        # flat: frontend/<leaf>, full-stack/<leaf>
        return category, None, rel_parts[-1]
    if category == "background-jobs":
        # background-jobs/<trigger>/<runtime> -- the runtime IS the leaf
        trigger = rel_parts[1]
        runtime = rel_parts[2]
        return category, trigger, runtime
    if category == "data-stores":
        # data-stores/<subcat>/<engine>
        return category, rel_parts[1], rel_parts[-1]
    if category == "self-hosted":
        # self-hosted/<subcat>/<app>
        return category, rel_parts[1], rel_parts[-1]
    return category, None, rel_parts[-1]


def build_metadata(template_dir: Path) -> dict:
    rel = template_dir.relative_to(ROOT)
    rel_parts = rel.parts
    category, subcategory, leaf = classify(list(rel_parts))

    if category == "background-jobs":
        lang_name = display_name(leaf)
        trigger_label = "Worker" if subcategory == "worker" else "Cron Job"
        name = f"{lang_name} {trigger_label}"
    else:
        name = display_name(leaf)

    bzync_cloud = template_dir / "BZYNC_CLOUD"
    fields = parse_bzync_cloud(bzync_cloud) if bzync_cloud.exists() else {}
    runtime = fields.get("runtime", "")
    framework = fields.get("framework", "")

    tags = sorted({t for t in (runtime, framework, category, subcategory or "", leaf) if t})
    if leaf.endswith("-ts"):
        tags.append("typescript")

    template_id = "-".join(rel_parts)
    kind = CATEGORY_DESCRIPTIONS.get(category, "template")
    description = f"{name} {kind} for Bzync Cloud."

    metadata = {
        "id": template_id,
        "displayName": name,
        "category": category,
        "subcategory": subcategory,
        "tags": tags,
        "description": description,
    }
    return metadata


def main() -> None:
    if len(sys.argv) > 1:
        targets = [Path(sys.argv[1]).resolve()]
    else:
        targets = [ROOT]

    written, skipped = 0, 0
    for target in targets:
        for bzync_cloud in sorted(target.rglob("BZYNC_CLOUD")):
            template_dir = bzync_cloud.parent
            metadata_path = template_dir / ".bzync-template.json"
            if metadata_path.exists():
                skipped += 1
                continue
            metadata = build_metadata(template_dir)
            metadata_path.write_text(json.dumps(metadata, indent=2) + "\n")
            written += 1
            print(f"wrote {metadata_path.relative_to(ROOT)}")

    print(f"\n{written} written, {skipped} already had metadata.")


if __name__ == "__main__":
    main()
