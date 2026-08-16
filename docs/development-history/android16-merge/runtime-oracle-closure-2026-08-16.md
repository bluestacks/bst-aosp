# Android 16 Runtime Oracle Closure, 2026-08-16

## Scope and identity

This record closes the remaining executable A13-to-A16 runtime oracles and the
GMS cold-boot regression found during that review. Only the markxu Android 16,
app-player, release, and local `Tiramisu64` paths were used. No AOSP16 source
or output was read, Android 13 was not built or run, and no Henry process or
workspace was inspected or changed.

The Windows host was locked. Graphics and interaction evidence therefore uses
guest ADB framebuffer pixels, guest UI hierarchy, Android services, and host
protocol readback. A Windows screenshot is not evidence in this cycle.

| Item | Identity |
| --- | --- |
| Android root before final gitlink commit | `aosp16-bst-merge` / `eb146d4c3b26dbd8447e74f343020015ee85ced7` |
| Android root final commit | `82f24848a502fac3b2542b54aa26398355ee082c` (`[A16] Fix GMS provider startup after unlock`) |
| `frameworks/base` | `0791b84e1687eeeea19276593f09359c0b6bde4b` |
| app-player | `bst-v5.22.210-A16` / `ea1e0f040393dac4cec6af7d6d472a8da332f9c6` |
| product / OUT | `android_x86_64-trunk_staging-eng` / `out_nxt_Baklava64` |

## GMS cold-boot regression

### Finding and root cause

Every pre-fix cold boot produced a deterministic
`com.google.android.gms.persistent` null-pointer crash in
`ActivityThread.installProviderAuthoritiesLocked()`. DropBox retained examples
at `06:48:45`, `07:21:25`, `07:45:58`, `07:47:41`, `07:49:08`, and
`08:15:03` on 2026-08-16. GMS restarted later, so a process-alive check alone
had hidden the startup failure.

GMS and GSF contain overlapping provider authorities. Android 16
`ComponentResolver.addProvidersLocked()` rejects the duplicate names and
leaves a provider with a null authority when all its names conflict. The user
unlock path in `ContentProviderHelper.installEncryptionUnawareProviders()`
then scheduled every package provider without checking whether PackageManager
had registered an authority. The client process eventually called
`split(";")` on that null value. The normal post-unlock provider query did not
use this unfiltered list, which explains why the restarted GMS process stayed
alive.

### Minimal fix and code review

`frameworks/base` commit `0791b84e` skips a provider in the user-unlock late
installation loop when `ProviderInfo.authority` is null and emits a warning
with the provider class name.

- Necessity: blocking startup correctness fix; the crash occurred on every
  observed cold boot before the change.
- Scope: five added lines in
  `services/core/java/com/android/server/am/ContentProviderHelper.java`; no
  client, PackageManager registration, manifest, or GMS payload change.
- Correctness: a provider without any registered authority cannot be reached
  through ContentResolver, so scheduling it contradicts PackageManager's
  conflict decision. Providers retaining at least one authority are unchanged.
- Performance: one null comparison per encryption-unaware provider during user
  unlock; no steady-state or per-request cost.
- Security: preserves authority uniqueness and does not relax visibility,
  permissions, SELinux, or cross-user checks.
- Compatibility: A13 source was inspected only for comparison and was not
  changed. Its older payload does not create the observed conflict. A broad
  `ActivityThread` null guard was rejected because it would mask malformed
  provider lists from other server paths.

### Incremental build and deployment

The canonical app-player flow ran with `--incremental --jobs 8`. It did not
remove the Android OUT directory. The affected `services.core`, `services.jar`,
`system.img`, and packaged `system.sfs` were regenerated; unaffected HD module
steps mostly reported no work. Build and packaging completed successfully in
20:38.

| Artifact | SHA-256 / identity |
| --- | --- |
| `Root.vhd` | `0fcdb9e6e8369758d2c9f97a91a0816a9fed891a1ffed2346e9cf7e12432f904` |
| `fastboot.vdi` | `375f2e2fbafd4aaaf0d812370d1dc9495a2dcd8b3f111269d7e12d1395777906` |
| Root UUID | `54e9ad31-a169-4d5b-a0e0-705d62e96e71` |
| fastboot UUID | `91b80c95-aa7d-459d-93e4-c479f5babbb7` |
| generated at | `2026-08-16T08:47:29+08:00` |

The Windows deploy gate rehashed both files and read both on-disk UUIDs before
replacement. It preserved timestamped backups and changed only the
`Tiramisu64` instance.

### Runtime acceptance

Two consecutive cold boots passed all boot, host-GL, and guest-framebuffer
oracles. The first 1600x900 frame had non-black ratio `0.997788` and SHA-256
`dc2984e02e6b129e60919ca2301b11a7fdf7ef44ee68991ced98e289d15aad8d`;
the second had ratio `0.974381` and SHA-256
`4caa6b2bbd8a8defaca2a69a6642f238349753ab8290982b8c6b7c46ecaa8bab`.
The second boot ID was `7522411a-ad87-43a7-94e4-ec13a6dde8c2`.

On the second boot, SystemServer logged the expected skips for
`GservicesProvider` and `GoogleSettingsProvider`. GMS persistent and Play Store
remained alive, Play resolved and launched, current-boot logs contained no
matching NPE, and DropBox's latest matching GMS entry remained the pre-fix
`08:15:03` record. No current-boot UBSAN, Oops, panic, RCU stall, or vboxsf
fault was found.

The post-fix package also passed:

| Gate | Result |
| --- | --- |
| Runtime regression | PASS after the required stability window |
| Property precedence | PASS, 455 exact values and zero critical mismatch |
| Dynamic FPS | PASS, exact `60 -> 30 -> 60` periods with bounded CPU deltas |
| ADB policy | PASS; restored policy SHA-256 `afaa1ab10855378ffbeaa544f8d3c0de705bee4ebc271d0974ac19a5a2f8be92` |
| Shared folder | PASS; runtime guest write plus host ADB push/readback |

## Remaining A13 behavior groups

The supplemental pass closed the matrix items that were still described as
manual despite being testable while the host was locked:

- Recents: opening Recents cleared the injected host mouse-action property,
  swiping removed the Chrome task, and selecting a card resumed Chrome. The
  guest framebuffer SHA-256 was
  `36a97fe7d1c43cbeb872ec183902fa9f9f4c073f35014680ba10ad5be2034fa8`.
- Taskbar/HOME: the guest UI hierarchy contained no taskbar and HOME resolved
  to `com.uncube.launcher3/com.bluestacks.launcher.activity.HomeActivity`.
  Guest frame SHA-256 was
  `e8cab2560e4811e0ceb361821c439c5ca86607f8da97e28f0fe0e4b21aa0fc22`.
- Settings: Wi-Fi, Display, Storage, Security, Locale, Accounts, Sound, and
  Developer Settings resolved to their expected activities without a
  Settings or SystemUI crash.
- Storage/vold: a 128-small-file plus 1 MiB workload, rename, append, sync, and
  host-to-guest round trip passed. Guest and host both saw 129 files. The blob
  hash was `30e14955ebf1352266dc2ff8067e68104607e750abb9d3b36582b8af909fcb58`;
  no quota, vold, vboxsf, UBSAN, Oops, or panic signature appeared.
- Graceful shutdown: `bst.config.start_shutdown=1` reached S5 in about 2.3
  seconds, wrote `/sdcard/.bstshutdown_sync`, and did not use the 20-second
  forced fallback. The following formal cold boot passed.
- HAL/service registration: expected HIDL audio, camera, ConfigStore, DRM,
  light, power, and SoundTrigger instances were present; AIDL memtrack, power,
  and Bluetooth services and their processes were alive. Lock settings was
  disabled as intended.
- SIM locale: the source fallback order is `persist.sys.locale` then
  `bst.locale`. This `android_x86_64` product does not publish the telephony or
  subscription Binder API required to execute the SIM locale call, so the
  runtime case is product-not-applicable rather than a failed regression.

## Residual coverage boundaries

No known automated regression remains open for the reviewed promotion set.
Two coverage boundaries are intentionally not reported as passes:

- Human-audible host output was not observed by a person. Audio service,
  routing, and AudioTrack API behavior passed.
- A broad third-party application corpus, including app-specific Skia and
  native-bridge behavior, was not executed. The direct Canvas, ARM64 JNI,
  Houdini map, cpuinfo, and binfmt mechanisms passed in their hash-bound
  oracles.

Authorized protected-content playback remains a separate product/license test,
not evidence that can be inferred from DRM service registration.
