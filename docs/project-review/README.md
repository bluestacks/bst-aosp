# Repository-Wide Project Review

This review treats the validated AOSP16 line as the primary development record and
the AOSP16-to-Android-16 work as a promotion into the mainline integration tree.

## Generated Artifacts

- [`inventory.json`](inventory.json): authoritative per-file machine inventory.
- [`inventory.md`](inventory.md): human-readable file index.
- [`findings.md`](findings.md): P0-P3 generated findings and actions.
- [`inventory.schema.json`](inventory.schema.json): inventory contract.
- [`validation.md`](validation.md): full Python, JSON, Bash, and PowerShell static validation.
- [`baseline.md`](baseline.md): immutable worktree identity captured before this review.
- [`security.md`](security.md): secret-material disposition and rotation requirement.
- [`scripts.md`](scripts.md): active and historical script classification.
- [`documents.md`](documents.md): documentation source-of-truth and conflict review.
- [`patches.md`](patches.md): patch, payload, and checkpoint review map.
- [AOSP16 timeline](../development-history/aosp16/timeline.md).
- [Android-16 promotion timeline](../development-history/android16-merge/timeline.md).
- [Patch traceability](../development-history/android16-merge/patch-traceability.md).

## Current Snapshot

- Inventory entries: **1046**
- Existing files: **1045**
- Text lines: **333089**
- Stages: `android16-promotion`=34, `aosp16-development`=842, `generated`=35, `reference`=87, `shared`=48
- Findings: P2=1, P3=25

Regenerate with:

```bash
python scripts/generate_project_review.py
```
