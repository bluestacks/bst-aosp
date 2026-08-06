# Review and Evidence Contract

## Required Identity

Every build or validation record binds:

| Field | Requirement |
|---|---|
| tree | Resolved absolute source root |
| branch | Non-detached branch |
| source commit | Full project/root SHA |
| dirty state | Zero for an accepted build; freeze records a patch identity before integration |
| OUT_DIR | Resolved output directory under the same tree |
| product | Lunch product and variant |
| artifact | Absolute artifact path |
| artifact identity | SHA-256; retain legacy MD5 only for historical comparison |
| validation | Exact command, exit code, timestamps, and independent readback |

The maintained Android-16 scripts emit `.identity` sidecars carrying these
fields. Deployment verifies the transferred Root image against that sidecar.

## Review Base

- Historical AOSP16 port: its recorded Android 16 upstream/fork point.
- Promotion: the Android-16 project state before AOSP16 content was applied.
- Current mainline work: `aosp16-bst` or the explicitly recorded work-unit fork
  point.

Review includes commits plus tracked and untracked working-tree changes. If a
base cannot be established, the report must state that it covers only the
working tree.

## Severity

- P0: credential exposure, unrecoverable corruption, or broad old-source
  replacement.
- P1: build/boot correctness, wrong-tree validation, swallowed failure, or
  host-guest contract risk.
- P2: maintainability, reproducibility, stale process, or broken navigation.
- P3: duplication, naming, storage, or documentation quality.

## Completion

A work unit is complete only when its required gate passes by readback. A
missing remote build or boot gate is reported as pending; it is not converted
into a local pass.

For BlueStacks guest validation, host `[Ready]` is only one startup oracle. An
accepted run must also keep HD-Adb online and preserve the guest boot ID and
`system_server` PID for at least 95 seconds after HOME launch. Watchdog or
zygote/system-server restart evidence overrides earlier ready and
`sys.boot_completed=1` markers.
