#!/usr/bin/env python3
"""Validate every recorded A13-to-Android-16 target commit against a checkout."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import Any


TARGET_PATH_MAP = {
    "build": "build/make",
    "kernel": "kernel-a16",
}
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def resolve_repository(
    root: Path, target_path: str
) -> tuple[Path | None, str, str | None]:
    candidate = root / target_path
    if (candidate / ".git").exists():
        return candidate, target_path, None

    indexed = git(root, "ls-files", "--stage", "--", target_path)
    if indexed.returncode:
        return None, target_path, "target-index-query-failed"
    entries = [line for line in indexed.stdout.splitlines() if line]
    if not entries:
        return None, target_path, "target-project-missing"
    for entry in entries:
        metadata, indexed_path = entry.split("\t", 1)
        if indexed_path == target_path and metadata.startswith("160000 "):
            return None, target_path, "target-project-uninitialized"
    return root, ".", None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--android16-root", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    root = args.android16_root.resolve()
    discovered_root = Path(
        git(root, "rev-parse", "--show-toplevel").stdout.strip()
    ).resolve()
    if discovered_root != root:
        raise SystemExit(f"not an Android root Git checkout: {root}")

    ledger = json.loads(args.ledger.read_text(encoding="utf-8"))
    references: dict[tuple[str, str], list[str]] = defaultdict(list)
    for entry in ledger.get("entries", []):
        source = entry.get("source_commit") or entry.get("kind", "unknown")
        for commit in entry.get("target_commits", []):
            references[(entry["project"], commit)].append(source)

    repository_cache: dict[str, tuple[Path | None, str, str | None]] = {}
    results: list[dict[str, Any]] = []
    for (project, commit), sources in sorted(references.items()):
        target_path = TARGET_PATH_MAP.get(project, project)
        if target_path not in repository_cache:
            repository_cache[target_path] = resolve_repository(root, target_path)
        repo, repository_path, repository_error = repository_cache[target_path]
        result: dict[str, Any] = {
            "project": project,
            "target_path": target_path,
            "target_repository": repository_path,
            "commit": commit,
            "source_commits": sorted(set(sources)),
            "errors": [],
        }
        if repository_error:
            result["errors"].append(repository_error)
        elif not SHA_PATTERN.fullmatch(commit):
            result["errors"].append("invalid-target-commit")
        else:
            assert repo is not None
            exists = git(repo, "cat-file", "-e", f"{commit}^{{commit}}")
            if exists.returncode:
                result["errors"].append("target-commit-missing")
            else:
                reachable = git(repo, "merge-base", "--is-ancestor", commit, "HEAD")
                if reachable.returncode:
                    result["errors"].append("target-commit-not-reachable-from-head")
                subject = git(repo, "show", "-s", "--format=%s", commit)
                result["subject"] = subject.stdout.strip()
                if not result["subject"].startswith("[A16] "):
                    result["errors"].append("target-subject-not-a16")
                if repository_path == ".":
                    changed = git(
                        repo,
                        "diff-tree",
                        "--no-commit-id",
                        "--name-only",
                        "-r",
                        commit,
                        "--",
                        target_path,
                    )
                    if not changed.stdout.strip():
                        result["errors"].append(
                            "target-commit-does-not-touch-root-path"
                        )
        results.append(result)

    error_count = sum(bool(item["errors"]) for item in results)
    output = {
        "schema_version": 1,
        "mode": "a13-target-commit-validation",
        "android16_root": str(root),
        "android16_root_head": git(root, "rev-parse", "HEAD").stdout.strip(),
        "counts": {
            "ledger_references": sum(len(values) for values in references.values()),
            "unique_project_commits": len(results),
            "repositories": len(repository_cache),
            "errors": error_count,
        },
        "results": results,
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(output, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )
    print(json.dumps(output["counts"], indent=2))
    if error_count:
        for item in results:
            if item["errors"]:
                print(
                    f"{item['project']} {item['commit']}: "
                    + ",".join(item["errors"])
                )
    return 1 if error_count else 0


if __name__ == "__main__":
    raise SystemExit(main())
