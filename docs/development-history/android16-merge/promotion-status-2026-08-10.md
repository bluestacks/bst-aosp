# Android-16 promotion status - 2026-08-10

## Executive Status

- Promotion source: validated AOSP16 development behavior plus final A13 code
  authority, both used read-only.
- Target: `~/android-16`, branch `aosp16-bst-merge`, product
  `android_x86_64-trunk_staging-eng`.
- Candidate root: `2be2bd594015046288f67420c72ac3d964595d14`.
- Target branch: `bluestacks/android-16:bst-v5.22.210-A16` at
  `33cdca5464ea1a50e98058a40c36bf3121dbe2b7` when frozen.
- Merge disposition: the target tip is the merge base and an ancestor of the
  candidate; target-only commits and paths are empty. No synthetic merge commit
  is necessary.
- Layer 1: incremental Android/image/package build passed.
- Layer 2: clean-Data 7/7 boot plus 95-second stability passed; visible Launcher
  frame confirmed.
- Extended regression: failed on exact `bst.*` lookup and shared-folder mount.

The target merge was explicitly replayed after the freeze. Git returned
`Already up to date`, kept HEAD at `2be2bd594015046288f67420c72ac3d964595d14`,
and left the pre-existing unstaged root `.gitignore` untouched.

## Completed Work

- Audited all initialized Android projects, branch discipline, root gitlinks,
  detached states, dirty paths, and publication topology.
- Compared A13 authority, validated AOSP16 implementation, and Android-16 code
  at file/hunk level; restored missing framework, HAL, graphics, audio,
  property, package, storage, Houdini, and board-specific behavior.
- Kept the Windows product on `android_x86_64`; removed unified remote/common
  board assumptions.
- Standardized new commits to `[A16] <message>`.
- Added deterministic incremental packaging, source/artifact identity gates,
  bounded boot/runtime oracles, and target-instance-only Windows operations.
- Kept app-player auxiliary modules and `scratch-gaurav` outside submission.
- Preserved original development records and classified rejected fixes instead
  of rewriting them as successes.

## Current Evidence

| Evidence | Result |
| --- | --- |
| Root identity | `2be2bd594015046288f67420c72ac3d964595d14` |
| Incremental command | `g1_build_app_player.sh --incremental --jobs 8` passed |
| Root SHA-256 | `c13024b449ed2bf6cce7ac4e7e7dae0289b116f5c57ff858416074ebf2063976` |
| system.img SHA-256 | `e8a4866d9652f3ed6a6a257e6aa0b661de414c67d60b2a3449eee7c45cb4ce16` |
| system.sfs SHA-256 | `73e2d5a535b19b346645f3c70e3f419963d5d69914e35809ce974e32183279c3` |
| fastboot.vdi SHA-256 | `3d80f8748019808d076d6f1a49c9e8491e26e544c138df740b04450ad86463c8` |
| Clean boot | 7/7 in 170 seconds |
| Stability | 95 seconds; no fatal boot signature |
| Launcher | visible and resolved to uncube HOME |
| Package visibility | BlueStacks Settings launch/return passed |

## Post-merge Smoke Regression

The bounded runtime script was run against the live `Tiramisu64` endpoint
`127.0.0.1:5556` with a 15-second stability window after the no-op target
merge. It completed all checks and returned failure only for:

- `bst_max_fps:`
- `bst_shared_folders:`
- `shared_folder`
- `shared_folder_adb_push`
- `wifi_mac_property:`

The shared-folder shell probe found no mounted path and the ADB push failed
with `secure_mkdirs() failed: Permission denied`. No Launcher resolver,
Launcher resume, Settings return, guest reboot, system-server PID, watchdog,
SystemUI, HAL/service, Houdini, IPv4, telephony, entropy, or payload failure was
reported by the same run. The smoke result therefore confirms the known
property/shared-folder blocker without introducing a new failure class.

## Remaining Problems

### Publication blocker

Exact `getprop <bst.name>` reads are empty although no-argument enumeration
shows the same names and values. `mountsf` consequently receives no shared
folder list and `/mnt/windows/BstSharedFolder` is not mounted. FPS and Wi-Fi
identity consumers are also affected. Details and required evidence are in
`a13-runtime-gaps-2026-08-07.md`.

### Regression debt

- Repeat the short boot/Launcher/Settings smoke after the no-op target merge
  readback.
- Repeat full runtime regression after the exact-property fix.
- Run real shared-folder host/guest transfer, camera frames, audio
  playback/capture, Widevine protected playback, and translated ARM64 app
  execution.
- Confirm dynamic FPS behavior and sustained renderer CPU on the corrected
  property identity.
- Complete interactive Launcher taskbar, recents, rotation, input, and Settings
  navigation checks.

### Publication topology

All gitlinks changed relative to `bst-v5.22.210-A16` were checked against a
canonical BlueStacks organization URL with `git ls-remote`. The following
repositories return `Repository not found` and require manual creation/upload:

| Project path | Required BlueStacks repository | Fork state |
| --- | --- | --- |
| `external/ffmpeg` | `bluestacks/external-ffmpeg-a16` | `mark-bst/external-ffmpeg-a16` exists |
| `external/stagefright-plugins` | `bluestacks/external-stagefright-plugins-a16` | `mark-bst/external-stagefright-plugins-a16` exists |
| `external/v86d` | `bluestacks/external-v86d-a16` | `mark-bst/external-v86d-a16` is also missing |

Every other changed gitlink has a reachable BlueStacks repository. The
`external/v86d` repository is a component-publication blocker, while the other
two can be reviewed from their existing forks pending organization upload.
Root publication must not be described as topology-complete until all three
BlueStacks repositories and the `external/v86d` fork are readable and contain
the referenced commits.

## Rejected Or Superseded Changes

- Broad A13 feature XML restoration: rejected after stale staging produced
  RescueParty/black-screen behavior; current declarations follow AOSP16.
- Cross-directory package scan order as the Settings visibility root cause:
  disproven by runtime; retained only as historical evidence.
- Early second-stage reads from `/data`: superseded by the AOSP16-matching
  post-data load path.
- Exact-only `bst.max_fps` property context: superseded by the complete `bst.`
  prefix declaration.

## Publication Rule

Publishing this candidate is suitable for code review only while the property
blocker is open. The pull request description must state that minimum boot is
green but full runtime acceptance is not. The PR must not be merged until the
exact property and shared-folder gates pass or the reviewer explicitly accepts
that known limitation.
