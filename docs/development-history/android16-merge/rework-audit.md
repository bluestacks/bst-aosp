# Android-16 Promotion Rework Audit

> Historical snapshot for root `298403a` and withdrawn PR #2. Later A13
> authority review restored additional behavior, including the full FPS
> callback path. Current decisions and validation debt are recorded in
> [`a13-authority-completion.md`](a13-authority-completion.md); final runtime
> closure is recorded in
> [`runtime-oracle-closure-2026-08-16.md`](runtime-oracle-closure-2026-08-16.md).

## Status

The first promotion candidate was withdrawn on 2026-07-31. GitHub PR
`bluestacks/android-16#1` is closed. Its 7/7 boot result remains useful
historical evidence, but it is not an accepted mainline baseline because a
commit-only freeze omitted working-tree behavior and a later graphics commit
regressed the Android-16 module graph.

The completed rework applied three non-negotiable rules:

- build, stage and validate only `~/android-16` with product
  `android_x86_64`;
- keep unmodified components on `aosp16-bst` and modified components on
  `aosp16-bst-merge`;
- use `[A16] <imperative summary>` for every promotion/mainline commit title.

No `~/aosp16/out*` artifact is an input. The AOSP16 source tree is read-only
evidence for locating committed, staged and untracked development changes.

## Confirmed Omissions

| Area | Omission | Rework decision | Necessity / cost |
|---|---|---|---|
| `frameworks/native` FPS control | The cont.90 green record was not represented by the final AOSP16 source snapshot | Retain only the Scheduler-side `bst.max_fps` VSync configuration update | Optional performance control; one property read on an existing hardware-VSync resync path, with no polling or new callback protocol |
| `hardware/bst/{audio,camera,lights,memtrack,power}` | `device/generic/common` referenced five HAL sources that were absent from the first Android-16 root | Add the missing implementations; after mainline sync keep its inline camera and the other four as submodules | Required for ALSA policy/audio plus four installed legacy HAL modules; include-path changes have no runtime cost and camera API substitutions preserve behavior |
| `external/{alsa-lib,alsa-utils}` | AOSP16 used source/config payloads through app-player metadata but Android-16 had no immutable root pointers | Track both source SHAs and disable their obsolete Make build entry points | Required for provenance and packaging; no runtime code is added to the Android image by these commits |
| `device/generic/x86_64` | Vendor HIDL services had no installed `vndservicemanager` | Add the stock product package; its required modules provide `vndservice` and init/SELinux files | Boot-critical for vendor binder registration; no custom service implementation |

## Reviewed And Rejected Expansion

The first rework pass treated every nearby Android 13 customization as an
omission. A file-level comparison against the actual AOSP16 green tree and the
Windows board inheritance showed that this would enlarge the delta without
green-baseline evidence. The following trial ports were removed:

- broad Settings and Launcher UI changes;
- extra `frameworks/base` service/UI behaviors;
- absolute-mouse handling beyond the retained FPS contract in
  `frameworks/native`;
- ART loader/export expansion;
- OMX, FLAC, camera and media-source additions in `frameworks/av`;
- speculative Unicode, library-symlink and firmware-path changes in
  `system/core`;
- the Android 13 custom `su` implementation in `system/extras`.

The already promoted, independently reviewed AOSP16 changes in those projects
remain. This decision rejects only the additional rework hunks that lacked a
green-baseline or board dependency.

## Structural Regressions

| Finding | Decision |
|---|---|
| `device/bst/qvirt` introduced a second Windows product and coupled mac/win board policy | Remove it. Windows uses `device/generic/x86_64/android_x86_64`; mac remains a separate future product decision. |
| Commit `7c04d2fdc` renamed all 62 `hardware/google/gfxstream` `Android.bp` files | Revert it. Preserve the 25Q4 native gfxstream graph; the external BlueStacks goldfish tree is built separately and selected at the Windows product/staging layer. |
| The r4 `hardware/google/aemu` change removed `gfxstream_defaults` | Revert it to the target baseline so Linux host Vulkan variants remain valid. |
| A later build/soong commit re-added `../ggl/goldfish-opengl-pie/Android.mk` to the main Kati scan | Remove only that entry. Keep HD guest modules in the outside list; build/stage goldfish through the dedicated graphics script so provider names cannot collide. |
| Global `build/make` changes disabled VINTF enforcement, downgraded outside-include errors and moved hwservicemanager | Restore 25Q4 defaults. Keep only the kernel-config extraction capability; retain the existing common-device HD include exception and put package exclusions in the x86_64 product. |
| `system/hwservicemanager` removed the A16 system_ext compatibility symlink | Restore the 25Q4 placement/symlink while retaining the formal manager@1.2 runtime fix. |
| The FPS rework added framebuffer polling and called Scheduler resync from `onComposerHalRefresh()` while SurfaceFlinger held `mStateLock` | Remove the new HWC/refresh callback chain. Keep the cont.90 Scheduler hook, but update VSync configuration directly because its locked caller already owns `mDisplayLock`. |

## Minimal Board Delta

The AOSP16 green tree shows that `bst_x86_64` inherited
`device/generic/common/x86_64.mk`; qvirt changed product identity and added the
hwservicemanager package, AIDL power example, a product VINTF assignment,
graphics properties and four package exclusions. The AOSP16 global build policy
and qvirt both enforce VINTF. Android 16 additionally makes that variable a
read-only global `true`, so the short-lived attempt to force `false` from the
product was both ineffective and a source-level deviation. Android-16 keeps the
native `android_x86_64` identity, records the qvirt `true` policy, adapts only
the obsolete health/keymaster/USB declarations to FCM 8, and transfers the
remaining proven runtime behaviors. The three graphics device-manifest
fragments and narrow FCM 8 bridge are target-only build-graph adaptations for
the separately built legacy goldfish provider. The HD sibling include exception
already belongs to `device/generic/common/BoardConfig.mk` and is not duplicated
in the x86_64 board.

## SurfaceFlinger Lock Review

The first FPS rework created a target-only protocol that was absent from the
final AOSP16 source tree: `HWC2OnFbAdapter` polled `bst.max_fps`, emitted a
refresh callback and made SurfaceFlinger resync hardware VSync while holding
`mStateLock`. Removing that expansion still left a second problem in the
Scheduler-only port: `resyncToHardwareVsyncLocked()` already owns
`mDisplayLock`, but the initial adaptation called `updatePhaseConfiguration()`,
which tries to lock `mDisplayLock` again. With a non-zero host FPS property this
is a deterministic recursive-lock stall during SurfaceFlinger initialization.

The corrected implementation follows the cont.90 intent without broadening the
contract: validate `1..240`, require the pacesetter display, update the existing
VSync configuration under `mVsyncConfigLock`, and never introduce a polling
thread or callback. It has no per-frame property read and no steady-state work
unless the existing hardware-VSync resync path runs.

The five restored HAL implementations are the complete hardware/bst set reached
from that inheritance chain. No other Android 13 hardware repository is added.
They were easy to miss because AOSP16 did not list them in
`.repo/project.list`: their working directories used Git metadata under the
app-player Android 13 module store. The promotion records four as explicit
Android-16 submodules; camera is retained from the updated mainline's inline
source instead of recreating a duplicate gitlink.

A path-set comparison after the additions reports 1011 entries in the AOSP16
`.repo/project.list` and 1022 Android-16 submodules, with no AOSP16 manifest
project missing. The eleven target-only paths are the four submodule HALs above,
`external/{alsa-lib,alsa-utils}`, `bootable/newinstaller`,
`external/{efibootmgr,efivar,syslinux}` and `kernel-a16`; these are explicit
Android-x86/BlueStacks source, packaging or build inputs rather than accidental
source-tree copies.

| Path | AOSP16 source SHA | Android-16 merge SHA | Review |
|---|---|---|---|
| `hardware/bst/audio` | `f4c2a5b71cdaa74ce4fe7bea332931c67515b3c6` | `ac13f7b60680f60a3b0efc031aaa42019be254be` | One build include; runtime audio path unchanged |
| `hardware/bst/camera` | `a87e8be3bd354ab0951ee352c958034be8a0bd20` | inline root commits `ccb6e51`, `33cdca5` | Mainline carries the String8/header adaptation and fixes 64-bit MessageQueue pointer truncation; reviewed fork `16e8482` is publication history, not the final gitlink |
| `hardware/bst/lights` | `31b9fb5f5e2e2d9e3e7aaca748b7eb0b2ba06fbf` | `d7fb147bdaf6c5675ba98c308c0411c8f6762bdd` | Vendor header visibility only |
| `hardware/bst/memtrack` | `b2aa1fc432d7cb1e37cd977161fb033643c65b9c` | `d3596f32d4f042ccbb17653ab84132cfa07080d0` | Header visibility only; dummy implementation unchanged |
| `hardware/bst/power` | `ff0cda46a0cf102e4da2388cc9efb05f79906184` | `2b2e3e1dd69985937d122b400dded54532e8519f` | Header visibility only; retained alongside AIDL hint-session service |

## Cross-Patch Coverage Readback

The re-audit compared every file path in the archived P2 mechanical/framework
patches with `git diff aosp16-bst..working-tree` in the target component. This
is a presence check followed by semantic review, not proof that an old hunk was
copied verbatim.

| Component group | Readback |
|---|---|
| Framework core/app, peripheral, services and WM batches | Previously promoted AOSP16 changes remain; newly inferred surrounding changes were removed unless the green baseline or board graph required them |
| Audio, camera and `IMediaSource` | Existing promoted behavior remains; speculative surrounding AV/camera changes from the rework pass were removed |
| Wi-Fi, Ethernet, telephony, LatinIME and ADB | Present in their owning components |
| Init, property service, battery, toolbox and shutdown | Present; malformed archived init text was regenerated |
| Bionic | Fortify/open/poll/DNS/property behavior present; syscall/linker/timezone non-ports are listed below |
| Build/product | The four qvirt-proven app exclusions moved to `android_x86_64`; unrelated app and ART debug-package changes were dropped, and target-global bypasses are removed |
| ART | Existing promoted native-loader/native-bridge contract remains; additional loader/export and JNI/OAT replay is excluded |
| Launcher3 and Settings | Existing promoted paths remain; no extra UI surface is imported from the Android 13 neighborhood |

The AOSP16 working-tree-only audit also found staged loader changes and
uncommitted VINTF/HIDL files. The loader behavior was reimplemented against A16;
the manager@1.2 device manifest and hwservicemanager behavior were already
present in the target. Kernel `baklava64` was not copied because the deployed
Windows engine contract still uses instance identity `tiramisu64`.

## Intentional Non-Ports

These are reviewed decisions, not undiscovered omissions:

- Do not replay ART JNI/OAT internals from Android 13. They require an
  A16-specific design and runtime tests.
- Do not add bionic `iopl`/`ioperm`, the obsolete FFmpeg text-relocation
  exception, or broad linker exceptions.
- Do not hard-code the obsolete Iran DST rule; current tzdata is authoritative.
- Do not disable YV12. The selected BlueStacks gralloc supports it, and forcing
  RGB565 would reduce quality and add conversion cost.
- Do not import proprietary Widevine/FFmpeg binaries without immutable source,
  license and supply-chain evidence.
- Do not import the flawed custom `getevent` source. Packaging currently uses
  the reviewed `bst_getevents` payload; source ownership remains unresolved.
- Screenshot shared-folder integration remains a separately approved
  virtualization-stage item.

## Validation Results

All rework gates passed against root `298403a`:

1. Soong/Kati graph, focused components and clean target-only `m droid` passed
   for `android_x86_64-trunk_staging-eng` in 08:50.
2. The retained FPS synchronization was reviewed without polling, callback
   expansion or recursive display locking.
3. External goldfish rebuilt its 32/64 runtime closure in 155 actions.
4. Target-only stage/package/deploy completed with the tree, branch, commit,
   `OUT_DIR`, GGL SHA and all artifact SHA-256 values bound in one identity.
5. Windows Layer 2 passed 7/7 at 86 seconds.
6. The 1022-submodule audit passed at 987 base + 35 merge with every modified
   component SHA reachable from the expected remote.
7. PR #2 reported no base conflict at the time; it was later withdrawn and is
   not the current submission candidate.
