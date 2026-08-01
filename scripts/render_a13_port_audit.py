#!/usr/bin/env python3
"""Render compact Markdown from the A13 three-tree audit JSON files."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


GOOD = {"exact-file", "high-line-coverage", "a13-file-deleted"}
WEAK = {"project-missing", "file-missing", "low-line-coverage"}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def counts(project: dict[str, Any], target: str) -> Counter[str]:
    return Counter(item[target]["classification"] for item in project.get("files", []))


def needs_review(project: dict[str, Any]) -> bool:
    return any(
        item["aosp16"]["classification"] in WEAK
        and item["android16"]["classification"] in WEAK
        for item in project.get("files", [])
    )


def short_counts(values: Counter[str]) -> str:
    labels = (
        ("exact-file", "E"),
        ("high-line-coverage", "H"),
        ("partial-line-coverage", "P"),
        ("low-line-coverage", "L"),
        ("file-missing", "M"),
        ("project-missing", "PM"),
        ("deletion-or-metadata-review", "D"),
        ("a13-file-deleted", "AD"),
    )
    return " ".join(f"{label}:{values[key]}" for key, label in labels if values[key]) or "-"


def root_groups(payload: dict[str, Any]) -> list[tuple[str, int, int, int]]:
    groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for item in payload["root_payload"]["files"]:
        parts = item["path"].split("/")
        group = "/".join(parts[:3]) if len(parts) >= 3 else item["path"]
        groups[group].append(item)
    result = []
    for group, items in groups.items():
        aosp_missing = sum(item["aosp16"]["classification"] == "file-missing" for item in items)
        android_missing = sum(item["android16"]["classification"] == "file-missing" for item in items)
        result.append((group, len(items), aosp_missing, android_missing))
    return sorted(result, key=lambda item: (-item[1], item[0]))


def render(submodules: dict[str, Any], root: dict[str, Any]) -> str:
    summary = submodules["summary"]
    lines = [
        "# A13 Port Coverage Matrix",
        "",
        "> Generated evidence. Classification is a triage signal, not a port decision.",
        "",
        "## Scope",
        "",
        f"- A13 projects: **{summary['a13_projects']}**",
        f"- Projects with a final custom delta: **{summary['changed_projects']}**",
        f"- Files in those deltas: **{summary['changed_files']}**",
        f"- Baseline-boundary projects: **{summary['projects_with_errors']}**",
        f"- Root non-gitlink files: **{root['root_payload']['tracked_non_gitlink_files']}**",
        "",
        "Legend: `E` exact, `H` high line coverage, `P` partial, `L` low, `M` file missing,",
        "`PM` project missing, `D` deletion/metadata review, `AD` deleted in final A13.",
        "",
        "## Projects Requiring Semantic Review",
        "",
        "| Project | Commits | Files | AOSP16 | Android-16 |",
        "|---|---:|---:|---|---|",
    ]
    for project in submodules["projects"]:
        files = project.get("files", [])
        if not files:
            continue
        aosp = counts(project, "aosp16")
        android = counts(project, "android16")
        if not needs_review(project):
            continue
        lines.append(
            f"| `{project['path']}` | {project.get('custom_commit_count', 0)} | "
            f"{len(files)} | {short_counts(aosp)} | {short_counts(android)} |"
        )
    lines.extend(
        [
            "",
            "## Covered Custom Projects",
            "",
            "These projects have a final custom delta but no file classified weak in both targets.",
            "",
            "| Project | Commits | Files | AOSP16 | Android-16 |",
            "|---|---:|---:|---|---|",
        ]
    )
    for project in submodules["projects"]:
        files = project.get("files", [])
        if not files:
            continue
        aosp = counts(project, "aosp16")
        android = counts(project, "android16")
        if needs_review(project):
            continue
        lines.append(
            f"| `{project['path']}` | {project.get('custom_commit_count', 0)} | "
            f"{len(files)} | {short_counts(aosp)} | {short_counts(android)} |"
        )
    lines.extend(
        [
            "",
            "## Baseline Boundaries",
            "",
            "These projects have no usable `android-13.0.0_r49` or fallback A13 tag.",
            "They require direct tree/provenance review and are not counted as omissions.",
            "",
            "| Project | A13 HEAD | Error |",
            "|---|---|---|",
        ]
    )
    for project in submodules["projects"]:
        if project.get("errors"):
            lines.append(
                f"| `{project['path']}` | `{project.get('a13_head', '-')}` | "
                f"{', '.join(project['errors'])} |"
            )
    lines.extend(
        [
            "",
            "## Root Payload Groups",
            "",
            "| Path group | Files | Missing AOSP16 | Missing Android-16 |",
            "|---|---:|---:|---:|",
        ]
    )
    for group, total, aosp_missing, android_missing in root_groups(root):
        lines.append(f"| `{group}` | {total} | {aosp_missing} | {android_missing} |")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--submodules", type=Path, required=True)
    parser.add_argument("--root-payload", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        render(load(args.submodules), load(args.root_payload)),
        encoding="utf-8",
        newline="\n",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
