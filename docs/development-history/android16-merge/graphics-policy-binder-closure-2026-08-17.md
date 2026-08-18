# Android-16 Graphics Binder Closure, 2026-08-17

Stage: Android-16 mainline maintenance
Status: canonical incremental build/package and runtime regression PASS

## Scope

This change closes two related Binder-domain regressions in the Android-16
graphics path:

1. goldfish graphics code could not read the SystemServer `bstfilterapps`
   package policy without destabilizing SurfaceFlinger/HWC startup;
2. vendor Vulkan clients could not find the system-built `RTVboxMM` service and
   aborted Chromium's in-process GPU thread after a five-second lookup timeout.

Only the markxu Android-16/app-player trees and local Windows `Tiramisu64`
instance were used. No AOSP16 tree/output, Android 13 build/runtime, Henry
process, `scratch-gaurav`, or unrelated app-player component was used or
changed.

## Final Source Identity

| Item | Branch / commit |
| --- | --- |
| Android root implementation | `aosp16-bst-merge` / `fdb58550acf66d758cd0785b7d32b5760b614a61` |
| Android root PR head | `aosp16-bst-merge` / `901fee3084925d8581ebb3eee6501039b6dea374` |
| Android root PR base | `bst-v5.22.210-A16` / `7e9105c` |
| `frameworks/native` | `aosp16-bst-merge` / `626929d3cf379373e2aa768642ffbe407fa0d6e5` |
| `system/sepolicy` | `aosp16-bst-merge` / `ef2ccbdecffe6991f58f204aee00e056f9ea08ec` |
| app-player | `bst-v5.22.210-A16` / `1bdbf5b5f0e75cab32e2a4dee65f0bea7447ff7d` |
| goldfish-opengl | `bst-v5.22.210-A16` / `87a539e25bbfe6f3b384118d66827b7d5c4f28b1` |
| HD / VBox | unchanged: `bfbab1b...` / `af3611cc932497d7756409437fc151586e61aa72` |

The app-player root includes the latest remote commit
`794c8e8ce58bec84a61c03b56c956deda9b52c60` before the local A16 commits.

Publication: [bluestacks/android-16 PR #6](https://github.com/bluestacks/android-16/pull/6)
is open and ready for review. The source branch first merged the latest target
at `7e9105c`; the resulting PR has no conflicts and changes only the
`frameworks/native` and `system/sepolicy` gitlinks.

## Failure Sequence

### Stable no-op baseline

Commit `080784acd4` matched the previously verified AOSP16 compile boundary by
making the A16 goldfish-facing manager return defaults. It removed repeated
vendor-Binder lookups for the system-only `bstfilterapps` service and restored
stable rendering, but disabled valid package-specific renderer, extension,
Vulkan and workaround policy.

### Rejected direct-client attempt

Commit `57472db409` introduced a public `libbinder_ndk` client for the existing
SystemServer service. Its public query helpers loaded `libbinder_ndk.so` before
checking the caller UID. SurfaceFlinger, composer and other non-app processes
therefore loaded a second system-Binder client even though they never needed a
policy transaction. It also restored six A13 failure defaults to `true`:

- HPP;
- Intel automatic GL flush;
- GL program binary;
- GL unmap-buffer optimization;
- texture-target check disablement;
- host map-buffer-range.

Two cold boots were black. This implementation is rejected.

### Rejected global driver switch

Commit `0b040ef8f1` changed vendor `libbinder` to `/dev/binder`. The guest booted,
but graphics calls still failed to obtain a compatible typed service, logged
waits, and rendered black. A global driver switch also risks every legitimate
vendor service using `/dev/vndbinder`. It is rejected; vndservicemanager remains
enabled.

## Final Graphics-Policy Design

The final `frameworks/native` implementation starts directly from the stable
no-op baseline and makes two narrow corrections:

- `isAppPolicyClient()` runs before `getNdkBinderApi()`, service lookup, or any
  transaction. System/HAL/vendor service UIDs return an A16-safe fallback and
  never load the system NDK Binder client.
- All six unsafe fallback values are `false`. Application UIDs use only public
  NDK Binder APIs to query the real `bstfilterapps` service on `/dev/binder`.

The service handle is strongly owned, liveness-checked and cached. The code
does not convert `AIBinder` to vendor `sp<IBinder>`, add a daemon/proxy, duplicate
the Java service, remove vndservicemanager, or change global Binder routing.

The zero-based transaction offsets were checked against
`IBstFilterAppsService.aidl`; dispatch adds Binder transaction base `1`. The
mapped methods remain in AIDL order through offsets 121 and 122.

## RTVboxMM Follow-up

With application graphics running, GameCenter exposed an independent Vulkan
failure:

```text
Waiting for service 'RTVboxMM' on '/dev/vndbinder'...
Service RTVboxMM didn't start. Returning NULL
RTVboxGuestServiceConnect::getRTVboxMMServ()
SIGABRT Chrome_InProcGp
```

Runtime readback showed `RTVboxGuestService` had registered `RTVboxMM` on
system Binder while `libvulkan_enc.so` correctly queried vendor Binder.

An intermediate attempt only called `ProcessState::initWithDriver()` from the
system-built service. vndservicemanager rejected its `SYST` stability header
because the binary still linked the system `libbinder` ABI. The final goldfish
change builds the service as a vendor module for A16, installs it under
`/vendor/bin`, supplies an A16 vendor rc, and registers with the `VNDR` ABI.
Android 13 keeps the original system module, rc and default Binder driver.

## Patch Review Matrix

| Commit | Purpose | Necessity | Performance / security | Result |
| --- | --- | --- | --- | --- |
| `frameworks/native` `626929d3c` | expose one manager ABI and route all vendor graphics-policy queries through the app-gated system NDK Binder client | required to remove the header ABI split while retaining real package policy | no non-app Binder work; cached app service handle; no global Binder-domain change | current, canonical PASS |
| `system/sepolicy` `ef2ccbdec` | label `bstfilterapps` as an app-visible SystemServer service | required for the app-side client when enforcing policy is completed | read-only service discovery; no writer or bypass | current; permissive guest means enforcing acceptance is pending |
| goldfish `8fd66dd4` | select `/dev/vndbinder` in the A16 RTVbox service entry | identifies the correct service domain while retaining the A13 default path | removes failed system-domain routing; alone still linked system Binder ABI | superseded in isolation by `87a539e2`, retained in final series |
| goldfish `87a539e2` | build/install RTVbox as an A16 vendor module with a vendor rc | required to emit the `VNDR` Binder header and match vendor Vulkan clients | removes five-second lookup/abort; no proxy or duplicate service | current, targeted PASS |
| app-player `87dde7fcc` | merge latest remote `bst-v5.22.210-A16` odex staging fix | required to build from the actual current branch | no graphics behavior change | current |
| app-player `65ddb7d5f`, `9cb835667` | advance the goldfish gitlink in component-first order | required for reproducible app-player builds | metadata-only | current |
| app-player `1bdbf5b5f` | reject missing vendor or stale system RTVbox paths and record the goldfish SHA | required because incremental OUT retained obsolete system installs | package-only check; no build behavior change | current, canonical PASS |
| Android root `fdb58550a`, `901fee308` | first advance native/sepolicy together, then advance native to the unified client | required for the root PR to reproduce the reviewed closure | metadata-only | current |

## Review

### Necessity

The app-only system-Binder path restores policy that the no-op workaround
disabled. The vendor RTVbox service is required because Vulkan treats a missing
service as fatal. Both changes repair existing contracts rather than adding a
new cross-partition API.

### Performance

Non-app graphics processes now pay only a UID comparison and no Binder load.
Applications perform synchronous policy transactions during graphics
initialization; the service handle is cached and there is no polling thread or
per-frame work. RTVbox removes a five-second failed lookup. Package-result
caching remains a possible later optimization if profiling finds repeated hot
calls.

### Security

`bstfilterapps` stays in SystemServer and receives no write API or bypass. Its
service type is `app_api_service`; only app UIDs enter the direct client.
`RTVboxMM` now uses the intended vendor Binder domain. The current guest is
SELinux permissive. The targeted package initially reported the vendor files
as `unlabeled`; the canonical image labels them `vendor_file` and
`vendor_configs_file`, but the service still runs as `u:r:init:s0`. This is not
an enforcing-policy acceptance result. Defining a narrow executable type, init
transition and required device rules is a separate hardening task. No broad
temporary allow rule is included in this graphics fix.

### A13 compatibility

The manager now has one source and binary interface. Vendor behavior is selected
by the existing `__ANDROID_VNDK__` build boundary: vendor consumers use the NDK
system-Binder policy client, while system `libbinder` retains its legacy service
path and defaults. `BST_ANDROID16_GUEST` remains only at genuine goldfish
build/API and RTVbox packaging boundaries; it no longer changes the manager
class layout. The goldfish Make conditional leaves A13's service as a system
module using its existing rc and default Binder driver. A13 was reviewed at
source level only, as requested; it was not built or run.

## Targeted Build Evidence

- `libbinder` plus the complete 32/64-bit goldfish closure built successfully.
- The final vendor RTVbox target built successfully and contains
  `/dev/vndbinder`; SHA-256:
  `6cd0754be74efc80000ea45621d7c882911bae409cfbc027ad24dce926f78ca1`.
- No clean, OUT deletion, source sync, AOSP16 artifact, or Henry process was
  used.

The targeted validation Root has SHA-256
`055a67f08cee0e5a5b343f2fbd06b83b7fbf289d69ce99f3ae9b8cf91752a772`
and `system.sfs` SHA-256
`38138f7da555898bb0e83469a91a77f52d888c9028558e46408a38ed30db82e0`.

## Targeted Runtime Evidence

- App-only policy package: three cold boots passed 7/7 lifecycle gates; guest
  framebuffer non-black ratios were `0.998584`, `0.998982`, and `0.999071`.
- Final RTVbox vendor layout: two cold boots passed 7/7; framebuffer ratios
  were `0.992434` and `0.992655`.
- `bstfilterapps` was present on system Binder and `bst.max_fps=60` loaded.
- direct-client success markers belonged to application UIDs; SurfaceFlinger,
  composer and system_server emitted none. No `Waited too long for
  bstfilterapps` message occurred.
- `vndservice list` returned `RTVboxMM`; no startup timeout or GPU abort
  remained.
- SELinux readback was `Permissive`; `RTVboxGuestService` ran in `u:r:init:s0`
  and its vendor files were `unlabeled`. This is recorded as an enforcing
  hardening gap, not counted as a security pass.
- A forced GameCenter restart stayed foreground. Its 1600x900 framebuffer had
  non-black ratio `0.936593`; the previous Chromium GPU abort did not recur.
- Launcher/property/shared-folder runtime regression passed.

## Canonical Build And Package, 2026-08-18

The canonical `build_Baklava64.sh --incremental --jobs 8` run preserved
`out_nxt_Baklava64` and performed 62,657 Soong actions. A changed
`WITHOUT_CHECK_API` environment invalidated substantially more cache than a
small module-only increment; the Android phase completed in `03:15:39` without
cleaning or syncing.

The first package was rejected before deployment because both the new vendor
RTVbox files and stale system files survived in incremental OUT. Only these two
obsolete files were removed from the target product staging:

- `/system/bin/RTVboxGuestService`;
- `/system/etc/init/RTVboxGuestService.rc`.

No OUT directory or unrelated artifact was deleted. A package-only rerun under
app-player commit `1bdbf5b5f` rebuilt the package and passed the new mandatory
layout gate. Independent `debugfs` readback found the vendor binary and rc and
confirmed both stale paths absent.

Final package identity:

- `system.img`: `bb604f5423e2d13dab43b6157975a3576e26e01e9f6354a1845ea09544b10033`;
- `system.sfs`: `b81e90163a5bd51afb41a0b2304e1cfb05416964cb9a53ecacec78bd8f758759`;
- `Root.vhd`: `ddfdace92976d45663a0d0da18dca4fb2484d466f3d17595b7dc32cf741b0720`;
- Root UUID: `54e9ad31-a169-4d5b-a0e0-705d62e96e71`;
- fastboot SHA-256: `cb9d26aa3265d6d874cd1c9992aceed293b462ebd25c05982fc961907d4b6432`;
- generated at `2026-08-18T03:57:36+08:00`.

## Canonical Runtime Acceptance

- First cold boot: 7/7 lifecycle gates, 95-second stabilization, 1600x900
  framebuffer `non_black_ratio=0.994867`, elapsed 149 seconds.
- Standard Launcher/property/shared-folder runtime regression: PASS.
- Forced GameCenter restart: foreground, framebuffer
  `non_black_ratio=0.992478`, no service wait, SIGABRT or fatal exception.
- A second GameCenter-only run confirmed zero `Expecting header`, service-wait
  and fatal messages. The one earlier `VNDR`/`0x0` message was reproduced only
  by the diagnostic `vndservice list` interface probe, not the Vulkan client.
- Second cold boot: 7/7 gates, 20-second stabilization, framebuffer
  `non_black_ratio=0.988319`, elapsed 74 seconds.
- Final readback: system `bstfilterapps` present, `bst.max_fps=60`,
  `bst.prefer_dedicated_gpu=1`, host `GpuPreference=2`, and no Intel vendor
  override.

The functional black-screen and GameCenter Vulkan regressions are closed for
this canonical package. SELinux enforcing-domain hardening remains explicit
follow-up work.

## Unified Native Client Follow-up, 2026-08-18

Commit `626929d3cf379373e2aa768642ffbe407fa0d6e5` removes the
`BST_ANDROID16_GUEST` class split from `BstFilterAppsManager`. All consumers now
see the complete exported manager API. In vendor `libbinder`, the 34 graphics
policy helpers used by goldfish are routed through the UID-gated NDK
system-Binder client; the legacy vendor `getService()` path returns no service
and therefore cannot synchronously query the system-only service through vendor
Binder. Other vendor Binder services and global Binder routing are unchanged.

The change also preserves the A16 compatibility aliases required by goldfish
and fixes the existing null-service dereference in `updateIl2cppPkgs()`.
Static review confirmed that all 30 manager methods currently called by
goldfish are declared by the unified header and select the vendor NDK policy
path. The complete 32/64-bit `libbinder`, OpenGL, Vulkan, HWC and HD packaging
closure compiled incrementally with:

```text
APP_PLAYER_DIR=/home/clouddev/bst/workspace/markxu/app-player \
  bash buildscripts/build_Baklava64.sh --incremental --jobs 8
```

The run used app-player `1bdbf5b5f0e75cab32e2a4dee65f0bea7447ff7d`,
preserved `out_nxt_Baklava64`, performed no clean or source sync, and completed
in 37 minutes 52 seconds. The source checkout used the updated native component
at `626929d3c`; the generated build identity still records root
`fdb58550acf66d758cd0785b7d32b5760b614a61` because the root gitlink commit was
created only after validation. Root commit
`901fee3084925d8581ebb3eee6501039b6dea374` then published that exact component
SHA to PR #6.

Follow-up package identity:

- `system.img`: `fae729ef10b540ba9b5487a3f7dc6570245d83d2af5929fb352839156a305301`;
- `system.sfs`: `d4c89576c4216ef5543e135e63dcb7b36e2afd672d158cfddce1741643bab9eb`;
- `Root.vhd`: `940c7c8cf33244696338d75ebca37e1dda7c1603c7e2d5ee31b5e0e1ac37b8da`;
- Root UUID: `54e9ad31-a169-4d5b-a0e0-705d62e96e71`;
- `fastboot.vdi`: `3876ef98b220d94a9aadae2924efbc519975190af6450957fb8337198ecb0c99`;
- fastboot UUID: `91b80c95-aa7d-459d-93e4-c479f5babbb7`;
- generated at `2026-08-18T11:19:34+08:00`.

The package contains `/vendor/bin/RTVboxGuestService` and
`/vendor/etc/init/RTVboxGuestService-vendor.rc`; both stale system paths are
absent. The first cold boot passed all 7 lifecycle gates. Guest framebuffer
readback on the correct `emulator-5554` transport was 1600x900 with
`non_black_ratio=0.988673`; the standard runtime regression passed. Forced
GameCenter remained foreground with `non_black_ratio=0.998009`, a live
`bstfilterapps` service and RTVbox service, and no Binder wait, RTVbox timeout,
header mismatch, fatal signal or watchdog marker.

Two later cold boots again passed all lifecycle gates and rendered GameCenter
in host-window captures, but the local legacy HD-Adb transport remained
offline, so those boots do not claim an additional guest-framebuffer pass. The
host captures have SHA-256 values
`520866291ef19798da45ec4434f6592b2151e5f8e2c50f970bb0658daa307289` and
`dfed713265af7d19f11bc7bd5f85d1b5747e45e263307cd3d3e51c22eafb1dd7`.
This is recorded as a validation-tool limitation rather than hidden as a guest
graphics result.
