# A13 to AOSP16/Android-16 Code Audit

## Result

This is a read-only, code-level comparison of the final Android 13 product
line against both A16 trees. It does not use the old registry status as proof
of coverage and it does not treat a low textual match as an omission.

The audit found two direct runtime contract breaks, several real but
design-sensitive A13 feature gaps, and a large amount of version, test,
prebuilt and inactive source noise. No AOSP source tree was changed or built.

### Frozen identities

| Tree | Identity |
|---|---|
| A13 | `~/app-player/android-13`, branch `bst-v5.22.210`, HEAD `be7d9511db9c9045f346a8212eb1f41e6b36d354`, tree `b5fc5adb3b33c8f71252affb01e7188c7dddffab` |
| AOSP16 | `~/aosp16`, repo manifest HEAD `15128c9e27cfa599c48d294babd39286ee8f1426`, 1011-project list SHA-256 `33880a26e376eac0d69ec546e435412c3bff56c18074ac4453ba672cd2ad2bf5` |
| Android-16 | `~/android-16`, branch `aosp16-bst-merge`, HEAD `298403aba7234f2f120170f49e6afe7dcde16be9`, tree `09b2de0e8254036963aad188a18e28e7ac509ab0` |

### Scale

- 1056 A13 submodules were enumerated.
- 177 projects have a final delta reached from a BlueStacks/A13/ROB-signalled
  non-merge commit; 1623 final changed files were compared.
- 879 projects have no such final custom delta.
- 809 files were initially low/missing in both A16 trees. Of these, 496 are
  test/toolchain/prebuilt sync, 86 are device payload entries, and 227 are
  runtime source candidates requiring semantic review.
- The A13 superproject directly tracks another 1485 non-gitlink files. This
  layer was absent from the old submodule-only review.

The generated per-project evidence is in
[`coverage-matrix.md`](coverage-matrix.md).

## Confirmed Contract Breaks

### P0: legacy BST HAL selection is incomplete

A13 commit `98d36f865b80` added a final `.bst` lookup in
`hardware/libhardware/hardware.c`. Neither A16 tree contains that lookup.
Both A16 products still install `audio.primary.bst`, `camera.bst`,
`lights.bst`, `memtrack.bst` and `power.bst`, but their product source only
sets `ro.hardware.gralloc=bst`; it does not set the class selectors used by
`hw_get_module_by_class()`.

This is a code-level broken producer/consumer contract, even though boot 7/7
passes: the boot oracle did not test audio, camera, lights, memtrack or legacy
power behavior. The smallest Android-16 adaptation is to add the five
class-specific `ro.hardware.<name>=bst` product properties. That avoids the
broad A13 fallback, which would make every unknown HAL class probe `.bst`.

Runtime cost of the property solution is limited to existing HAL lookup. The
A13 fallback would add one filesystem probe per unresolved HAL load.

### P0: `mountsf` has a trigger but no in-tree producer

A13 commit `19949f84b376` calls
`SetProperty("bst.config.mountsf", "1")` from `VolumeManager::start()`.
Neither A16 `system/vold` does so. Both A16 `system/core/rootdir/init.rc` files
still declare `service mountsf` and only start it on
`bst.config.mountsf=1`. No other tracked producer was found in the relevant
device, framework, BlueStacks service or init source.

The current tree can therefore boot while shared-folder mounting never starts.
Restoring the lifecycle signal has negligible steady-state cost. It needs a
focused shared-folder test because the sibling A13 vold change
`fb129833c9b2` suppresses all project-quota operations by returning success;
that quota bypass must not be copied without an `EOPNOTSUPP` reproduction.

## Real Gaps Requiring A16 Design

| Priority | A13 source | Code-level result | Review / next gate |
|---|---|---|---|
| P0/P1 | `packages/inputmethods/LatinIME`, `a0a806229` | All six touched files lack the A13 host-IME behavior. BstCommandProcessor still selects `com.android.inputmethod.latin/.LatinIME`. | The A13 code starts an infinite wildcard `ServerSocket(0)`, publishes its port, has no peer authentication, adds platform APIs and implements hard-key/text injection. Do not copy it verbatim. Confirm the Windows IME protocol, then design an authenticated A16 channel and functional tests for compose/delete/enter/hard-key paths. |
| P1 | `packages/modules/Wifi` + `libcore` | Fake Wi-Fi state/DHCP/MAC generation and the `eth0` to `wlan0` Java facade are absent in both A16 trees. Connectivity's static guest IP adaptation is present, but it does not replace app-visible Wi-Fi identity. | Treat as one contract, not two independent patches. Test `WifiInfo`, `NetworkInterface`, MAC visibility, transport type and permission behavior before choosing a modern service-side implementation. |
| P1 | `external/skia`, `90765aac` | A13's atlas allocation padding is absent after the code moved to `src/gpu/AtlasTypes.cpp`; both A16 allocations use exactly `bpp * width * height`. | The old workaround addresses a goldfish encoder over-read but adds only `fWidth` bytes, which is not enough for every bytes-per-pixel/left-offset case. Reproduce with ASan or the affected apps and fix the encoder or calculate a proven bound; do not mechanically replay the padding. |
| P1 | `frameworks/opt/telephony`, `0a28c7cf` | IMEI and part of subscriber/UICC behavior are adapted, but the old `SubscriptionController` fake-SIM list no longer exists in the A16 architecture. | Verify APIs that enumerate active subscriptions, SIM ready state, subscriber ID and slot mapping. Port into the A16 subscription service only if the fake-SIM product contract remains required. |
| P1 | `packages/modules/NetworkStack`, `36f17f9d`/`7843886c` | `bst.country`/`bst.oem` captive-portal bypass is absent. | Validate China-game networking and current captive-portal policy. A global ignore weakens network validation, so gate it narrowly if retained. |
| P1 | `packages/services/Telephony`, `c64fce29a` | SIM locale fallback to `persist.sys.locale`/`bst.locale` is absent. | Run locale-without-SIM coverage; adapt only if Android-16 still calls this path. |
| P1 | `packages/modules/Bluetooth`, `4853f516` | The A13 workaround disables Bluetooth keystore initialization wholesale; no equivalent is present. | Reproduce the A16 crash. The old unconditional return drops key persistence and is not acceptable as a default fix. |
| P2 | `frameworks/av`, `90ee78b4` | The Tinder workaround that ignores unsupported AE/AWB locks is absent. | Camera rotation and the `com.papegames.lysk.en` multi-read workaround are already present in adapted A16 locations. Test the Tinder camera flow before relaxing parameter validation. |
| P2 | Launcher3/Settings | Launcher default-home handling is partly adapted in `OverviewComponentObserver`; taskbar suppression, recents host-call guards and most Settings UI optimization are absent. | Validate first-boot home selection, recents close, taskbar, accessibility and physical-keyboard UI. These are product-policy changes, not boot requirements. |
| P2 | `external/libxml2`, `74cffc0e` | A13's Make-only `xmllint` target is absent. | Add a current Soong host/device tool only if recovery still invokes it; no invocation was found in the reviewed product source. |

## Absent Code That Must Not Be Replayed

- `libcore` SafetyNet URL rewriting changes Google anti-abuse endpoints and is
  a security/compliance intervention. It is genuinely absent and should stay
  absent without explicit product/legal approval.
- The A13 DownloadProvider receiver is exported without a permission, lets any
  app reset and reschedule downloads, and finishes its async receiver before
  the nested worker completes. The feature is absent, but the patch is not a
  safe port candidate.
- The custom `system/extras/su` implementation, whitelist and crypto wrapper
  are absent. `report_daemon.c`, its rc, and shared utilities are exact in both
  A16 trees. Retaining the reviewed packaged `bstk/su` boundary is safer than
  restoring the old privileged C implementation.
- A13 Widevine and FFmpeg additions include proprietary binaries and obsolete
  OMX/Stagefright integration. They remain excluded pending immutable source,
  license and A16 media architecture evidence.
- Bionic `iopl/ioperm`, x86 text relocations and the hard-coded Iran DST fix
  remain intentional non-ports. Current tzdata is authoritative.
- A13's HWC2 FPS patch polls `bst.max_fps` every second, calls a refresh
  callback without an explicit null guard, and creates a second FPS control
  plane. The Android-16 Scheduler-side implementation is the reviewed
  replacement and avoids polling/callback re-entry.
- ART JNI/OAT hooks remain an A16 design item. The native bridge/loader
  contract already promoted is not evidence that the old internals are safe.

## Confirmed Adaptations

Low line coverage produced several false positives that were resolved by
reading the current code:

- A13 and AOSP16 kernel are exactly commit
  `686f860abf3a5c7117d6a784ef0360ac99bfcef0` and tree
  `dbe01af7ab01d7e4181e2cebfd7caf1eef047b14`. The kernel is not missing from
  AOSP16; Android-16 carries its reviewed A16 continuation.
- `frameworks/av` retains the per-app camera rotation through
  `CameraService.cpp` and the Love and Deepspace multi-read exception through
  `IMediaSource.cpp`, adapted to A16 APIs.
- `system/core` retains `/data/.bluestacks.prop` loading, `ro.boot.hardware`
  derivation, `/dev/hvmem` permissions, and the `mountsf` init declaration.
- `frameworks/opt/telephony` retains the BST enable gate and IMEI path;
  `packages/modules/Connectivity` retains the property-driven static guest IP
  configuration.
- All five `hardware/bst` implementations are exact or high-coverage source
  matches. Their source presence does not cure the HAL selector break above.
- Root-tracked BstCommandProcessor has 35 exact and four high-coverage files in
  AOSP16; its Android-16 copy differs in only the reviewed A16 adaptation.

## Root Payload Review

The 1430 root-tracked files absent from AOSP16 are not one feature set:

- 1156 files under `hardware/intel/common` are the old libva/vaapi import.
  Android-16 retains the product-selected i965 driver and uses its current
  `external/libva` project instead of duplicating the A13 libva source. The
  required `/vendor/lib64/dri` discovery path is tracked in the authority
  completion review.
- 155 files under `external/arm-runtime` are historical translator source; its
  own A13 history marks the module obsolete and replaced by qemu.
- 85 `BstSettings` files were reviewed separately. `BstFolder` is disabled in
  the final A13 tree by `Android.mk` to `Android.mk.orig` rename and its
  successor daemon was later deleted; both A13 and A16 retain the byte-identical
  native helper under `external/bluestacks/bstfolder`.
- `system/bstime` was a real omission: active product and init declarations
  referenced the absent executable. Android-16 now carries the byte-identical
  A13 source with Soong-only build metadata.
- QCOM board makefiles and root bootstrap metadata are irrelevant to the
  Windows `android_x86_64` product.

These files remain first-class historical evidence. Their absence is recorded,
but source existence alone is not a necessity signal.

## Reproduction And Evidence

Run the read-only audit on the remote host:

```bash
python3 ~/a16-tools/audit_a13_port_coverage.py \
  --a13-root ~/app-player/android-13 \
  --aosp16-root ~/aosp16 \
  --android16-root ~/android-16 \
  --scope all --jobs 24 \
  --output ~/a16-tools/a13-port-coverage.json
```

The first submodule scan (schema 1) is SHA-256
`e113b5da4dcc103eeb7f22806592d8fe8cf3d5e6d4b056d304d5e787013c907b`.
The root-only schema 2 scan is SHA-256
`2af8e9df3d240bdda0972c07f95df81711b17c18ee7754fb7cc07558c8674a5a`.
The raw JSON is intentionally not tracked: it is 3.5 MB, contains no unique
source payload, and is reproducible from the frozen identities. The compact
matrix and this semantic review are the durable repository evidence.

## Validation Status

This audit performed no build, package, deployment or boot run. The prior
Android-16 7/7 boot evidence remains valid only for its recorded identity and
does not cover HAL functionality, shared folders, IME, fake Wi-Fi, camera app
compatibility, subscription APIs or Skia crash reproduction.

Before a new promotion completion claim, the two P0 contracts must be fixed or
explicitly waived, and every accepted P1 item must have a feature-specific
oracle bound to the new Android-16 source and artifact identity.
