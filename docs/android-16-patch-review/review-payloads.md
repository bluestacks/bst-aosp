# Patch-Equivalent Payload Review

This chapter covers archived AOSP16 changes that are not represented by one of
the 81 top-level `.patch` or `.diff` files. They are still part of the
whole-tree migration surface: kernel state, BootImage source snapshots,
untracked source files, prebuilt binaries, APKs, signing material and build
archives.

These payloads must not be applied as a directory copy. Each group below has a
different ownership, provenance and release policy.

## Executive Findings

| Severity | Finding | Required action |
|---|---|---|
| P0 | A signing keystore is archived under `device/generic/common/apksigner` | Remove it from source history, rotate the credential if it was usable, and inject release signing through the approved secret/build service |
| P0 | The binary manifest contains 95 BusyBox, native-translation, APK and signing-tool entries with MD5 only | Require SHA-256, producer/version/license, build ID, malware scan and signature verification before packaging |
| P0 | The BootImage untracked list contains 155 generated libraries, JARs, images, backups and staging files | Never import these as source; reproduce them from pinned Android 16 outputs |
| P1 | `device/generic/common` combines board policy, HAL selection, APKs, compatibility data and privileged scripts | Split by owner and product feature; review mount/property/VINTF behavior independently |
| P1 | BST framework services expose a broad Binder-to-native host control surface | Enforce caller permissions per operation, bound payload sizes and keep blocking host I/O off Binder/system-server threads |
| P1 | Kernel/config state is a snapshot rather than a complete reproducible change set | Pin source commit, config derivation, toolchain and output hashes in CI |

## Kernel Payload

### `patches/android-16/kernel/git.txt`

- **Code/purpose:** records kernel commit
  `686f860abf3a5c7117d6a784ef0360ac99bfcef0`, small x86/BST hook changes and
  removal of 19 prebuilt/test/config gitlinks from the archived kernel tree.
- **Review:** **P1 reproducibility**. The file records a historical absolute
  source path and a summary, but not the actual commit object, parent, remote,
  toolchain or patch. Deleting gitlinks can be valid when those projects are
  supplied elsewhere, but it also makes a checkout incomplete unless the build
  contract names their replacement.
- **Performance:** the recorded two-line x86/BST hook changes require the
  actual commit for assessment. Kernel hooks can be hot; the summary alone is
  insufficient to claim no overhead.
- **Necessity/status:** `required snapshot`. The kernel is required for boot,
  but this text file is evidence, not a replay mechanism.
- **Required validation:** archive `git format-patch --full-index` or a signed
  bundle, record remote/parent/toolchain, run kernel self-tests, and compare
  kernel/module hashes against the packaged image.

### `patches/android-16/kernel/config`

- **Code/purpose:** captures the effective kernel `.config` used by the
  migrated product.
- **Review:** **P1**. A raw `.config` is architecture and kernel-revision
  specific. It can silently retain debug, tracing or insecure options and is
  not a substitute for a maintained defconfig/config fragment.
- **Performance:** potentially `medium/high`; scheduler, preemption, tracing,
  compression and mitigation options affect boot time, throughput and memory.
- **Necessity/status:** `required input`, conditional on the exact pinned
  kernel revision.
- **Required validation:** derive it with `olddefconfig`, diff against the
  Android baseline, audit security/debug options, and store the resulting
  config plus kernel image hash as CI artifacts.

## BootImage Source Snapshot

### `patches/android-16/bootimage/hd/guest`

- **Code/purpose:** six source files define guest/initrd assembly and early
  boot behavior: the guest `Makefile`, BootImage `Makefile`, `bstsetconf.sh`,
  `bstsetup.env`, `init.sh` and `stage2.sh`.
- **Review:** **P1**. This is a patch-equivalent source snapshot that overlaps
  `hd-guest.patch`. It must be reconciled with that patch and the current
  `app-player` build scripts before use. Early-boot shell runs with broad
  privileges, so mount sources, property imports, permissions, error handling
  and fallback paths are security-sensitive.
- **Performance:** `medium` during boot. Repeated archive extraction, copying,
  relabeling or scanning in `init.sh`/`stage2.sh` directly extends boot time.
- **Necessity/status:** `required but snapshot-only`; the kernel/initrd and
  APEX/linker bootstrap contract is required, while this archived copy may be
  superseded by later host-side changes.
- **Required validation:** shell syntax tests, clean initrd assembly, no
  absolute developer paths, deterministic file order/timestamps, SELinux label
  verification and Layer2 7/7 from an empty Data directory.

### `patches/android-16/meta/hd-guest-untracked.txt`

- **Code/purpose:** records 155 files that existed outside version control,
  including ART/i18n libraries, framework JARs, linkerconfig outputs, initrd
  images, cache staging and several `.bak`/`.orig` scripts.
- **Review:** **P0 replay risk**. Most entries are generated Android outputs or
  backups. Copying them into source can mix releases and make a successful
  incremental build depend on stale artifacts.
- **Performance:** stale ART/JAR/linker artifacts can cause boot fallback,
  dexopt churn, linker failures or subtle runtime regressions.
- **Necessity/status:** `audit-only`. The manifest is useful forensic evidence;
  the listed files are not source patches.
- **Required action:** regenerate all payloads from the pinned `android-16`
  build, reject backups/staging files, and publish a signed output manifest
  with SHA-256 hashes.

## Product and Device Source

### `untracked-src/aosp16__device_bst_qvirt`

- **Code/purpose:** four new product files register `bst_x86_64` and
  `bst_arm64`, select the shared qvirt board, choose graphics/power packages
  and enable VINTF enforcement.
- **Review:** **P1 contract-critical**. This is the correct ownership layer for
  product selection and is safer than global build-system or
  `hwservicemanager` bypasses. The arm64 and x86_64 package/VINTF contracts
  still need independent validation; the example power service should not be
  treated as a production implementation without profiling.
- **Performance:** `low` directly; selected graphics and power HALs have
  `high` indirect impact.
- **Necessity/status:** `required`. These files define the migrated products
  and replace several temporary generic/global workarounds.
- **Required validation:** both lunch targets, VINTF check, package
  installation list, graphics startup and power-hint behavior.

### `untracked-src/aosp16__device_generic_common`

- **Code/purpose:** 74 archived source/config files provide generic product
  policy, boot/fstab/uevent rules, media/Wi-Fi/input/ALSA configuration,
  native-bridge selection, APK packaging, utility scripts and kernel/system
  build tasks.
- **Review:** **P1 broad ownership**. This directory is necessary as a source
  of intent but should not be imported wholesale. Specific concerns include:
  disabled VINTF enforcement in `device.mk`, legacy ELF-copy escape hatches,
  a root/unroot bind-mount helper, broad product properties, old HAL package
  lists and duplicate native-bridge policy directories.
- **Performance:** `medium/high` indirectly. Media codecs, graphics/HWC,
  native translation, init services and copied libraries affect boot, app
  startup, frame time and memory.
- **Necessity/status:** `partially required`. Board/init/media/input essentials
  are required; legacy HALs, debug behavior, PPP hardware profiles and bundled
  applications are conditional or optional.
- **Required action:** split the content into board core, feature packages,
  compatibility data and release payloads. Keep VINTF enforcement in qvirt,
  remove dead/duplicate policy and gate privileged maintenance scripts.

### `build-error.patch`

- **Location:** `untracked-src/aosp16__device_generic_common/build-error.patch`.
- **Code/purpose:** a nested diagnostic patch enabling APK architecture output
  and adding kernel build-tool paths.
- **Review:** **P2**. This artifact is outside the 81-patch directory but is a
  real migration patch. The extra `info` output is diagnostic noise; the
  kernel tool-path change may be necessary, but must be expressed in the
  canonical build task rather than retained as an error-era side patch.
- **Performance:** none at runtime; negligible build logging overhead.
- **Necessity/status:** `superseded/audit-only`.
- **Required action:** compare its kernel-tool settings with the final build
  scripts, preserve only the needed path fix, then delete the diagnostic patch
  from any release input.

### `untracked-src/aosp16__device_generic_x86_64`

- **Code/purpose:** one legacy x86_64 product makefile.
- **Review:** **P2 duplication**. It overlaps the unified qvirt product and can
  reintroduce a second product identity or divergent package list.
- **Performance:** none directly.
- **Necessity/status:** `superseded` by `device/bst/qvirt`.
- **Required action:** retain only as migration evidence unless a separately
  supported generic x86_64 target is declared.

## Framework New-File Payload

### `untracked-src/aosp16__frameworks_base`

- **Code/purpose:** 13 new Java/AIDL/JNI files implement BST app filtering,
  utility APIs and the Binder-to-host call service. They are the new-file
  counterparts required by modifications in `aosp16__frameworks_base.patch`
  and the surgical framework patches.
- **Review:** **P1**, with **P0 permission-sensitive operations**. The surface
  includes property mutation, URLs, clipboard, file import/export, APK
  installation events, account/advertising identifiers, UI dumps and native
  host commands. Every Binder entry must enforce an explicit caller policy;
  exception-to-default behavior must not become authorization fail-open.
  Large AIDL strings also need size bounds before JNI conversion.
- **Performance:** `medium/high`. `BstFilterAppsService` maintains many lists,
  observers and configuration files; host calls are synchronous Binder/JNI
  operations unless explicitly queued. Frequent display/input/app lifecycle
  callers must use cached decisions and bounded asynchronous delivery.
- **Necessity/status:** `required core plus conditional features`. HostCall and
  the compatibility-policy service are product foundations; individual
  affiliate, ad, IAP, telemetry and spoofing operations are optional.
- **Required validation:** Binder permission matrix, fuzzed AIDL/JNI strings,
  host-disconnect/time-out tests, StrictMode/system-server latency checks,
  concurrent config reload tests and API compatibility checks.

### `untracked-src/aosp16__frameworks_native`

- **Code/purpose:** adds the native Binder interface header used by BST app
  filtering and archives a disabled Vulkan null-driver build file.
- **Review:** **P1 ABI**. Java AIDL and native transaction ordering/comments
  indicate a manual cross-language contract; transaction drift can route a
  call to the wrong operation. The disabled null driver is historical state,
  not an active build definition.
- **Performance:** `low` for the interface itself; implementation cost depends
  on call frequency and payload size.
- **Necessity/status:** Binder contract `conditional/required` when the native
  peer is enabled; disabled null-driver file `audit-only`.
- **Required validation:** generated/stable AIDL where possible, transaction
  compatibility tests, malformed parcel tests and death-recipient handling.

### `untracked-src/aosp16__hardware_libhardware`

- **Code/purpose:** preserves disabled gralloc and hwcomposer Android.bp files
  from graphics bring-up.
- **Review:** **P2**. Renaming build files is a fragile exclusion mechanism and
  can hide the selected graphics implementation. Product variables or explicit
  module selection are preferable.
- **Performance:** no direct cost, but choosing the wrong gralloc/HWC path has
  `high` graphics impact.
- **Necessity/status:** `superseded/audit-only`.
- **Required action:** document the single supported graphics provider in
  qvirt and verify that duplicate modules are absent from Soong's graph.

## HAL Archive

### `untracked-src/g1_hal_fixes.tar.gz`

- **Code/purpose:** contains six source/build replacements for camera image
  processing and memtrack/lights/power/audio module definitions.
- **Review:** **P1**. A tarball obscures per-file history and makes partial
  application difficult. Camera metadata code needs API/ownership review;
  Android.mk-only HAL enablement can select obsolete interfaces.
- **Performance:** potentially `medium/high` for camera, audio and power paths.
- **Necessity/status:** `conditional/audit-only archive`; individual fixes may
  be required, but the tarball is not an accepted integration unit.
- **Required action:** extract to review-only staging, create one commit per
  HAL owner, verify Android 16 interface versions and benchmark camera/audio
  latency and power behavior.

## Binary, APK and Signing Payload

### `meta/binary-untracked-manifest.txt`

- **Code/purpose:** records 95 omitted binary payloads: BusyBox, native
  translation/proxy libraries, arm64 runtime libraries, eight APKs and
  `apksigner.jar`.
- **Review:** **P0 supply-chain gap**. Entries use MD5, which is suitable only
  as a historical identity hint, not release integrity. The archive does not
  state source revision, producer, compiler, license, Android ABI/API target,
  signature certificate or vulnerability status.
- **Performance:** native translation is `high` impact for ARM app startup,
  memory, graphics and CPU execution. Bundled APKs add system image size,
  first-boot scan/dexopt work and background activity.
- **Necessity/status:** native translation `conditional/required` for ARM app
  compatibility; BusyBox `temporary/diagnostic`; APKs `conditional/optional`;
  bundled signing tool `build-only`.
- **Required validation:** SHA-256/SBOM/provenance, ELF dependency and symbol
  checks, W^X/RELRO/BTI or applicable hardening checks, malware/vulnerability
  scan, APK certificate/permission review, cold-start/RSS benchmarks and
  license approval.

### `untracked-src/.../apksigner/bluestacks-market.keystore`

- **Code/purpose:** an archived application signing credential.
- **Review:** **P0 secret exposure**. Signing keys must not be stored in a
  patch payload or source repository. Even if this is a test key, its scope
  and revocation policy must be explicit.
- **Performance:** none.
- **Necessity/status:** `rejected as source payload`; signing itself is
  required, this credential distribution method is not.
- **Disposition:** removed from the current tree; size and SHA-256 are recorded
  in `docs/project-review/security.md`. Existing Git history and the binary-file
  marker in the archived project patch are retained for traceability in this
  local review. Treat the credential as exposed, rotate it externally, and use
  controlled CI signing with access audit logs. A history rewrite requires a
  separately coordinated repository-wide operation.

## Build-Script and Metadata Manifests

### `meta/app-player-buildscripts-untracked.txt`

- **Code/purpose:** records eight host build/packaging scripts, including
  Baklava system assembly and VDI/SquashFS helpers.
- **Review:** **P1 reproducibility**. The four active scripts are legitimate
  companion sources; `.bak` files are not. Host tools, paths, filesystem
  options and expected Android outputs must be pinned.
- **Performance:** build/packaging only; SquashFS options can affect image size,
  startup I/O and decompression CPU.
- **Necessity/status:** active packaging scripts `required`; backup files
  `rejected`.
- **Required validation:** shell lint, clean host build, deterministic image
  hashes, no developer-specific paths and failure on missing inputs.

### `meta/base.txt`

- **Code/purpose:** records the baseline manifest/reference used when the
  archive was generated.
- **Review:** **P1 traceability**. It is necessary evidence only if every
  project revision and submodule state can be reconstructed from it.
- **Performance:** none.
- **Necessity/status:** `required metadata`.
- **Required validation:** confirm all projects are initialized, the intended
  source branches are `aosp16-bst` and imported integration branches are
  `aosp16-bst-merge`, and store a resolved manifest with immutable SHAs.

## Integration Decision Matrix

| Payload | Decision | Reason |
|---|---|---|
| qvirt product files | Integrate and maintain | Canonical product ownership and VINTF/graphics selection |
| Kernel source/config | Integrate from pinned commit/config derivation | Boot-critical, but current text snapshot is not reproducible |
| BootImage source scripts | Rebase and maintain | Boot-critical; must match current app-player packaging |
| Framework HostCall/filter new files | Integrate with permission and latency hardening | Required product IPC and compatibility policy |
| Generic common source/config | Split and selectively integrate | Mixed required, legacy, optional and privileged content |
| Native translation binaries | Conditional release payload | Needed for ARM compatibility, subject to provenance/performance gates |
| Bundled APKs | Feature-by-feature decision | Not required for core boot; add image and background cost |
| HAL tarball | Decompose before integration | Archive is not reviewable or traceable as one unit |
| Disabled build files, backups and generated outputs | Do not integrate | Historical/debug state with stale-output risk |
| Keystore | Remove and rotate as applicable | Source-controlled secret is unacceptable |

## Payload Release Gate

1. Resolve every required payload to an immutable source commit or signed
   artifact digest.
2. Remove credentials, backups, `.orig` files and generated Android outputs
   from source inputs.
3. Replace MD5-only identity with SHA-256 plus SBOM, license and producer data.
4. Verify qvirt VINTF, graphics and HAL selection without global compatibility
   bypasses.
5. Run Binder permission and host-disconnect tests for every HostCall/utility
   operation.
6. Benchmark boot, first app launch, frame time, native translation RSS and
   image decompression against the known-good AOSP16 product.
7. Build kernel, Android image and BootImage from a clean workspace and publish
   a signed, reproducible output manifest.
