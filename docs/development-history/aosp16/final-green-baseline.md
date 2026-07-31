# AOSP16 Final Green Baseline

The final pre-promotion AOSP16 baseline is the cont.101 completion loop recorded
on 2026-07-26. It is the development-line freeze point for promotion analysis,
not a generic upstream Android 16 tag.

## Identity

| Item | Evidence |
|---|---|
| Source tree role | Validated AOSP16 BlueStacks development line |
| Product | `bst_x86_64` / `qvirt` |
| Build | `m droid` returned 0; `system.img` MD5 prefix `a878d3c8` |
| Stage | vendor 473, system_ext 70, product 114 files folded into the staged system |
| Root image | MD5 `02690d1182ff507faedb1c5e438806f4` |
| Root UUID | `54e9ad31-a169-4d5b-a0e0-705d62e96e71` |
| Layer 2 | 7/7 at 161 seconds |
| Oracles | system mounted, second-stage init, odsign, boot completed, activity displayed, player ready, boot progress hidden |

Primary evidence:
[`progress/porting-log.md:2419-2435`](../../../progress/porting-log.md#L2419).

## Final Explicit Commits

- `c581b1bae8`: frameworks/native Binder implementation and Android 16
  mechanical fixes.
- `00274255beb7`: frameworks/base subscription behavior.
- `2cf8a0cf64c5`: frameworks/base pagefusion page-size adaptation.

The corresponding archived artifacts are
`aosp16__frameworks_native_libs_binder.patch`,
`aosp16__frameworks_base__d8-subscription.patch`, and
`aosp16__frameworks_base__pagefusion.patch`.

## Earlier Reproducible G1 Baseline

The G1 checkpoint remains the minimum source-built recovery baseline:

- G1 Root MD5 `2a7a497afd48a595758bba026faf55ae`.
- DIAG-closed Root MD5 `503235fc18bcb0f6ca9a32568de889e0`.
- `system.sfs` MD5 `5e151f429b2677b895b2464a8b7f6a57`.
- `system.img` MD5 `fd910a81595badb92b0de83072a82ee1`.

See
[`patches/android-16/checkpoints/G1-RESTORE.md`](../../../patches/android-16/checkpoints/G1-RESTORE.md).

## Freeze Caveat

Cont.101 recorded 16 frameworks/base files whose verified runtime content was
not yet represented by project commits. Promotion therefore cannot trust only
the three commits above: the patch archive, working-tree snapshots, registry,
and later 31-project promotion audit are all required to reconstruct the
validated source state.
