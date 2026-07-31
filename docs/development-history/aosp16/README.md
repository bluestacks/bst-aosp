# AOSP16 Development Line

AOSP16 is the primary development and validation line, not a disposable
predecessor. It records how the Android 16 guest became buildable, packable, and
bootable under the BlueStacks host contract before promotion into the
`android-16` mainline tree.

## Record Map

- [`timeline.md`](timeline.md) indexes every development and boot-debug heading.
- [`final-green-baseline.md`](final-green-baseline.md) identifies the last fully
  evidenced AOSP16 build, package, deployment, and boot state.
- [`failures-and-decisions.md`](failures-and-decisions.md) preserves failed
  hypotheses and the decisions that replaced them.
- [`../../../progress/porting-log.md`](../../../progress/porting-log.md) is the
  append-only implementation chronology.
- [`../../../progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md)
  contains the detailed R1-R177 runtime-staging investigation.
- [`../../../patches/android-16/RESTORE.md`](../../../patches/android-16/RESTORE.md)
  and the G1 checkpoints describe recovery from archived patches.
- [`../../android-16-patch-review/README.md`](../../android-16-patch-review/README.md)
  contains code, necessity, performance, and replay-risk review for the patch
  archive.

## Development Phases

| Phase | Purpose | Evidence |
|---|---|---|
| Environment and source triage | Establish correct Android 13 sources, submodule branches, BlueStacks device/HAL deltas, and the Android 16 base | porting log Phase 0 and setup records |
| Runtime-staging bring-up | Diagnose init, APEX, linker, ART, odsign, keystore, zygote, graphics, and host-state failures through R1-R177 | archived boot-debug timeline |
| Source-built G1 baseline | Replace runtime overlays with a source-built `bst_x86_64` guest and authoritative stage/package/deploy flow | G1 and G1-RESTORE checkpoints |
| G2-G10 and Phase 2 | Port boot-minimal groups, framework/system behavior, mechanical modules, and deferred features | patch registry and cont.4-cont.101 |
| Green-line freeze | Record commits, generated patches, artifact hashes, and Layer 2 7/7 before promotion | cont.101 and patch inventory |

## Preservation Rules

- Historical `~/aosp16` paths remain unchanged in the original scripts and
  logs; they identify the tree used by that development step.
- Failed scripts and rejected aggregate patches remain available with explicit
  status. They must not be silently repaired into evidence that never existed.
- AOSP16 build products are provenance records only. Current Android-16 builds
  must not consume or fall back to them.
- A conclusion is valid only when linked to build output, artifact identity, or
  independent boot readback.
