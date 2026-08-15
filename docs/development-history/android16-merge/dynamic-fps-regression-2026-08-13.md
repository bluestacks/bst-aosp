# Dynamic-FPS Regression on EmuHWC2, 2026-08-13

This record tracks the **repeatable dynamic-FPS regression** named as
Current Gate #1 in
[`formal-regression-followup-2026-08-12.md`](formal-regression-followup-2026-08-12.md).
It covers: root cause (verified by remote source readback), the guest graphics
fix (committed, Layer 1 green), and the **packager-level blocker** that
prevented Layer 2 (boot/FPS oracle) from running this session.

No A13 build or runtime validation was run for the FPS oracle itself. Layer 1
(guest graphics incremental compile) is green; Layer 2 (repackage + FPS oracle)
is blocked by the packager `m` non-idempotency documented below.

## 2026-08-15 Successor Status

This document is retained as the first diagnosis and failed packaging record;
its commit identity, polling implementation, and Layer 2 blocker are no longer
the current solution.

- Goldfish commit `71ef0ac1` was superseded by
  `a899e765559bdbddf07270675410a106c70e0c47` on
  `bst-v5.22.210-A16`.
- The final implementation reads `bst.max_fps` at most once per second while
  vsync is enabled, rather than once per vsync tick. It updates the active
  config period, splits periods of one second or more correctly between
  `timespec.tv_sec` and `tv_nsec`, and invokes Refresh after releasing both
  the display and callback-map locks.
- The authoritative patch was regenerated from the final commit and is still
  `patches/android-16/patches/aosp16__goldfish-opengl-pie__emuhwc2-bst-max-fps.patch`.
- The old wrapper sequence that rebuilt `m init systemimage kernel` and then
  compared a stale graphics identity was removed. The active wrapper delegates
  to the canonical app-player incremental/package-only flow, keeps the Android
  OUT, and verifies the final packaged providers against that OUT.
- The one requested clean Android build and the subsequent incremental build
  completed successfully. Formal packaged FPS runtime results belong to the
  2026-08-15 successor record, not to the historical blocker section below.

The remaining sections intentionally preserve what was observed on August 13
and should be read as superseded development history.

## Scope And Identity

| Item | Identity |
| --- | --- |
| Android-16 tree | `/home/clouddev/bst/workspace/markxu/android-16` |
| Root branch and commit | `aosp16-bst-merge` at `ddc1eeba951ccddea52ef1937138facdf3241909` |
| Product and output | `android_x86_64`, `out_nxt_Baklava64` |
| Goldfish branch and commit | `bst-v5.22.210-A16` at `71ef0ac105ca362d5377d19380a28662150942f2` (FPS fix) |
| Active HWC2 provider | goldfish `system/hwc2/EmuHWC2` (staged as `hwcomposer.default.so`) |

## The Regression (unchanged from the formal follow-up)

`bst.max_fps` readback changes 60 to 30, but SurfaceFlinger Scheduler's
`app duration` stays at 16,666,666 ns instead of moving to about 33,333,333 ns.
The active `hwcomposer.default.so` is staged from external goldfish
`system/hwc2/EmuHWC2`, which has no `bst.max_fps` observer and emits no refresh
callback when the property changes.

## Root Cause (verified by remote source readback)

The A13-validated FPS mechanism has **two halves**, and **both are already
present in the A16 tree** — but the active HWC path was missing its half:

| layer | file | A13 | A16 |
| --- | --- | --- | --- |
| SurfaceFlinger reads prop | `frameworks/native/.../Scheduler/Scheduler.cpp:872` (`resyncToHardwareVsyncLocked`) | yes | yes (already ported) |
| HWC polls prop | `hardware/interfaces/.../hwc2onfbadapter/HWC2OnFbAdapter.cpp:962` (`VsyncThread::syncFpsWithConfigLocked`, commit `bf800caa`) | yes | yes (already ported) |

The framebuffer-adapter FPS polling (`HWC2OnFbAdapter`) is on the
**framebuffer-adapter HWC path, which is INACTIVE on this board**. The active
HWC is goldfish `EmuHWC2`, which had **zero** `bst.max_fps` handling (confirmed:
`grep bst.max_fps` across the entire `goldfish-opengl-pie` tree returns empty).

Three concrete defects in `system/hwc2/EmuHWC2.cpp` (1439 lines):

1. `Display::mVsyncPeriod` (uint32_t, `EmuHWC2.h:322`) is initialized to
   `1000*1000*1000/60` = 16,666,666 ns (line 408) and never changes.
2. `VsyncThread::threadLoop()` reads `mVsyncPeriod` into `wait_time.tv_nsec`
   **once before the loop** (line 1171) and never re-reads it, so even changing
   `mVsyncPeriod` would not change the sleep cadence.
3. Only the **Vsync** callback fires (line 1198). The **Refresh** callback is
   registered (`Callback::Refresh`, line 322) but never invoked, so
   SurfaceFlinger is never told to re-query `getDisplayAttribute(VsyncPeriod)`.

`BST_ANDROID16_GUEST` is `true` for this A16 guest build
(`goldfish-opengl-pie/Android.mk:43-48`: set when `PLATFORM_SDK_VERSION==36` and
guest build; added to `EMUGL_COMMON_CFLAGS` at line 87). A live
`#ifdef BST_ANDROID16_GUEST` stub already existed in `threadLoop` at line 1164
(a prior attempt had started here).

## The Fix (committed)

`system/hwc2/EmuHWC2.cpp` + `EmuHWC2.h`, +78 lines, all under
`#ifdef BST_ANDROID16_GUEST` (A13/host builds unaffected). Mirrors
`HWC2OnFbAdapter::syncFpsWithConfigLocked`:

1. New `VsyncThread::syncBstMaxFpsLocked()` (caller holds `mDisplay.mStateMutex`):
   reads `bst.max_fps` (valid only for `>0 && <=240`), computes
   `1e9/maxFps`, and on change updates `mDisplay.mVsyncPeriod` **and** the active
   config's `VsyncPeriod` attribute (so `getDisplayAttribute` observes it).
2. `threadLoop` calls it each tick and **re-reads `wait_time.tv_nsec` inside the
   loop** (fixes defect #2).
3. On period change, fires the registered `Callback::Refresh` **outside**
   `mStateMutex` (per the formal follow-up constraint) so SurfaceFlinger
   re-queries and recomputes its vsync config.
4. `A16DBG:HWC2:` instrumentation (`bst.max_fps=<n> period <old>-><new>` and
   `fire Refresh`), paired, grep-able in logcat.

Constraints honored (from the formal follow-up): observer on the active
`EmuHWC2` only; publish via the existing display attribute; refresh callback
outside locks; no new HWC; no Windows board change; no unbounded polling.

**Committed:** goldfish `bst-v5.22.210-A16` at `71ef0ac105ca362d5377d19380a28662150942f2`
("[A16] Add dynamic-FPS observer to active EmuHWC2"). Local patch:
`patches/android-16/patches/aosp16__goldfish-opengl-pie__emuhwc2-bst-max-fps.patch`.

## Layer 1 — guest graphics incremental compile: GREEN

`BST_OUT_DIR_NAME=out_nxt_Baklava64 BST_GOLDFISH_OPENGL_ROOT=~/app-player/ggl/goldfish-opengl-pie bash ~/bst-aosp/scripts/g1_rebuild_graphics.sh build`
→ `#### build completed successfully ####`, no ABI break
(`header-abi-diff` clean), no compile errors. The FPS-patched
`hwcomposer.default.so` is staged to `~/releases/Baklava64/system/vendor/{lib,lib64}/hw/`
(lib sha `46917524…`, lib64 sha `161e671a…`) and is present in the
`out_nxt_Baklava64` product tree (sha `161e671a…`). Build identity written with
`graphics_head=71ef0ac1`.

## Layer 2 — repackage + FPS oracle: BLOCKED

The FPS oracle already exists and is correct:
[`scripts/g1_fps_regression.ps1`](../../../scripts/g1_fps_regression.ps1). It
sets `bst.max_fps` (default 30), reads SurfaceFlinger `app duration` via
`dumpsys SurfaceFlinger`, asserts it is within 8% of `1e9/fps` (so at fps=30 it
requires ~33,333,333 ns — exactly what the fix produces), checks bounded CPU,
checks SF/composer stability, and restores the original fps in `finally`. This
oracle is exactly what the fix must pass; **no oracle work remains**.

Layer 2 is blocked because the **packager cannot complete the repackage**:
`g1_build_app_player.sh --incremental` runs `m init systemimage kernel`, then
`g1_rebuild_graphics.sh --stage-only` (which calls `bst_verify_identity_file`
comparing the recorded `system.img` sha to the current `system.img`), then
`make vbox`. The `--stage-only` identity check **fails on every run**.

### Blocker: `m init systemimage kernel` is not idempotent — `system.img` sha changes every run

Observed across 5 packager runs: each `m init systemimage kernel` **rebuilds
`system.img`**, changing its sha. The identity file (written by the graphics
build's `build` mode, recording the `system.img` sha at that instant) is
therefore stale by the time `--stage-only` verifies it, regardless of how or
when the identity is regenerated. Examples (all on a stable, committed tree,
goldfish unchanged at `71ef0ac1`):

| run | `system.img` sha (short) | mtime |
| --- | --- | --- |
| graphics build (01:07) | `66c91dbc…` | 00:48 |
| packager #4 (01:29) | `f469c64c…` | 01:29 |
| packager #5 (10:51) | `bf6f118a…` | 10:51 |

The proximate trigger is a kernel `restat` gap surfaced by ninja each run:

```
ninja: Missing `restat`? An output file is older than the most recent input:
 output: out_nxt_Baklava64/target/product/x86_64/obj/kernel/include/generated/rustc_cfg
  input: out_nxt_Baklava64/target/product/x86_64/obj/kernel/arch/x86/boot/bzImage
```

`rustc_cfg` (mtime 22:38) is older than `bzImage` (mtime 12:15). Ninja rebuilds
the kernel, which cascades into a `systemimage` rebuild, which regenerates
`system.img` with a new sha. Because the kernel intermediates' relative mtimes
do not settle between runs, `m init systemimage kernel` rebuilds `system.img`
**every time**.

This is a real stability defect in the packager's `m` step, not an artifact of
the FPS change: the FPS-patched `hwcomposer.default.so` sha (`161e671a…`) is
itself stable across runs; the `system.img` churn is driven entirely by the
kernel `restat` gap.

### Why the `--stage-only` design cannot tolerate this

`g1_rebuild_graphics.sh --stage-only` (lines 87-91) calls
`bst_verify_identity_file` with the current `system.img`, which recomputes its
sha and compares to the recorded `artifact_sha256`. The identity is written by
the `build` mode at a single instant; if `m` changes `system.img` afterward,
the check fails with `artifact SHA-256 mismatch`. There is no way to make the
identity "catch up" because regenerating it requires running graphics `build`
(which re-runs `mmm`, touching the product tree and triggering yet another
`system.img` rebuild on the next `m`).

### Compounding session issue (resolved, recorded for completeness)

During this session a prior-session runaway `grep -R ... ~` (PID 543254, 23h)
plus a stray remote `find` orphan from this session (PID 2900516, a child that
survived a local `TaskStop`) starved clouddev disk IO (load ~2000, 2000+ D-state)
and corrupted a ninja frontend fifo (`FAILED: Got error reading from ninja:
unexpected EOF` / `proto: cannot parse invalid wire-format data`) in an earlier
`m` run. Both strays were killed; the disk recovered; the fifo corruption did
not recur in later runs. See memory `[[a16-remote-stray-children]]`.

## Open Items / Gates

1. **Resolve the `m init systemimage kernel` non-idempotency** (kernel
   `rustc_cfg`/`bzImage` restat gap → `system.img` churns every run). This is
   the single blocker for completing the FPS repackage. Candidate fixes (need
   human decision — packager build-flow semantics): (a) make the kernel target
   `restat=1` so `rustc_cfg` settles; (b) stop the packager's `m` from including
   `kernel` when only graphics/system changed; (c) relax
   `bst_verify_identity_file` to not bind to `system.img` sha for the
   `--stage-only` graphics gate (verify graphics closure sha instead). **This is
   a build-flow judgment call → escalate.**
2. After (1): `g1_build_app_player.sh --incremental` produces Root.vhd/fastboot.vdi,
   deploy on win, boot to launcher, run `scripts/g1_fps_regression.ps1`
   (setprop 30 → assert SF `app duration` ~33.3ms → restore 60). Expect
   `A16DBG:HWC2: bst.max_fps=30 period 16666666->33333333` + `fire Refresh` in
   logcat.
3. The other Current Gates from `formal-regression-followup-2026-08-12.md`
   remain unchanged (intermittent CPU3 RCU stall; Hyper-V shared-folder +
   Windows IME contracts; VBox 6.12 source formalization; GMS/native-bridge app
   gates).

## Files / artifacts

- Fix commit: goldfish `bst-v5.22.210-A16` `71ef0ac1`
- Local patch: `patches/android-16/patches/aosp16__goldfish-opengl-pie__emuhwc2-bst-max-fps.patch`
- FPS oracle (ready, unblocked once repackage works): `scripts/g1_fps_regression.ps1`
- Packager (the blocker): `scripts/g1_build_app_player.sh` (`m init systemimage kernel` at line 260; `--stage-only` graphics at line 309; identity verify in `scripts/lib/android16_env.sh` `bst_verify_identity_file`)
- Remote build logs (clouddev): `~/g1_rebuild_graphics_fps*.log`, `~/g1_pack_fps_repackage*.log`
