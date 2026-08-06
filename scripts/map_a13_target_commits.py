#!/usr/bin/env python3
"""Map explicit A13 commit references in Android-16 promotion commits."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any


TARGET_PATH_MAP = {
    "build": "build/make",
    "kernel": "kernel-a16",
}


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if check and result.returncode:
        raise RuntimeError(
            f"git {' '.join(args)} failed in {repo}: {result.stderr.strip()}"
        )
    return result.stdout


def resolve_baseline(repo: Path) -> tuple[str | None, str | None]:
    for ref in (
        "origin/aosp16-bst",
        "bluestacks/aosp16-bst",
        "aosp16-bst",
    ):
        if git(repo, "rev-parse", "--verify", "--quiet", ref, check=False).strip():
            baseline = git(repo, "merge-base", ref, "HEAD").strip()
            return baseline, ref
    return None, None


def target_commits(repo: Path, baseline: str) -> list[dict[str, Any]]:
    marker = "@@A16COMMIT@@"
    output = git(
        repo,
        "log",
        "--reverse",
        "--format=" + marker + "%n%H%n%P%n%s%n%b",
        f"{baseline}..HEAD",
    )
    commits: list[dict[str, Any]] = []
    for block in output.split(marker + "\n"):
        if not block.strip():
            continue
        lines = block.splitlines()
        if len(lines) < 3:
            continue
        commit = lines[0]
        parents = lines[1].split()
        if parents:
            changed_files = git(
                repo, "diff", "--name-only", parents[0], commit
            ).splitlines()
        else:
            changed_files = git(
                repo,
                "diff-tree",
                "--root",
                "--no-commit-id",
                "--name-only",
                "-r",
                commit,
            ).splitlines()
        commits.append(
            {
                "commit": commit,
                "parents": parents,
                "subject": lines[2],
                "body": "\n".join(lines[3:]).strip(),
                "changed_files": changed_files,
            }
        )
    return commits


def explicit_refs(
    commits: list[dict[str, Any]], source_commits: list[str]
) -> dict[str, list[str]]:
    refs: dict[str, list[str]] = {commit: [] for commit in source_commits}
    for target in commits:
        message = target["subject"] + "\n" + target["body"]
        for source in source_commits:
            if any(source[:length] in message for length in (40, 12, 10, 8, 7)):
                refs[source].append(target["commit"])
    return {source: targets for source, targets in refs.items() if targets}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--coverage", type=Path, required=True)
    parser.add_argument("--android16-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    coverage = json.loads(args.coverage.read_text(encoding="utf-8"))
    projects: list[dict[str, Any]] = []
    for source_project in coverage["projects"]:
        source_commits = [
            item["commit"] for item in source_project.get("commits", [])
        ]
        source_commits.extend(
            item["commit"] for item in source_project.get("merge_commits", [])
        )
        if not source_commits and not source_project.get("errors"):
            continue

        source_path = source_project["path"]
        target_path = TARGET_PATH_MAP.get(source_path, source_path)
        repo = args.android16_root / target_path
        record: dict[str, Any] = {
            "source_path": source_path,
            "target_path": target_path,
            "source_commits": len(source_commits),
        }
        if not (repo / ".git").exists():
            record["error"] = "target-project-missing"
            projects.append(record)
            continue

        baseline, baseline_ref = resolve_baseline(repo)
        record.update(
            {
                "target_head": git(repo, "rev-parse", "HEAD").strip(),
                "target_branch": git(repo, "branch", "--show-current").strip(),
                "target_baseline": baseline,
                "target_baseline_ref": baseline_ref,
            }
        )
        if baseline is None:
            record["error"] = "target-baseline-unresolved"
            projects.append(record)
            continue

        commits = target_commits(repo, baseline)
        record["target_commits"] = commits
        record["explicit_source_refs"] = explicit_refs(commits, source_commits)
        projects.append(record)

    output = {
        "schema_version": 1,
        "mode": "a13-explicit-target-commit-map",
        "coverage_identity": coverage["identities"],
        "android16_root": str(args.android16_root.resolve()),
        "android16_root_head": git(args.android16_root, "rev-parse", "HEAD").strip(),
        "projects": projects,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(
        json.dumps(
            {
                "projects": len(projects),
                "errors": sum("error" in project for project in projects),
                "explicit_source_refs": sum(
                    len(project.get("explicit_source_refs", {})) for project in projects
                ),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
