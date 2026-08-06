#!/usr/bin/env python3
"""Validate commit-free A13-to-Android-16 target-state equivalence."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def resolve_repository(root: Path, project: str) -> tuple[Path | None, str | None]:
    candidate = root / project
    if (candidate / ".git").exists():
        return candidate, None
    indexed = git(root, "ls-files", "--stage", "--", project)
    if indexed.returncode:
        return None, "target-index-query-failed"
    for line in indexed.stdout.splitlines():
        metadata, indexed_path = line.split("\t", 1)
        if indexed_path == project and metadata.startswith("160000 "):
            return None, "target-project-uninitialized"
    return None, "target-project-missing"


def check_paths(check: dict[str, Any], entry: dict[str, Any]) -> list[str]:
    paths = check.get("paths")
    if check.get("paths_from_source_entry"):
        paths = entry.get("files", [])
    if not isinstance(paths, list) or not paths or not all(
        isinstance(path, str) and path for path in paths
    ):
        raise ValueError("check has no valid paths")
    return paths


def run_check(repo: Path, entry: dict[str, Any], check: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    check_type = check.get("type")
    if check_type in {"files-exist", "files-absent", "gitlinks-absent", "lfs-paths"}:
        paths = check_paths(check, entry)
    else:
        paths = []

    if check_type == "files-exist":
        for path in paths:
            if not (repo / path).is_file() or git(repo, "ls-files", "--error-unmatch", "--", path).returncode:
                errors.append(f"required-file-missing:{path}")
    elif check_type == "files-absent":
        for path in paths:
            if (repo / path).exists() or not git(repo, "ls-files", "--error-unmatch", "--", path).returncode:
                errors.append(f"forbidden-file-present:{path}")
    elif check_type == "gitlinks-absent":
        for path in paths:
            indexed = git(repo, "ls-files", "--stage", "--", path)
            if indexed.returncode:
                errors.append(f"gitlink-query-failed:{path}")
            elif any(line.startswith("160000 ") for line in indexed.stdout.splitlines()):
                errors.append(f"forbidden-gitlink-present:{path}")
    elif check_type == "gitmodule-path-absent":
        module_paths = check_paths(check, entry)
        gitmodules = repo / ".gitmodules"
        if gitmodules.exists():
            configured = git(
                repo,
                "config",
                "-f",
                ".gitmodules",
                "--get-regexp",
                r"^submodule\..*\.path$",
            )
            if configured.returncode not in {0, 1}:
                errors.append("gitmodules-query-failed")
            values = {
                line.split(maxsplit=1)[1]
                for line in configured.stdout.splitlines()
                if len(line.split(maxsplit=1)) == 2
            }
            for path in module_paths:
                if path in values:
                    errors.append(f"forbidden-gitmodule-path:{path}")
    elif check_type == "lfs-paths":
        lfs = git(repo, "lfs", "ls-files", "--name-only")
        if lfs.returncode:
            errors.append("git-lfs-query-failed")
            lfs_paths: set[str] = set()
        else:
            lfs_paths = set(lfs.stdout.splitlines())
        for path in paths:
            attribute = git(repo, "check-attr", "filter", "--", path)
            if attribute.returncode or not attribute.stdout.rstrip().endswith("filter: lfs"):
                errors.append(f"lfs-filter-missing:{path}")
            if path not in lfs_paths:
                errors.append(f"lfs-object-missing:{path}")
    elif check_type == "file-sha256":
        path = check.get("path")
        expected = check.get("sha256")
        if not isinstance(path, str) or not path:
            raise ValueError("file-sha256 check has no path")
        if not isinstance(expected, str) or not re.fullmatch(
            r"[0-9a-fA-F]{64}", expected
        ):
            raise ValueError("file-sha256 check has no valid digest")
        source = repo / path
        if not source.is_file() or git(
            repo, "ls-files", "--error-unmatch", "--", path
        ).returncode:
            errors.append(f"sha256-source-missing:{path}")
        else:
            digest = hashlib.sha256()
            with source.open("rb") as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b""):
                    digest.update(block)
            if digest.hexdigest() != expected.lower():
                errors.append(f"sha256-mismatch:{path}")
    elif check_type in {"regex-present", "regex-absent", "regex-ordered"}:
        path = check.get("path")
        patterns = check.get("patterns")
        if not isinstance(path, str) or not path or not isinstance(patterns, list) or not patterns:
            raise ValueError("regex check is incomplete")
        source = repo / path
        if not source.is_file():
            return [f"regex-source-missing:{path}"]
        text = source.read_text(encoding="utf-8", errors="replace")
        if check_type == "regex-ordered":
            offset = 0
            for pattern in patterns:
                match = re.search(pattern, text[offset:])
                if match is None:
                    errors.append(f"ordered-pattern-missing:{path}:{pattern}")
                    break
                offset += match.end()
        else:
            for pattern in patterns:
                found = re.search(pattern, text) is not None
                if check_type == "regex-present" and not found:
                    errors.append(f"required-pattern-missing:{path}:{pattern}")
                if check_type == "regex-absent" and found:
                    errors.append(f"forbidden-pattern-present:{path}:{pattern}")
    else:
        errors.append(f"unsupported-check-type:{check_type}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--android16-root", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    root = args.android16_root.resolve()
    if "aosp16" in str(root) or root.name != "android-16":
        raise SystemExit(f"expected Android-16 target root, got {root}")
    discovered = git(root, "rev-parse", "--show-toplevel")
    if discovered.returncode or Path(discovered.stdout.strip()).resolve() != root:
        raise SystemExit(f"not an Android root Git checkout: {root}")

    ledger = json.loads(args.ledger.read_text(encoding="utf-8"))
    entries = [
        entry
        for entry in ledger.get("entries", [])
        if entry.get("review_status") == "reviewed-equivalent"
    ]
    results: list[dict[str, Any]] = []
    repositories: dict[str, tuple[Path | None, str | None]] = {}
    check_count = 0
    for entry in entries:
        state = entry.get("target_state", {})
        project = state.get("project", "")
        if project not in repositories:
            repositories[project] = resolve_repository(root, project)
        repo, repository_error = repositories[project]
        result = {
            "source_project": entry["project"],
            "source_commit": entry.get("source_commit"),
            "target_project": project,
            "assertion": state.get("assertion"),
            "errors": [],
        }
        if repository_error:
            result["errors"].append(repository_error)
        elif repo is not None:
            for check in state.get("checks", []):
                check_count += 1
                try:
                    result["errors"].extend(run_check(repo, entry, check))
                except (KeyError, TypeError, ValueError, re.error) as exc:
                    result["errors"].append(f"invalid-check:{exc}")
        results.append(result)

    error_count = sum(bool(result["errors"]) for result in results)
    output = {
        "schema_version": 1,
        "mode": "a13-target-state-validation",
        "android16_root": str(root),
        "android16_root_branch": git(root, "branch", "--show-current").stdout.strip(),
        "android16_root_head": git(root, "rev-parse", "HEAD").stdout.strip(),
        "counts": {
            "equivalent_entries": len(entries),
            "checks": check_count,
            "repositories": len(repositories),
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
    for result in results:
        if result["errors"]:
            print(
                f"{result['source_project']} {result['source_commit']}: "
                + ",".join(result["errors"])
            )
    return 1 if error_count else 0


if __name__ == "__main__":
    raise SystemExit(main())
