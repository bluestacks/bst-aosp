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

### Android-x86_64 legacy HAL manifest gap

The A13 final `device/generic/common/manifest.xml` declared the legacy HIDL
providers used by its generic x86_64 product. The AOSP16 development line later
reduced the common manifest to audio, graphics fragments, and
`android.hidl.manager`; promotion retained that reduced file while changing the
Windows product from qvirt to `android_x86_64`. The board migration therefore
lost declarations for several services that `device/generic/common/treble.mk`
still packages and init still starts.

This is a code-level omission rather than a binary or packaging-input issue:

- Light 2.0, Power 1.0, Camera Provider 2.4, ConfigStore 1.1, Media OMX 1.0,
  DRM 1.0, and their init rc files are present in the Android-16 installed-file
  inventory, but none of those HIDL modules supplies a VINTF fragment.
- SoundTrigger 2.3 is loaded by the retained HIDL audio service and likewise
  has no service-owned fragment.
- Sensors 1.0 is a passthrough provider rather than a daemon. The canonical
  app-player build enables `BUILD_EXTERNAL_BLUESTACKS_SENSORS` and installs
  `sensors.default` plus `android.hardware.sensors@1.0-impl` for 32-bit and
  64-bit, but the Android-16 device manifest does not declare it.
- The old runtime log independently recorded 673 rejected Light 2.0
  registrations, 671 rejected Power 1.0 registrations, and 34 rejected
  SoundTrigger 2.3 registrations. These counts are diagnostic evidence from
  the old Tiramisu64 deployment, not current-image boot credit.
- The existing review decisions incorrectly said that Light, Power, ConfigStore,
  and the retained HIDL DRM default service owned their declarations, and
  incorrectly treated Sensors as unselected. Source, generated-output, and
  canonical app-player build readback disprove those statements. The Widevine
  1.3 service is different: its generated module-owned fragment already
  declares both Widevine factories and must not be duplicated by the board.

The minimal adaptation is prepared as
[`device-generic-x86_64-legacy-hal-vintf.patch`](../../../patches/android-16/a13-completion/device-generic-x86_64-legacy-hal-vintf.patch).
It attaches one Windows-product-only device manifest and adds level-8 framework
matrix bridges only for legacy HIDL interfaces no longer accepted by the stock
Android-16 matrix. Media OMX, RenderScript, and SoundTrigger need device
declarations but no custom matrix entry because frozen FCM 8 already accepts
their exact HIDL versions.

Bluetooth, Dumpstate, GNSS, Memtrack, USB, and KeyMint are deliberately not
redeclared as A13 HIDL HALs: current AIDL services or APEXes provide their own
verified fragments. ClearKey similarly stays on the Android-16 AIDL service;
the retained Widevine 1.3 service keeps its module-owned HIDL fragment and
existing framework bridge. Sensors
1.0 is retained as a passthrough HAL: the app-player build selects and installs
both `sensors.default` variants and both `android.hardware.sensors@1.0-impl`
variants. It therefore needs the A13 device declaration and an FCM 8 bridge,
but no standalone service binary.

The patch adds metadata only and no daemon, polling loop, or data-path code.
Its normal-path performance cost is therefore negligible; enabling already
packaged services should remove failed registration/restart work. Security
impact is limited to making the intentionally retained legacy HAL endpoints
visible to the framework on `android_x86_64`. This is explicit compatibility
debt and remains scoped away from common, arm, and retired qvirt products.
Patch structure, XML parsing, and `git apply --check` pass. It must not be
applied to the remote component until the active full build has stopped using
the frozen source tree. Acceptance requires `check-vintf-all`, component and
root commits, a target-only incremental rebuild, and clean-Data runtime
registration checks.

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

The automated runtime gate now covers the stable shell-readable subset of that
list: uncube HOME and crash stability, shared-folder mount plus a real write and
read, device-side `xmllint`, non-mutating lock-settings readback,
Houdini/native-bridge payloads, kernel entropy availability, an IPv4 default
route, Wi-Fi MAC property/file consistency, virtual-SIM operator format,
`bstime`, `imeservice`, retained HIDL registrations, current AIDL HAL services,
and Settings/BlueStacks Settings launch and return-to-HOME smoke tests.

| Oracle | Automated evidence | Remaining acceptance evidence |
| --- | --- | --- |
| Launcher/SystemUI | 95-second boot-ID and `system_server` stability, uncube HOME, crash/watchdog scan, return from Settings | Host navigation, taskbar and recents policy |
| Shared folder/storage | Mounted path and exact probe-file write/read/cleanup; valid XML parsed under `/data/local/tmp` | Host-to-guest transfer and configured screenshot path |
| Wi-Fi/network | Route, valid `bst.wifi_mac_addr`, `.ma` equality, service health | Unprivileged app `WifiInfo`/`DhcpInfo`, captive-portal behavior, external reachability |
| HAL/media | Exact HIDL/AIDL service registration, audio/camera Binder presence | Real camera frames, audio playback/capture, Widevine playback, Skia rendering |
| Houdini | Native-bridge properties, payloads and binfmt entries | Known ARM64 APK install and translated execution |
| Settings/lock state | `locksettings get-disabled`, platform Settings and BlueStacks Settings launch without fatal crash | Interactive page navigation and user-visible policy checks |
| Download retry | None from shell because shell is an authorized caller | Unprivileged app must be denied; authorized provider path must retry |

Service presence or shell readback must not be promoted into a pass claim for
the remaining application and host behaviors. The test-app/manual column is a
required gate, not optional follow-up.

The temporary app-UID oracle is now implemented under
[`tests/android16-runtime-oracle`](../../../tests/android16-runtime-oracle/README.md),
with the bounded Windows runner
[`g1_app_runtime_oracle.ps1`](../../../scripts/g1_app_runtime_oracle.ps1). It is
not runtime evidence yet. Local API-34 `android.jar` compilation, D8 conversion,
AAPT2 packaging, zip alignment, v3 APK signing/verification, manifest XML, Bash
syntax, PowerShell parsing, and `-CheckOnly` pass. The lightweight build omits
javac debug metadata because
build-tools 34 D8 rejects JDK 21 anonymous-class debug metadata; this does not
change executable code or oracle coverage. Target Android-16 APK assembly and
guest execution remain blocked on the active full build. The
runner requires independent DownloadProvider rejection for the installed app
UID and uninstalls the APK in `finally`. Camera acceptance requires a non-empty
YUV frame, while AudioTrack acceptance proves the guest playback pipeline only,
not audible host output.

All 32 ledger entries that still require runtime evidence are mapped without
commit omissions in
[`a13-runtime-oracle-matrix.md`](a13-runtime-oracle-matrix.md). The corrected
count replaces the earlier broad text-search count, which could mistake
`PendingIntent.java` for a pending validation result.

The stability gate is 95 seconds by default because the old deployed guest can
remain superficially ready for about 82 seconds between watchdog resets. During
that window the gate polls HD-Adb and verifies that the guest boot ID and
`system_server` PID do not change. It also rejects watchdog, zygote/system-server
termination, package-state, and repeated SystemUI crash signatures. A host
`[Ready]` state is never accepted as a substitute for these guest checks.

## Read-only HD Regression

The running old instance was inspected without restart, deployment, Data
changes, log clearing, or HOME launch. HD-Player remained present and the host
log still reported `[Ready]`, but `HD-Adb devices` reported
`emulator-5554 offline`. The readback snapshot contained at least 42 watchdog
events, 142 zygote SIGKILL lines, and 672 zygote service lifecycle lines; the
live logs continued to accumulate events afterward. The repeating sequence is
approximately 81 to 83 seconds:

1. the kernel emits blocked-task, memory, and backtrace sysrq output;
2. watchdog terminates `system_server`;
3. zygote exits because its system server terminated;
4. zygote and framework services restart.

The first retained event in `Player.log.1` occurs at host time `19:58:48` with
guest uptime 6068 seconds. At `20:55:00`, the retained context identifies the
watchdog process and the terminated system-server PID before zygote restarts.
Rotated logs may omit earlier cycles, so this is a lower bound, not the onset
time. The memory dump still shows roughly 3.3 GiB free in DMA32, so the evidence
does not support whole-guest memory exhaustion as the cause.

The exact Java handler that watchdog considered blocked is not available in the
serial Player log. It may be present under guest `/data/anr`, but live Data is
not mounted and the instance is not restarted while it is offline. The next
clean-Data validation must capture logcat and ANR evidence before ADB loss. This
old instance therefore fails boot validation; the host-ready marker is a false
positive and provides no credit to the current source commits.

Legacy light and power HAL VINTF registration errors also repeat in the log.
They are tracked as compatibility noise pending a new-image reproduction and
are not asserted as the watchdog root cause. Repeated audioserver requests for
the missing activity service are consistent with system-server unavailability,
not an independent audio pass or failure.

## Deterministic APK Inputs

The Baklava config originally resolved through links outside the markxu-owned
workspace, and the generated staging directory lacked 17 configured payloads
plus three packaging inputs. The active build now uses a self-contained,
reviewable bundle assembled only from immutable Git/LFS identities and an exact
markxu-owned legacy Root backup. It does not read or modify another developer's
process or workspace.

- preparation script: `scripts/prepare_android16_package_inputs.sh`
- bundle: `~/a16-package-inputs/bst-v5.22.210-A16-e7a61686`
- size/files/APKs: 507,407,646 bytes / 62 files / 49 APKs
- BlueStacks A16 input commit:
  `e7a61686ae5b7c599f0c1e650ea900ac922f97c7`
- Baklava config SHA-256:
  `cb82f64d7c5728e7b5ced336ec01e7dffca43a6f7ec973dc0f99fc199c670010`
- Chrome/Trichrome source commit:
  `fac0e983ac95f32510406e4bf1d2e9eb8eef3cbc`
- legacy Root SHA-256:
  `6ed535717f89bdac8e6318924f39246fe10a95f1adb701f6096d13f43e7153b1`

Independent readback verified `SOURCE.identity`, every `SHA256SUMS` entry, all
35 config or auxiliary paths, and every staged APK as a ZIP. Both active
Baklava config links resolve inside the markxu-owned bundle. Existing bundles
are now verified and reused rather than overwritten; a missing or mismatched
identity fails before installation.

The full-build release staging previously retained files from the August 5
target-only package because the app-player copy phase uses merging `cp -ar`
semantics. Conflicting duplicate APK hashes proved that this could create a
mixed-source Root. The stale active staging and outputs were moved intact to
`~/releases/Baklava64/.pre-full-build-20260806`; they were not deleted. The
current build must create fresh active staging before any artifact can receive
the current-build identity.

## Full Build In Progress

The release-complete app-player build started after the requested 19:30 China
Standard Time gate. Its active attempt began at remote time
`2026-08-06T19:32:01+08:00` and remains in progress; it is not boot evidence.

Frozen inputs:

- Android tree: `~/android-16`, branch `aosp16-bst-merge`, root
  `4eb695060852919cdb100617f4880c737bc9bdcf`
- `frameworks/base`: `5acece03e566c739235304c30a81afb7e7a3256c`
- initialized and clean target repositories: 1025, with only the root
  `.gitignore` allowlisted
- product/lunch: `android_x86_64` /
  `android_x86_64-trunk_staging-eng`
- OUT_DIR: `~/android-16/out_nxt_Baklava64`
- graphics: `goldfish-opengl-pie` at
  `840a3eadac139e3640a604bbd2ff1986c00b74d3`
- app-player: branch `bst-v5.22.210`, root
  `8ed098751ed028c30665b4ce968137d5aba34554`
- app-player Makefile SHA-256:
  `2abca840df831d3c9b9eabb92528d63132ae2033d3f87beebb8bfa0fde2bd0dd`
- complete local build-flow diff SHA-256:
  `aa441a8dde9e76f70cc5e1c73ce35d6a604e5441af2a30b9e7beaef38c109a12`
- concurrency: app-player Make and Android Ninja both resolve to `-j8`

Two pre-build packaging assumptions were found before the active attempt. The
Makefile unconditionally copied a missing `scratch-rosen/apks/*.apk`, then
looked for a nonexistent `scratch-gaurav/gapps_baklava64`. The local app-player
adaptation now skips the optional Rosen APK set when empty, uses the existing
A13-compatible `gapps_tiramisu64` payload for Baklava, and avoids overwriting
the Android-16 native-bridge integration with nonexistent legacy
`3bt/baklava64` libraries. Neither scratch submodule was changed, staged, or
selected for publication, and the app-player Makefile remains an uncommitted
build input under the explicit no-submit boundary.

At remote time `19:52:16`, Ninja had reached `1227/110421` actions with no
`FAILED:` line and an estimated eight hours remaining. The background wrapper
is PID `3932664`; its log and completion code are respectively
`~/android16-app-player-build-20260806.log` and
`~/android16-app-player-build-20260806.exit`. Deployment, clean-Data boot, and
all runtime gates remain blocked until exit code zero and artifact identity
generation complete.
