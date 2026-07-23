#!/usr/bin/env python3
"""Aggregate every template's .bzync-template.json into catalog.json.

This is the file a marketplace UI should read — never the directory tree
directly. See TEMPLATE-CATALOG-ARCHITECTURE.md §6: decoupling the
marketplace-facing taxonomy from the physical path is what lets future
catalog reorganizations happen without breaking anything downstream.

Fails loudly (non-zero exit) if:
  - a BZYNC_CLOUD directory has no .bzync-template.json (run
    scaffold-template-metadata.py first)
  - two templates claim the same "id"
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    entries = []
    ids_seen = {}
    missing_metadata = []

    for bzync_cloud in sorted(ROOT.rglob("BZYNC_CLOUD")):
        template_dir = bzync_cloud.parent
        metadata_path = template_dir / ".bzync-template.json"
        if not metadata_path.exists():
            missing_metadata.append(str(template_dir.relative_to(ROOT)))
            continue

        metadata = json.loads(metadata_path.read_text())
        rel_path = str(template_dir.relative_to(ROOT))
        metadata["path"] = rel_path

        template_id = metadata.get("id")
        if template_id in ids_seen:
            print(
                f"ERROR: duplicate id '{template_id}' at {rel_path} "
                f"and {ids_seen[template_id]}",
                file=sys.stderr,
            )
            return 1
        ids_seen[template_id] = rel_path
        entries.append(metadata)

    if missing_metadata:
        print("ERROR: missing .bzync-template.json for:", file=sys.stderr)
        for path in missing_metadata:
            print(f"  {path}", file=sys.stderr)
        print(
            "Run scripts/scaffold-template-metadata.py to generate one.",
            file=sys.stderr,
        )
        return 1

    entries.sort(key=lambda e: e["id"])
    catalog = {"templates": entries}

    out_path = ROOT / "catalog.json"
    out_path.write_text(json.dumps(catalog, indent=2) + "\n")
    print(f"wrote {out_path.relative_to(ROOT)} ({len(entries)} templates)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
