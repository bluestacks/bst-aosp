#!/usr/bin/env python3
"""Read-only freeze, submodule, branch, gitlink, and publish audit."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any


BASE_BRANCH = "aosp16-bst"
MERGE_BRANCH = "aosp16-bst-merge"
CURRENT_BASELINE = (1025, 974, 51)
WITHDRAWN_BASELINE = (1016, 985, 31)
EMPTY_PATCH_SHA256 = hashlib.sha256(b"").hexdigest()


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


def root_dirty(root: Path) -> bool:
    tree = run(root, "git", "ls-tree", "-r", "-z", "HEAD")
    if tree.returncode:
        return True
    files = []
    for raw in tree.stdout.split("\0"):
        if not raw:
            continue
        metadata, relative = raw.split("\t", 1)
        mode = metadata.split(None, 1)[0]
        if mode != "160000":
            files.append(relative)
    tracked = run(
        root,
        "git",
        "diff",
        "--quiet",
        "HEAD",
        "--",
        *files,
    )
    if tracked.returncode not in {0, 1}:
        return True
    untracked = git(
        root,
        "ls-files",
        "--others",
        "--exclude-standard",
        "--directory",
    )
    return tracked.returncode == 1 or bool(untracked)


def patch_identity(path: Path) -> dict[str, Any]:
    diff = subprocess.run(
        ["git", "diff", "--binary", "--ignore-submodules=dirty", "HEAD", "--"],
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


def branch_delta(path: Path) -> dict[str, Any]:
    """Describe the committed promotion delta without reading another tree."""
    result: dict[str, Any] = {
        "base_ref": BASE_BRANCH,
        "base_head": None,
        "merge_base": None,
        "base_is_ancestor": None,
        "commits": [],
        "changed_files": [],
        "changed_file_count": 0,
        "added_lines": 0,
        "deleted_lines": 0,
        "binary_file_count": 0,
    }
    base = run(path, "git", "rev-parse", "--verify", BASE_BRANCH)
    if base.returncode:
        return result
    result["base_head"] = base.stdout.strip()
    merge_base = run(path, "git", "merge-base", BASE_BRANCH, "HEAD")
    if merge_base.returncode == 0:
        result["merge_base"] = merge_base.stdout.strip()
    ancestor = run(path, "git", "merge-base", "--is-ancestor", BASE_BRANCH, "HEAD")
    result["base_is_ancestor"] = ancestor.returncode == 0

    log_output = git(
        path,
        "log",
        "--reverse",
        "--format=%H%x09%s",
        f"{BASE_BRANCH}..HEAD",
    )
    for line in log_output.splitlines():
        if not line:
            continue
        commit, _, subject = line.partition("\t")
        result["commits"].append({"commit": commit, "subject": subject})

    numstat = git(
        path,
        "diff",
        "--no-renames",
        "--numstat",
        f"{BASE_BRANCH}...HEAD",
        "--",
    )
    for line in numstat.splitlines():
        if not line:
            continue
        added, deleted, relative = line.split("\t", 2)
        binary = added == "-" or deleted == "-"
        if binary:
            result["binary_file_count"] += 1
        else:
            result["added_lines"] += int(added)
            result["deleted_lines"] += int(deleted)
        result["changed_files"].append(
            {
                "path": relative,
                "added": None if binary else int(added),
                "deleted": None if binary else int(deleted),
                "binary": binary,
            }
        )
    result["changed_file_count"] = len(result["changed_files"])
    return result


def file_digest(path: Path) -> tuple[str, str | None]:
    if not os.path.lexists(path):
        return "missing", None
    if path.is_symlink():
        target = os.readlink(path)
        return "symlink", hashlib.sha256(target.encode()).hexdigest()
    if path.is_file():
        return "file", hashlib.sha256(path.read_bytes()).hexdigest()
    if path.is_dir():
        return "directory", None
    return "other", None


def compare_changed_files(
    source_root: Path, target_root: Path, states: list[dict[str, Any]]
) -> None:
    """Attach source-tree provenance to files already changed by promotion."""
    for state in states:
        delta = state.get("branch_delta")
        if not delta:
            continue
        repository = "" if state["path"] == "." else state["path"]
        for changed in delta["changed_files"]:
            relative = changed["path"]
            source = source_root / repository / relative
            target = target_root / repository / relative
            source_type, source_sha = file_digest(source)
            target_type, target_sha = file_digest(target)
            if source_type == "missing":
                comparison = "source-missing"
            elif target_type == "missing":
                comparison = "target-missing"
            elif source_type != target_type:
                comparison = "type-mismatch"
            elif source_sha == target_sha:
                comparison = "exact"
            else:
                comparison = "adapted"
            changed["source_comparison"] = comparison
            changed["source_type"] = source_type
            changed["source_sha256"] = source_sha
            changed["target_type"] = target_type
            changed["target_sha256"] = target_sha


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
        "remote_commit_reachable": None,
        "nonconforming_commits": [],
        "branch_delta": None,
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
    if relative:
        state["dirty"] = bool(
            git(path, "status", "--porcelain=v1", "--untracked-files=normal")
        )
    else:
        state["dirty"] = root_dirty(path)
    if state["dirty"]:
        state.update(patch_identity(path))
    else:
        state.update(
            {
                "patch_identity_sha256": EMPTY_PATCH_SHA256,
                "tracked_diff_bytes": 0,
                "untracked_files": [],
            }
        )
    if state["branch"] == MERGE_BRANCH:
        state["branch_delta"] = branch_delta(path)
        if state["branch_delta"]["base_head"] is None:
            state["errors"].append("missing-base-branch")
        elif not state["branch_delta"]["base_is_ancestor"]:
            state["errors"].append("base-not-ancestor")
        subjects = git(
            path,
            "log",
            "--format=%H%x09%s",
            f"{BASE_BRANCH}..HEAD",
        ).splitlines()
        state["nonconforming_commits"] = [
            subject
            for subject in subjects
            if subject and not subject.split("\t", 1)[-1].startswith("[A16] ")
        ]

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
    mark_bst_remotes = [
        remote
        for remote, url in state["remotes"].items()
        if "mark-bst" in url.lower()
    ]
    if state["branch"] == MERGE_BRANCH:
        preferred = "mark-bst" if "mark-bst" in mark_bst_remotes else (
            mark_bst_remotes[0] if mark_bst_remotes else None
        )
    else:
        preferred = "origin" if "origin" in remotes else (
            "mark-bst" if "mark-bst" in remotes else None
        )
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
            if state["branch"] == MERGE_BRANCH:
                state["remote_matches_head"] = (
                    state["remote_branch_head"] == state["head"]
                )
                state["remote_commit_reachable"] = state["remote_matches_head"]
            elif state["remote_branch_head"] == state["head"]:
                state["remote_matches_head"] = True
                state["remote_commit_reachable"] = True
            else:
                reachable = run(
                    path,
                    "git",
                    "fetch",
                    "--dry-run",
                    "--no-tags",
                    state["remote_url"],
                    state["head"],
                )
                state["remote_commit_reachable"] = reachable.returncode == 0
                state["remote_matches_head"] = state["remote_commit_reachable"]
                if reachable.returncode:
                    state["errors"].append("remote-commit-unreachable")
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
        "nonconforming_commits": sum(
            len(state["nonconforming_commits"]) for state in states
        ),
        "repositories_with_errors": sum(bool(state["errors"]) for state in states),
    }


def audit(
    root: Path,
    check_remotes: bool,
    jobs: int,
    source_reference_root: Path | None = None,
) -> dict[str, Any]:
    root = root.expanduser().resolve()
    paths = submodule_paths(root)
    states = [repo_state(root, "", check_remotes)]
    with ThreadPoolExecutor(max_workers=max(1, jobs)) as executor:
        states.extend(
            executor.map(
                lambda path: repo_state(root, path, check_remotes),
                paths,
            )
        )
    source_reference = None
    if source_reference_root is not None:
        source_path = source_reference_root.expanduser().resolve()
        if not source_path.is_dir():
            raise SystemExit(f"missing source reference tree: {source_path}")
        compare_changed_files(source_path, root, states)
        source_reference = str(source_path)
    return {
        "schema_version": 2,
        "mode": "android16-audit",
        "root": str(root),
        "source_reference_root": source_reference,
        "expected_branches": [BASE_BRANCH, MERGE_BRANCH],
        "summary": summarize(states),
        "repositories": states,
    }


def freeze(source: Path, paths_root: Path | None, jobs: int) -> dict[str, Any]:
    source = source.expanduser().resolve()
    manifest_root = (paths_root or source).expanduser().resolve()
    paths = submodule_paths(manifest_root)
    states = [repo_state(source, "", False)]
    with ThreadPoolExecutor(max_workers=max(1, jobs)) as executor:
        states.extend(executor.map(lambda path: repo_state(source, path, False), paths))
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
    if summary["nonconforming_commits"]:
        result.append(
            f"commits without '[A16] ' prefix: "
            f"{summary['nonconforming_commits']}"
        )
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
    audit_parser.add_argument("--jobs", type=int, default=16)
    audit_parser.add_argument(
        "--source-reference-root",
        type=Path,
        help="read-only source tree used to classify each changed file",
    )
    audit_parser.add_argument(
        "--enforce-current-baseline",
        action="store_true",
        help="enforce the current 1025/974/51 A13-complete topology",
    )
    audit_parser.add_argument(
        "--enforce-recorded-baseline",
        action="store_true",
        help="enforce the withdrawn first-candidate 1016/985/31 topology",
    )
    audit_parser.add_argument("--output", type=Path)

    freeze_parser = subparsers.add_parser("freeze")
    freeze_parser.add_argument("--source-root", type=Path, default=Path("~/aosp16"))
    freeze_parser.add_argument(
        "--paths-from",
        type=Path,
        default=Path("~/android-16"),
        help="Tree whose .gitmodules defines the project path set.",
    )
    freeze_parser.add_argument("--jobs", type=int, default=16)
    freeze_parser.add_argument("--output", type=Path)

    args = parser.parse_args()
    if args.command == "audit":
        if args.enforce_current_baseline and args.enforce_recorded_baseline:
            parser.error("baseline enforcement options are mutually exclusive")
        payload = audit(
            args.root,
            args.check_remotes,
            args.jobs,
            args.source_reference_root,
        )
        if args.enforce_current_baseline:
            (
                args.expected_total,
                args.expected_base,
                args.expected_merge,
            ) = CURRENT_BASELINE
        if args.enforce_recorded_baseline:
            (
                args.expected_total,
                args.expected_base,
                args.expected_merge,
            ) = WITHDRAWN_BASELINE
        problems = failures(
            payload,
            args.expected_total,
            args.expected_base,
            args.expected_merge,
        )
    else:
        payload = freeze(args.source_root, args.paths_from, args.jobs)
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
