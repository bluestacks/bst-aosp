# Android-16 Clean-Build Runtime Regression, 2026-08-15

Stage: Android-16 mainline maintenance
Status: historical cycle closed by the 2026-08-16 successor package

> **2026-08-16 status note:** this file preserves the previous clean-build
> cycle and its identities. After the hwservicemanager restart fix, the user
> explicitly authorized one new OUT reset and clean baseline. Current work and
> the rule that every later build is incremental are recorded in
> [`restart-regression-closure-2026-08-16.md`](restart-regression-closure-2026-08-16.md).
> That successor cycle is complete for black screen, properties, launcher,
> ADB policy, dynamic FPS, application behavior, Camera2, Houdini/binfmt, and
> shared folders. The shared-folder diagnosis and later closure are recorded
> in [`shared-folder-regression-2026-08-16.md`](shared-folder-regression-2026-08-16.md).

## Scope

This cycle follows the black-screen root cause and targeted validation in
[`graphics-black-screen-2026-08-15.md`](graphics-black-screen-2026-08-15.md).
It uses only the markxu Android-16 target tree, app-player branch, and local
Windows `Tiramisu64` instance. It does not read, build, deploy, or reuse AOSP16
source/output, does not build or run Android 13, and does not access or affect
Henry's source, output, package, or processes.

## Published Source Identity

| Component | Branch / commit | Change |
| --- | --- | --- |
| Android root | `aosp16-bst-merge` / `e73454d0b365e0c9d98b51fe2c272717f875ba9d` | records the four runtime component pins |
| `frameworks/native` | `aosp16-bst-merge` / `080784acd49a450170b8555d270f4cdc5109dfa3` | isolates A16 goldfish from the system Binder filter service |
| LatinIME | `aosp16-bst-merge` / `38ceff92adc0978823ef686b4cece01d9610efec` | binds the BST IME bridge to IPv4 loopback |
| `device/generic/common` | `aosp16-bst-merge` / `0b64aa991a28855c6b05f42a3b7098f83bfeadb9` | selects NDK translation using the per-namespace VDSO sentinel |
| `system/core` | `aosp16-bst-merge` / `dd46679b55f95cdc43d91ebcf51ccd49cfd233e3` | rejects stale per-instance ABI identity overrides |
| goldfish-opengl | `bst-v5.22.210-A16` / `a899e765559bdbddf07270675410a106c70e0c47` | restores bounded dynamic FPS on active EmuHWC2 |
| app-player | `bst-v5.22.210-A16` / `86b26bd6c26e2145995afd746c957dc81f087f94` | records the goldfish gitlink and canonical Baklava flow |

Independent `ls-remote` readback matched both app-player and Android root
local heads. All component changes use `[A16]` commit subjects and were pushed
before the formal package started.

## Code Review

### Goldfish Binder Isolation

`frameworks/native` compiles an inline no-op `BstFilterAppsManager` only when
`BST_ANDROID16_GUEST` is defined. This is necessary because the external
goldfish libraries execute in the vendor Binder domain while `bstfilterapps`
is registered by SystemServer on the system Binder domain. The previous calls
blocked graphics startup and returned the same defaults only after timeout.

- Necessity: blocking black-screen fix; matches the validated AOSP16 decision.
- Performance: removes synchronous service waits; adds no allocation, thread,
  polling, or per-frame work.
- Security: preserves the system/vendor Binder boundary and adds no SELinux or
  Binder permission exception.
- Compatibility: A13 and non-guest callers retain the full manager. A16 guest
  app-specific graphics filters remain unavailable until a supported
  cross-partition service contract exists; this is an explicit residual
  compatibility risk, not a hidden fallback.

### IME IPv4 Listener

LatinIME now binds `BstImeBridge` to `127.0.0.1`. Android 16 selected IPv6 for
`InetAddress.getLoopbackAddress()`, while the existing `bstime` client connects
to IPv4 loopback.

- Necessity: restores the existing guest-local IME protocol without a host
  lifecycle change.
- Performance: no steady-state cost; only the address family changes.
- Security: remains loopback-only and does not widen network exposure.
- Compatibility: the protocol, dynamic port, backlog, and reconnect behavior
  are unchanged.

### Native-Bridge Namespace Sentinel

`libnb.so` now detects `/system/lib64/arm64/libnative_bridge_vdso.so`, which
Zygote bind-mounts only in an `arm64_ndk` namespace. Houdini 16 stores
`libtcb.so` outside that sysroot, so the A13 sentinel incorrectly selected NDK
translation for ordinary Houdini applications.

- Necessity: required for ARM64 Houdini execution on the new payload layout.
- Performance: one `access()` remains on the existing selection path.
- Security: reads namespace-local mount state and does not broaden filesystem
  access.
- Compatibility: preserves the current Zygote namespace decision instead of
  adding package names or another policy source. Formal acceptance requires
  the ARM64 application and standalone binfmt oracles.

### ABI Identity Override Filter

The post-data BlueStacks property loader now treats the three
`ro.product.cpu.abilist*` values as platform identity. Old instance property
files may advertise ARM32 even though Houdini 16 is arm64-only; all unrelated
BlueStacks overrides continue to load.

- Necessity: prevents retained data from overriding image-owned ABI support.
- Performance: three bounded string comparisons during property-file load.
- Security: narrows externally supplied read-only identity and adds no writer.
- Compatibility: x86, x86_64, and arm64 remain image-derived; the filter does
  not discard other product properties.

### Dynamic FPS

The active external goldfish `EmuHWC2` polls `bst.max_fps` at most once per
second while vsync is enabled, updates the active config period, correctly
splits nanoseconds into `timespec`, and invokes Refresh after releasing both
display and callback locks.

- Necessity: `hardware/interfaces` implements the same contract only for the
  inactive framebuffer fallback.
- Performance: one bounded property read per second, not per frame.
- Security: accepts only numeric values from 1 through 240 and adds no external
  interface.
- Compatibility: all code is under `BST_ANDROID16_GUEST`; Android 13 source
  behavior is unchanged.

The five authoritative patch files under `patches/android-16/patches/` pass
`git apply --reverse --check` against their published component heads.

## Clean And Incremental Build Evidence

The requested one-time clean removed only
`/home/clouddev/bst/workspace/markxu/android-16/out_nxt_Baklava64`. The
canonical Android-16 build then completed 183,214 actions in 5:57:03. No later
clean is permitted or needed.

After the four runtime fixes, targeted incremental compilation completed
4,788 actions in 18:51. A canonical follow-up incremental build completed 75
actions in 15:57. The current Android output identity is:

| Item | Value |
| --- | --- |
| Product | `android_x86_64-trunk_staging-eng` |
| OUT | `out_nxt_Baklava64` |
| Android root | `e73454d0b365e0c9d98b51fe2c272717f875ba9d` |
| goldfish | `a899e765559bdbddf07270675410a106c70e0c47` |
| `system.img` SHA-256 | `545c4ca078d0c06d7a2f0227c6ff039d8d60e72656998317aa3bd1823b5f396d` |

Binary readback found the VDSO sentinel in `libnb.so`, the stale-identity log
message in `init`, the rebuilt LatinIME APK, and `bst.max_fps` handling in both
32-bit and 64-bit HWC providers. The inspected graphics closure contains zero
`BstFilterAppsManager` symbols.

An obsolete wrapper briefly forced `USE_CCACHE=1` and exposed a 135,806-action
queue. Only that markxu-owned process was stopped before source compilation;
no Henry process was queried for completion or changed. The authoritative
`system.img` remained byte-identical. The wrapper is now reduced to strict
identity preflight plus the canonical `build_Baklava64.sh` entry. It maps
`--incremental` to the canonical incremental flow and
`--package-resume`/`--package-only` to canonical package-only. It contains no
clean, source sync, AOSP16 path, alternate release directory, or ccache
override.

The first canonical package-only run performs a one-time Soong environment
reconciliation from the interrupted `USE_CCACHE=1` state back to the canonical
unset state. Its actual first module queue was 105 `xpl` targets, not a full
Android rebuild. Subsequent module invocations reuse that environment.

## Pre-Package Runtime Findings

The diagnostic black-screen Root passed three cold boots and guest framebuffer
readback. Play Store remained foreground for 20 seconds with no crash-buffer
entry, and the GMS process remained alive. These observations must be repeated
against the canonical package before they become formal acceptance evidence.

The shared-folder failure was reconfirmed and narrowed:

- Windows config registers `InputMapper` and `BstSharedFolder`, and the guest
  loads `vboxguest` plus `vboxsf`.
- The active host and `/data/.bstconf.prop` report
  `bst.status.hypervisor=hyperv`; `mountsf` therefore requests the absent
  `bstfolder` filesystem and all four mounts fail.
- A runtime-only switch to `vbox` selects the installed `vboxsf` path, but the
  active Hyper-V host exposes no VBox shared-folder names and reports
  `No shared folder specified`.
- The property was restored to `hyperv` after the bounded diagnostic.

This rules out an Android permission-only fix. Hyper-V needs its coordinated
9P/VSOCK or custom `bstfolder` host/kernel/package contract, while VBox needs a
VBox host backend that actually registers the exports. Falsifying the
hypervisor property or chmodding empty mountpoint directories would create a
false pass and is not accepted.

A later window-recovery black screen was host-only. ADB returned a complete
Launcher framebuffer and showed that the guest had not rebooted, while the
player startup log showed `GL_VENDOR=NVIDIA`. Windows had an explicit
`GpuPreference=2` override for `HD-Player.exe`, which overrode the player
configuration. After backing up the settings, the executable was routed to
the Intel GPU and a true cold boot reached `Player state: ready` with a complete
Launcher frame. This matches the earlier R236 Intel green baseline and requires
no guest source change. The boot oracle now includes the expected host GL
vendor so this host-side false pass cannot recur unnoticed.

## Formal Runtime Matrix

The entries below were closed by the clean-derived final package and successor
evidence recorded on 2026-08-16. The pre-package observations above remain
historical context; they are not the final acceptance state.

| Gate | Status |
| --- | --- |
| canonical package identity and graphics provider uniqueness | PASS: final Root/fastboot identity and component closure read back |
| repeated cold boot and guest framebuffer | PASS: 10/10 cold boots, all framebuffer probes non-black |
| post-data property load and ABI identity | PASS: 455 exact properties, zero critical mismatch |
| Launcher / Settings / HD-facing lifecycle | PASS |
| dynamic FPS 60 -> 30 -> 60 and CPU bound | PASS: exact periods, 0.00% delta, bounded CPU |
| IME listener and `bstime` lifecycle | PASS: `imeservice` running, loopback listener on 40143 |
| app-visible graphics/audio/camera/network | PASS: ordinary-app oracle plus a non-empty Camera2 frame |
| ARM64 Houdini application and binfmt | PASS |
| Play Store / GMS startup | PASS: Vending/GMS alive after 60 seconds, no target crash/ANR |
| ADB policy | PASS |
| shared-folder host-visible round trip | SUPERSEDED/PASS: successor package mounted four exports and passed bidirectional exact readback across cold restarts |
| intermittent CPU3 RCU cold-boot rate | PASS for current package: 0/10 cold boots |

The Windows workstation is locked. All formal graphics evidence must come
from guest ADB `screencap` and decoded pixel readback; Windows screenshots are
not an accepted oracle. Full identities and hashes are in
[`restart-regression-closure-2026-08-16.md`](restart-regression-closure-2026-08-16.md).
