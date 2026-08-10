# Promotion Record

> **Superseded candidate:** PR
> [bluestacks/android-16#1](https://github.com/bluestacks/android-16/pull/1)
> was closed on 2026-07-31. The result below is historical evidence, not the
> current promotion baseline. See
> [rework-audit.md](rework-audit.md) for the active review and correction set.

## Frozen Input

The promotion input is the validated AOSP16 state represented by the cont.101
green baseline, the 82 archived patch/diff artifacts, untracked source payloads,
registry entries, checkpoints, and explicit project commits. A commit-only
comparison is insufficient because cont.101 identified verified source that had
not yet been committed.

## Merge Expansion

The initial hard-coded project list covered 20 projects. Cross-checking against
the local patch archive found six omitted projects:

- `device/generic/common`
- `device/generic/x86_64`
- `hardware/google/aemu`
- `hardware/libhardware`
- `system/hwservicemanager`
- `system/libhidl`

The final branch audit recorded 1016/1016 initialized projects:

- 985 projects on `aosp16-bst`.
- 31 projects on `aosp16-bst-merge`.
- No detached or unexpected branches.

Primary evidence:
[`progress/porting-log.md:2437-2530`](../../../progress/porting-log.md#L2437).

## Conflict Decisions

| Conflict | Decision | Reason |
|---|---|---|
| kernel boot cmdline `baklava64` vs `tiramisu64` | Keep `tiramisu64` | Matches the deployed Engine instance contract |
| kernel empty parameter list vs `(void)` | Keep `(void)` | Equivalent behavior with modern C declaration |
| r4 AEMU `gfxstream_defaults` disable | Preserve Android-16 25Q4 host variants while retaining one selected guest provider | The newer host Vulkan modules require host support; duplicate guest HAL ownership is still forbidden |
| hwservicemanager `/system` migration | Restore 25Q4 system_ext placement and compatibility links | Required by the newer shared-system-image model |
| build/make generic product change | Restore 25Q4 implementation | Avoid missing common-architecture dependencies |
| external goldfish-opengl-pie integration | Keep the established external tree and build it explicitly; avoid broad duplicate-provider scans | BlueStacks EGL/gralloc/HWC remains required, while 25Q4 AEMU host modules must also remain buildable |
| HD guest integration | Preserve `../hd/Source` scanning and export `APP_PLAYER_DIR`/`HD_SOURCE_TOP` | Required by BlueStacks host-guest IPC modules |
| qvirt vs `android_x86_64` | Remove the second product and transfer only its proven runtime overrides after common inheritance | Keeps the Windows board identity stable and avoids a divergent package/VINTF graph |

These decisions preserve BlueStacks behavior where it is product-specific while
retaining Android-16 mainline infrastructure where r4-era substitutions would
break the evolved 25Q4 tree.

## First-Candidate Target-Tree Validation

The first purported Android-16 build was invalid: `g1_build.sh` changed directory
to `~/aosp16`, so its successful output belonged to the development tree.
Promotion validation was restarted with a target-specific build script and
readback of cwd, Git root, branch, HEAD, and OUT_DIR.

The withdrawn candidate produced this Android-16 result:

- Root branch at the recorded validation point:
  `aosp16-bst-merge`, commit `9254e5d`.
- Vendor manifest MD5 `be3fe5cbf66be87b89af9f9ba0857c05`.
- Root image MD5 `5dea6c256bbf7bae1bb1061153312b68`.
- Fastboot image MD5 `40892c6e7b5b4ddd922bd88a994b5f6f`.
- Fastboot UUID `91b80c95-aa7d-459d-93e4-c479f5babbb7`.
- Layer 2 7/7 at 123 seconds.
- Guest ready at 86.6 seconds, host ready at 92.1 seconds, launcher displayed
  at 112.4 seconds.

No AOSP16 build artifact was used for that build/package/boot loop.

## Publication

The first candidate component commits were pushed to `mark-bst` on
`aosp16-bst-merge`. The root integration branch contains seven root commits and
41 changed files and was submitted as
[bluestacks/android-16#1](https://github.com/bluestacks/android-16/pull/1)
against `aosp16-bst`. That PR is now closed and must not be used as an accepted
merge or publication record.

Future publication checks must verify that every root gitlink SHA is reachable
from the expected component remote; a root PR URL alone is not sufficient
evidence.

## Rework Publication

The rework path-set audit found no missing project from the 1011-entry AOSP16
manifest. After synchronizing `bluestacks:aosp16-bst` at `33cdca5`, Android-16
records 1022 submodules. The mainline inline `hardware/bst/camera` source
supersedes the duplicate camera submodule and includes the 64-bit
`MessageQueue::arg0` fix. The final branch distribution is 987 base plus 35
merge projects, with no dirty tree, detached HEAD, gitlink mismatch, remote
SHA gap or nonconforming commit title.

The reviewed root is `298403aba7234f2f120170f49e6afe7dcde16be9` and is
published as
[bluestacks/android-16#2](https://github.com/bluestacks/android-16/pull/2).
The target-only `m droid` build passed in 08:50, external graphics rebuilt 155
actions, and Windows reached all seven boot oracles in 86 seconds. Artifact
SHA-256 identities are:

- `system.img`: `f4c4a75d94e5253c73c63e9874ab8e1a982653aecf6ff264c3ac221aa48a6226`
- `system.sfs`: `d7272562caef4522750b8c23cef760306d90a60625f2e7539dc3b8b604b0850e`
- `Root.vhd`: `d9d728039085df177d11f7e4ce47415a917b24cee161203e724b34f5a183842e`

Every root-referenced modified component SHA was pushed to and read back from
its `mark-bst` fork. PR #2 reports no conflict with the current base and is
ready for mainline review; it has not been merged by this workflow.

## A13 Authority Completion Publication

The preceding rework record remains the evidence for root `298403a`; it is not
the current PR tip. The code-level A13 authority review expanded the final tree
to 1025 submodules and restored omitted runtime areas rather than treating the
earlier PR as complete.

Current publication identity:

- Root: `5c8f8eb90d60afbb6cb4b21566552b6a8f3bd1e8`.
- Branch distribution: 975 `aosp16-bst`, 50 `aosp16-bst-merge`.
- Full target build, supplemental libraries, system image and package: pass.
- Root.vhd SHA-256:
  `8d8afc15d0f8a183bcd1259e30e56c007c2eafbdb32d5aafdf6ad4bb78752cd7`.
- Windows Layer 2: 7/7 at 168 seconds.
- Final `--check-remotes` audit: 1026/1026 initialized, zero detached,
  gitlink mismatches, remote mismatches, structural errors and nonconforming
  commit subjects.

Fifteen missing `mark-bst` forks were created. The FFmpeg and stagefright
plugin A16-named forks retain their A13 upstream fork relationship; v86d keeps
the existing A13 repository name. Both `aosp16-bst` and
`aosp16-bst-merge` tips were pushed and read back for every new fork. Existing
modified forks were advanced only after proving that every update was a fast
forward.

The root path `.` was unintentionally included in the final component push
batch, so the root remote moved before the intended final component readback.
No content diverged: the subsequent complete 1026-repository audit reports
zero remote mismatches. Exact repositories, branch tips, audit identity and
the process deviation are recorded in
[`evidence/2026-08-05-publication-closure.json`](evidence/2026-08-05-publication-closure.json).

PR #2 remains open and conflict-free. Its description was updated to the
current topology, artifact hashes, 7/7 boot result, runtime limitations and
publication evidence. This workflow did not merge the PR.

## Component Target Merge Closure

PR #2 was later closed and superseded by Draft PR
[bluestacks/android-16#3](https://github.com/bluestacks/android-16/pull/3),
which targets `bst-v5.22.210-A16`. On 2026-08-10 every promoted component was
merged or fast-forwarded into its BlueStacks target branch before the root PR
was updated. Final readback reported 51/51 exact target tips and 51/51 exact
source tips.

Root `d3e80def2ce05594d50cee4819e8a85c20757617` records the 14 gitlinks that
changed during component merging. The special kernel merge preserves the
Android 16 kernel 6.12 target and `baklava64` identity while explicitly porting
the missing SquashFS configuration. See
[`component-target-merge-2026-08-10.md`](component-target-merge-2026-08-10.md)
for the full matrix and conflict decisions.

Root `90f87eed8d0bbd1bed49f077f775309bd9f2d843` is the final ownership metadata
follow-up. Six omitted ALSA/HAL components were fast-forwarded on their
BlueStacks target branches before their personal-fork URLs were replaced. The
final `.gitmodules` contains only BlueStacks URLs and every explicit branch
tracks `bst-v5.22.210-A16`.

No build or boot validation is attributed to this new root. The latest green
artifact evidence remains bound to `2be2bd594015046288f67420c72ac3d964595d14`.
PR #3 therefore remains Draft pending a new incremental build, focused boot
regression, and closure of the exact `bst.*` lookup/shared-folder blocker.
