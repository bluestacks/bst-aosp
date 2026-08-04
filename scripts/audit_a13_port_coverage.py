#!/usr/bin/env python3
"""Compare every final A13 branch patch with AOSP16 and Android-16 trees."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shlex
import subprocess
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
from pathlib import Path
from typing import Any


DEFAULT_TAG = "android-13.0.0_r49"
EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
CUSTOM_WITHOUT_TAG = (
    "device/bst/",
    "external/bluestacks/",
    "hardware/bst/",
)
CUSTOM_COMMIT_RE = re.compile(
    r"bluestacks|(?:^|[-_@])bst(?:$|[-_@.])|\[a13\]|\brob[-_ ]?\d+|"
    r"bst_|bstvmsg|bstpgaipc|qvirt|vbox",
    re.IGNORECASE,
)

TARGET_PATH_REWRITES = {
    "device/generic/common": (
        (
            "libndk_tiramisu64/",
            "libndk_baklava64/",
            "Android platform codename update: Tiramisu to Baklava",
        ),
    ),
    "frameworks/base": (
        (
            "core/java/com/android/internal/os/BatteryStatsImpl.java",
            "services/core/java/com/android/server/power/stats/BatteryStatsImpl.java",
            "Battery stats implementation moved into system_server power stats",
        ),
        (
            "core/java/com/android/server/SystemConfig.java",
            "services/core/java/com/android/server/SystemConfig.java",
            "SystemConfig moved from framework core into system_server",
        ),
        (
            "location/java/android/location/Location.java",
            "core/java/android/location/Location.java",
            "Location moved into framework core",
        ),
        (
            "packages/SettingsProvider/res/xml/bookmarks.xml",
            "core/res/res/xml/bookmarks.xml",
            "Framework bookmarks moved out of SettingsProvider",
        ),
        (
            "packages/SystemUI/src/com/android/systemui/screenshot/SaveImageInBackgroundTask.java",
            "packages/SystemUI/src/com/android/systemui/screenshot/ImageExporter.java",
            "Screenshot persistence moved to ImageExporter",
        ),
        (
            "packages/SystemUI/src/com/android/systemui/screenshot/ScreenshotController.java",
            "packages/SystemUI/src/com/android/systemui/screenshot/ScreenshotController.kt",
            "ScreenshotController migrated from Java to Kotlin",
        ),
        (
            "packages/SystemUI/src/com/android/systemui/statusbar/StatusBarMobileView.java",
            "packages/SystemUI/src/com/android/systemui/statusbar/pipeline/mobile/ui/view/ModernStatusBarMobileView.kt",
            "Mobile status icon moved to the modern Kotlin pipeline",
        ),
        (
            "services/core/java/com/android/server/NetworkManagementService.java",
            "services/core/java/com/android/server/net/NetworkManagementService.java",
            "NetworkManagementService moved into the server.net package",
        ),
        (
            "services/core/java/com/android/server/NetworkTimeUpdateService.java",
            "services/core/java/com/android/server/timedetector/NetworkTimeUpdateService.java",
            "Network time service moved into the time detector package",
        ),
        (
            "services/core/java/com/android/server/pm/VerificationParams.java",
            "services/core/java/com/android/server/pm/VerifyingSession.java",
            "Package verification state moved to VerifyingSession",
        ),
        (
            "services/core/java/com/android/server/pm/permission/PermissionManagerServiceImpl.java",
            "services/permission/java/com/android/server/permission/access/permission/PermissionService.kt",
            "Runtime permission policy moved into the permission service",
        ),
        (
            "services/core/java/com/android/server/wm/RecentsAnimationController.java",
            "libs/WindowManager/Shell/src/com/android/wm/shell/recents/RecentsTransitionHandler.java",
            "Legacy recents animation moved into WindowManager Shell transitions",
        ),
    ),
}


def run(cwd: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(
        list(args), cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    if check and result.returncode:
        detail = result.stderr.decode("utf-8", "replace").strip()
        raise RuntimeError(f"{' '.join(args)} failed in {cwd}: {detail}")
    return result


def git_text(cwd: Path, *args: str, check: bool = True) -> str:
    return run(cwd, "git", *args, check=check).stdout.decode("utf-8", "replace")


def submodule_paths(root: Path) -> list[str]:
    text = (root / ".gitmodules").read_text(encoding="utf-8", errors="replace")
    return sorted(
        match.group(1).strip()
        for line in text.splitlines()
        if (match := re.match(r"\s*path\s*=\s*(.+?)\s*$", line))
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_line(line: str) -> str | None:
    value = re.sub(r"\s+", "", line.strip())
    if len(value) < 12 or value in {"{", "}", "};", ");"}:
        return None
    if value.startswith(("//", "/*", "*", "package", "import", "#include")):
        return None
    return value


def parse_numstat(raw: bytes) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for record in raw.split(b"\0"):
        if not record:
            continue
        fields = record.split(b"\t", 2)
        if len(fields) != 3:
            continue
        added_raw, deleted_raw, path_raw = fields
        path = path_raw.decode("utf-8", "surrogateescape")
        binary = added_raw == b"-" or deleted_raw == b"-"
        result[path] = {
            "added": None if binary else int(added_raw),
            "deleted": None if binary else int(deleted_raw),
            "binary": binary,
        }
    return result


def parse_added_lines(patch: str) -> dict[str, set[str]]:
    additions: dict[str, set[str]] = defaultdict(set)
    current: str | None = None
    for line in patch.splitlines():
        if line.startswith("diff --git "):
            try:
                parts = shlex.split(line)
                current = parts[3][2:] if len(parts) >= 4 else None
            except ValueError:
                current = None
            continue
        if current and line.startswith("+") and not line.startswith("+++"):
            normalized = normalize_line(line[1:])
            if normalized:
                additions[current].add(normalized)
    return additions


def parse_changed_lines(patch: str) -> dict[str, dict[str, set[str]]]:
    changes: dict[str, dict[str, set[str]]] = defaultdict(
        lambda: {"added": set(), "removed": set()}
    )
    current: str | None = None
    for line in patch.splitlines():
        if line.startswith("diff --git "):
            try:
                parts = shlex.split(line)
                current = parts[3][2:] if len(parts) >= 4 else None
            except ValueError:
                current = None
            continue
        if not current:
            continue
        if line.startswith("+") and not line.startswith("+++"):
            normalized = normalize_line(line[1:])
            if normalized:
                changes[current]["added"].add(normalized)
        elif line.startswith("-") and not line.startswith("---"):
            normalized = normalize_line(line[1:])
            if normalized:
                changes[current]["removed"].add(normalized)
    return changes


def parse_commits(text: str) -> tuple[list[dict[str, Any]], dict[str, list[str]]]:
    commits: list[dict[str, Any]] = []
    file_refs: dict[str, list[str]] = defaultdict(list)
    current: dict[str, Any] | None = None
    for line in text.splitlines():
        if line.startswith("@@A13@@"):
            fields = line[len("@@A13@@"):].split("\t", 3)
            if len(fields) == 4:
                current = {
                    "commit": fields[0],
                    "author": fields[1],
                    "author_email": fields[2],
                    "subject": fields[3],
                    "files": [],
                }
                commits.append(current)
            continue
        if current and line.strip():
            path = line.strip()
            current["files"].append(path)
            file_refs[path].append(current["commit"])
    return commits, file_refs


def is_custom_commit(commit: dict[str, Any]) -> bool:
    evidence = "\n".join(
        str(commit.get(key, ""))
        for key in ("author", "author_email", "subject")
    )
    return bool(CUSTOM_COMMIT_RE.search(evidence))


@lru_cache(maxsize=None)
def source_file_lines(path: Path) -> set[str]:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return set()
    return {value for line in text.splitlines() if (value := normalize_line(line))}


def commit_target_evidence(
    target_root: Path,
    project: str,
    relative: str,
    surviving_added: set[str],
    surviving_removed: set[str],
) -> dict[str, Any]:
    project_root = target_root / project
    state: dict[str, Any] = {
        "matched_path": None,
        "path_adaptation": None,
        "surviving_added_lines": len(surviving_added),
        "surviving_removed_lines": len(surviving_removed),
        "matched_added_lines": 0,
        "matched_removed_lines": 0,
        "coverage": None,
        "classification": "target-project-missing",
    }
    total = len(surviving_added) + len(surviving_removed)
    if total == 0:
        state["classification"] = "superseded-in-a13"
        return state
    if not project_root.is_dir():
        return state

    candidate_paths = [(relative, None)]
    for source_prefix, target_prefix, reason in TARGET_PATH_REWRITES.get(project, ()):
        if relative.startswith(source_prefix):
            candidate_paths.append((target_prefix + relative[len(source_prefix):], reason))
    candidates = [
        (project_root / candidate, reason)
        for candidate, reason in candidate_paths
        if (project_root / candidate).is_file()
    ]
    if not candidates:
        if not surviving_added:
            state["matched_removed_lines"] = len(surviving_removed)
            state["coverage"] = 1.0
            state["classification"] = "complete-removal-evidence"
        else:
            state["classification"] = "target-file-missing"
        return state

    best: tuple[float, int, int, Path, str | None] | None = None
    for candidate, adaptation in candidates:
        target_lines = source_file_lines(candidate)
        matched_added = len(surviving_added & target_lines)
        matched_removed = len(surviving_removed - target_lines)
        coverage = (matched_added + matched_removed) / total
        score = (coverage, matched_added, matched_removed, candidate, adaptation)
        if best is None or score[:3] > best[:3]:
            best = score
    assert best is not None
    coverage, matched_added, matched_removed, candidate, adaptation = best
    state.update(
        {
            "matched_path": candidate.relative_to(project_root).as_posix(),
            "path_adaptation": adaptation,
            "matched_added_lines": matched_added,
            "matched_removed_lines": matched_removed,
            "coverage": round(coverage, 4),
        }
    )
    if coverage == 1.0:
        state["classification"] = "complete-line-evidence"
    elif coverage >= 0.25:
        state["classification"] = "partial-line-evidence"
    else:
        state["classification"] = "low-line-evidence"
    return state


def tree_identity(root: Path) -> dict[str, Any]:
    if run(root, "git", "rev-parse", "--git-dir", check=False).returncode == 0:
        return {
            "kind": "git-superproject",
            "root": str(root),
            "branch": git_text(root, "branch", "--show-current").strip(),
            "head": git_text(root, "rev-parse", "HEAD").strip(),
            "tree": git_text(root, "rev-parse", "HEAD^{tree}").strip(),
        }
    manifest_repository = root / ".repo" / "manifests"
    project_list = root / ".repo" / "project.list"
    if manifest_repository.is_dir() and project_list.is_file():
        return {
            "kind": "repo-workspace",
            "root": str(root),
            "manifest_branch": git_text(
                manifest_repository, "branch", "--show-current"
            ).strip(),
            "manifest_head": git_text(manifest_repository, "rev-parse", "HEAD").strip(),
            "project_list_sha256": sha256(project_list),
            "project_count": len(project_list.read_text(encoding="utf-8").splitlines()),
        }
    raise RuntimeError(f"cannot identify source tree at {root}")


def root_tracked_files(root: Path) -> list[tuple[str, str]]:
    records = run(root, "git", "ls-files", "-s", "-z").stdout.split(b"\0")
    result: list[tuple[str, str]] = []
    for record in records:
        if not record:
            continue
        metadata, path_raw = record.split(b"\t", 1)
        mode = metadata.split(b" ", 1)[0].decode("ascii")
        if mode == "160000":
            continue
        result.append((mode, path_raw.decode("utf-8", "surrogateescape")))
    return result


def root_target_state(
    target_root: Path, relative: str, a13_file: Path, a13_hash: str | None
) -> dict[str, Any]:
    candidate = target_root / relative
    state: dict[str, Any] = {
        "exists": candidate.is_file() or candidate.is_symlink(),
        "sha256": None,
        "exact_file": False,
        "substantive_a13_lines": 0,
        "matched_a13_lines": 0,
        "coverage": None,
        "classification": "file-missing",
    }
    if not state["exists"]:
        return state
    if a13_file.is_symlink() or candidate.is_symlink():
        a13_link = a13_file.readlink().as_posix() if a13_file.is_symlink() else None
        target_link = candidate.readlink().as_posix() if candidate.is_symlink() else None
        state["exact_file"] = a13_link is not None and a13_link == target_link
        state["classification"] = "exact-file" if state["exact_file"] else "symlink-review"
        return state

    state["sha256"] = sha256(candidate)
    state["exact_file"] = a13_hash == state["sha256"]
    if state["exact_file"]:
        state["classification"] = "exact-file"
        state["coverage"] = 1.0
        return state

    a13_lines = source_file_lines(a13_file)
    target_lines = source_file_lines(candidate)
    matched = len(a13_lines & target_lines)
    state["substantive_a13_lines"] = len(a13_lines)
    state["matched_a13_lines"] = matched
    if not a13_lines:
        state["classification"] = "binary-or-metadata-review"
        return state
    coverage = matched / len(a13_lines)
    state["coverage"] = round(coverage, 4)
    if coverage >= 0.8:
        state["classification"] = "high-line-coverage"
    elif coverage >= 0.25:
        state["classification"] = "partial-line-coverage"
    else:
        state["classification"] = "low-line-coverage"
    return state


def inspect_root_payload(
    a13_root: Path, aosp16_root: Path, android16_root: Path, jobs: int
) -> dict[str, Any]:
    def inspect_file(item: tuple[str, str]) -> dict[str, Any] | None:
        mode, relative = item
        source = a13_root / relative
        if not source.is_file() and not source.is_symlink():
            return None
        a13_hash = None if source.is_symlink() else sha256(source)
        return {
            "path": relative,
            "git_mode": mode,
            "a13_sha256": a13_hash,
            "aosp16": root_target_state(aosp16_root, relative, source, a13_hash),
            "android16": root_target_state(android16_root, relative, source, a13_hash),
        }

    with ThreadPoolExecutor(max_workers=max(1, jobs)) as executor:
        inspected = executor.map(inspect_file, root_tracked_files(a13_root))
        files = sorted(
            (entry for entry in inspected if entry is not None),
            key=lambda entry: entry["path"],
        )
    aosp_counts: Counter[str] = Counter()
    android_counts: Counter[str] = Counter()
    for entry in files:
        aosp_counts[entry["aosp16"]["classification"]] += 1
        android_counts[entry["android16"]["classification"]] += 1
    return {
        "tracked_non_gitlink_files": len(files),
        "aosp16_classifications": dict(sorted(aosp_counts.items())),
        "android16_classifications": dict(sorted(android_counts.items())),
        "files": files,
    }


def target_state(
    target_root: Path,
    project: str,
    relative: str,
    a13_file: Path,
    added_lines: set[str],
) -> dict[str, Any]:
    project_root = target_root / project
    state: dict[str, Any] = {
        "project_exists": project_root.is_dir(),
        "requested_path": relative,
        "matched_path": None,
        "path_adaptation": None,
        "exact_file": False,
        "substantive_added_lines": len(added_lines),
        "matched_added_lines": 0,
        "coverage": None,
        "classification": "project-missing",
    }
    if not project_root.is_dir():
        return state
    candidate_paths = [(relative, None)]
    for source_prefix, target_prefix, reason in TARGET_PATH_REWRITES.get(project, ()):
        if relative.startswith(source_prefix):
            candidate_paths.append(
                (target_prefix + relative[len(source_prefix):], reason)
            )
    candidates = [
        (project_root / candidate, reason)
        for candidate, reason in candidate_paths
        if (project_root / candidate).is_file()
    ]
    if not candidates:
        state["classification"] = "file-missing"
        return state

    a13_hash = sha256(a13_file) if a13_file.is_file() else None
    best: tuple[float, int, Path, bool, str | None] | None = None
    for candidate, adaptation in candidates:
        exact = bool(a13_hash and sha256(candidate) == a13_hash)
        target_lines = source_file_lines(candidate) if added_lines else set()
        matched = len(added_lines & target_lines)
        coverage = matched / len(added_lines) if added_lines else 0.0
        score = 2.0 if exact else coverage
        if best is None or score > best[0]:
            best = (score, matched, candidate, exact, adaptation)
    assert best is not None
    _score, matched, candidate, exact, adaptation = best
    state["matched_path"] = candidate.relative_to(project_root).as_posix()
    state["path_adaptation"] = adaptation
    state["exact_file"] = exact
    state["matched_added_lines"] = matched
    if exact:
        state["coverage"] = 1.0
        state["classification"] = "exact-file"
    elif not added_lines:
        state["classification"] = "deletion-or-metadata-review"
    else:
        coverage = matched / len(added_lines)
        state["coverage"] = round(coverage, 4)
        if coverage >= 0.8:
            state["classification"] = "high-line-coverage"
        elif coverage >= 0.25:
            state["classification"] = "partial-line-coverage"
        else:
            state["classification"] = "low-line-coverage"
    return state


def choose_baseline(repository: Path, project: str, requested: str) -> tuple[str | None, str]:
    if run(repository, "git", "rev-parse", "-q", "--verify", f"{requested}^{{commit}}", check=False).returncode == 0:
        return requested, "requested-tag"
    tags = git_text(repository, "tag", "--list", "android-13.0.0_r*").splitlines()
    if tags:
        def revision(tag: str) -> int:
            match = re.search(r"_r(\d+)$", tag)
            return int(match.group(1)) if match else -1
        return max(tags, key=revision), "fallback-highest-a13-tag"
    if project.startswith(CUSTOM_WITHOUT_TAG):
        return EMPTY_TREE, "custom-project-empty-tree"
    return None, "no-a13-baseline"


def inspect_project(
    a13_root: Path,
    aosp16_root: Path,
    android16_root: Path,
    project: str,
    requested_tag: str,
    commit_detail: bool,
) -> dict[str, Any]:
    repository = a13_root / project
    result: dict[str, Any] = {"path": project, "errors": []}
    if not repository.is_dir() or run(repository, "git", "rev-parse", "--git-dir", check=False).returncode:
        result["errors"].append("missing-or-uninitialized-a13-project")
        return result
    result["a13_head"] = git_text(repository, "rev-parse", "HEAD").strip()
    result["a13_branch"] = git_text(repository, "branch", "--show-current").strip()
    baseline, method = choose_baseline(repository, project, requested_tag)
    result["baseline"] = baseline
    result["baseline_method"] = method
    if baseline is None:
        result["errors"].append("no-a13-baseline")
        return result


    log = git_text(
        repository,
        "log",
        "--no-merges",
        "--name-only",
        "--format=@@A13@@%H%x09%an%x09%ae%x09%s",
        f"{baseline}..HEAD",
    )
    commits, _all_file_refs = parse_commits(log)
    for commit in commits:
        commit["product_signal"] = is_custom_commit(commit)
        if commit_detail:
            commit_patch = git_text(
                repository,
                "show",
                "--format=",
                "--no-ext-diff",
                "--no-renames",
                "--unified=0",
                "--no-color",
                commit["commit"],
            )
            changed_lines = parse_changed_lines(commit_patch)
            evidence: list[dict[str, Any]] = []
            for relative in commit["files"]:
                changed = changed_lines.get(relative, {"added": set(), "removed": set()})
                final_file = repository / relative
                final_lines = source_file_lines(final_file) if final_file.is_file() else set()
                surviving_added = changed["added"] & final_lines
                surviving_removed = changed["removed"] - final_lines
                evidence.append(
                    {
                        "path": relative,
                        "commit_added_lines": len(changed["added"]),
                        "commit_removed_lines": len(changed["removed"]),
                        "surviving_added_lines": len(surviving_added),
                        "surviving_removed_lines": len(surviving_removed),
                        "aosp16": commit_target_evidence(
                            aosp16_root,
                            project,
                            relative,
                            surviving_added,
                            surviving_removed,
                        ),
                        "android16": commit_target_evidence(
                            android16_root,
                            project,
                            relative,
                            surviving_added,
                            surviving_removed,
                        ),
                    }
                )
            commit["evidence"] = evidence
    result["non_merge_commit_count"] = len(commits)
    result["product_signal_commit_count"] = sum(
        commit["product_signal"] for commit in commits
    )
    if not commits:
        result["changed_file_count"] = 0
        result["excluded_reason"] = "no-a13-branch-delta"
        return result

    file_refs: dict[str, list[str]] = defaultdict(list)
    for commit in commits:
        for path in commit["files"]:
            file_refs[path].append(commit["commit"])
    custom_paths = sorted(file_refs)

    numstat_raw = run(
        repository,
        "git",
        "diff",
        "--no-renames",
        "--numstat",
        "-z",
        f"{baseline}..HEAD",
        "--",
        *custom_paths,
    ).stdout
    numstat = parse_numstat(numstat_raw)
    result["changed_file_count"] = len(numstat)
    if not numstat:
        return result

    patch = git_text(
        repository,
        "diff",
        "--no-renames",
        "--unified=0",
        "--no-color",
        f"{baseline}..HEAD",
        "--",
        *custom_paths,
    )
    additions = parse_added_lines(patch)
    result["commits"] = commits
    files: list[dict[str, Any]] = []
    for relative, stats in sorted(numstat.items()):
        a13_file = repository / relative
        entry: dict[str, Any] = {
            "path": relative,
            **stats,
            "a13_exists": a13_file.is_file(),
            "a13_sha256": sha256(a13_file) if a13_file.is_file() else None,
            "commit_refs": file_refs.get(relative, []),
        }
        if a13_file.is_file():
            added = additions.get(relative, set())
            entry["aosp16"] = target_state(
                aosp16_root, project, relative, a13_file, added
            )
            entry["android16"] = target_state(
                android16_root, project, relative, a13_file, added
            )
        else:
            entry["aosp16"] = {"classification": "a13-file-deleted"}
            entry["android16"] = {"classification": "a13-file-deleted"}
        files.append(entry)
    result["files"] = files
    return result


def summarize(projects: list[dict[str, Any]]) -> dict[str, Any]:
    changed = [project for project in projects if project.get("changed_file_count")]
    aosp = Counter()
    android = Counter()
    missing_both = 0
    for project in changed:
        for item in project.get("files", []):
            ac = item["aosp16"]["classification"]
            tc = item["android16"]["classification"]
            aosp[ac] += 1
            android[tc] += 1
            weak = {"project-missing", "file-missing", "low-line-coverage"}
            if ac in weak and tc in weak:
                missing_both += 1
    return {
        "a13_projects": len(projects),
        "projects_with_errors": sum(bool(project.get("errors")) for project in projects),
        "changed_projects": len(changed),
        "changed_files": sum(project.get("changed_file_count", 0) for project in changed),
        "aosp16_classifications": dict(sorted(aosp.items())),
        "android16_classifications": dict(sorted(android.items())),
        "low_or_missing_in_both": missing_both,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--a13-root", type=Path, required=True)
    parser.add_argument("--aosp16-root", type=Path, required=True)
    parser.add_argument("--android16-root", type=Path, required=True)
    parser.add_argument("--base-tag", default=DEFAULT_TAG)
    parser.add_argument("--jobs", type=int, default=12)
    parser.add_argument(
        "--scope", choices=("all", "submodules", "root"), default="all"
    )
    parser.add_argument(
        "--project",
        action="append",
        dest="projects",
        help="limit submodule audit to this exact project path; repeat as needed",
    )
    parser.add_argument(
        "--commit-detail",
        action="store_true",
        help="record surviving added/removed line evidence for every A13 commit",
    )
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    a13_root = args.a13_root.expanduser().resolve()
    aosp16_root = args.aosp16_root.expanduser().resolve()
    android16_root = args.android16_root.expanduser().resolve()
    payload = {
        "schema_version": 4,
        "mode": "a13-port-coverage",
        "scope": args.scope,
        "identities": {
            "a13": tree_identity(a13_root),
            "aosp16": tree_identity(aosp16_root),
            "android16": tree_identity(android16_root),
        },
        "requested_base_tag": args.base_tag,
    }
    if args.scope in {"all", "submodules"}:
        paths = submodule_paths(a13_root)
        if args.projects:
            requested = set(args.projects)
            unknown = sorted(requested - set(paths))
            if unknown:
                parser.error(f"unknown A13 project path(s): {', '.join(unknown)}")
            paths = [path for path in paths if path in requested]
        with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as executor:
            projects = list(
                executor.map(
                    lambda project: inspect_project(
                        a13_root,
                        aosp16_root,
                        android16_root,
                        project,
                        args.base_tag,
                        args.commit_detail,
                    ),
                    paths,
                )
            )
        payload["summary"] = summarize(projects)
        payload["projects"] = projects
    if args.scope in {"all", "root"}:
        payload["root_payload"] = inspect_root_payload(
            a13_root, aosp16_root, android16_root, args.jobs
        )
    output = args.output.expanduser()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    result_summary = payload.get("summary", {})
    if "root_payload" in payload:
        result_summary = {
            **result_summary,
            "root_payload": {
                key: value
                for key, value in payload["root_payload"].items()
                if key != "files"
            },
        }
    print(json.dumps(result_summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
