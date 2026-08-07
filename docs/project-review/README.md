# Repository-Wide Project Review

This review treats the validated AOSP16 line as the primary development record and
the AOSP16-to-Android-16 work as a promotion into the mainline integration tree.

## Generated Artifacts

- [`inventory.json`](inventory.json): per-file inventory with explicit authority and availability.
- [`inventory.md`](inventory.md): human-readable file index.
- [`binary-retention.md`](binary-retention.md): byte-retention decision for every binary-like record.
- [`binary-local-evidence.json`](binary-local-evidence.json): observed identities for ignored local binaries.
- [`binary-artifact-staging.json`](binary-artifact-staging.json): deterministic archive identities awaiting publication.
- [Binary artifact workflow](../development-workflow/binary-artifacts.md): deterministic external bundle handling.
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

- Inventory entries: **1815**
- Existing files: **1814**
- Text lines: **1346707**
- Stages: `android16-promotion`=637, `aosp16-development`=840, `generated`=15, `reference`=45, `shared`=278
- Availability: `generated`=15, `local-only`=238, `removed-tombstone`=1, `repository`=1561
- Findings: P2=1, P3=239

Regenerate with:

```bash
python scripts/generate_project_review.py
```
