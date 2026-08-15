# Android-16 Graphics Black-Screen Regression, 2026-08-15

Stage: Android-16 mainline maintenance
Status: source fix committed; targeted build and three cold boots passed; clean
build complete; canonical package and full runtime regression in progress

## Scope And Identity

The regression was reproduced and fixed only in the promoted Android-16 tree.
No AOSP16 tree, AOSP16 output, Android 13 build, Henry workspace, or unrelated
app-player module was modified or used.

| Item | Identity |
| --- | --- |
| Android tree | `/home/clouddev/bst/workspace/markxu/android-16` |
| Root branch | `aosp16-bst-merge` |
| Fixed root commit | `585193af7172118f81157a5ae20f3dd0ee8e929b` |
| `frameworks/native` fix | `080784acd49a450170b8555d270f4cdc5109dfa3` |
| Goldfish source | `f6841e72d677a02de240231b56045663948032e1` |
| app-player source | `b6f585b2aa899bf16b626d6a64f024bd2a4bd822` |
| Product / OUT | `android_x86_64-trunk_staging-eng` / `out_nxt_Baklava64` |

## Symptom

After a host restart the player reached Android boot completion and kept
`system_server`, Launcher, SurfaceFlinger, and the graphics composer alive, but
the guest framebuffer was black. Host process existence and boot-complete logs
were therefore false-positive graphics evidence.

The bad guest screencap was 7,751 bytes with SHA-256
`1bb07dd9fe0243fdb1e6a8c44c508ece063a8633d209efa9ef3e9e479b6fc253`.
The host was locked during validation, so no Windows screenshot was used as an
oracle; all image evidence came from Android `screencap` through the instance
ADB endpoint.

## Root Cause

The Android-16 goldfish graphics closure was linked against the full
`BstFilterAppsManager` implementation from `frameworks/native`. Goldfish
graphics modules run in the vendor Binder domain, while `bstfilterapps` is
registered by SystemServer on the system Binder domain. Calls made from
`HostConnection::createUnique()` could not reach that service and repeatedly
logged:

```text
BstFilterAppsManager: Waited too long for bstfilterapps service, giving up
```

The repeated synchronous lookup occurred in graphics process startup and left
the composed Launcher frame black even though the Android lifecycle oracles
were green.

The AOSP16 development payload already contained the missing promotion
decision: when `BST_ANDROID16_GUEST` is defined, goldfish includes an inline
no-op manager instead of using the system-service client. The promotion had
omitted that header branch.

## A/B Isolation

The failure was isolated at shared-library granularity:

1. Current `libGLESv2_enc` combined with the last known-good
   `libOpenglSystemCommon` rendered correctly.
2. Replacing only the common library with the current implementation
   reproduced the exact black guest framebuffer and service-wait warnings.
3. A temporary four-callsite `HostConnection` guard still produced black and
   was fully reverted. It is not part of any submitted repository.
4. Rebuilding the complete 32/64-bit graphics dependency closure with the
   AOSP16-validated header isolation removed all dynamic
   `BstFilterAppsManager::` references from the twelve inspected guest graphics
   libraries.

This rules out the recently synchronized `frameworks/base`,
`device/generic/common`, and `system/core` component updates as the cause and
avoids a broad goldfish rollback.

## Fix And Review

`frameworks/native/libs/binder/include/binder/BstFilterAppsManager.h` now has
two compile-time paths:

- `BST_ANDROID16_GUEST`: inline methods return the same defaults that the
  unreachable service calls returned after timing out.
- all other builds: the existing full Binder-backed manager is unchanged.

### Necessity

The change is necessary for the current partition and Binder-domain layout.
Leaving the calls in place makes a normal cold boot nondeterministically render
black. Moving the Java service into the vendor Binder domain would create a
larger cross-partition API and security change and is outside this promotion.

### Compatibility

The macro is enabled by the goldfish Android-16 SDK gate. Android 13 and
non-guest users compile the original implementation, so their source behavior
is preserved. The real SystemServer `bstfilterapps` service is not removed.

### Performance

The fix removes repeated blocking service lookups from graphics startup. It
adds no thread, polling loop, allocation, or per-frame work. A16 loses no
working filter result because the service was unreachable and every attempted
query already fell back to the same default values.

### Security

The fix restores the intended vendor/system boundary instead of weakening
Binder policy or adding a service-domain exception. No SELinux bypass or
permission expansion is introduced.

## Targeted Validation

The targeted `mmm` rebuilt all dependent 32/64-bit graphics libraries. A test
Root containing the coherent closure had SHA-256
`46a5e5d61b872d8fb9081dc153e83560a13ffc32525f97c188ba5be96abf9907`;
its `system.sfs` had SHA-256
`173a4a18d9b022cde2f0258fdf33aa462e000f3f470b1483c142d7429d8a97e6`.

Three cold starts passed all seven boot oracles and rendered Launcher. The
first two guest PNGs were 1,443,749 and 1,438,574 bytes, with SHA-256 prefixes
`313bac4f` and `5181bb43`. The third run passed the automated framebuffer gate
with `non_black_ratio=0.992522` and PNG SHA-256 prefix `bdc44a32`. No
`Waited too long for bstfilterapps service` warning occurred in any fixed run.

The test Root was assembled for diagnosis and is not a publication artifact.
Acceptance still requires the clean canonical package described below.

## New Fail-Closed Graphics Gate

`scripts/g1_boot_verify.ps1` now captures the guest framebuffer after the boot
and stability oracles pass. It samples decoded PNG pixels and requires at least
0.5 percent of samples to exceed the near-black threshold. An unavailable,
unreadable, or black guest framebuffer fails the run as
`graphics:guest_framebuffer_black_or_unreadable`.

This closes the earlier oracle gap where process health and boot completion
could pass while the user-visible guest remained black. The gate deliberately
does not depend on the Windows desktop or host screenshots.

## Host-Only Black Screen After Window Recovery

A separate black screen was reported later on 2026-08-15. This occurrence was
not a recurrence of the guest Binder failure:

- the deployed diagnostic Root identity was unchanged;
- `sys.boot_completed=1`, SurfaceFlinger, composer, and Launcher were healthy;
- the guest had been running for 29,744 seconds, so no guest reboot had
  occurred; and
- a guest-only ADB screencap was a complete 1600x900 Launcher frame (1,420,998
  bytes), while the Windows player surface was black.

The current player log identified the host renderer as `NVIDIA GeForce MX450`.
Windows `UserGpuPreferences` forced `HD-Player.exe` and `HD-GLCheck.exe` to
`GpuPreference=2`, and `bluestacks.conf` also requested the dedicated GPU.
This contradicted the established A16 green baseline: the earlier R233-R236
trace isolated the NVIDIA path to `nvoglv64.dll`, while Intel Iris Xe completed
the same graphics startup.

Setting only `bst.prefer_dedicated_gpu=0` was insufficient: the next cold boot
still logged `GL_VENDOR=NVIDIA`, proving that the Windows per-application rule
had precedence. The two executable preferences were then changed to
`GpuPreference=1`. The following true cold boot logged:

```text
GL_VENDOR = Intel
GL_RENDERER = Intel(R) Iris(R) Xe Graphics
Player state: ready
```

The guest reached boot completion, Launcher was the resumed activity, and the
final guest frame was a complete 1600x900 image (1,421,343 bytes). The original
configuration and GPU preference values were retained in timestamped backups
under `C:\ProgramData\BlueStacks_nxt`.

This was a host routing/configuration regression, so no Android or goldfish
source patch was added. `g1_boot_verify.ps1` now requires the expected host GL
vendor in the same cold-boot log window, in addition to the guest framebuffer
gate. That prevents an Intel-qualified regression run from passing while
Windows silently routes a later player session to the known-bad NVIDIA path.

## Post-Restart Boot Black Screen: Missing HWSM Compatibility Link

The 2026-08-15 20:53 cold boot of canonical Root SHA-256 `24909e4b...`
reproduced a guest-side black screen. Intel rendering and the early mounts
passed, but ADB stayed offline and the boot oracle remained at 4/8 for 617
seconds. The guest log repeated `vold: Waited for hwservicemanager.ready`.

The package contained `/system/system_ext/bin/hwservicemanager` while its rc
started `/system/bin/hwservicemanager`. The compatibility symlink module
existed in `system/hwservicemanager`, but `android_x86_64` did not select it;
the previously green diagnostic package had supplied the link through a
staging overlay. The board-scoped fix adds
`hwservicemanager_compat_symlink_module` beside `hwservicemanager` in
`device/generic/x86_64/android_x86_64.mk`. It does not restore the older global
build/make relocation.

Component commit `20b180160890870891672920172317d8939a0340` and root commit
`eb146d4c3b26dbd8447e74f343020015ee85ced7` were pushed component-first. A
four-target incremental build installed the link in 18 seconds. The repackaged
system image exposes `/bin/hwservicemanager ->
/system/system_ext/bin/hwservicemanager`; Root SHA-256 is `c2fdc085...` and
system.img SHA-256 is `fe5d0ed0...`.

The fixed cold boot reached 8/8 at 51 seconds and passed the 95-second
stability window. Final framebuffer evidence was 1600x900,
`non_black_ratio=0.997611`, SHA-256
`32d9b105bc23575503ff4a12b5a9e1866d3dee017c67f74f5e0038a56be74878`.
Property verification passed. Dynamic FPS remains independently open: changing
60 to 30 FPS left the measured period at 16,666,666 ns.

## Remaining Acceptance Gates

1. Repeat the fixed cold boot enough times to establish restart stability.
2. Run Launcher, Settings, dynamic FPS, property, shared-folder, IME, Houdini,
   native-bridge, ADB policy, HAL, and HD-facing regression oracles.
3. Record and resolve every reproduced open regression before changing the
   pull request from Draft/validation-pending status.
