# Android-16 Formal Regression Follow-up, 2026-08-12

## Scope And Identity

This record follows the formal goldfish package regression documented in
[`runtime-regression-2026-08-11.md`](runtime-regression-2026-08-11.md). It
records read-only artifact comparison and Windows runtime checks. No A13 build
or runtime validation was run, and no AOSP16 tree or AOSP16 output was used.

| Item | Identity |
| --- | --- |
| Android-16 tree | `/home/clouddev/bst/workspace/markxu/android-16` |
| Root branch and commit | `aosp16-bst-merge` at `ddc1eeba951ccddea52ef1937138facdf3241909` |
| Product and output | `android_x86_64`, `out_nxt_Baklava64` |
| Goldfish branch and commit | `bst-v5.22.210-A16` at `f6841e72d677a02de240231b56045663948032e1` |
| Root.vhd | `80b25fa7a55ff43b9e1bf4aad7bad9d9c291ecda28d8fb73b2a9d47b2300e7cc` |
| Rebuilt fastboot.vdi | `80557dd7f7bffa428c85b3fad75e3f3ba6b91dffd4d4d80938cae0a7b5049911` |
| Previous green fastboot.vdi | `f7152a98e7c81b719aadc0ddf68294d67c26273aac23b94c65bb28cb6574d445` |
| Kernel in both fastboot images | `166d74107143cd6d31d2dcd650a2fc27b46caf11822a17eb3f40b187246e50b9` |

The package-resume operation did not rebuild the Android platform, but it did
recreate the HD BootImage and `fastboot.vdi`. The first boot of that pair is
therefore retained as a valid failure observation, but the follow-up tests
below change the causal interpretation.

## Boot A/B Results

The first boot with the rebuilt fastboot passed only `system_mounted` and
`init_second`. During `vboxguest.ko` loading, CPU3 emitted RCU warnings and then
repeated expedited-stall reports. Android did not reach odsign, boot completion
or Launcher.

The A/B tests kept the new Root.vhd unchanged:

| Run | Effective fastboot | Result | Stability |
| --- | --- | --- | --- |
| Initial formal run | `80557dd7...` | 2/7, CPU3 RCU stall | failed before Android completion |
| Previous-fastboot A/B | `f7152a98...` | 7/7 | 95-second post-oracle window passed; 227 seconds total |
| Rebuilt-fastboot retest | `80557dd7...` | 7/7 | 30-second post-oracle window passed; 124 seconds total |

The rebuilt image retest reached odsign, boot completion,
`com.uncube.launcher3`, Player ready and boot-progress hiding. The same
`VBOXGUEST_IOCTL_HGCM_CALL` failure and `Malformed guest properties enum
result` message appeared during this successful boot. Those messages are
therefore not sufficient evidence of the RCU-stall root cause.

### Artifact Comparison

Both VDI files contain the same kernel bytes. Their extracted initrds contain
the same 24 regular files and three symlinks. Every payload hash matches,
including:

- `vboxguest.ko` and `vboxsf.ko`;
- all BST audio, camera, input, memory, message and PGA IPC modules;
- `videobuf-core.ko`;
- `init`, `stage2.sh`, `bstsetconf.sh`, `bstsetup.env` and all initrd tools.

File modes, owners, sizes and archive order also match. The uncompressed cpio
archives are both 4,244,992 bytes and differ in 384 bytes of archive metadata;
the meaningful difference is the rebuild timestamp. This disproves the
working theory that the new fastboot contained a different kernel-module
binary.

### Revised Boot Finding

The RCU failure is currently an intermittent boot-time failure consistent with
a race, not a repeatable bad-fastboot result. The first warning occurred in the
module-load window and the stalled CPU was observed in RCU/IPI and idle paths,
so the VBox guest driver and 6.12 interrupt/RCU interaction remain the
narrowest investigation area. The exact offending code path is not proven.

The boot verifier must continue treating the RCU-stall signature as fatal.
Publication also requires repeated cold-start evidence; one successful retry
must not hide a nonzero boot failure rate. No speculative sleep, retry or
module replacement is justified by the current evidence.

## Runtime Regression

The rebuilt-fastboot successful run was used for runtime checks. Launcher HOME
resolved to and resumed
`com.uncube.launcher3/com.bluestacks.launcher.activity.HomeActivity`. The
system boot ID and system_server remained stable. Houdini sanity, IPv4, Wi-Fi,
telephony, retained HIDL registration, current AIDL services, Bluetooth and
Settings-to-Launcher return did not add a new failure.

Two failures reproduce the already documented host-contract gaps:

- `/mnt/windows/BstSharedFolder` exists as `root:root 0770`, but the shell and
  ADB push receive `Permission denied`; no host-visible round trip passed.
- `bst.config.ime_listenerport` is nonzero while `init.svc.imeservice=stopped`;
  the Windows IME listener contract is still absent.

These remain open, but they are not regressions introduced by the formal
goldfish commit.

## Dynamic FPS Regression

The current formal package has a separate, repeatable dynamic-FPS failure.
`bst.max_fps` readback changes from 60 to 30, but SurfaceFlinger Scheduler's
`app duration` remains 16,666,666 ns instead of moving to about 33,333,333 ns.
The oracle restores the property to 60 after failure.

Code-level routing explains the gap:

1. The active `hwcomposer.default.so` is staged from external goldfish
   `system/hwc2/EmuHWC2`, not from `HWC2OnFbAdapter`.
2. The FPS polling and refresh callback in target `hardware/interfaces` commit
   `bf800caa090008c2fbbc1723c6fe814ece6f7eb9` affect only the framebuffer
   fallback and are inactive on this board.
3. `frameworks/native` at `58665c720140f614849a92aad57efb5a28904ba2`
   reads `bst.max_fps` in `Scheduler::resyncToHardwareVsyncLocked()`, but a
   property write alone does not enter that path.
4. Formal goldfish commit `f6841e72` contains no `bst.max_fps` observer and
   emits no refresh callback when the property changes.

The previous 60 -> 30 -> 60 pass remains valid for its earlier diagnostic
runtime identity, but it must not be used as acceptance evidence for the
formal goldfish package. The minimal correction must attach the A13-validated,
bounded property observation to the active `EmuHWC2` provider, publish the
changed period through the existing display attribute, and invoke the standard
refresh callback outside internal locks. It must not introduce another HWC,
change the Windows board, or add unbounded polling.

## Repository Hygiene Observation

The local app-player VBox source used to create the package is at detached
commit `e23c34d1a2f2ce6beda832dfce0c71890fddb798`, while the app-player gitlink
records `2992dc1f267566916fc4bd6c9e03377915d6d158`. Six tracked VBox source files
carry uncommitted Linux 6.12 API adaptations. The extracted A/B module hashes
match, so this state does not explain the different boot outcomes, but it is
not a publishable or reproducible component identity. App-player/VBox remains
outside the current submission and was not modified during this follow-up.

## Current Gates

1. Adapt and review dynamic FPS on the active external goldfish `EmuHWC2`
   path, then run the targeted incremental compile, package and FPS oracle.
2. Run repeated cold starts with the exact packaged Root/fastboot identity and
   record the RCU-stall rate.
3. Resolve the Hyper-V shared-folder host contract and Windows IME listener
   lifecycle, or formally redefine their supported runtime contracts.
4. Formalize the boot-critical VBox 6.12 source state before any package is
   accepted for publication.
5. Keep PR #4 in Draft until these gates and the remaining GMS/native-bridge
   application gates are complete.
