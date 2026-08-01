# Primary AOSP16 and Companion Patch Review

This chapter covers the 24 top-level patch artifacts. Statistics and exact
changed paths are in [patch-inventory.md](patch-inventory.md).

## AOSP16 Project Snapshots

### `aosp16__art.patch`

- **Code/purpose:** skips a missing `DexCache` during
  `ZygoteVerificationTask` instead of dereferencing it. This was a bring-up
  guard for missing APEX framework jars.
- **Review:** **P1**. The null check is memory-safe, but it turns a boot class
  path consistency failure into partial verification. The log explicitly marks
  it as `temp_debt`.
- **Performance:** low direct cost; skipped verification can defer class work
  and produce later JIT/class-resolution cost.
- **Necessity:** `temporary`, not a permanent product feature. A correct APEX
  and bootclasspath assembly should make the branch unreachable.
- **Recommendation:** add the missing-jar identity to the log, assert that only
  an allowlisted jar can be skipped, and remove after bootclasspath validation.

### `aosp16__build_make.patch`

- **Code/purpose:** supports external kernel config/version metadata, relaxes
  outside include checks, disables VINTF enforcement and moves
  `hwservicemanager` ownership from `system_ext` toward `/system`.
- **Review:** **P0/P1 mixed patch**. Kernel metadata override is a valid build
  feature; `pretty-error` to warning broadens build inputs; global VINTF
  disable removes an important compatibility gate; partition relocation
  conflicts with Android 16 GSI/product assumptions.
- **Performance:** no runtime CPU cost. Partition/package changes affect image
  size and incremental-build invalidation.
- **Necessity:** kernel metadata is `required`; VINTF disable is `temporary`;
  hwservicemanager relocation is `conditional` on the single-partition Root
  image and must remain synchronized with its rc and manifest.
- **Recommendation:** split into three commits and keep enforcement enabled for
  CI. Express Windows product exceptions in `device/generic/x86_64`, not global
  build files; qvirt is historical only.

### `aosp16__build_soong.patch`

- **Code/purpose:** adds bootclasspath allowlist entries, permits legacy
  Android.mk locations, discovers out-of-tree `hd`/graphics modules, and makes
  `mm`/`mmm` use no-dependency build modes.
- **Review:** **P1**. External module discovery is needed by the existing
  app-player flow, but no-dependency `mm`/`mmm` changes standard developer
  semantics and can report success with stale dependencies. Scanning both
  built-in gfxstream and goldfish-opengl can create duplicate modules.
- **Performance:** faster incremental commands, but potentially more clean
  rebuilds and non-reproducible artifacts. Runtime performance is unaffected.
- **Necessity:** external `hd` discovery is `required`; goldfish discovery is
  `conditional`; no-dependency command replacement is `optional`.
- **Recommendation:** add new explicit commands instead of changing `mm`/`mmm`;
  select one graphics provider in product configuration; add a clean CI build.

### `aosp16__device_generic_common.patch`

- **Code/purpose:** 170-path device overlay containing product definitions,
  init/ueventd/fstab files, native bridge, input profiles, media/ALSA assets,
  BST utilities, APKs, signing material and binary payloads.
- **Review:** **P0/P1** because source, product policy, credentials and opaque
  binaries are bundled together. The keystore and prebuilt APK provenance
  cannot be established from a text review. Generic-device ownership also
  makes upstream rebases difficult.
- **Performance:** device properties and media configuration affect boot,
  memory and codec selection. Preinstalled APKs increase image size and boot
  package scan time.
- **Necessity:** only a subset is `required`. Shared Android-x86/BST behavior
  remains under `device/generic/common`, while Windows-only selection belongs
  in `device/generic/x86_64`; hardware-specific ALSA/IDC files and unused APKs
  are `conditional` or `optional`.
- **Recommendation:** inventory every binary by hash/license, remove credentials
  from patch history, and split product, init, media, input and app payloads.

### `aosp16__device_generic_goldfish.patch`

- **Code/purpose:** adjusts the generic goldfish product to align graphics and
  hwservicemanager packaging with the BST image.
- **Review:** **P1**. The small diff changes ownership of boot-critical modules;
  it must agree with `android_x86_64` product packages, build/make and VINTF.
- **Performance:** none directly.
- **Necessity:** `conditional`; needed only when this product inheritance path
  remains active. The `android_x86_64` product is authoritative for Windows.
- **Recommendation:** add a product-composition test that checks exactly one
  allocator, composer and hwservicemanager implementation.

### `aosp16__device_generic_x86_64.patch`

- **Code/purpose:** provides the x86_64 product entry, AndroidProducts listing
  and board inheritance used by the current Windows product.
- **Review:** **P1 product contract**. The original file is thin; the rework
  keeps the `android_x86_64` identity and adds only the proven qvirt-era runtime
  services, graphics properties and package exclusions. Android 16 VINTF
  enforcement remains active and matches qvirt. Obsolete common HAL
  declarations are adapted to FCM 8, while a product-local framework matrix
  supplies only the three legacy declarations required by build-time VINTF
  validation.
- **Performance:** none.
- **Necessity:** `required/current`; qvirt is superseded.
- **Recommendation:** test `android_x86_64-trunk_staging-eng` independently and
  reject any reintroduction of the second qvirt product identity.

### `aosp16__external_boringssl.patch`

- **Code/purpose:** prevents x86_64-only boot from starting a missing 32-bit
  BoringSSL self-test that uses `reboot_on_failure`.
- **Review:** **P1**. It avoids a false reboot, but disabling all self-test rc
  coverage also hides genuine crypto startup failures.
- **Performance:** slightly faster boot; no steady-state effect.
- **Necessity:** `conditional` for the current 64-bit-only product.
- **Recommendation:** ship the matching 64-bit self-test or gate only the
  unavailable 32-bit variant instead of removing all init integration.

### `aosp16__frameworks_base__d8-subscription.patch`

- **Code/purpose:** reports one active subscription when
  `bst.config.enable_telephony` is enabled, providing a minimal fake-SIM signal
  without extending Binder APIs.
- **Review:** **P1**. Count and list/detail APIs can disagree. The implementation
  is safer than the rejected synthetic `SubscriptionInfo` list but still
  changes public API semantics.
- **Performance:** negligible property/branch cost.
- **Necessity:** `conditional` anti-detection compatibility feature.
- **Recommendation:** UID-gate third-party callers and test consistency across
  count, list, slot, SIM-state and permission paths.

### `aosp16__frameworks_base__pagefusion.patch`

- **Code/purpose:** imports the VirtualBox page-fusion command and adapts it to
  Android 16, including a local 4096-byte page-size definition.
- **Review:** **P1**. The fixed page size is correct for the current x86_64
  guest but invalid for a future 16 KiB-page product. The command handles
  process memory and host IPC, so bounds/error handling matter.
- **Performance:** potentially high while invoked because it scans and shares
  process pages; no cost when the service is idle.
- **Necessity:** `conditional` memory optimization, not required to boot.
- **Recommendation:** obtain page size at runtime, benchmark RSS/CPU savings,
  and keep the service disabled unless the host advertises support.

### `aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch`

- **Code/purpose:** disables Shell Transitions to avoid a boot stall caused by
  a missing performance-hint HAL.
- **Review:** **P1 historical workaround**. It masks the dependency and changes
  window animation behavior.
- **Performance:** can reduce animation work but is not a valid optimization
  measurement.
- **Necessity:** `superseded`; registry status is `removed` after the power HAL
  and HintManager path were restored.
- **Recommendation:** never replay. Keep a regression test for WMShell startup
  and performance-hint session creation.

### `aosp16__frameworks_base.patch`

- **Code/purpose:** 97-path, 936 KiB framework snapshot containing BST Java/AIDL
  services, hostcall integration, app compatibility hooks, pagefusion, WMS/AM
  changes, UI behavior, telephony and service modifications.
- **Review:** **P0 replay risk**. It mixes required IPC contracts, optional
  compatibility features, diagnostics and changes later reverted or replaced.
  Earlier whole-framework deployment caused `system_server` regressions.
- **Performance:** mixed and unbounded as a unit. Individual hot paths include
  Display/Resources/Input/ActivityThread and synchronous Binder operations.
- **Necessity:** `audit-only`. Required parts must be replayed through reviewed
  surgical commits, not this aggregate patch.
- **Recommendation:** use this snapshot only for coverage comparison. The
  Phase 2 surgical documents are the implementation authority.

### `aosp16__frameworks_native_libs_binder.patch`

- **Code/purpose:** implements native BST utility/filter Binder clients and
  interfaces used by graphics, media and camera code.
- **Review:** **P1**. This replaces fail-open stubs with real IPC and restores
  product behavior. Risks are interface-token compatibility, vendor/VNDK
  visibility, caller identity and service-unavailable behavior.
- **Performance:** medium. Calls are synchronous Binder IPC; per-frame graphics
  callers must cache profile decisions.
- **Necessity:** `required` for compatibility features that query BST profiles;
  boot can run with stubs but functionality is lost.
- **Recommendation:** version the interface, add service-death handling and
  benchmark/cache calls made from graphics or camera paths.

### `aosp16__frameworks_native.patch`

- **Code/purpose:** adds a fail-open `BstFilterAppsManager` stub, allowlists the
  manual `RTVboxMM` Binder interface and removes the null Vulkan driver module.
- **Review:** **P1**. The manual interface entry is a real contract. The stub
  makes all policy decisions false and can silently disable compatibility.
  Deleting `vulkan.default` is valid only when another provider is guaranteed.
- **Performance:** stub calls are cheap; selecting the wrong graphics provider
  has large functional/performance consequences.
- **Necessity:** Binder allowlist is `required`; stub is `superseded` by the
  real binder patch; null-driver removal is `conditional`.
- **Recommendation:** do not retain both stub and real implementation in the
  same replay path.

### `aosp16__hardware_google_aemu.patch`

- **Code/purpose:** removes references to `gfxstream_defaults` from aemu test
  and host-common modules to coexist with the selected external graphics tree.
- **Review:** **P1**. Commenting out defaults can remove host support, flags or
  sanitizer settings. It also suppresses host tests rather than resolving
  graphics ownership structurally.
- **Performance:** runtime target cost is negligible; host tooling/test coverage
  can change.
- **Necessity:** `conditional` on disabling the built-in gfxstream modules.
- **Current decision:** `rejected for Android-16`. The 25Q4 host Vulkan graph
  requires these defaults. Restore target aemu unchanged and isolate the
  external BlueStacks provider through the Windows product and separate build.

### `aosp16__hardware_interfaces.patch`

- **Code/purpose:** disables legacy GNSS and memtrack HIDL default services that
  are not backed by the Windows `android_x86_64` device.
- **Review:** **P1**. This avoids service startup failures but can remove APIs
  expected by framework components. The product manifest must omit the same
  services.
- **Performance:** small boot/RSS reduction.
- **Necessity:** `conditional`; valid when equivalent BST services are absent
  and framework feature declarations are also disabled.
- **Recommendation:** use product package selection instead of setting upstream
  modules globally `enabled: false`.

### `aosp16__hardware_libhardware.patch`

- **Code/purpose:** removes/disables default gralloc and hwcomposer modules so
  the BST goldfish implementations own those HAL names.
- **Review:** **P1 boot-critical**. Duplicate providers are invalid, but no
  fallback remains if BST graphics packaging fails.
- **Performance:** provider choice determines graphics performance; the patch
  itself has no cost.
- **Necessity:** `required` when the external BST graphics stack is selected.
- **Recommendation:** enforce exactly-one-provider checks in the product build
  and validate installed ELF/VINTF names.

### `aosp16__packages_apps_Launcher3.patch`

- **Code/purpose:** removes Launcher3 HOME ownership, adjusts overview routing
  and guards widget-provider null cases so the BST launcher is authoritative.
- **Review:** **P2**. HOME removal is correct for the product. Hard-coded
  overview behavior should be product-configured; the null guard is safe.
- **Performance:** none.
- **Necessity:** HOME removal is `required`; overview customization is
  `conditional`; NPE guard is generally useful.
- **Recommendation:** verify one HOME resolver after factory reset and after
  launcher package updates.

### `aosp16__system_core.patch`

- **Code/purpose:** combines init/ueventd diagnostics, first-stage mount changes,
  BST property loading, shutdown recovery, service definitions, device
  permissions, permissive SELinux behavior and multiple fail-open checks.
- **Review:** **P0**. Unconditional first-stage-mount skip, property permission
  bypass, SELinux policy/load/domain bypasses and insecure-file acceptance
  remove core Android security and integrity guarantees. Required shutdown and
  device-node logic is inseparable in this snapshot.
- **Performance:** high diagnostic logging during boot; skipped policy/mount
  work may shorten boot but is not a valid optimization. Added services consume
  memory only when triggered.
- **Necessity:** shutdown, BST device nodes and selected property/init triggers
  are `required`; security bypasses are `temporary` and not production-safe.
- **Recommendation:** split by subsystem, keep device policy in the active
  generic-common/x86_64 ownership layers, remove unconditional returns and add
  coldboot/property/SELinux tests.

### `aosp16__system_hwservicemanager.patch`

- **Code/purpose:** installs hwservicemanager on `/system` and includes a
  diagnostic transport bypass for legacy VINTF behavior.
- **Review:** **P0/P1**. Partition placement may be necessary for Root.vhd, but
  `if (false)` around transport validation defeats manifest compatibility and
  was documented as diagnostic debt.
- **Performance:** no meaningful steady-state cost.
- **Necessity:** placement is conditional on the image layout; the transport
  bypass is `superseded` by the active device manifest and product-local VINTF
  enforcement.
- **Recommendation:** preserve validation and add a boot assertion that the
  allocator/composer/mapper services are declared and registered.

### `aosp16__system_libhidl_vintf.patch`

- **Code/purpose:** adds an allocator HIDL declaration to a framework VINTF
  manifest.
- **Review:** **P1**. A device HAL in framework VINTF can duplicate device or
  module fragments and makes target-level filtering difficult.
- **Performance:** none.
- **Necessity:** `superseded` by the active Android-x86 device manifest.
- **Recommendation:** keep device-specific HALs in the device manifest and run
  `assemble_vintf`/runtime transport checks.

### `aosp16__system_security.patch`

- **Code/purpose:** ignores failure of the keystore `EarlyBootEnded` permission
  check and proceeds.
- **Review:** **P0**. This weakens a privileged keystore lifecycle boundary and
  logs the bypass without enforcing caller authorization.
- **Performance:** negligible.
- **Necessity:** `temporary`; only justified as a bring-up diagnostic.
- **Recommendation:** restore permission enforcement and fix the caller/domain
  or policy. Add positive and negative Binder permission tests.

## Host, Build and Graphics Companions

### `app-player_buildscripts.patch`

- **Code/purpose:** adds Baklava selection, android-16 build targets, kernel and
  system.sfs packaging, environment overrides and VDI creation changes.
- **Review:** **P1**. It is the main build-flow bridge, but includes hard-coded
  NBD/user paths, globally commented APK builds, conditional copies that hide
  missing artifacts and an implicit missing-dependency contract.
- **Performance:** build-time only. Existing-artifact reuse can improve build
  time but risks stale output.
- **Necessity:** core Baklava selection and packaging are `required`; developer
  shortcuts are `optional`.
- **Recommendation:** parameterize paths/NBD allocation, fail on required
  inputs, restore explicit APK targets and add a clean-build CI recipe.

### `goldfish-opengl-pie.patch`

- **Code/purpose:** adapts legacy BST EGL/GLES/HWC2 to Android 16 headers and
  linker rules, selects GLES over Vulkan/gfxstream, repairs VsyncThread
  ownership and bridges host graphics/profile behavior.
- **Review:** **P1 boot/performance critical**. The strong-reference
  VsyncThread fix is correct. Global `-Wno-error`, forced extension reporting,
  config stripping and static host-connection lifetime can hide real driver
  incompatibilities or races.
- **Performance:** high impact because this is the render path. Extra tracing,
  synchronous profile IPC and extension workarounds can affect frame time.
- **Necessity:** `required` while BST uses this graphics provider.
- **Recommendation:** remove global warning suppression, gate diagnostics,
  cache profile queries, run frame-time/VSync tests and document Vulkan policy.

### `hd-guest.patch`

- **Code/purpose:** adapts BootImage/initrd for Baklava, mounts runtime/i18n
  APEX files, creates linkerconfig and metadata, loads guest modules and adds
  boot diagnostics.
- **Review:** **P0/P1 replay risk**. Core APEX bootstrap is required and solved
  the StartingKernel deadlock, but the archive includes hard-coded release
  paths, fixed fallback Android ID, non-fatal module failures, forced printk
  verbosity and copied linkerconfig state. The original Makefile also ignored
  a missing `videobuf-core.ko`.
- **Performance:** boot-only loop/mount work is small; forced logging can delay
  boot. A 256 MiB metadata tmpfs consumes memory on demand.
- **Necessity:** APEX detection/mount and required module packaging are
  `required`; debug logging/fallback identity are `temporary`.
- **Recommendation:** do not replay wholesale. Use the reviewed current
  `app-player/hd` commits, parameterize all inputs, hard-fail missing modules
  and generate unique identity through the hostcall contract.
