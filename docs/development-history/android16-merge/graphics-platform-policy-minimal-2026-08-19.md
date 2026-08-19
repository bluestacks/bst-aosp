# Minimal Platform Graphics Policy, 2026-08-19

Stage: Android-16 mainline maintenance

Status: accepted by focused incremental build, exact Root readback, clean-Data
7/7 boot gates, live Camera and current Recents regression. Initial component
pull request
[bluestacks/ggl-goldfish-opengl-pie#225](https://github.com/bluestacks/ggl-goldfish-opengl-pie/pull/225)
is merged. The Camera follow-up is published and under review in
[PR #226](https://github.com/bluestacks/ggl-goldfish-opengl-pie/pull/226).
No app-player, Android root or app-player `buildscripts` source is part of the
change.

## Scope

This follow-up narrows the Camera2 and Quickstep correction after the real
`bstfilterapps` system-Binder client was proven stable. It keeps the A13 service
contract and default values for ordinary applications, removes package policy
from common `frameworks/native`, and selects only the package-scoped A16
exceptions demonstrated by controlled runtime A/B tests.

The work used the markxu Android-16/app-player trees and the Windows
`Tiramisu64` instance. It did not read, build or reuse AOSP16 output, run Android
13, modify Henry's workspace or processes, or modify app-player `buildscripts`.

## Source Baseline

| Item | Branch / commit |
| --- | --- |
| Android root | `bst-v5.22.210-A16` / `2fd36fe849bca69fac6f82ecc5c2e5880e24f914` |
| `frameworks/native` | `bst-v5.22.210-A16` / `626929d3cf379373e2aa768642ffbe407fa0d6e5` |
| `device/generic/common` | `bst-v5.22.210-A16` / `c55b6bbddccd10329b4ec3acb48b5eaf0e27a227` |
| goldfish base | `bst-v5.22.210-A16` / `87a539e25bbfe6f3b384118d66827b7d5c4f28b1` |
| goldfish initial correction | `codex/a16-platform-graphics-policy` / `37901957f219f2d5aac6760f97e8c1f19a2e6b33` |
| goldfish Camera2 follow-up | `codex/a16-platform-graphics-policy` / `eef4466f2dbb23f7dee318902fe410828c3af136` |

The local, unpublished `frameworks/native` commit `bc0b387827` was removed.
The checkout and target branch both resolve to `626929d3cf`; the unified
UID-gated NDK system-Binder client remains intact, while Camera/Launcher package
exceptions no longer live in common Binder code.

## A13 Contract Review

The A13 and A16 `BstFilterAppsService.java` implementations are byte-identical
for the relevant methods. Packages without explicit database rules receive
these legacy defaults:

| Policy | Service default |
| --- | --- |
| GL program binary (`GLPB`) | `true` |
| GL unmap-buffer optimization (`GLUBPerf`) | `true` |
| texture-target check disabled (`TTCDisabled`) | `true` |
| host map-buffer-range (`GLMBRH`) | `true` |

Changing all defaults to false in `frameworks/native`, using an empty manager,
or discarding the Binder client would therefore change A13 behavior for every
ordinary application. Those alternatives remain rejected.

## Controlled Runtime A/B

The test Root contains the working direct Binder client and no native package
exclusion. The original guest database was saved and restored with SHA-256
`4c2a2e5ad0ab7cf0c9048d26b2cbb1f152e3a28fa2925d0862ed51712ebb21ff`.
Each variant changed one package property, relied on the service file observer
to reload it, and restarted the affected process to clear encoder policy
caches.

### Camera2

| Variant | Result |
| --- | --- |
| all four defaults `true` | FAIL: placeholder/black preview |
| all four `false` | PASS: live camera frame |
| only `TTCDisabled=false` | FAIL: exact same placeholder frame |
| `TTCDisabled=false`, `GLPB=false` | PASS: live camera frame |
| `TTCDisabled=false`, `GLUBPerf=false` | PASS: live camera frame |
| `TTCDisabled=false`, `GLMBRH=false` | FAIL: exact same placeholder frame |

The earlier TTC-only pass was confounded by runtime state and is superseded by
the repeated four-way A/B above. Camera2 needs `TTCDisabled=false` plus either
`GLPB=false` or `GLUBPerf=false`. The source correction selects `GLPB=false`:
program-binary initialization is outside the buffer hot path, while globally
changing the unmap-buffer optimization would carry a broader performance
risk. `GLUBPerf` and `GLMBRH` therefore retain the A13 default `true`.

The input and capture split was also checked independently. The HP HD Camera
produced a normal host frame, and Camera2 could save a normal JPEG while its
TextureView preview still showed the static placeholder. This localizes the
failure to Camera2's GLES preview policy, not the privacy shutter, host input,
V4L2/HAL transport, YUYV conversion or still-capture path.

### Launcher3 / Quickstep Recents

The oracle created Camera, Clock, Documents and GameCenter snapshots, performed
a guest-managed shutdown, cold booted, and opened Recents. With all defaults
true the cards reproduced white fill, black/red borders and corrupted texture
content.

| Single package override | Result after process restart |
| --- | --- |
| `TTCDisabled=false` | FAIL |
| `GLMBRH=false` | FAIL |
| `GLUBPerf=false` | FAIL |
| `GLPB=false` | PASS |

A second guest-managed shutdown and cold boot with only `GLPB=false` also
passed. Minimum: `com.android.launcher3` requires only `GLPB=false`.

Evidence identities:

- Camera all-default failure:
  `9b4d2c219daed2d790b50439d2be07d93c83e9a8eea817bfe5de5511b7d88600`;
- Camera all-false pass:
  `8d7831c9fb4d0bf1c61b68c6b9b5e71c4474da5c007d72fdcb6a365dffbf1d99`;
- Camera TTC-only failure and GLMBRH-false failure:
  `9b4d2c219daed2d790b50439d2be07d93c83e9a8eea817bfe5de5511b7d88600`;
- Camera TTC+GLPB pass:
  `3be8301ba866f1bef689adbdf5365af8b81e6e19043e30708b87165fc119eada`;
- Camera TTC+GLUBPerf pass:
  `6850f6044b399e2c6232407fb44fb887f125fb8f7e534f33b9f69a20a532e95a`;
- direct host frame:
  `926bf4190628fd5f803dd5d368f6530b26d795727535c5f24e2ea6a294fa1a9c`;
- guest still capture:
  `78eef84fdb426a642cc1aed40943df6144f1f8bf2fcede9c44d072ea740138b0`;
- Recents all-default cold-boot failure:
  `7421d9eea9edd6644b29069cbbf0868cb994f8e94afb5c06f314255ce66f8116`;
- Recents GLPB-only cold-boot pass:
  `c348d4f4801b4d0f7bd6abd3ec16cad923fac55d97a24b08e5972b9daa7d7e5f`.

## Minimal Source Correction

Goldfish commits `37901957` and `eef4466f` change only
`system/GLESv2_enc/GL2Encoder.cpp`:

- `CheckProgramBinaryNeed()` caches `false` for
  `com.android.launcher3` and `com.android.camera2` before querying Binder in
  A16 builds;
- `TexTargetCheckDisabled()` caches `false` for
  `com.android.camera2` before querying Binder in A16 builds;
- all other packages continue through the real `bstfilterapps` query and keep
  the A13 default/rule behavior;
- both checks use the existing `BST_ANDROID16_GUEST` compile boundary, so A13
  builds compile the original path and retain their Camera/Launcher behavior.

Review:

- necessity: the Launcher exception is cardinality-one; the Camera exception
  is the minimum two-policy combination selected from repeated A/B results;
- performance: two package comparisons occur once per encoder policy cache,
  with no per-frame branch, polling, allocation or additional transaction;
- compatibility: the existing A16 build guard removes both checks from A13;
  the change does not alter the manager ABI, Binder domain, AIDL or service;
- security: no permission, SELinux label, service exposure or write path is
  added;
- rejected scope: no global fallback change, database wildcard, native package
  list, Binder-domain switch, HWC replacement or broad four-policy disablement.

## Build, Package And Runtime Acceptance

The focused 32/64-bit `GLESv2_enc` increment completed without cleaning the
Android OUT tree. The canonical package-only target first regenerated the
incremental dependency graph, but a later `frameworks/base` prerequisite
expanded to 10828 actions. That markxu-owned attempt was stopped immediately;
no Henry process was read, waited on, signalled or changed. The accepted Root
was then rebuilt from the previously deployed, hash-identified Root by replacing
only the two `libGLESv2_enc.so` files in its embedded system image. Independent
readback preserved mode `0644`, UID/GID `0`, the `vendor_file` SELinux label,
the VHD UUID and the unchanged fastboot image. No build-script source was
modified.

Tested source identity:

- Android root: `2fd36fe849bca69fac6f82ecc5c2e5880e24f914`;
- app-player carrier: `1bdbf5b5f0e75cab32e2a4dee65f0bea7447ff7d`;
- HD: `bfbab1b0c210f7714dbdbd890187ec73d5b4a6e4`;
- VBox: `af3611cc932497d7756409437fc151586e61aa72`;
- goldfish: `eef4466f2dbb23f7dee318902fe410828c3af136`.

Final focused package identity, generated `2026-08-19T14:53:13+08:00`:

- base `Root.vhd`: `44e0999c7803333d4e59125164c693352ff3f7eafd3fe3daa859deb2465ad1d0`;
- corrected `Root.vhd`: `7f169acf854a5ae28530a4bcb67623bc1c76bf3e8d8759a0d73c71fc6297b2e8`;
- `system.img`: `05a20536b5bb210e94b08f6a95cf600b81e18468d731e639f86f351e378d33d0`;
- `system.sfs`: `eccbcb02bef50220052a3f2f29757c8bcf0ac6dfaf73d611fbac77e20cd38577`;
- `fastboot.vdi`: `2396260a7c0d6f8298048a92d00c5a34c8c47a70d1d10be4c8c9c17fde93bbac`;
- Root UUID: `54e9ad31-a169-4d5b-a0e0-705d62e96e71`;
- fastboot UUID: `91b80c95-aa7d-459d-93e4-c479f5babbb7`;
- packaged 32-bit `libGLESv2_enc.so`:
  `908b3c48a072bb6ae95a41dcb1ad913665328667aa59bfbc198109e65ff74261`;
- packaged 64-bit `libGLESv2_enc.so`:
  `bf01ae57da9a2bf2a0759bd8827ab4a8e897658e88e140a5f2b27ad88b6809fb`.

The focused package readback reported
`core_package_identity=focused-readback-verified` and
`validation_mode=focused-gles2-encoder-root-repack`. Deployment used the
original clean Data base with SHA-256
`d9baa0f42ee4636b21b9549849ae90fc4bd315e75cf28946c7b765d04ab02e9a`.
Before the clean-Data deployment, the active `config.db` was restored byte for
byte to SHA-256
`4c2a2e5ad0ab7cf0c9048d26b2cbb1f152e3a28fa2925d0862ed51712ebb21ff`.
The accepted runtime log explicitly identifies both Camera exceptions as
`platform default`, so the result does not depend on a test-only database
override.

Runtime acceptance:

- the host lifecycle oracle reached all 7/7 gates in 68 seconds; its wrapper
  later failed only because the stale `emulator-5554` ADB transport was
  offline, after which the same modern SDK ADB connected to the live guest at
  `127.0.0.1:5556`;
- guest readback matched both packaged library hashes exactly;
- Camera2 logged exactly `TTCDisabled=0`, `GLPB=0`, `GLUBPerf=1` and
  `GLMBRH=1`;
- two stable live Camera frames differed as expected, with screenshot SHA-256
  `a36173ae9d8477a2af84546cd02a8f3f6a8d1be501e9a5bc608d72b611c6e3a3`
  and `f7efb448667015265f8a6a34a321ea1e30c2d4d6a623fdbd814bc858260c7f0a`;
- the already-merged Launcher3 path retained its `GLPB=0` exception;
- current Recents rendered Settings, Camera, GameCenter and Documents without
  white cards or black/red borders; Camera's live content also appeared in its
  task card. Screenshot SHA-256
  `3f60a8bd299676e0bc345df593631af2001e772542ae3de492752de8a03f088d`;
- no Camera fatal exception, fatal signal or ANR was present after the test.

The legacy HD-Adb binary must not be used for this oracle: invoking it replaces
the modern platform-tools ADB server with an incompatible protocol version and
can falsely report the guest offline. The accepted readback used only the
modern SDK ADB transport.

An independent residual issue remains: the bundled Play Store
`com.android.vending` version 39.4.23 repeatedly crashes its `VpaService` on
cold boot because Android 16 requires the system-exempted foreground-service
and exact-alarm permissions. It is neither caused nor masked by this goldfish
change and is tracked separately from the Camera/Recents acceptance.

## Publication Boundary

The initial goldfish correction was merged into
`bluestacks/ggl-goldfish-opengl-pie:bst-v5.22.210-A16` through
[PR #225](https://github.com/bluestacks/ggl-goldfish-opengl-pie/pull/225) as
BlueStacks commit `27a021a9064bf2325e92091ab8f87471bfe7b544`. The feature branch
`codex/a16-platform-graphics-policy` is published to
`mark-bst/ggl-goldfish-opengl-pie` at exact commit
`eef4466f2dbb23f7dee318902fe410828c3af136`. Because PR #225 was already
merged before this follow-up was pushed, `eef4466f` is under direct component
review in [PR #226](https://github.com/bluestacks/ggl-goldfish-opengl-pie/pull/226)
against `bst-v5.22.210-A16`. GitHub readback reports one commit, one changed
file, no conflicts and Ready to merge.

Per the current module-publication rule, neither app-player nor the Android-16
root is updated or submitted. Build identity records the tested component SHA
directly. No direct push to a BlueStacks target branch is authorized.
