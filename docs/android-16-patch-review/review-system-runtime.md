# System, Runtime and Mechanical Patch Review

This chapter covers 22 bionic/ART/external source overlays and Phase 2
cross-project patches.

## Runtime and External Source Overlays

### `a13__art__bst_full.patch`

- **Code/purpose:** full Android 13 ART customization snapshot covering native
  bridge exports/namespace handling, JNI behavior and OAT quick-method logic.
- **Review:** **P0 replay risk**. ART internals changed substantially by Android
  16. Only the native-loader namespace portion was initially accepted
  surgically; copying JNI/OAT code across releases can violate runtime metadata
  and GC/JIT assumptions.
- **Performance:** potentially `high`; JNI and OAT paths are hot.
- **Necessity/status:** `audit-only/partially ported`. Use it to identify intent,
  not as a replay unit.
- **Recommendation:** maintain per-hunk tests for native bridge namespace and
  omit code already provided by Android 16.

### `a13__bionic__bst_full.patch`

- **Code/purpose:** full bionic snapshot containing x86 I/O syscalls, fortify,
  open/poll, DNS, property filtering, timezone and linker changes.
- **Review:** **P0 replay risk**. The patch crosses ABI, security and loader
  boundaries. Android 16 intentionally lacks some `iopl/ioperm` exports; adding
  map entries without implementations is invalid. Property and DNS behavior
  must be reviewed independently.
- **Performance:** potentially `high` because libc property, open, poll and DNS
  calls are common.
- **Necessity/status:** `audit-only/partially ported`; surgical getaddrinfo,
  fortify/open/poll and property changes were validated separately.
- **Recommendation:** never apply whole. Keep ABI symbol tests, libc unit tests
  and app/system caller matrices for each retained behavior.

### `a13__boringssl__bst.patch`

- **Code/purpose:** carries Android 13 RSA-PSS compatibility and BoringSSL
  self-test packaging changes.
- **Review:** **P1**. RSA padding code is cryptographic core and must not be
  overlaid when Android 16 already contains equivalent upstream support.
  Self-test startup should be handled separately.
- **Performance:** negligible for packaging; RSA path performance is workload
  dependent.
- **Necessity/status:** `superseded/equivalent upstream`; registry records no
  further RSA overlay.
- **Recommendation:** retain only the 64-bit self-test packaging decision and
  verify with crypto known-answer tests.

### `a13__icu__ROB14898-iran-tz.patch`

- **Code/purpose:** fixes Iran/Tehran timezone transition behavior in ICU Java
  bridge classes.
- **Review:** **P1 correctness**. Timezone rules are data/version sensitive;
  hard-coded logic can become stale or disagree with tzdata.
- **Performance:** `low`; timezone calculation only.
- **Necessity/status:** `conditional`, surgically ported and Layer2 verified.
- **Recommendation:** add date-boundary tests around the affected transitions
  and compare with the bundled tzdata release.

## Cross-Project Mechanical Patches

### `P2-MECH-1-audio.diff`

- **Code/purpose:** removes the explicit one-thread Binder pool cap from the
  default audio service.
- **Review:** **P1**. It can prevent host/audio callback starvation, but leaves
  concurrency to Binder defaults and may expose thread-safety bugs.
- **Performance:** mixed; lower latency under contention, higher thread/RSS
  potential.
- **Necessity/status:** `conditional`, ported and 7/7 verified.
- **Tests:** concurrent route/volume/stream operations and thread-count/RSS
  observation.

### `P2-MECH-1-battery.diff`

- **Code/purpose:** suppresses BatteryMonitor kernel-log spam and changes the
  global klog level.
- **Review:** **P2**. Gating repetitive logs is valid; changing global log level
  from a component is broad and can hide unrelated diagnostics.
- **Performance:** small boot/runtime logging reduction.
- **Necessity/status:** `optional`, ported.
- **Recommendation:** rate-limit the specific message instead of changing
  global verbosity.

### `P2-MECH-2-launcher3-manifest.diff`

- **Code/purpose:** removes HOME categories from Launcher3 so the BST launcher
  exclusively handles HOME.
- **Review:** **P2**. Direct deletion is cleaner than the invalid XML comment
  attempted in the Android 13 form.
- **Performance:** none.
- **Necessity/status:** `required`, ported and 7/7 verified.
- **Tests:** resolver query and first-boot HOME selection.

### `P2-MECH-3-getprop.diff`

- **Code/purpose:** hides `bst.*` and named BST properties from the `getprop`
  command unless a debug property is enabled.
- **Review:** **P1**. This affects the CLI only and is anti-detection rather than
  access control; native property APIs can still expose values. Static debug
  state is read once.
- **Performance:** `low`; linear scan over a short fixed list per property.
- **Necessity/status:** `optional/conditional`, ported.
- **Tests:** named/prefix properties, debug toggle semantics and vendor/recovery
  toolbox variants.

### `P2-MECH-4-start.diff`

- **Code/purpose:** stops appstatsd and resets BST boot/top-activity properties
  when default Android services are stopped.
- **Review:** **P1**. Reset behavior is useful for host state consistency but
  must execute only for the intended stop command and not arbitrary service
  control.
- **Performance:** negligible.
- **Necessity/status:** `required` for clean shutdown/restart state, ported.
- **Tests:** start/stop cycles, property readback and appstatsd absence.

### `P2-MECH-5-buildmake.diff`

- **Code/purpose:** removes several platform apps and disables ART debug
  packaging in upstream product makefiles.
- **Review:** **P1 build correctness**. It broke Android 16 release-config
  evaluation and was reverted.
- **Performance:** smaller image/package scan if implemented correctly; no
  steady runtime cost.
- **Necessity/status:** `superseded`. App removal was reimplemented at
  `device/bst/qvirt`; do not modify global build/make for this.
- **Tests:** clean lunch/release-config and installed package list.

### `P2-MECH-6-adb.diff`

- **Code/purpose:** reads `/data/downloads/.adbcmd` as an ADB command allowlist
  and extends file-sync treatment for `/sdcard` and `/mnt/windows`.
- **Review:** **P0**. Substring matching is not command parsing; an empty line,
  missing newline or crafted command can bypass policy, and `line[strlen-1]`
  is unsafe for an empty string. Missing file means allow-all. The file trust
  and ownership model is undocumented.
- **Performance:** `medium`; opens and scans a file for commands.
- **Necessity/status:** shared-folder sync is `conditional`; this whitelist
  implementation requires redesign despite being ported/boot-verified.
- **Recommendation:** parse an authenticated structured policy once, match
  command/arguments exactly, reject unsafe file metadata and add fuzz tests.

### `P2-MECH-7-ethernet.diff`

- **Code/purpose:** builds static Ethernet IP configuration from BST properties
  when network modification is enabled.
- **Review:** **P1**. Defaults match the emulator network, but invalid IP/prefix
  properties and runtime changes need graceful fallback.
- **Performance:** `low`; configuration-time parsing only.
- **Necessity/status:** `conditional`, ported and verified for network identity.
- **Tests:** malformed properties, DHCP fallback, DNS list and property-off.

### `P2-MECH-8-settings.diff`

- **Code/purpose:** skips selected Settings action-bar customization when the
  BST settings property is enabled.
- **Review:** **P2**. Narrow UI behavior with an explicit gate; the default-on
  choice should be product-defined.
- **Performance:** none.
- **Necessity/status:** `optional`, ported.
- **Tests:** both property values and affected Settings entry points.

### `P2-MECH-9-imediasource.diff`

- **Code/purpose:** disables multi-read media behavior for a configured game
  profile via the native BST utility/filter service.
- **Review:** **P1**. A fail-open service lookup is appropriate, but synchronous
  Binder calls must not occur for every media buffer.
- **Performance:** `medium/high` if uncached; disabling multi-read can reduce
  throughput for the target app.
- **Necessity/status:** `optional`, ported as an app-specific workaround.
- **Tests:** cache the decision per source, compare throughput and verify
  non-target apps.

### `P2-MECH-10-camera.diff`

- **Code/purpose:** overrides reported camera sensor orientation per calling
  application in CameraService and CameraProviderManager.
- **Review:** **P1**. The modulo chain accepts profile-encoded values but should
  validate range explicitly. Caller PID/package can race with Binder lifecycle.
- **Performance:** `medium`; profile IPC during camera info/open, not per frame
  if implemented as shown.
- **Necessity/status:** `conditional`, ported for app camera compatibility.
- **Tests:** front/back camera, rotation values, service absence and app switch.

### `P2-MECH-11-wifi.diff`

- **Code/purpose:** always reports Wi-Fi state as enabled.
- **Review:** **P1 correctness**. It computes the real state and discards it,
  producing inconsistency with connection info, scans and callbacks. No caller
  gate is present.
- **Performance:** negligible.
- **Necessity/status:** `conditional` anti-detection feature, ported but should
  be UID/property gated.
- **Tests:** system versus app callers, actual disabled state and callback/API
  consistency.

### `P2-MECH-12-latinime.diff`

- **Code/purpose:** initializes the BST IME listener-port property through
  reflection, avoiding Soong SDK visibility restrictions on BST framework
  classes.
- **Review:** **P2/P1**. Reflection is a pragmatic boundary workaround and
  fails non-fatally, but method/service names are untyped and can drift.
- **Performance:** `low`; one-time `onCreate` work.
- **Necessity/status:** `conditional`, ported and 7/7 verified.
- **Tests:** service/method absent, reflection exception, process restart and
  listener-port readback.

### `P2-MECH-14-telephony.diff`

- **Code/purpose:** returns the configured BST IMEI from
  PhoneSubInfoController when fake telephony is enabled.
- **Review:** **P1**. The surrounding controller permission checks must remain
  authoritative; the hook should not widen access.
- **Performance:** `low`.
- **Necessity/status:** `conditional`, ported.
- **Tests:** permission-denied callers, system/app UIDs, empty IMEI property and
  telephony-disabled mode.

### `P2-MECH-15-telephony2.diff`

- **Code/purpose:** returns a configured fake IMEI from GsmCdmaPhone and forces
  UICC application state to READY.
- **Review:** **P1**. Global SIM READY can affect system telephony flows, not
  only third-party detection. The property gate should be product- and
  caller-aware.
- **Performance:** negligible.
- **Necessity/status:** `conditional`, ported and verified.
- **Tests:** system telephony initialization, property off, empty IMEI and
  state/API consistency.

### `P2-MECH-16-propsvc.diff`

- **Code/purpose:** loads `/data/.bluestacks.prop` and `/data/.bstconf.prop`
  into init property processing when the files exist.
- **Review:** **P0**. Data-partition files influence system properties during
  boot. Ownership, mode, label, allowed property namespaces and override order
  must be strictly enforced.
- **Performance:** `low` boot-time file parsing.
- **Necessity/status:** `required` for the existing host-generated property
  contract, ported.
- **Tests:** file permissions/SELinux labels, invalid lines, protected `ro.*`
  properties, missing files and precedence.

### `P2-MECH-17-initrc.diff`

- **Code/purpose:** intended to add `install_zip` and
  `bst_getevents_logger` services plus property triggers.
- **Review:** **P0 artifact defect**. The archived added content is collapsed
  onto a single line after the comment, so it is not a valid replay of the
  intended init syntax.
- **Performance:** intended services are inert until triggered.
- **Necessity/status:** behavior was ported and boot-verified, but this artifact
  is `rejected` as a restore source.
- **Recommendation:** regenerate from the committed `system/core` change and
  validate with the init parser before replacing this file.

### `P2-MECH-19-bionic-propsvc.diff`

- **Code/purpose:** intercepts libc property reads/writes, classifies the caller
  through `/proc`, hides BST properties, returns synthetic secure/product/ABI
  values and applies per-app overrides.
- **Review:** **P0**. This is a 425-line policy engine inside a ubiquitous libc
  path. `/proc` reads, string reversal, file reads and package inference create
  correctness, race, security and maintainability risks. Property semantics can
  differ between libc and other readers.
- **Performance:** `high`; property APIs are hot and `/proc`/file work can
  amplify startup and steady-state cost.
- **Necessity/status:** `conditional` anti-detection feature, ported and
  Layer2-verified, but not proven performance-safe.
- **Recommendation:** move policy to a cached, versioned profile service or
  precomputed per-process state; benchmark app startup/property microbenchmarks
  and test all UID classes.
