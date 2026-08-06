#!/usr/bin/env python3
"""Generate a one-entry-per-commit A13 promotion review ledger."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


COMPLETE_CLASSES = {
    "complete-line-evidence",
    "complete-removal-evidence",
    "exact-file",
}


def classify(commit: dict[str, Any], project: dict[str, Any]) -> str:
    if project.get("errors"):
        return "baseline-unresolved"
    if commit.get("detail_limited_reason"):
        return "metadata-review"
    evidence = commit.get("evidence", [])
    if not evidence:
        return "no-surviving-final-delta"
    classes = {item["android16"]["classification"] for item in evidence}
    if classes == {"superseded-in-a13"}:
        return "superseded-in-a13"
    if classes <= COMPLETE_CLASSES:
        return "textually-complete"
    return "semantic-review-required"


def evidence_counts(commit: dict[str, Any], tree: str) -> dict[str, int]:
    counts = Counter(
        item[tree]["classification"]
        for item in commit.get("evidence", [])
        if tree in item
    )
    return dict(sorted(counts.items()))


def apply_review_decisions(
    entries: list[dict[str, Any]], decision_path: Path | None
) -> None:
    if decision_path is None:
        return

    payload = json.loads(decision_path.read_text(encoding="utf-8"))
    review_fields = (
        "review_status",
        "manual_disposition",
        "target_commits",
        "rationale",
        "necessity",
        "performance",
        "security",
        "validation_evidence",
    )
    def rule_matches(entry: dict[str, Any], match: dict[str, Any]) -> bool:
        for field, expected in match.items():
            if field == "files_all_prefix":
                files = entry.get("files", [])
                if not files or not all(path.startswith(expected) for path in files):
                    return False
                continue
            if field == "candidate_target_commits_present":
                if bool(entry.get("candidate_target_commits")) != expected:
                    return False
                continue
            values = expected if isinstance(expected, list) else [expected]
            if entry.get(field) not in values:
                return False
        return True

    for rule in payload.get("rules", []):
        matched = 0
        for entry in entries:
            if not rule_matches(entry, rule["match"]):
                continue
            if "review_rule" in entry:
                raise RuntimeError(
                    f"overlapping review rules for {entry['project']} "
                    f"{entry.get('source_commit')}"
                )
            for field in review_fields:
                if field in rule:
                    entry[field] = rule[field]
            if rule.get("target_commits_from_candidates"):
                candidates = entry.get("candidate_target_commits", [])
                if not candidates:
                    raise RuntimeError(
                        f"review rule {rule['id']} requires target candidates for "
                        f"{entry['project']} {entry.get('source_commit')}"
                    )
                entry["target_commits"] = candidates
            entry["review_rule"] = rule["id"]
            matched += 1
        if matched != rule["expected_matches"]:
            raise RuntimeError(
                f"review rule {rule['id']} expected {rule['expected_matches']} "
                f"matches, got {matched}"
            )

    decisions = payload.get("decisions", [])
    entry_by_key = {
        (entry["project"], entry["kind"], entry.get("source_commit")): entry
        for entry in entries
    }
    seen: set[tuple[str, str, str | None]] = set()
    for decision in decisions:
        key = (
            decision["project"],
            decision["kind"],
            decision.get("source_commit"),
        )
        if key in seen:
            raise RuntimeError(f"duplicate review decision: {key}")
        seen.add(key)
        if key not in entry_by_key:
            raise RuntimeError(f"review decision has no ledger entry: {key}")
        if decision.get("review_status", "").startswith("pending-"):
            raise RuntimeError(f"review decision is still pending: {key}")

        entry = entry_by_key[key]
        for field in review_fields:
            if field in decision:
                entry[field] = decision[field]


def apply_target_candidates(
    entries: list[dict[str, Any]], target_map_path: Path | None
) -> int:
    if target_map_path is None:
        return 0

    payload = json.loads(target_map_path.read_text(encoding="utf-8"))
    entry_by_key = {
        (entry["project"], entry.get("source_commit")): entry for entry in entries
    }
    mapped = 0
    for project in payload.get("projects", []):
        for source_commit, target_commits in project.get(
            "explicit_source_refs", {}
        ).items():
            entry = entry_by_key.get((project["source_path"], source_commit))
            if entry is None:
                raise RuntimeError(
                    "target candidate has no ledger entry: "
                    f"{project['source_path']} {source_commit}"
                )
            entry["candidate_target_commits"] = target_commits
            entry["target_identity"] = {
                "path": project["target_path"],
                "head": project["target_head"],
                "baseline": project["target_baseline"],
                "baseline_ref": project["target_baseline_ref"],
            }
            mapped += 1
    return mapped


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--coverage", type=Path, required=True)
    parser.add_argument("--json-output", type=Path, required=True)
    parser.add_argument("--markdown-output", type=Path, required=True)
    parser.add_argument("--decisions", type=Path, action="append", default=[])
    parser.add_argument("--decisions-dir", type=Path)
    parser.add_argument("--target-map", type=Path)
    args = parser.parse_args()

    coverage = json.loads(args.coverage.read_text(encoding="utf-8"))
    entries: list[dict[str, Any]] = []
    for project in coverage["projects"]:
        identity = {
            "source_branch": project.get("a13_branch"),
            "source_head": project.get("a13_head"),
            "source_root_gitlink": project.get("a13_root_gitlink"),
            "source_head_matches_root_gitlink": project.get(
                "a13_head_matches_root_gitlink"
            ),
            "baseline": project.get("baseline"),
            "baseline_method": project.get("baseline_method"),
        }
        if project.get("errors"):
            entries.append(
                {
                    "project": project["path"],
                    "kind": "baseline-boundary",
                    "source_commit": project.get("a13_head"),
                    "source_identity": identity,
                    "errors": project["errors"],
                    "automated_disposition": "baseline-unresolved",
                    "review_status": "pending-baseline-review",
                    "target_commits": [],
                    "validation_evidence": [],
                }
            )
        for commit in project.get("commits", []):
            entries.append(
                {
                    "project": project["path"],
                    "kind": "patch",
                    "source_commit": commit["commit"],
                    "subject": commit["subject"],
                    "author": commit["author"],
                    "author_email": commit["author_email"],
                    "product_signal": commit["product_signal"],
                    "files": commit["files"],
                    "source_identity": identity,
                    "automated_disposition": classify(commit, project),
                    "aosp16_evidence": evidence_counts(commit, "aosp16"),
                    "android16_evidence": evidence_counts(commit, "android16"),
                    "review_status": "pending-semantic-review",
                    "target_commits": [],
                    "validation_evidence": [],
                }
            )
        for commit in project.get("merge_commits", []):
            entries.append(
                {
                    "project": project["path"],
                    "kind": "merge",
                    "source_commit": commit["commit"],
                    "parents": commit["parents"],
                    "subject": commit["subject"],
                    "author": commit["author"],
                    "author_email": commit["author_email"],
                    "source_identity": identity,
                    "automated_disposition": "integration-merge",
                    "review_status": "pending-parent-mapping",
                    "target_commits": [],
                    "validation_evidence": [],
                }
            )

    entries.sort(key=lambda item: (item["project"], item["kind"], item["source_commit"]))
    explicit_candidate_count = apply_target_candidates(entries, args.target_map)
    decision_paths = list(args.decisions)
    if args.decisions_dir:
        decision_paths.extend(
            sorted(args.decisions_dir.glob("a13-review-decisions*.json"))
        )
    unique_decision_paths = list(dict.fromkeys(path.resolve() for path in decision_paths))
    for decision_path in unique_decision_paths:
        apply_review_decisions(entries, decision_path)
    patch_count = sum(entry["kind"] == "patch" for entry in entries)
    merge_count = sum(entry["kind"] == "merge" for entry in entries)
    boundary_count = sum(entry["kind"] == "baseline-boundary" for entry in entries)
    expected = coverage["summary"]
    if patch_count != expected["non_merge_commits"]:
        raise RuntimeError(
            f"patch count mismatch: expected {expected['non_merge_commits']}, got {patch_count}"
        )
    if merge_count != expected["merge_commits"]:
        raise RuntimeError(
            f"merge count mismatch: expected {expected['merge_commits']}, got {merge_count}"
        )
    if boundary_count != expected["projects_with_errors"]:
        raise RuntimeError(
            "baseline-boundary count mismatch: "
            f"expected {expected['projects_with_errors']}, got {boundary_count}"
        )

    dispositions = Counter(entry["automated_disposition"] for entry in entries)
    review_statuses = Counter(entry["review_status"] for entry in entries)
    projects = Counter(
        entry["project"]
        for entry in entries
        if entry["automated_disposition"] in {"semantic-review-required", "baseline-unresolved"}
    )
    output = {
        "schema_version": 1,
        "mode": "a13-patch-ledger",
        "coverage_identity": coverage["identities"],
        "coverage_summary": coverage["summary"],
        "counts": {
            "entries": len(entries),
            "patches": patch_count,
            "merges": merge_count,
            "baseline_boundaries": boundary_count,
            "automated_dispositions": dict(sorted(dispositions.items())),
            "review_statuses": dict(sorted(review_statuses.items())),
            "explicit_target_candidates": explicit_candidate_count,
        },
        "entries": entries,
    }
    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    args.json_output.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    lines = [
        "# A13 Patch Ledger",
        "",
        "This ledger contains one entry for every non-merge and merge commit found on the",
        "A13 `bst-v5.22.210` component branches relative to their selected A13 baselines.",
        "Automated dispositions are triage evidence, not final port or validation claims.",
        "",
        "## Counts",
        "",
        f"- Entries: {len(entries)}",
        f"- Patch commits: {patch_count}",
        f"- Merge commits: {merge_count}",
        f"- Unresolved baseline boundaries: {boundary_count}",
        f"- Explicit A13-to-A16 commit candidates: {explicit_candidate_count}",
        f"- Source-head/root-gitlink mismatches: {expected['a13_head_root_gitlink_mismatches']}",
        "",
        "| Automated disposition | Entries |",
        "| --- | ---: |",
    ]
    lines.extend(f"| `{name}` | {count} |" for name, count in sorted(dispositions.items()))
    lines.extend(
        [
            "",
            "| Review status | Entries |",
            "| --- | ---: |",
        ]
    )
    lines.extend(f"| `{name}` | {count} |" for name, count in sorted(review_statuses.items()))
    lines.extend(
        [
            "",
            "## Semantic Review Queue",
            "",
            "| Project | Pending entries |",
            "| --- | ---: |",
        ]
    )
    lines.extend(f"| `{name}` | {count} |" for name, count in projects.most_common())
    lines.extend(
        [
            "",
            "The machine-readable per-commit identity, file list, evidence classes, target",
            "commit mapping and validation fields are in `a13-patch-ledger.json`.",
        ]
    )
    args.markdown_output.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps(output["counts"], ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
