# Henry-Compatible Baklava64 Incremental Build Flow

Date: 2026-08-13 to 2026-08-14 (Asia/Shanghai)
Stage: Android-16 mainline maintenance
Status: implementation, package, replacement, and cold-boot validation complete

## Purpose

The active Android-16 package flow follows the same orchestration shape as the
current Henry Baklava64 build:

```text
build_Baklava64.sh -> build_Baklava_common.sh -> build.sh
  -> Makefile vbox -> create_zips.sh
```

`/home/henry/workspace/app-player/buildscripts/build_Baklava64.sh` and the
related package resources were inspected read-only. No Henry process, source,
output, or package directory was changed. The markxu implementation keeps the
established flow but adds target identity, concurrency, incremental-output,
and error-propagation gates.

## Validated Identity

| Input | Identity |
| --- | --- |
| app-player | `bst-v5.22.210-A16` at `b6f585b2aa899bf16b626d6a64f024bd2a4bd822` |
| Android target | `aosp16-bst-merge` at `a94003163555d715df85fdc486ff09d037597253` |
| Android root | `/home/clouddev/bst/workspace/markxu/android-16` |
| Android output | `out_nxt_Baklava64` |
| Product | `android_x86_64-trunk_staging-eng` |
| Jobs | maximum 8 |
| Package output | `/home/clouddev/bst/workspace/markxu/releases/bst-v5.22.210-A16-9527` |
| A16 package payload | `a16-package-inputs/bst-v5.22.210-A16-e7a61686` |

The app-player head exactly matched its remote branch before execution. The
new Android root is a descendant of the previously validated root; its twelve
advanced component commits only remove dangling nested gitlinks. The flow did
not read, write, or reuse `~/aosp16` or `~/aosp16/out*`.

## Adaptation

- Added `build_Baklava64.sh`, `build_Baklava_common.sh`, and
  `make-baklava-system-sfs.sh` under app-player `buildscripts`.
- Enforced app-player branch, Android branch, resolved target path, existing
  incremental OUT, job ceiling, and target package path before execution.
- Set `FORCE_CLEAN=false` and `SYNC_SOURCE_CODE=false`; compiled objects and
  dependency metadata are preserved. Package staging and final images may be
  regenerated without cleaning the Android OUT.
- Added an OUT lock and live-process check. Baklava VDI creation selects and
  locks a free NBD device, verifies ownership, and only disconnects the NBD it
  attached. A13 retains its existing fixed-device behavior.
- Uses the verified external A16 APK bundle. `scratch-gaurav` and unrelated
  app-player modules remain outside tracking and submission.
- Keeps the Windows `android_x86_64`/Tiramisu test-shell media identity. The
  Baklava archive reuses byte-identical Tiramisu64 data and OEM resources;
  it does not import Henry's temporary standalone A16 UUID template.
- `create_zips.sh` now uses a per-process workspace log in incremental mode,
  removes stale archives before compression, and propagates all failures.
- The disk-signature tool still prefers PyCryptodome. When that optional
  module is absent, it uses the installed `cryptography` backend for the same
  RSA PKCS#1 v1.5 SHA-256 signature format. Existing A13 environments retain
  the original backend and behavior.
- The BootImage pre-mounts the Android runtime and i18n APEX files before
  second-stage Android binaries run. This is the minimal AOSP16-validated fix
  for the earlier PID 1 failure and is gated to Baklava.

## Incremental Evidence

The latest run started at `2026-08-14 05:56 +08:00`. It reused the existing
OUT and ran with `-j8`; no clean or source sync occurred.

- Blueprint bootstrap reported `ninja: no work to do`.
- The root-pin update caused one dependency-graph refresh and metadata
  repackaging. It did not rebuild the Android Java/C++ source closure.
- Kernel make reported the existing `bzImage` ready after configuration
  reconciliation.
- `ramdisk` completed in 15 seconds.
- The changed gcall target rebuilt four C++ objects and two static libraries
  in 30 seconds.
- Android ISO completed successfully. Root, debug Root, system.sfs, VDI/VHD,
  disk signature, SFX archive, and debug archive were then regenerated.
- SELinux image inspection confirmed
  `vendor/bin/hw/android.hardware.audio.service` has
  `hal_audio_default_exec`.

The main build and VDI package phase completed in 1 hour 3 minutes 31 seconds;
most elapsed time was synchronous filesystem copy into VDI, not compilation.
The final archive-only retry did not re-enter Android, HD, or VDI builds.

## Artifact Evidence

| Artifact | Size | Digest / identity |
| --- | ---: | --- |
| `Root.vhd` | 1,697,028,608 | SHA-256 `6097e063b0b1151b7794c19e75648439ee32cb46ac724b38852cdb3e113b7355`; UUID `54e9ad31-a169-4d5b-a0e0-705d62e96e71` |
| `fastboot.vdi` | 13,631,488 | SHA-256 `9f9669333bdf2573665233256a6f948d2b4a12b4701c850ea67e89377cd7c27a`; UUID `91b80c95-aa7d-459d-93e4-c479f5babbb7` |
| `Baklava64.dsgn` | 7,008 | 2 fastboot chunks, 203 Root chunks, 256-byte RSA signature |
| `Baklava64.exe` | 1,296,495,831 | SFX archive generated successfully with MD5 sidecar |
| `Baklava64-RootVdiDebug.7z` | 2,573,055,625 | debug archive generated successfully with MD5 sidecar |

The Windows replacement stored backups named with timestamp
`20260814-0719` and read back the complete identity file before starting the
guest.

## Runtime Regression

Cold boot on the Windows Tiramisu64 shell passed all seven oracles:

| Oracle | Result |
| --- | --- |
| ext4 system mount | pass |
| stage2 init | pass |
| runtime APEX pre-mount | pass |
| boot complete | pass |
| activity displayed | pass |
| player ready | pass |
| boot surface hidden / visible guest frame | pass |

All oracles were present after 53 seconds. The guest then remained free of
fatal oracle patterns for a 45-second stabilization interval; total check time
was 99 seconds. The validated launcher activity is
`com.uncube.launcher3/HomeActivity`.

## Review Boundary

Shell syntax, Python compilation, and scoped Git whitespace checks pass. All
NBD attachments and package mounts were released. Android 13 was not built or
run, as requested; its isolation assessment remains static. The A16-specific
paths are gated by `Baklava64`, `baklava`, or `BST_INCREMENTAL_BUILD`.

The markxu app-player and HD changes remain local and uncommitted at the end of
this validation. Non-blocking follow-up: `linkerconfig --target /linkerconfig`
returns 127 in the early APEX helper, although second-stage init and the full
boot/runtime oracle pass. This should be cleaned up separately without
expanding the accepted promotion delta.
