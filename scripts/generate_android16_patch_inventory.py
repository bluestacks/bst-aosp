#!/usr/bin/env python3
"""Generate a reproducible inventory for the archived Android 16 patch set."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANDROID16_ROOT = ROOT / "patches" / "android-16"
PATCH_ROOT = ANDROID16_ROOT / "patches"
REGISTRY_PATH = ROOT / "patches" / "registry.json"
OUTPUT_DIR = ROOT / "docs" / "android-16-patch-review"
INVENTORY_JSON = OUTPUT_DIR / "patch-inventory.json"
INVENTORY_MD = OUTPUT_DIR / "patch-inventory.md"

PATCH_SUFFIXES = {".patch", ".diff"}


def normalize_patch_path(raw: str) -> str:
    path = raw.split("\t", 1)[0].strip()
    if path.startswith(("a/", "b/")):
        path = path[2:]
    return path


def classify(path: Path) -> str:
    rel = path.relative_to(ANDROID16_ROOT).as_posix()
    name = path.name
    if rel.startswith("untracked-src/"):
        return "Patch-equivalent untracked payloads"
    if rel.startswith("patches/p2-bionic-art/"):
        return "P2 bionic/art source overlays"
    if rel.startswith("patches/p2-external/"):
        return "P2 external source overlays"
    if rel.startswith("patches/p2-framework-rest/"):
        if name.startswith("P2-FW-CORE-APP-"):
            return "P2 framework core/app surgical patches"
        if name.startswith("P2-FW-SERVICES-"):
            return "P2 framework services surgical patches"
        if name.startswith("P2-FW-PERIPH-"):
            return "P2 framework peripheral surgical patches"
        if name.startswith("P2-FW-WM-"):
            return "P2 framework WM surgical patches"
        if name.startswith("P2-MECH-"):
            return "P2 cross-project mechanical patches"
        return "P2 aggregate/candidate snapshots"
    if name.startswith("aosp16__"):
        return "AOSP16 project snapshots"
    return "Host/build/graphics companion patches"


def parse_patch(path: Path) -> dict:
    data = path.read_bytes()
    text = data.decode("utf-8", errors="replace")
    lines = text.splitlines()
    files: list[str] = []
    additions = 0
    deletions = 0
    hunks = 0
    embedded_binary = False
    binary_reference = False

    for line in lines:
        if line.startswith("diff --git "):
            match = re.match(r"diff --git a/(.*?) b/(.*)", line)
            if match:
                files.append(normalize_patch_path(match.group(2)))
        elif line.startswith("+++ ") and not files:
            candidate = normalize_patch_path(line[4:])
            if candidate != "/dev/null":
                files.append(candidate)

        if line.startswith("@@ "):
            hunks += 1
        elif line.startswith("+") and not line.startswith("+++"):
            additions += 1
        elif line.startswith("-") and not line.startswith("---"):
            deletions += 1

        if line.startswith("GIT binary patch"):
            embedded_binary = True
        elif line.startswith("Binary files "):
            binary_reference = True

    files = sorted(set(files))
    rel = path.relative_to(ROOT).as_posix()
    return {
        "artifact": rel,
        "name": path.name,
        "category": classify(path),
        "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data),
        "lines": len(lines),
        "files_changed": len(files),
        "hunks": hunks,
        "additions": additions,
        "deletions": deletions,
        "contains_binary_patch": embedded_binary,
        "references_binary_difference": binary_reference,
        "files": files,
    }


def load_registry() -> list[dict]:
    payload = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    return payload.get("patches", [])


def registry_matches(item: dict, artifact: dict) -> bool:
    references = " ".join(
        str(item.get(key) or "")
        for key in ("boot_artifact", "checkpoint_ref", "verification", "notes")
    )
    rel = artifact["artifact"]
    name = artifact["name"]
    return rel in references or name in references


def overlap_key(file_path: str) -> str:
    parts = file_path.split("/")
    if len(parts) >= 3 and parts[0] in {
        "core",
        "services",
        "packages",
        "telephony",
        "libs",
        "cmds",
    }:
        return "/".join(parts[:3])
    return file_path


def enrich(artifacts: list[dict], registry: list[dict]) -> None:
    file_to_artifacts: dict[str, list[str]] = defaultdict(list)
    for artifact in artifacts:
        for file_path in artifact["files"]:
            file_to_artifacts[file_path].append(artifact["artifact"])

    for artifact in artifacts:
        matches = [item for item in registry if registry_matches(item, artifact)]
        artifact["registry"] = [
            {
                "id": item.get("id"),
                "project_path": item.get("project_path"),
                "phase": item.get("phase"),
                "related_group": item.get("related_group"),
                "port_status": item.get("port_status"),
                "purpose": item.get("purpose"),
                "quality": item.get("quality"),
                "impact": item.get("impact"),
                "verification": item.get("verification"),
                "host_compat": item.get("host_compat"),
                "temp_debt": item.get("temp_debt"),
            }
            for item in matches
        ]
        artifact["overlaps"] = {
            file_path: file_to_artifacts[file_path]
            for file_path in artifact["files"]
            if len(file_to_artifacts[file_path]) > 1
        }
        artifact["overlap_groups"] = sorted(
            {overlap_key(path) for path in artifact["overlaps"]}
        )


def markdown(artifacts: list[dict]) -> str:
    total_bytes = sum(item["bytes"] for item in artifacts)
    categories = Counter(item["category"] for item in artifacts)
    output = [
        "# Android 16 Patch Inventory",
        "",
        "> Generated by `scripts/generate_android16_patch_inventory.py`. "
        "Do not hand-edit this file; review conclusions live in the sibling documents.",
        "",
        "## Summary",
        "",
        f"- Patch artifacts: **{len(artifacts)}**",
        f"- Total size: **{total_bytes / 1024 / 1024:.2f} MiB**",
        f"- Artifacts containing binary patch data: "
        f"**{sum(1 for item in artifacts if item['contains_binary_patch'])}**",
        f"- Payload-free artifacts referencing binary differences: "
        f"**{sum(1 for item in artifacts if item['references_binary_difference'])}**",
        f"- Unique changed paths: "
        f"**{len({path for item in artifacts for path in item['files']})}**",
        "",
        "| Category | Count |",
        "|---|---:|",
    ]
    for category, count in sorted(categories.items()):
        output.append(f"| {category} | {count} |")

    output.extend(
        [
            "",
            "## Artifact Index",
            "",
            "| Artifact | Category | Files | Hunks | + | - | KiB | Binary | Registry |",
            "|---|---|---:|---:|---:|---:|---:|---|---:|",
        ]
    )
    for item in artifacts:
        artifact_link = "../../" + item["artifact"]
        output.append(
            f"| [`{item['name']}`]({artifact_link}) | {item['category']} | "
            f"{item['files_changed']} | {item['hunks']} | {item['additions']} | "
            f"{item['deletions']} | {item['bytes'] / 1024:.1f} | "
            f"{'embedded' if item['contains_binary_patch'] else 'reference-only' if item['references_binary_difference'] else 'no'} | "
            f"{len(item['registry'])} |"
        )

    output.extend(["", "## Per-Artifact Detail", ""])
    for item in artifacts:
        output.extend(
            [
                f"### `{item['name']}`",
                "",
                f"- Artifact: [`{item['artifact']}`](../../{item['artifact']})",
                f"- Category: {item['category']}",
                f"- SHA-256: `{item['sha256']}`",
                f"- Size/stat: {item['bytes']} bytes, {item['files_changed']} files, "
                f"{item['hunks']} hunks, +{item['additions']}/-{item['deletions']}",
                f"- Binary evidence: "
                f"{'embedded payload' if item['contains_binary_patch'] else 'reference only; no payload bytes' if item['references_binary_difference'] else 'none'}",
            ]
        )
        if item["registry"]:
            output.append("- Registry mapping:")
            for record in item["registry"]:
                output.append(
                    f"  - `{record['id']}`: status=`{record['port_status']}`, "
                    f"phase=`{record['phase']}`, project=`{record['project_path']}`"
                )
        else:
            output.append("- Registry mapping: none; classify from progress records before replay")

        if item["overlaps"]:
            output.append(
                f"- Overlap: **yes**, {len(item['overlaps'])} changed paths also occur "
                "in other archived artifacts. See `patch-inventory.json` for exact edges."
            )
        else:
            output.append("- Overlap: none detected by changed path")

        output.append("- Changed paths:")
        if item["files"]:
            for file_path in item["files"]:
                output.append(f"  - `{file_path}`")
        else:
            output.append("  - Parser found no canonical `diff --git` path; inspect raw artifact")
        output.append("")

    return "\n".join(output).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    artifacts = [
        parse_patch(path)
        for path in sorted(ANDROID16_ROOT.rglob("*"))
        if path.is_file() and path.suffix.lower() in PATCH_SUFFIXES
    ]
    enrich(artifacts, load_registry())
    rendered_json = (
        json.dumps(
            {
                "schema_version": 1,
                "generated_from": ANDROID16_ROOT.relative_to(ROOT).as_posix(),
                "artifacts": artifacts,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n"
    )
    rendered_markdown = markdown(artifacts)
    if args.check:
        current_json = (
            INVENTORY_JSON.read_text(encoding="utf-8")
            if INVENTORY_JSON.exists()
            else ""
        )
        current_markdown = (
            INVENTORY_MD.read_text(encoding="utf-8")
            if INVENTORY_MD.exists()
            else ""
        )
        if current_json != rendered_json or current_markdown != rendered_markdown:
            print("generated patch inventory is stale")
            return 1
        print(f"patch inventory is current ({len(artifacts)} artifacts)")
        return 0
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    INVENTORY_JSON.write_text(rendered_json, encoding="utf-8", newline="\n")
    INVENTORY_MD.write_text(rendered_markdown, encoding="utf-8", newline="\n")
    print(f"generated {len(artifacts)} artifacts")
    print(INVENTORY_JSON)
    print(INVENTORY_MD)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
