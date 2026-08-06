#!/usr/bin/env python3
"""Merge deterministic A13 audit batches and verify complete project coverage."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from typing import Any


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def summarize(projects: list[dict[str, Any]]) -> dict[str, Any]:
    changed = [project for project in projects if project.get("changed_file_count")]
    aosp16: Counter[str] = Counter()
    android16: Counter[str] = Counter()
    missing_both = 0
    weak = {"project-missing", "file-missing", "low-line-coverage"}
    for project in changed:
        for item in project.get("files", []):
            aosp_class = item["aosp16"]["classification"]
            android_class = item["android16"]["classification"]
            aosp16[aosp_class] += 1
            android16[android_class] += 1
            if aosp_class in weak and android_class in weak:
                missing_both += 1
    return {
        "a13_projects": len(projects),
        "projects_with_errors": sum(bool(project.get("errors")) for project in projects),
        "changed_projects": len(changed),
        "changed_files": sum(project.get("changed_file_count", 0) for project in changed),
        "aosp16_classifications": dict(sorted(aosp16.items())),
        "android16_classifications": dict(sorted(android16.items())),
        "low_or_missing_in_both": missing_both,
        "a13_head_root_gitlink_mismatches": sum(
            project.get("a13_head_matches_root_gitlink") is False for project in projects
        ),
        "a13_unexpected_branches": sum(
            project.get("a13_branch") != "bst-v5.22.210" for project in projects
        ),
        "non_merge_commits": sum(project.get("non_merge_commit_count", 0) for project in projects),
        "merge_commits": sum(project.get("merge_commit_count", 0) for project in projects),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch", action="append", type=Path, required=True)
    parser.add_argument("--root-payload", type=Path, required=True)
    parser.add_argument("--expected-projects", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    batches = [json.loads(path.read_text(encoding="utf-8")) for path in args.batch]
    if not batches:
        parser.error("at least one batch is required")
    identities = batches[0]["identities"]
    schema_version = batches[0]["schema_version"]
    requested_base_tag = batches[0]["requested_base_tag"]
    projects: list[dict[str, Any]] = []
    provenance: list[dict[str, Any]] = []
    for path, batch in zip(args.batch, batches):
        if batch["identities"] != identities:
            raise RuntimeError(f"tree identity mismatch in {path}")
        if batch["schema_version"] != schema_version:
            raise RuntimeError(f"schema mismatch in {path}")
        if batch["requested_base_tag"] != requested_base_tag:
            raise RuntimeError(f"base tag mismatch in {path}")
        projects.extend(batch["projects"])
        provenance.append(
            {"path": path.as_posix(), "sha256": sha256(path), "projects": len(batch["projects"])}
        )

    paths = [project["path"] for project in projects]
    duplicates = sorted(path for path, count in Counter(paths).items() if count != 1)
    if duplicates:
        raise RuntimeError(f"duplicate project paths: {', '.join(duplicates)}")
    if len(projects) != args.expected_projects:
        raise RuntimeError(
            f"expected {args.expected_projects} projects, found {len(projects)}"
        )

    root_payload_document = json.loads(args.root_payload.read_text(encoding="utf-8"))
    if root_payload_document["identities"] != identities:
        raise RuntimeError("root payload tree identity mismatch")
    payload = {
        "schema_version": schema_version,
        "mode": "a13-port-coverage",
        "scope": "all",
        "identities": identities,
        "requested_base_tag": requested_base_tag,
        "batch_provenance": provenance,
        "summary": summarize(projects),
        "projects": sorted(projects, key=lambda project: project["path"]),
        "root_payload": root_payload_document["root_payload"],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(json.dumps(payload["summary"], ensure_ascii=False, indent=2))
    print(f"output_sha256={sha256(args.output)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
