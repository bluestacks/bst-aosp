"""Safety gate for historical Python helpers that mutate Android-16."""

from __future__ import annotations

import subprocess
from pathlib import Path


def require_historical_target(root: Path, apply: bool) -> Path:
    if not apply:
        raise SystemExit(
            "historical mutation helper is inert; review the promotion record and "
            "pass --apply-historical explicitly"
        )
    root = root.expanduser().resolve()
    reference = Path("~/aosp16").expanduser().resolve()
    if root == reference or reference in root.parents:
        raise SystemExit(f"refusing AOSP16 development root: {root}")
    probe = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "--is-inside-work-tree"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    if probe.returncode != 0:
        raise SystemExit(f"not an initialized Android-16 Git root: {root}")
    branch = subprocess.run(
        ["git", "-C", str(root), "symbolic-ref", "--quiet", "--short", "HEAD"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    ).stdout.strip()
    if branch != "aosp16-bst-merge":
        raise SystemExit(
            f"historical mutation requires aosp16-bst-merge, found {branch or 'DETACHED'}"
        )
    return root
