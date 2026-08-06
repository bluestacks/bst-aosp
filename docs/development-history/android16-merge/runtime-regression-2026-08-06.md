# Android-16 Runtime Regression - 2026-08-06

## Scope

This record separates failures reproduced with the previously deployed HD
artifact from validation of the next Android-16 build. It does not treat old
artifact behavior as evidence that the current source commits have passed boot
validation.

Old deployed Root identity:

- source tree: `~/android-16`
- root commit: `3e9d155230055db8eec1d2294186fb4b470620a2`
- product: `android_x86_64`
- Root SHA-256: `0b4a93e20eb592114e58f99b930d044d98075c1a3ff169e0718a0141286c1573`

The first clean-data boot passed the seven Layer 2 boot gates in 171 seconds.
That result is only the baseline used to reproduce the regressions below.

## Findings

### Launcher package-state race

The HOME resolver selects
`com.uncube.launcher3/com.bluestacks.launcher.activity.HomeActivity`, but the
launcher can crash while querying launchable activities during early package
scan. The remote exception reaches `AppsFilterBase.shouldFilterApplication()`
with a stale resolve result whose `PackageStateInternal` is null. A subsequent
HOME start can leave WindowManager transition collection stuck.

The same failure is not launcher-specific. On a later baseline reboot,
SystemUI called `LauncherApps.getActivityList()` after the seven host boot
oracles had passed, hit the same remote null dereference, entered a persistent
crash loop, and left HD-Adb offline. The boot verifier therefore adds a
post-oracle stabilization window and treats this stack as a boot failure.

The Android-16 adaptation drops stale activity and service resolve results in
`ComputerEngine.applyPostResolutionFilter()` before calling `AppsFilter`. This
is fail-closed: the stale package is not exposed to the caller. The normal path
adds only a null branch; warning emission occurs only for the exceptional race.

#### Patch review and identity

- archived patch:
  [`frameworks-base-stale-package-resolve.patch`](../../../patches/android-16/a13-completion/frameworks-base-stale-package-resolve.patch)
- target component: `frameworks/base`
- changed file:
  `services/core/java/com/android/server/pm/ComputerEngine.java`
- component commit:
  `5acece03e566c739235304c30a81afb7e7a3256c`
- root gitlink commit:
  `4eb695060852919cdb100617f4880c737bc9bdcf`
- stage: `android16-promotion`
- result: `current`, with runtime validation pending

The activity and service paths have the same lifetime hazard and therefore
receive the same guard. Removing a stale result is necessary because passing a
null package state into `AppsFilter` crashes the caller; keeping such a result
would also return an object whose package disappeared from the current package
snapshot. The change deliberately does not reconstruct state, retry resolution,
or alter visibility policy, which keeps it narrowly aligned with Android-16
snapshot semantics.

Code review found no new privilege or information-disclosure path. The null
case is fail-closed and the existing filtering behavior is unchanged for valid
results. The normal-path performance cost is one predictable null check per
resolved activity or service. Warning formatting and logging occur only in the
race case. A retry was rejected because it would add locking and query cost to
the package resolution hot path without guaranteeing that a concurrently
removed package becomes valid again.

This is an Android-16 runtime adaptation discovered during promotion regression,
not evidence of an omitted A13 source commit. Its necessity is established by
the old artifact's uncube Launcher and SystemUI crash traces. Acceptance still
requires a clean-data boot of the new image followed by the post-oracle
stabilization window and explicit Launcher/SystemUI crash scan.

Final validation remains pending. It must prove that HOME reaches the uncube
launcher without an uncube crash, package-state null dereference, or transition
flush failure.

### Shared-folder payload missing from the old image

The guest has `bst.config.mountsf=1` and the init service declaration, but
`/system/bin/mountsf`, `/mnt/windows`, and `/sdcard/windows` are absent. Starting
the service reports that `/system/bin/mountsf` does not exist.

The payload is not an Android source module. It is the long-standing tracked
`app-player/bst/bin/mountsf` script (SHA-256
`439cfb6c27f88b6a335bc59bfbec3ceb3cccd334d5370e7c3c405452fdf9c0a3`), and the
existing Root packaging Makefile copies it into `system/bin`. The old
`system.img` also lacks the sibling external tools and the BlueStacks build
identity, showing that it was produced without the complete app-player
injection stage. No duplicate prebuilt is added to the Android tree.

The omitted stage was identified precisely: the target-only
`g1_stage_system.sh` path used `rsync --delete` from Android OUT and then added
only APK, overlay, and HAL changes. It did not invoke the established app-player
Makefile payload and build-property steps. The active full-package entry now
delegates to app-player, while the target-only repack refuses to emit a release
Root when those payloads are absent.

Final packaging validation must inspect the newly generated `system.img` and
the deployed guest for `mountsf`, then prove that the configured shared-folder
mount is usable.

### Property files

Post-data loading now makes the `.bstconf.prop` runtime values visible;
`bst.max_fps=60` matches. The baseline also contains 15 duplicate property
entries and an unlabeled externally generated `.bstconf.prop`; these are HD
input and relabel findings, not missing Android-16 file-context changes, because
A13, AOSP16, and Android-16 have no dedicated path rule for these files.

The old image has 17 `ro.build.*` mismatches against `.bluestacks.prop`. Its
`system.img` contains the AOSP engineering `build.prop` rather than the
BlueStacks packaging input, so these mismatches share the incomplete packaging
root cause with `mountsf`. The next complete package must be checked again.

## Baseline Passes

The old artifact passed static or service-level checks for audio, SurfaceFlinger
and EGL, Widevine HIDL services, Houdini/native-bridge payload presence, and the
core `bst.*` instance properties. Telephony identity changes made after this
artifact cannot be credited by this run.

## Next Build Gate

The next build must start after 19:30 China Standard Time, use only
`~/android-16`, lunch `android_x86_64-trunk_staging-eng`, and run with at most
eight jobs. Before deployment, bind the root and component commits to hashes of
the new Root, `system.img`, and `system.sfs`. Boot, property, Launcher, shared
folder, network, telephony, DRM, audio, graphics, and Houdini checks must then be
rerun on clean Data.

The automated runtime gate now covers the stable readback subset of that list:
uncube HOME and crash stability, shared-folder mount, Houdini/native bridge,
kernel entropy availability, an IPv4 default route, virtual-SIM operator
format, the `bstime` payload and running `imeservice`, both Widevine HIDL 1.3
factories, and the audio, graphics, camera, connectivity, phone and subscription
Binder services. Fake-Wi-Fi API presentation, real camera frames, media
playback, and external network reachability remain explicit application or host
oracles; service presence alone must not be reported as those behaviors passing.
