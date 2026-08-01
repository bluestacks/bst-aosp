# Android 16 Patch Review

> **Correction, 2026-07-31:** this review was written before the first
> promotion candidate was withdrawn. References to qvirt as the current board
> or PR #1 as accepted are historical. Windows now targets
> `android_x86_64`; current decisions and newly confirmed omissions are tracked
> in
> [the rework audit](../development-history/android16-merge/rework-audit.md).

The rework added a dedicated review for the five product-referenced HAL
repositories that were missing from the first root candidate:
[`review-hardware-bst.md`](review-hardware-bst.md).

## 1. Scope

This directory reviews every `.patch` and `.diff` artifact under
`patches/android-16/` as of 2026-07-30:

- 82 patch artifacts, 6.97 MiB in total: 81 in the primary patch archive and
  one nested diagnostic patch in the untracked source payload.
- AOSP16 project snapshots.
- Phase 2 Android 13/AOSP16 functional overlays.
- Framework surgical patches and cross-project mechanical patches.
- Companion `app-player`, `hd` and `goldfish-opengl-pie` patches.
- Aggregate, failed, reverted and superseded patches. These remain in the
  inventory because they are part of the migration history.

The review evaluates the archived artifact. It does not assume that applying
the artifact verbatim produces the current `android-16` tree. Current code may
contain a rebased implementation, a smaller replacement, or a later fix.

## 2. Documents

| Document | Coverage |
|---|---|
| [Patch inventory](patch-inventory.md) | Generated SHA-256, line/file statistics, changed paths, registry links and overlap edges |
| [Primary snapshots](review-primary-snapshots.md) | 24 AOSP16 project and host/graphics companion patches |
| [Framework surgical patches](review-framework-surgical.md) | 30 core/app, WM, service and peripheral patches |
| [System and runtime patches](review-system-runtime.md) | 22 bionic, ART, external and cross-project mechanical patches |
| [Aggregate snapshots](review-aggregate-snapshots.md) | 5 Batch A/B source or candidate bundles |
| [Payload review](review-payloads.md) | The nested 82nd patch plus kernel, BootImage and untracked source/binary payloads that are patch-equivalent |
| [Machine inventory](patch-inventory.json) | Structured form of the generated inventory |

Regenerate the inventory after adding or replacing an artifact:

```bash
python scripts/generate_android16_patch_inventory.py
```

## 3. Status Vocabulary

| Status | Meaning |
|---|---|
| `required` | Needed for the current `android_x86_64`/BST boot or a declared host-guest contract |
| `conditional` | Needed only when the corresponding product feature is enabled |
| `optional` | Compatibility, telemetry or presentation feature; boot does not depend on it |
| `temporary` | Bring-up bypass or diagnostic code; must have an owner and removal condition |
| `superseded` | Historical artifact replaced by a safer or Android 16-native implementation |
| `rejected` | Known regression, invalid API mapping or unsafe replay |
| `audit-only` | Source snapshot used to understand intent; never replay as one patch |

Integration status and necessity are separate. A patch can be integrated but
still be temporary or unnecessary for a production image.

## 4. Review Severity

- **P0**: security boundary disabled, unbounded hot-path cost, data corruption,
  or a patch known to break boot.
- **P1**: contract or correctness risk, broad fail-open behavior, fragile build
  dependency, or synchronous Binder/file work on a frequent path.
- **P2**: maintainability, diagnostics, excessive logging, weak gating, or
  missing focused tests.
- **P3**: style and cleanup that does not affect behavior.

## 5. Cross-Cutting Findings

### P0: security bypasses are mixed with functional changes

`aosp16__system_core.patch`, `aosp16__system_security.patch`,
`P2-MECH-6-adb.diff` and `P2-MECH-19-bionic-propsvc.diff` alter SELinux,
keystore permissions, ADB policy or process-visible properties. They must not
be reviewed as ordinary emulator compatibility code.

Required action:

1. Keep the intended permissive-product policy explicit at the product layer.
2. Remove unconditional property-service and keystore permission bypasses.
3. Gate ADB extensions behind an authenticated host contract.
4. Add tests that compare system, shell and untrusted-app callers.

### P0: aggregate patches are not replay units

The large `aosp16__frameworks_base.patch` and the Batch A/B artifacts overlap
dozens of later surgical patches. Earlier whole-jar testing caused
`system_server` regressions. Replaying these artifacts after surgical patches
can silently restore reverted code.

Only the documented project commits or the final surgical patch sequence are
valid replay sources.

### P1: frequent paths contain synchronous service lookups

Several Display, Resources, Settings, telephony, input and camera hooks perform
`ServiceManager`/Binder calls from APIs that applications call frequently.
Null checks prevent crashes but do not prevent latency or Binder contention.

Recommended pattern:

- cache the manager or immutable decision;
- invalidate on package/profile change;
- never perform file I/O or reflection per frame;
- keep a property kill switch for every hot-path override.

### P1: anti-detection changes alter public Android semantics

Telephony, Wi-Fi, system-property, input-device and accessibility patches
return synthetic data. These changes are sometimes a product requirement, but
they can violate API permission semantics and confuse system components.

Use UID/package gating and return synthetic values only to untrusted
third-party callers. `P2-FW-PERIPH-3b.diff` is the negative example; its
unconditional override was superseded by the UID-gated patch.

### P1: build behavior depends on hidden environment contracts

The current graphics selection can require `ALLOW_MISSING_DEPENDENCIES=true`.
`build/soong` also changes `mm`/`mmm` to no-dependency modes and scans
out-of-tree Android.mk files. These are not equivalent to a clean full build.

CI must declare:

- target and `OUT_DIR`;
- external `HD_SOURCE_TOP`/graphics source paths;
- whether missing dependencies are allowed;
- the exact graphics implementation selected;
- a clean-build gate that does not rely on incremental artifacts.

### P2: diagnostics remain in replay artifacts

Several patches force kernel log levels, emit high-volume `A16DBG` records, use
hard-coded user paths, or retain bring-up comments. Diagnostics were valuable
for boot discovery but are not production behavior.

## 6. Performance Evaluation Rules

| Grade | Interpretation |
|---|---|
| `none` | Build-only, one-time boot work, or constant-time branch outside a hot path |
| `low` | Cached property read or infrequent Binder call |
| `medium` | Synchronous Binder/reflection/logging in an app or system-service warm path |
| `high` | File or `/proc` I/O, allocation, service lookup or repeated polling in a hot path |

Performance conclusions are code-path assessments, not benchmark results.
Layer2 7/7 proves boot behavior, not frame time, Binder latency, memory use or
power consumption.

## 7. Necessity Baseline

Required for the current product:

- `android_x86_64` product/device definition and boot filesystem assembly;
- kernel and initrd contract;
- core APEX/linker bootstrap;
- BST hostcall/gcall IPC;
- selected graphics stack and VINTF declarations;
- launcher ownership and shutdown/data-integrity path.

Conditional:

- app compatibility profiles, fake telephony/Wi-Fi identity, camera rotation,
  IME synchronization, shared-folder access and property filtering.

Optional:

- telemetry, affiliate/referrer manipulation, IAP redirection, game-specific
  preference defaults and convenience UI behavior.

Temporary or rejected:

- unconditional security bypasses;
- broad VINTF/HAL bypasses;
- unconditional public-API spoofing;
- whole-tree/whole-framework replay patches that have surgical replacements.

## 8. Validation Required Before Release

1. Clean build with the documented environment and no stale output.
2. Patch-to-commit readback for every `required` artifact.
3. Layer2 boot oracle 7/7 from clean Data.
4. SELinux, keystore, ADB and Binder permission tests.
5. Telephony/Wi-Fi/accessibility behavior tests for system and app UIDs.
6. Frame-time and Binder-latency sampling with compatibility features enabled
   and disabled.
7. Reproducible packaging without hard-coded `/home/<user>` paths.
