# Android-16 promotion status - 2026-08-10

## Executive Status

- Promotion source: validated AOSP16 development behavior plus final A13 code
  authority, both used read-only.
- Target: `~/android-16`, branch `aosp16-bst-merge`, product
  `android_x86_64-trunk_staging-eng`.
- Candidate root: `d3e80def2ce05594d50cee4819e8a85c20757617`.
- Target branch: `bluestacks/android-16:bst-v5.22.210-A16` at
  `33cdca5464ea1a50e98058a40c36bf3121dbe2b7` when frozen.
- Component disposition: all 45 promoted components are published on
  `bluestacks/*:bst-v5.22.210-A16`; source and target readback are exact.
- Merge methods: 31 fast-forward/exact, three normal merges, ten reviewed
  promotion-tree history merges, and one target-first kernel 6.12 merge.
- Layer 1: passed for historical root `2be2bd594015046288f67420c72ac3d964595d14`;
  pending for the current candidate.
- Layer 2: clean-Data 7/7 boot plus 95-second stability passed for the
  historical root; pending for the current candidate.
- Extended regression: failed on exact `bst.*` lookup and shared-folder mount.

The initial root-level target replay was a no-op at `2be2bd594015046288f67420c72ac3d964595d14`.
Component-level target history was subsequently merged before root publication.
The resulting root is `d3e80def2ce05594d50cee4819e8a85c20757617`;
the pre-existing unstaged root `.gitignore` remained untouched.

Detailed component decisions and all final tips are recorded in
[`component-target-merge-2026-08-10.md`](component-target-merge-2026-08-10.md).

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

## Historical Validation Evidence

The following artifacts validate root `2be2bd594015046288f67420c72ac3d964595d14`,
not the current component-merge root. They must not be attributed to
`d3e80def2ce05594d50cee4819e8a85c20757617`.

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

- Incrementally build current root `d3e80def2ce05594d50cee4819e8a85c20757617`
  and repeat the short boot/Launcher/Settings smoke.
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
canonical BlueStacks organization URL with `git ls-remote`. The three
previously missing A16 repositories were created and populated on 2026-08-10:

| Project path | BlueStacks repository | `aosp16-bst` | `aosp16-bst-merge` |
| --- | --- | --- | --- |
| `external/ffmpeg` | `bluestacks/external-ffmpeg-a16` | `5caa26d67340b43aebef124bcb7e968ba37f6cb6` | `b58396a9a465ec3875e01d1719bd0beea971b359` |
| `external/stagefright-plugins` | `bluestacks/external-stagefright-plugins-a16` | `0b53a655eef7a8be53bfbcaefaca06d1a52a6add` | `6462e1ed74e9c91b4bf336713c8f928afeb3a4fc` |
| `external/v86d` | `bluestacks/external-v86d-a16` | `bf5f11a175a6740dd29cd224c804e03b2ac80558` | `49e046362296556bc38b45bb4d971965eab21dfe` |

Root commit `cac24e164bb53210c4f003405d3f00ded63c37da` first changed the three
`.gitmodules` URLs from temporary `mark-bst` locations to the formal
BlueStacks repositories. Root `d3e80def2ce05594d50cee4819e8a85c20757617`
then advances 14 gitlinks after the complete component-target merge. Repository
topology is complete; build and runtime acceptance remain open.

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

## Publication Result

- Created `mark-bst/system-sepolicy-a16` from the BlueStacks repository and
  published `acff98d684732d0ca05aff5f2799dfd3b32ed921` on
  `aosp16-bst-merge`.
- Published and read back the 10 other component tips that were ahead of their
  audited forks: bionic, generic common/x86_64, BoringSSL, frameworks base and
  telephony, libcore, Connectivity, NetworkStack, and system core.
- Published root `2be2bd594015046288f67420c72ac3d964595d14` to
  `mark-bst/android-16:aosp16-bst-merge` with a lease against the prior
  `5c8f8eb90d60afbb6cb4b21566552b6a8f3bd1e8` tip.
- Published both required branches to the new BlueStacks FFmpeg, Stagefright
  plugin, and v86d A16 repositories and read all six refs back successfully.
- Published root follow-up `cac24e164bb53210c4f003405d3f00ded63c37da`,
  which points those three module URLs at their formal BlueStacks repositories.
- Published all 45 promoted component tips to the BlueStacks
  `bst-v5.22.210-A16` branches and read back both source and target tips with
  zero mismatches.
- Published root `d3e80def2ce05594d50cee4819e8a85c20757617`, which advances the
  14 component gitlinks changed by the target-history merges.
- The remote build workspace remains at validated root
  `2be2bd594015046288f67420c72ac3d964595d14` because its GitHub fetch timed
  out during the metadata-only follow-up sync. Its pre-existing `.gitignore`
  remains the sole worktree modification. Before the next build, fast-forward
  the root to `d3e80def2ce05594d50cee4819e8a85c20757617` and rerun identity
  preflight; no existing artifact is attributed to the current root.
- Opened Draft PR
  [bluestacks/android-16#3](https://github.com/bluestacks/android-16/pull/3)
  from `mark-bst:aosp16-bst-merge` to
  `bluestacks:bst-v5.22.210-A16`. Its description now records the 45-component
  closure, new root, stale validation boundary and open runtime blocker; the
  pull request remains Draft.
- Closed superseded PR
  [bluestacks/android-16#2](https://github.com/bluestacks/android-16/pull/2),
  which targeted the old `aosp16-bst` branch, and linked it to PR #3.

PR #3 remains Draft and must wait for a new incremental build, boot regression,
and the runtime blocker. No repository upload remains pending and no PR was
merged.
