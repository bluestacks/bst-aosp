#!/usr/bin/env python3
"""Publish audited Android-16 component tips with explicit remote leases."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


MERGE_BRANCH = "aosp16-bst-merge"


def run(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [*args],
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def remote_head(cwd: Path, url: str, branch: str) -> str | None:
    result = run(cwd, "git", "ls-remote", url, f"refs/heads/{branch}")
    if result.returncode:
        raise RuntimeError(result.stdout.strip() or f"ls-remote failed for {url}")
    return result.stdout.split()[0] if result.stdout.strip() else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("audit", type=Path)
    parser.add_argument("--root", type=Path, default=Path("~/android-16"))
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--include-root", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    payload = json.loads(args.audit.expanduser().read_text(encoding="utf-8"))
    root = args.root.expanduser().resolve()
    records: list[dict[str, Any]] = []
    failed = False
    for state in payload["repositories"]:
        relative = state["path"]
        if state.get("branch") != MERGE_BRANCH:
            continue
        if relative == "." and not args.include_root:
            continue
        if state.get("remote_matches_head") is True:
            records.append({"path": relative, "status": "already-current"})
            continue
        if state.get("errors"):
            records.append(
                {"path": relative, "status": "blocked", "errors": state["errors"]}
            )
            failed = True
            continue
        repository = root if relative == "." else root / relative
        url = state.get("remote_url")
        expected = state.get("remote_branch_head")
        target = state["head"]
        if not url or "mark-bst" not in url.lower():
            records.append(
                {"path": relative, "status": "blocked", "errors": ["not-mark-bst"]}
            )
            failed = True
            continue
        current = remote_head(repository, url, MERGE_BRANCH)
        if current != expected:
            records.append(
                {
                    "path": relative,
                    "status": "lease-changed",
                    "expected": expected,
                    "actual": current,
                }
            )
            failed = True
            continue
        if not args.execute:
            print(f"DRY-RUN {relative}: {current or '<missing>'} -> {target}")
            records.append(
                {"path": relative, "status": "dry-run", "old": current, "new": target}
            )
            continue

        lease = f"--force-with-lease=refs/heads/{MERGE_BRANCH}:{current or ''}"
        pushed = run(
            repository,
            "git",
            "push",
            lease,
            url,
            f"HEAD:refs/heads/{MERGE_BRANCH}",
        )
        print(pushed.stdout, end="")
        if pushed.returncode:
            records.append(
                {"path": relative, "status": "push-failed", "output": pushed.stdout}
            )
            failed = True
            continue
        readback = remote_head(repository, url, MERGE_BRANCH)
        status = "published" if readback == target else "readback-mismatch"
        print(f"{status.upper()} {relative}: {readback}")
        records.append(
            {
                "path": relative,
                "status": status,
                "old": current,
                "new": target,
                "readback": readback,
            }
        )
        failed |= status != "published"

    result = {
        "schema_version": 1,
        "execute": args.execute,
        "include_root": args.include_root,
        "records": records,
    }
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        output = args.output.expanduser()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8", newline="\n")
    else:
        sys.stdout.write(rendered)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
