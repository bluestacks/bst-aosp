# Patch, Payload, and Checkpoint Review

## Coverage

The dedicated [Android 16 patch review](../android-16-patch-review/README.md)
reviews all archived `.patch` and `.diff` artifacts, including primary AOSP16
project snapshots, framework surgical patches, system/runtime changes,
aggregate candidates, companion host/graphics patches, and the diagnostic
nested patch.

[`patch-inventory.json`](../android-16-patch-review/patch-inventory.json)
contains each artifact's SHA-256, size, changed files, additions/deletions,
registry references, overlap edges, binary markers, and review category.
Curated review files add purpose, necessity, security, compatibility, and
performance judgments at patch and hunk-family level.

## Replay Policy

- Project snapshots are review/freeze evidence, not automatically safe replay
  units.
- Aggregate framework and Batch A/B patches overlap later surgical fixes and
  must never be applied after them without an overlap audit.
- A failed or reverted patch remains in the inventory with its status and
  replacement; it is not silently deleted.
- Untracked source and binary payloads are patch-equivalent inputs and are
  reviewed alongside textual diffs.
- Duplicate hashes do not prove redundant semantics. BootImage location,
  initrd layout, and checkpoint identity must be examined first.

## Traceability

[`patch-traceability.md`](../development-history/android16-merge/patch-traceability.md)
joins patch artifact, review category, registry IDs, checkpoint evidence, and
timeline references. The authoritative AOSP16 final-green identity and the
Android-16 promotion outcome are recorded separately so promotion does not
rewrite development history.

Where an artifact has no direct basename mention in a progress heading, the
registry and checkpoint are the semantic evidence. Such records are labeled
`registry-only`, not guessed.

## Security and Performance

Security-affecting system/core, system/security, ADB, property-service, and
keystore changes require independent boundary review. They cannot inherit a
generic emulator-compatibility approval.

Performance grades are static code-path assessments:

- build-only and one-time boot changes have no steady-state runtime cost;
- cached property decisions are low risk;
- synchronous Binder/service lookup in frequently called APIs is medium risk;
- repeated file, `/proc`, reflection, allocation, polling, or logging in hot
  paths is high risk.

Layer 2 7/7 validates boot behavior only. It does not establish frame-time,
memory, power, or Binder-latency parity.

## Credential Disposition

The tracked market-signing keystore was removed from the current tree after its
size and SHA-256 were recorded in [`security.md`](security.md). Existing history
still contains the bytes, so external credential rotation is mandatory. Future
signing uses secure injection; no source-tree fallback is permitted.
