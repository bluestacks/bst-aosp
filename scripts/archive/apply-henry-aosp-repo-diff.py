#!/usr/bin/env python3
"""Split henry repo-diff patch and apply per AOSP project."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def split_repo_diff(patch_text: str) -> list[tuple[str, str]]:
    blocks: list[tuple[str, str]] = []
    current_project: str | None = None
    current_lines: list[str] = []

    for line in patch_text.splitlines(keepends=True):
        if line.startswith("project ") and line.rstrip().endswith("/"):
            if current_project and current_lines:
                blocks.append((current_project, "".join(current_lines)))
            current_project = line[len("project ") :].strip().rstrip("/")
            current_lines = []
            continue
        if current_project is not None:
            current_lines.append(line)

    if current_project and current_lines:
        blocks.append((current_project, "".join(current_lines)))
    return blocks


def run(cmd: list[str], cwd: Path | None = None, input_text: str = "") -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, input=input_text)


def apply_block(aosp_root: Path, project: str, diff: str, dry_run: bool) -> tuple[str, str]:
    proj_dir = aosp_root / project
    if not proj_dir.is_dir():
        return "skip", f"missing project dir: {project}"

    check = run(["git", "apply", "--check", "-"], cwd=proj_dir, input_text=diff)
    if check.returncode == 0:
        if dry_run:
            return "would_apply", "clean apply"
        apply = run(["git", "apply", "-"], cwd=proj_dir, input_text=diff)
        if apply.returncode == 0:
            return "applied", "ok"
        return "failed", apply.stderr.strip() or apply.stdout.strip()

    reverse = run(["git", "apply", "--reverse", "--check", "-"], cwd=proj_dir, input_text=diff)
    if reverse.returncode == 0:
        return "already_applied", "reverse-check ok"

    if dry_run:
        return "conflict", check.stderr.strip() or check.stdout.strip()

    three = run(["git", "apply", "--3way", "-"], cwd=proj_dir, input_text=diff)
    if three.returncode == 0:
        return "applied_3way", "3way ok"
    return "failed", (three.stderr or three.stdout or check.stderr).strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("patch_file", type=Path)
    parser.add_argument("aosp_root", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    patch_text = args.patch_file.read_text(encoding="utf-8", errors="replace")
    blocks = split_repo_diff(patch_text)
    if not blocks:
        print("No project blocks found", file=sys.stderr)
        return 1

    print(f"projects={len(blocks)} aosp_root={args.aosp_root}")
    failed = 0
    for project, diff in blocks:
        status, detail = apply_block(args.aosp_root, project, diff, args.dry_run)
        print(f"{project}: {status}: {detail}")
        if status in {"failed", "conflict"}:
            failed += 1
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
