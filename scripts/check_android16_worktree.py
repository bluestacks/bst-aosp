#!/usr/bin/env python3
"""Check the Android-16 root and every submodule without Git's serial recursion."""

from __future__ import annotations

import argparse
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


ALLOWED_BRANCHES = {"aosp16-bst", "aosp16-bst-merge"}


def submodule_paths(root: Path) -> list[Path]:
    paths: list[Path] = []
    for line in (root / ".gitmodules").read_text(errors="replace").splitlines():
        match = re.match(r"\s*path\s*=\s*(.+?)\s*$", line)
        if match:
            paths.append(root / match.group(1))
    return paths


def root_tree(root: Path) -> tuple[list[str], dict[str, str]]:
    result = subprocess.run(
        ["git", "ls-tree", "-r", "-z", "HEAD"],
        cwd=root,
        check=True,
        stdout=subprocess.PIPE,
    )
    files: list[str] = []
    gitlinks: dict[str, str] = {}
    for raw in result.stdout.split(b"\0"):
        if not raw:
            continue
        metadata, encoded_path = raw.split(b"\t", 1)
        mode, _kind, sha = metadata.decode("ascii").split()
        relative = encoded_path.decode("utf-8", "surrogateescape")
        if mode == "160000":
            gitlinks[relative] = sha
        else:
            files.append(relative)
    return files, gitlinks


def status(
    path: Path, root: bool = False, root_files: list[str] | None = None
) -> tuple[Path, int, str]:
    if root:
        root_files = root_files or []
        tracked = subprocess.run(
            ["git", "diff", "--quiet", "HEAD", "--", *root_files],
            cwd=path,
        )
        untracked = subprocess.run(
            [
                "git",
                "ls-files",
                "--others",
                "--exclude-standard",
                "--directory",
            ],
            cwd=path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        details: list[str] = []
        if tracked.returncode == 1:
            names = subprocess.run(
                [
                    "git",
                    "diff",
                    "--name-status",
                    "HEAD",
                    "--",
                    *root_files,
                ],
                cwd=path,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            details.append(names.stdout.strip() or "tracked root changes")
        elif tracked.returncode:
            details.append("root git diff failed")
        if untracked.stdout.strip():
            details.append("untracked:\n" + untracked.stdout.strip())
        return path, max(tracked.returncode - 1, 0) or untracked.returncode, "\n".join(details)

    command = [
        "git",
        "status",
        "--porcelain=v1",
        # Directory-level reporting still detects untracked content without
        # recursively enumerating large source and generated trees.
        "--untracked-files=normal",
        # Every root-listed submodule is checked independently below. Avoid
        # recursively scanning it again while inspecting its owning project.
        "--ignore-submodules=all",
    ]
    result = subprocess.run(
        command,
        cwd=path,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return path, result.returncode, result.stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--jobs", type=int, default=16)
    parser.add_argument(
        "--allow-root-dirty",
        action="append",
        default=[],
        metavar="PATH",
        help="Allow an exact tracked superproject path to differ from HEAD.",
    )
    args = parser.parse_args()

    root = args.root.expanduser().resolve()
    paths = submodule_paths(root)
    root_files, gitlinks = root_tree(root)
    allowed_root_dirty = set(args.allow_root_dirty)
    invalid_allowed = sorted(
        path
        for path in allowed_root_dirty
        if Path(path).is_absolute()
        or ".." in Path(path).parts
        or path not in root_files
    )
    if invalid_allowed:
        print("invalid allowed root paths: " + ", ".join(invalid_allowed))
        return 2
    audited_root_files = [
        path for path in root_files if path not in allowed_root_dirty
    ]
    failures: list[str] = []

    root_path, root_rc, root_output = status(
        root, root=True, root_files=audited_root_files
    )
    if root_rc or root_output:
        failures.append(f"{root_path}:\n{root_output or 'git status failed'}")

    def check(path: Path) -> tuple[Path, int, str]:
        if not path.is_dir():
            return path, 1, "submodule path is missing or uninitialized"
        checked_path, returncode, output = status(path)
        relative = path.relative_to(root).as_posix()
        expected = gitlinks.get(relative)
        head = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        actual = head.stdout.strip()
        if head.returncode:
            return checked_path, head.returncode, output or "cannot read submodule HEAD"
        branch = subprocess.run(
            ["git", "symbolic-ref", "--quiet", "--short", "HEAD"],
            cwd=path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        branch_name = branch.stdout.strip()
        if branch.returncode or not branch_name:
            output = "\n".join(part for part in (output, "detached HEAD") if part)
        elif branch_name not in ALLOWED_BRANCHES:
            output = "\n".join(
                part
                for part in (
                    output,
                    f"unexpected branch: {branch_name}",
                )
                if part
            )
        if expected != actual:
            mismatch = f"gitlink mismatch: root={expected or 'missing'} submodule={actual}"
            output = "\n".join(part for part in (output, mismatch) if part)
        return checked_path, returncode, output

    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as executor:
        for path, returncode, output in executor.map(check, paths):
            if returncode or output:
                failures.append(f"{path}:\n{output or 'git status failed'}")

    if failures:
        print("Android-16 worktree audit failed:")
        print("\n".join(failures[:40]))
        if len(failures) > 40:
            print(f"... {len(failures) - 40} additional repositories omitted")
        return 1

    if allowed_root_dirty:
        print(
            "A16DBG:IDENTITY: allowed root dirty paths="
            + ",".join(sorted(allowed_root_dirty))
        )
    print(f"A16DBG:IDENTITY: clean root + {len(paths)} submodules")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
