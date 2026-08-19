# Minimal Platform Graphics Policy, 2026-08-19

Stage: Android-16 mainline maintenance

Status: accepted by incremental build, canonical package readback, clean-Data
first boot and cold-boot runtime regression. Direct component pull request
[bluestacks/ggl-goldfish-opengl-pie#225](https://github.com/bluestacks/ggl-goldfish-opengl-pie/pull/225)
is open. No app-player, Android root or app-player `buildscripts` source is
part of the change.

## Scope

This follow-up narrows the Camera2 and Quickstep correction after the real
`bstfilterapps` system-Binder client was proven stable. It keeps the A13 service
contract and default values for ordinary applications, removes package policy
from common `frameworks/native`, and selects only the two A16 platform
exceptions demonstrated by single-variable runtime tests.

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
| goldfish correction | `codex/a16-platform-graphics-policy` / `37901957f219f2d5aac6760f97e8c1f19a2e6b33` |

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

## Single-variable A/B

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
| only `TTCDisabled=false` | PASS: live camera frame after cold boot |

Minimum: `com.android.camera2` requires only `TTCDisabled=false`. GLPB,
GLUBPerf and GLMBRH retain the A13 default `true`.

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
- Camera TTC-only pass:
  `f4b996412cb01c3a589f5ffb1c056c8a89b2c78e990cc2d21e87d470a56d1adb`;
- Recents all-default cold-boot failure:
  `7421d9eea9edd6644b29069cbbf0868cb994f8e94afb5c06f314255ce66f8116`;
- Recents GLPB-only cold-boot pass:
  `c348d4f4801b4d0f7bd6abd3ec16cad923fac55d97a24b08e5972b9daa7d7e5f`.

## Minimal Source Correction

Goldfish commit `37901957` changes only
`system/GLESv2_enc/GL2Encoder.cpp`:

- `CheckProgramBinaryNeed()` caches `false` for
  `com.android.launcher3` before querying Binder in A16 builds;
- `TexTargetCheckDisabled()` caches `false` for
  `com.android.camera2` before querying Binder in A16 builds;
- all other packages continue through the real `bstfilterapps` query and keep
  the A13 default/rule behavior;
- both checks use the existing `BST_ANDROID16_GUEST` compile boundary, so A13
  builds compile the original path and retain their Camera/Launcher behavior.

Review:

- necessity: both checks directly match a reproduced A16 rendering failure and
  its cardinality-one fix;
- performance: two package comparisons occur once per encoder policy cache,
  with no per-frame branch, polling, allocation or additional transaction;
- compatibility: the existing A16 build guard removes both checks from A13;
  the change does not alter the manager ABI, Binder domain, AIDL or service;
- security: no permission, SELinux label, service exposure or write path is
  added;
- rejected scope: no global fallback change, database wildcard, native package
  list, Binder-domain switch, HWC replacement or broad four-policy disablement.

## Build, Package And Runtime Acceptance

The focused 32/64-bit graphics increment completed without cleaning the Android
OUT tree. Packaging reused the existing app-player carrier through the
canonical Baklava64 finalization and package validation path. An existing
wrapper also selected its `libs` prerequisite and unnecessarily expanded one
attempt into a large JNI build; that markxu-owned attempt was stopped and the
package-only Make target was then invoked directly. No Henry process was read,
waited on, signalled or changed, and no build-script source was modified.

Tested source identity:

- Android root: `2fd36fe849bca69fac6f82ecc5c2e5880e24f914`;
- app-player carrier: `1bdbf5b5f0e75cab32e2a4dee65f0bea7447ff7d`;
- HD: `bfbab1b0c210f7714dbdbd890187ec73d5b4a6e4`;
- VBox: `af3611cc932497d7756409437fc151586e61aa72`;
- goldfish: `37901957f219f2d5aac6760f97e8c1f19a2e6b33`.

Final package identity, generated `2026-08-19T12:35:12+08:00`:

- `Root.vhd`: `44e0999c7803333d4e59125164c693352ff3f7eafd3fe3daa859deb2465ad1d0`;
- `system.img`: `22f5f220e77fe1c966b7167a7a444a32db57886158d2571b0bc6865b82dbf2ac`;
- `system.sfs`: `9534d96c8c75c07489cee9f6a971cb18c152bee85cf4b18e1a27ca971aa5dc8b`;
- `fastboot.vdi`: `2396260a7c0d6f8298048a92d00c5a34c8c47a70d1d10be4c8c9c17fde93bbac`;
- Root UUID: `54e9ad31-a169-4d5b-a0e0-705d62e96e71`;
- fastboot UUID: `91b80c95-aa7d-459d-93e4-c479f5babbb7`;
- packaged 32-bit `libbinder.so`:
  `a74c465f7c4bb775e76ba43161fa00d48ee00570c0dbfaa55bd3058717a1b3c3`;
- packaged 64-bit `libbinder.so`:
  `2b048d7139e38359103ef774fe62172ac20c9bfb0b00324d12bf84820363a824`.

The package validator reported `core_package_identity=verified` and
`validation_mode=canonical-app-player-package`. Deployment used the original
clean Data base with SHA-256
`d9baa0f42ee4636b21b9549849ae90fc4bd315e75cf28946c7b765d04ab02e9a`.
The installed `config.db` retained its original SHA-256
`4c2a2e5ad0ab7cf0c9048d26b2cbb1f152e3a28fa2925d0862ed51712ebb21ff`;
therefore the result does not depend on a test-only database override.

Runtime acceptance:

- first boot rendered GameCenter; screenshot SHA-256
  `d6f18a4d59b27db03b8e48bf1781ec9ce490f6230f99866759083571ef3ef109`;
- Camera2 logged exactly `TTCDisabled=0`, `GLPB=1`, `GLUBPerf=1` and
  `GLMBRH=1`, then rendered a live 1600x900 camera frame; screenshot SHA-256
  `a03b141a4c99a560c90fe0ec5d488872edffe411b8534001e44ce96c25b1db25`;
- Launcher3 logged exactly `GLPB=0`, `TTCDisabled=1`, `GLUBPerf=1` and
  `GLMBRH=1`;
- current Recents rendered Settings, Camera, GameCenter and Clock without
  white cards or black/red borders; screenshot SHA-256
  `47f1ab4fab8e1630a61dd850ec76d824b7942a8b22e3579a3039e43159d81d58`;
- the cold boot passed all seven lifecycle gates in 115 seconds. Its 1600x900
  framebuffer had `non_black_ratio=0.911283` and SHA-256
  `4f9e5c3400ac5e883c12350303692f0870daad93221b2c76fdc293fe9a8c50b3`;
- cold-reloaded Recents again rendered Camera, Clock, Settings and GameCenter
  correctly; screenshot SHA-256
  `dc6bd5ff66ea5858de3059bdb5e6a3b5828de156e532ea13d2f9a6b708c25449`;
- Launcher home rendered normally after the cold test; screenshot SHA-256
  `6dc2d69f8302aa2334f0e77b81b6ab1bdfcc01411412d97c31c541ac41cac38f`;
- GameCenter reached its permission dialog without a new GameCenter fatal,
  ANR, RTVbox error, `bstfilterapps` wait or Binder timeout.

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

The goldfish feature branch `codex/a16-platform-graphics-policy` is published
to `mark-bst/ggl-goldfish-opengl-pie` and its remote tip was read back as exact
commit `37901957f219f2d5aac6760f97e8c1f19a2e6b33`. It must be reviewed directly
into `bluestacks/ggl-goldfish-opengl-pie:bst-v5.22.210-A16` through
[PR #225](https://github.com/bluestacks/ggl-goldfish-opengl-pie/pull/225).
GitHub readback shows one commit, one changed file, 16 additions, no conflicts,
and the correct base and head branches.

Per the current module-publication rule, neither app-player nor the Android-16
root is updated or submitted. Build identity records the tested component SHA
directly. No direct push to a BlueStacks target branch is authorized.
