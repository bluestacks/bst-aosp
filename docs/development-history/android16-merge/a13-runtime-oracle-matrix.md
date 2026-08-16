# A13 Runtime Oracle Matrix

> **2026-08-16 successor status:** the `prepared` cells below preserve the
> state when this matrix was authored. Later clean-derived and incremental
> packages closed the automated boot, property, HAL/service, Camera2, graphics,
> audio API, Houdini/binfmt, FPS, ADB-policy, and shared-folder gates. See
> [`restart-regression-closure-2026-08-16.md`](restart-regression-closure-2026-08-16.md)
> and [`shared-folder-regression-2026-08-16.md`](shared-folder-regression-2026-08-16.md).
> Host-only audible output, recents interaction, broad Settings traversal,
> locale cases, graceful shutdown, and representative third-party app checks
> remain manual coverage boundaries; the locked Windows host does not permit
> inferring those results from screenshots.

## Scope And Count

This matrix is generated conceptually from the current 1,342-entry A13 patch
ledger, then reviewed at source-commit level. A runtime-pending entry is a
`reviewed-ported` or `reviewed-equivalent` patch whose validation evidence
explicitly leaves runtime or feature-startup regression pending. There are
**37 such patch entries**,
collapsed below into **22 behavior groups** without dropping any source commit.

The former count of 40 was not authoritative. It searched serialized entries
for both words `runtime` and `pending`, so paths such as `PendingIntent.java`
could produce false positives and unrelated rationale text could widen the
set. The corrected count inspects `review_status` and validation evidence.

The five legacy-HAL VINTF entries are now `reviewed-ported`: their cross-project
mapping points from A13 `device/generic/common` to Android-16
`device/generic/x86_64` commit `773ab33851c67d54c6f9b6912f23baf208d8c11b`.
Build-time VINTF and generated-manifest uniqueness pass, while runtime service
registration remains part of this matrix.

Commit-free equivalence is separately executable rather than accepted from
prose alone. [`a13-target-state-validation.json`](a13-target-state-validation.json)
binds the ten equivalent entries and thirteen checks to Android root
`c4d2b530567706a7250b77e9db9a0cbafb18f903`; all checks pass with zero errors.

## Patch-To-Oracle Mapping

`prepared` means the executable gate exists but has not run against the new
image. It is not a pass result.

| Group | A13 source commit(s) | Target | Required runtime behavior | Acceptance gate | Current result |
| --- | --- | --- | --- | --- | --- |
| ART/native bridge | `3f6c563145b8`, `4f8c891b39ce`, `57905d797d85`, `7151a45339ef`, `8cd41668fa70`, `cfc8b82d8090` | `art` | ABI/config selection, package export, hotfix callbacks, cpuinfo bind, xarch and anti-detection work in translated apps | Install the hash-bound arm64-only native-bridge oracle; require regular/FastNative/CriticalNative results, `arm64-v8a` package ABI, Houdini and test ELF maps, ARMv8 cpuinfo and process stability | prepared; representative apps pending |
| Bionic property compatibility | `18a39d0ddb27`, `65628c9eb918`, `a23bc9079a62`, `e7687413bac8` | `bionic` | App UID sees synthetic/hardened values while framework property reads retain correct lengths | App oracle runs `/system/bin/getprop` as app UID and requires `ro.board.platform2=ngg-client`, `ro.debuggable=0`, `ro.secure=1`; shell property verifier covers target values | prepared |
| Developer options/dumpstate | `0aae19c5f0f1` | `device/generic/common` | Opening developer options does not crash while current AIDL dumpstate is registered | AIDL service check, launch `android.settings.APPLICATION_DEVELOPMENT_SETTINGS`, scan Settings/SystemUI crashes | prepared |
| Houdini 16 payload | `0f405e00d959`, `3d950593dd20` | `device/generic/common` | Native-bridge payload, callback API and binfmt registrations execute translated code | Shell payload/binfmt gate plus the hash-bound arm64-only native-bridge oracle and its static AArch64 direct-execution companion | translated execution and standalone binfmt gates prepared |
| Memtrack | `4498e9e02dfc` | `device/generic/common` | Current AIDL memtrack service registers from its APEX | `service check android.hardware.memtrack.IMemtrack/default` | prepared |
| GateKeeper removal | `7fd69d779315` | `device/generic/common` | Lock settings and Settings remain usable without the retired HAL lifecycle | `locksettings get-disabled`, lock service check, platform/BST Settings smoke and crash scan | prepared |
| x86_64 legacy HAL VINTF | `47816eea2ce9`, `4facbf0174fc`, `874610a60b6e`, `afba6c8513fe`, `ef2f4da5e521` | A13 `device/generic/common` -> A16 `device/generic/x86_64` | Camera, ConfigStore, Light, default DRM and Power register through the product-scoped declarations without duplicate ownership; OMX, RenderScript, Sensors and SoundTrigger remain declared once | `check-vintf-all` and generated uniqueness already pass; clean-Data `lshal -i`, Binder/service checks, Camera2 frame, DRM factories, light/power behavior and registration-error scan | build-time pass; runtime prepared |
| Camera product/HAL | `af22f7913f2a`, `62b0613d8fa3`, `68b5e0b2297b` | `device/generic/common`, `hardware/bst/camera` | `camera.bst` is selected and Camera2 returns real frames | HIDL/Binder registration plus app oracle Camera2 capture requiring a non-empty YUV frame | prepared |
| Skia atlas | `90765aac329a` | `external/skia` | Lazy atlas allocation no longer crashes affected apps | App oracle Canvas pixel check, then representative GP/Instagram/Facebook/Settings navigation | prepared for API path; representative apps pending |
| Audio service | `451dd10409f4` | `hardware/interfaces` | Audio service remains alive with the current Binder thread pool and accepts playback | HIDL/Binder checks, app oracle initialized/playing `AudioTrack`, host audible-output oracle | prepared for guest path; audible host output pending |
| FPS control | `7b5efb33e999` | `hardware/interfaces` | `bst.max_fps` reaches the synchronized callback path and changes frame pacing without deadlock | Property verifier, HIDL composer service, `g1_fps_regression.ps1` SurfaceFlinger period readback at two FPS values, process continuity and bounded CPU-jiffies measurement | timing/performance gate prepared |
| Launcher recents | `8993045592ea` | `packages/apps/Launcher3` | Closing an app from recents releases mouse state and removes the task | Host input plus visible recents close workflow, launcher/SystemUI crash scan | host/manual pending |
| Launcher taskbar | `8b9f433e5672` | `packages/apps/Launcher3` | Product taskbar remains hidden without breaking HOME | uncube HOME resolver/stability plus screenshot/host UI check | shell prepared; host UI pending |
| Launcher host policy | `d091215d140d` | `packages/apps/Launcher3` | Android-16 Kotlin launch path emits the expected host policy callback | Launch representative apps and read host hcall/package-policy logs | host/manual pending |
| Settings policy/navigation | `e4d840f84def` | `packages/apps/Settings` | Optimized top-level pages and controller removals navigate without crash | Platform Settings, BlueStacks Settings and developer-options smoke; interactive page traversal | smoke prepared; traversal pending |
| Bluetooth keystore startup | `4853f5160e4d` | `packages/modules/Bluetooth` | Delayed Keystore2 does not abort Bluetooth startup | AIDL HCI service, `com.android.bluetooth` PID and boot crash scan | prepared |
| Fake Wi-Fi | `162ac08516e1` | `packages/modules/Wifi` | App-visible SSID/MAC/BSSID/DHCP and Wi-Fi transport match the guest network; `.ma` is consistent | Shell MAC persistence plus app oracle `WifiInfo`, `DhcpInfo`, capabilities and `wlan0`/`eth0` facade | prepared |
| ADB policy/file sync | `6f4cd55e0773` | `packages/modules/adb` | Configured commands and shared-folder pushes work; non-allowlisted services fail closed; daemon remains unprivileged | Exact host `adb push` to shared mount with readback; `g1_adb_policy_regression.ps1` installs a restorable minimal policy, requires a random shell service to be closed, and verifies the original policy hash after restoration | allowed and denied gates prepared |
| SIM locale fallback | `c64fce29ac58` | `packages/services/Telephony` | Locale selection honors ordered `persist.sys.locale`/`bst.locale` fallback | Operator readback plus controlled locale-property cases and phone-process crash scan | operator prepared; fallback cases pending |
| Post-data property files | `133a180f8182` | `system/core` | `.bstconf.prop`, `.bluestacks.prop`, `.vendor.prop` and `.additional_system.prop` are loaded after Data mount with correct precedence | `g1_property_verify.ps1` file-by-file readback on clean Data | prepared |
| Init/shutdown bundle | `bcde7cf2cb5a` | `system/core` | Current init adaptations boot cleanly and graceful shutdown writes the host marker without forced power-down | Layer 2 boot plus `bst.config.start_shutdown=1`, marker/log readback and no 20-second forced shutdown | boot gate prepared; shutdown pending |
| Vold/quota compatibility | `fb129833c9b2` | `system/vold` | Host-backed shared storage does not fail unsupported quota/project-ID operations | Shared-folder guest write and host ADB push/readback; scan vold errors during storage workload | basic I/O prepared; broader storage workload pending |

## Final Regression Order

1. Run Layer 2 boot and property gates on clean Data.
2. Run `g1_runtime_regression.ps1`, including ADB push and Settings/developer
   options smoke tests.
3. Let `g1_build_pack.sh` build the two hash-bound temporary APKs and run the
   app, native-bridge, FPS and denied-ADB oracles; do not reuse an APK from a
   different Android root commit.
4. Run the remaining host/manual Launcher, locale, graceful-shutdown, audible
   audio, authorized Widevine playback and broader storage oracles listed as
   pending above.
5. Attach evidence to every source commit in this matrix before changing its
   ledger text from pending to pass.
