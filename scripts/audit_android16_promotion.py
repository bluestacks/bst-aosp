#!/usr/bin/env python3
"""Read-only freeze, submodule, branch, gitlink, and publish audit."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any


BASE_BRANCH = "aosp16-bst"
MERGE_BRANCH = "aosp16-bst-merge"


def run(
    cwd: Path, *args: str, check: bool = False
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [*args],
        cwd=cwd,
        check=check,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def git(cwd: Path, *args: str, check: bool = False) -> str:
    return run(cwd, "git", *args, check=check).stdout.strip()


def patch_identity(path: Path) -> dict[str, Any]:
    diff = subprocess.run(
        ["git", "diff", "--binary", "HEAD", "--"],
        cwd=path,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout
    untracked_raw = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
        cwd=path,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout
    untracked = sorted(
        item.decode("utf-8", "surrogateescape")
        for item in untracked_raw.split(b"\0")
        if item
    )
    digest = hashlib.sha256()
    digest.update(diff)
    for relative in untracked:
        candidate = path / relative
        digest.update(relative.encode("utf-8", "surrogateescape"))
        digest.update(b"\0")
        if candidate.is_file():
            digest.update(hashlib.sha256(candidate.read_bytes()).digest())
        digest.update(b"\0")
    return {
        "patch_identity_sha256": digest.hexdigest(),
        "tracked_diff_bytes": len(diff),
        "untracked_files": untracked,
    }


def submodule_paths(root: Path) -> list[str]:
    modules = root / ".gitmodules"
    if not modules.is_file():
        raise SystemExit(f"missing .gitmodules: {modules}")
    result = git(
        root,
        "config",
        "-f",
        ".gitmodules",
        "--get-regexp",
        r"^submodule\..*\.path$",
        check=True,
    )
    paths = [line.split(None, 1)[1].strip() for line in result.splitlines()]
    return sorted(set(paths))


def repo_state(root: Path, relative: str, check_remote: bool) -> dict[str, Any]:
    path = root / relative if relative else root
    state: dict[str, Any] = {
        "path": relative or ".",
        "initialized": False,
        "branch": None,
        "head": None,
        "dirty": None,
        "root_gitlink": None,
        "gitlink_matches_head": None,
        "patch_identity_sha256": None,
        "tracked_diff_bytes": None,
        "untracked_files": [],
        "remote_name": None,
        "remote_url": None,
        "remotes": {},
        "remote_branch_head": None,
        "remote_matches_head": None,
        "errors": [],
    }
    if not path.exists():
        state["errors"].append("path-missing")
        return state
    probe = run(path, "git", "rev-parse", "--is-inside-work-tree")
    if probe.returncode != 0:
        state["errors"].append("not-initialized")
        return state
    state["initialized"] = True
    state["head"] = git(path, "rev-parse", "HEAD")
    branch = git(path, "symbolic-ref", "--quiet", "--short", "HEAD")
    state["branch"] = branch or "DETACHED"
    state["dirty"] = bool(git(path, "status", "--porcelain=v1", "--untracked-files=all"))
    state.update(patch_identity(path))

    if relative:
        tree_line = git(root, "ls-tree", "HEAD", "--", relative)
        fields = tree_line.split()
        if len(fields) >= 3 and fields[1] == "commit":
            state["root_gitlink"] = fields[2]
            state["gitlink_matches_head"] = fields[2] == state["head"]
        else:
            state["errors"].append("missing-root-gitlink")

    remotes = git(path, "remote").splitlines()
    state["remotes"] = {
        remote: git(path, "remote", "get-url", remote) for remote in remotes
    }
    preferred = "mark-bst" if "mark-bst" in remotes else "origin" if "origin" in remotes else None
    if preferred:
        state["remote_name"] = preferred
        state["remote_url"] = state["remotes"][preferred]
    else:
        state["errors"].append("missing-remote")
    if state["branch"] == MERGE_BRANCH and not any(
        "mark-bst" in url.lower() for url in state["remotes"].values()
    ):
        state["errors"].append("missing-mark-bst-fork")

    if check_remote and state["remote_url"] and state["branch"] != "DETACHED":
        result = run(
            path,
            "git",
            "ls-remote",
            state["remote_url"],
            f"refs/heads/{state['branch']}",
        )
        if result.returncode != 0:
            state["errors"].append("remote-query-failed")
        elif result.stdout.strip():
            state["remote_branch_head"] = result.stdout.split()[0]
            state["remote_matches_head"] = (
                state["remote_branch_head"] == state["head"]
            )
        else:
            state["errors"].append("remote-branch-missing")
    return state


def summarize(states: list[dict[str, Any]]) -> dict[str, Any]:
    branches = Counter(
        state["branch"] for state in states[1:] if state["initialized"]
    )
    return {
        "repositories": len(states),
        "submodules": len(states) - 1,
        "initialized": sum(1 for state in states if state["initialized"]),
        "branches": dict(sorted(branches.items())),
        "detached": sum(state["branch"] == "DETACHED" for state in states),
        "dirty": sum(bool(state["dirty"]) for state in states),
        "gitlink_mismatches": sum(
            state["gitlink_matches_head"] is False for state in states
        ),
        "remote_mismatches": sum(
            state["remote_matches_head"] is False for state in states
        ),
        "repositories_with_errors": sum(bool(state["errors"]) for state in states),
    }


def audit(root: Path, check_remotes: bool) -> dict[str, Any]:
    root = root.expanduser().resolve()
    paths = submodule_paths(root)
    states = [repo_state(root, "", check_remotes)]
    states.extend(repo_state(root, path, check_remotes) for path in paths)
    return {
        "schema_version": 1,
        "mode": "android16-audit",
        "root": str(root),
        "expected_branches": [BASE_BRANCH, MERGE_BRANCH],
        "summary": summarize(states),
        "repositories": states,
    }


def freeze(source: Path, paths_root: Path | None) -> dict[str, Any]:
    source = source.expanduser().resolve()
    manifest_root = (paths_root or source).expanduser().resolve()
    paths = submodule_paths(manifest_root)
    states = [repo_state(source, "", False)]
    states.extend(repo_state(source, path, False) for path in paths)
    return {
        "schema_version": 1,
        "mode": "aosp16-freeze",
        "root": str(source),
        "path_manifest_root": str(manifest_root),
        "summary": summarize(states),
        "repositories": states,
    }


def failures(
    payload: dict[str, Any],
    expected_total: int | None,
    expected_base: int | None,
    expected_merge: int | None,
) -> list[str]:
    summary = payload["summary"]
    result: list[str] = []
    if summary["initialized"] != summary["repositories"]:
        result.append(
            f"initialized {summary['initialized']}/{summary['repositories']}"
        )
    if summary["detached"]:
        result.append(f"detached repositories: {summary['detached']}")
    if summary["dirty"]:
        result.append(f"dirty repositories: {summary['dirty']}")
    if summary["gitlink_mismatches"]:
        result.append(f"root gitlink mismatches: {summary['gitlink_mismatches']}")
    if summary["remote_mismatches"]:
        result.append(f"remote branch mismatches: {summary['remote_mismatches']}")
    if summary["repositories_with_errors"]:
        result.append(
            f"repositories with structural/remote errors: "
            f"{summary['repositories_with_errors']}"
        )
    branches = summary["branches"]
    unexpected = {
        branch: count
        for branch, count in branches.items()
        if branch not in {BASE_BRANCH, MERGE_BRANCH}
    }
    if unexpected:
        result.append(f"unexpected branches: {unexpected}")
    if expected_total is not None and summary["submodules"] != expected_total:
        result.append(
            f"submodule count {summary['submodules']} != {expected_total}"
        )
    if expected_base is not None and branches.get(BASE_BRANCH, 0) != expected_base:
        result.append(
            f"{BASE_BRANCH} count {branches.get(BASE_BRANCH, 0)} != {expected_base}"
        )
    if expected_merge is not None and branches.get(MERGE_BRANCH, 0) != expected_merge:
        result.append(
            f"{MERGE_BRANCH} count {branches.get(MERGE_BRANCH, 0)} != {expected_merge}"
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    audit_parser = subparsers.add_parser("audit")
    audit_parser.add_argument("--root", type=Path, default=Path("~/android-16"))
    audit_parser.add_argument("--check-remotes", action="store_true")
    audit_parser.add_argument("--expected-total", type=int)
    audit_parser.add_argument("--expected-base", type=int)
    audit_parser.add_argument("--expected-merge", type=int)
    audit_parser.add_argument("--enforce-recorded-baseline", action="store_true")
    audit_parser.add_argument("--output", type=Path)

    freeze_parser = subparsers.add_parser("freeze")
    freeze_parser.add_argument("--source-root", type=Path, default=Path("~/aosp16"))
    freeze_parser.add_argument(
        "--paths-from",
        type=Path,
        default=Path("~/android-16"),
        help="Tree whose .gitmodules defines the project path set.",
    )
    freeze_parser.add_argument("--output", type=Path)

    args = parser.parse_args()
    if args.command == "audit":
        payload = audit(args.root, args.check_remotes)
        if args.enforce_recorded_baseline:
            args.expected_total = 1016
            args.expected_base = 985
            args.expected_merge = 31
        problems = failures(
            payload,
            args.expected_total,
            args.expected_base,
            args.expected_merge,
        )
    else:
        payload = freeze(args.source_root, args.paths_from)
        problems = failures(payload, None, None, None)

    rendered = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        output = args.output.expanduser()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8", newline="\n")
    else:
        sys.stdout.write(rendered)
    if problems:
        for problem in problems:
            print(f"AUDIT_FAIL: {problem}", file=sys.stderr)
        return 1
    print("AUDIT_OK", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
