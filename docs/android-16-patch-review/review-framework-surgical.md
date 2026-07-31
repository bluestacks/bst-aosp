# Framework Surgical Patch Review

These patches are smaller replay/audit units extracted from the large
framework snapshot. Exact paths and hashes are in
[patch-inventory.md](patch-inventory.md).

## Core and App Process Patches

### `P2-FW-CORE-APP-1.diff`

- **Code/purpose:** connects soft-keyboard policy to `BstUtilsManager`, hides
  BST accessibility services from third-party callers, and blocks selected
  edits while IME composition is active.
- **Review:** **P1**. Null-service fallback is safe. Accessibility filtering is
  caller-sensitive policy and needs system-UID exemptions. Edit blocking
  performs package/profile lookup from an input path.
- **Performance:** `medium`; service/profile calls occur during accessibility
  queries and text editing.
- **Necessity/status:** `conditional`, ported and Layer2 verified. Required only
  for keyboard mapping and anti-detection profiles.
- **Tests:** trusted versus untrusted accessibility callers; composing/non-
  composing edit behavior; service-death fallback.

### `P2-FW-CORE-APP-2.diff`

- **Code/purpose:** forces native-library extraction for configured APKs and
  reports fullscreen/mouse-action changes to the host.
- **Review:** **P1**. Native extraction changes install/storage behavior.
  View-system-UI updates can be frequent; property-based deduplication helps
  but does not remove synchronous hostcall risk.
- **Performance:** `medium`; install-time I/O plus Binder work on UI changes.
- **Necessity/status:** `conditional`, ported. Extraction is per-app
  compatibility; mouse reporting is part of the host UI contract.
- **Tests:** split APKs, low-storage install, repeated visibility values and
  host service unavailable.

### `P2-FW-CORE-APP-3.diff`

- **Code/purpose:** adds Instrumentation hooks for proprietary intents,
  Play/market referrer capture and pre-unlock access allowances for selected
  packages.
- **Review:** **P0/P1**. Intent rewriting and credential-storage exceptions are
  security-sensitive. Broad package-prefix exemptions and referrer forwarding
  require explicit ownership and privacy review.
- **Performance:** `low/medium`; runs on activity launch and intent handling.
- **Necessity/status:** `optional/conditional`, ported. Boot does not require
  affiliate/referrer behavior.
- **Tests:** malformed intents, locked-user behavior, package spoofing and
  absence of BstCommandProcessor.

### `P2-FW-CORE-APP-4.diff`

- **Code/purpose:** masks BlueStacks/VirtualBox input-device names and applies
  per-app input exposure/pointer behavior.
- **Review:** **P1**. Calling-package resolution and Binder profile queries are
  performed from input APIs. Null package names and system callers must remain
  unmodified.
- **Performance:** `medium/high` if queried per input event; cache decisions by
  UID/device generation.
- **Necessity/status:** `conditional`, ported for anti-detection and input
  compatibility.
- **Tests:** hot-plug, multiple users, trusted callers, renamed devices and
  service death.

### `P2-FW-CORE-APP-5.diff`

- **Code/purpose:** provides per-app storage-path rewriting and hides selected
  developer/mock-location settings from applications.
- **Review:** **P1**. Storage path changes can violate scoped-storage
  assumptions. Settings filtering is caller-sensitive and must not affect
  framework/system services.
- **Performance:** `medium`; Settings APIs are frequent and include package
  lookup/Binder work.
- **Necessity/status:** `conditional`, ported. Neither feature is boot-required.
- **Tests:** app/system UID matrix, multi-user paths, MediaStore/SAF and null
  filter service.

### `P2-FW-CORE-APP-6.diff`

- **Code/purpose:** calculates editor cursor coordinates and notifies the host
  while BST text-edit mode is active.
- **Review:** **P1 performance-sensitive**. The patch correctly deduplicates
  coordinates, but layout access and Binder calls occur near cursor blink and
  text update paths.
- **Performance:** `high` when text mode is enabled; Binder calls can cause
  jank if the host is slow.
- **Necessity/status:** `conditional`, ported for Windows keyboard mapping.
- **Tests:** rapid typing/selection, multi-line and transformed text, host
  timeout, disabled mode and frame-time comparison.

### `P2-FW-CORE-APP-8.diff`

- **Code/purpose:** uses reflection on launch transaction items to redirect
  configured billing activities through a BST proxy.
- **Review:** **P1**. Reflection targets private fields that can change between
  releases. Intent mutation must preserve flags, caller identity and loop
  prevention; the `bst_hooked` guard is essential.
- **Performance:** `medium` on activity launches; reflection is not per-frame.
- **Necessity/status:** `optional`, ported for IAP compatibility.
- **Tests:** transaction-class changes, nested launches, disabled profile,
  missing proxy and security/exported-component rules.

### `P2-FW-CORE-APP-9.diff`

- **Code/purpose:** filters a native mouse device for a specific compatibility
  profile.
- **Review:** **P2**. Narrow scope is preferable to global masking, but package
  lookup in device enumeration should be cached and profile identity documented.
- **Performance:** `medium` during device enumeration/change.
- **Necessity/status:** `optional`, ported for a specific application issue.
- **Tests:** target/non-target packages, device reconnect and multi-user UID.

### `P2-FW-CORE-APP-10.diff`

- **Code/purpose:** overrides Display density and X/Y DPI according to BST
  profile policy.
- **Review:** **P1 hot path**. Several DisplayMetrics methods call package and
  Binder services. Inconsistent overrides can break resource selection,
  physical-size calculations and compatibility mode.
- **Performance:** `high` without caching because metrics are queried often.
- **Necessity/status:** `conditional`, ported for per-app DPI compatibility.
- **Tests:** configuration change, display hot-plug, privileged callers,
  density resource buckets and Binder-latency trace.

### `P2-FW-CORE-APP-11.diff`

- **Code/purpose:** applies custom density/X-Y DPI in `ResourcesImpl` and
  replaces status-bar dimensions when the BST status bar is hidden.
- **Review:** **P1 hot path**. Resource lookup is extremely frequent. Static
  property snapshots also ignore runtime property changes.
- **Performance:** `high` if service lookup occurs per resource update; cache
  immutable profile data in configuration state.
- **Necessity/status:** `conditional`, ported for custom DPI/status-bar layout.
- **Tests:** runtime property changes, resource overlays, orientation, multiple
  displays and no BST service.

### `P2-FW-CORE-APP-12.diff`

- **Code/purpose:** injects per-game default SharedPreferences and several
  game-specific preference read overrides.
- **Review:** **P1 correctness**. Framework-level mutation of app preferences
  is invasive and can conflict with app migrations. Profile parsing and file
  selection need strict bounds and one-time execution.
- **Performance:** `medium`; guarded by `mBstDefaultSet`, but initial profile
  parsing/file operations occur in preference paths.
- **Necessity/status:** `optional`, ported for selected game compatibility.
- **Tests:** corrupt profile strings, app upgrade, multiple preference files,
  first boot and disabled profile.

### `P2-FW-CORE-APP-13.diff`

- **Code/purpose:** observes Google IAP result flow and forwards purchase data
  to BstCommandProcessor.
- **Review:** **P0/P1 privacy/security**. Purchase payload handling requires
  explicit data minimization, protected explicit components and caller
  authentication. Debug logs must not expose transaction details.
- **Performance:** `low`; event-driven.
- **Necessity/status:** `optional`, ported for BST billing integration.
- **Tests:** redacted logging, missing/disabled command processor, forged
  intents and unsuccessful purchases.

### `P2-FW-CORE-APP-14.diff`

- **Code/purpose:** changes native-library ABI selection using per-app BST
  translation profiles.
- **Review:** **P1 correctness**. ABI ordering affects extraction, native bridge
  use and process startup. Invalid profile output must fall back to upstream
  selection.
- **Performance:** `medium` at install/load time; no steady per-frame cost.
- **Necessity/status:** `conditional`, ported for ARM/x86 translation
  compatibility.
- **Tests:** mixed-ABI split APKs, 32/64-bit products, invalid profile, native
  bridge unavailable and app update.

### `P2-FW-CORE-APP-15.diff`

- **Code/purpose:** implements affiliate/referrer timestamp and metadata
  rewriting in `BaseBundle`, backed by static maps and files.
- **Review:** **P0/P1**. `BaseBundle` is a broad hot API and a poor ownership
  boundary for analytics policy. Static maps risk process-lifetime growth;
  file-backed state and sensitive referrer data require privacy review.
- **Performance:** `high` risk due to common Bundle reads and map/string work.
- **Necessity/status:** `optional`, ported for affiliate analytics, not boot.
- **Tests:** memory growth, concurrency, malformed timestamps, process restart,
  non-referrer Bundles and data retention.

### `P2-FW-CORE-APP-16.diff`

- **Code/purpose:** applies default app profiles during process bind and sends
  Unreal Engine console commands to control maximum FPS.
- **Review:** **P1**. Reflection into engine internals is version-fragile.
  Profile parsing during app startup must fail open. Any repeating FPS loop
  needs cancellation when process/activity state changes.
- **Performance:** `high` for reflection/polling and possible repeated console
  commands; startup profile work is `medium`.
- **Necessity/status:** `conditional`, ported for game tuning.
- **Tests:** non-UE apps, UE version changes, process recreation, disabled
  profile, cancellation and CPU/frame-time sampling.

### `P2-FW-CORE-APP-17.diff`

- **Code/purpose:** adds per-app display-rotation override behind
  `bst.enable_display_rotation`.
- **Review:** **P1**. The default-off kill switch is the correct response to an
  earlier rotation regression. Binder/profile results must be cached per
  package/configuration and invalidated safely.
- **Performance:** `medium`; configuration/display calls can be frequent.
- **Necessity/status:** `conditional`, ported and guarded; leave disabled unless
  a profile requires it.
- **Tests:** fold/rotation changes, multiple displays, target/non-target apps,
  kill switch and service death.

## Window Manager and System Services

### `P2-FW-WM-1-ActivityStarter-ATM.diff`

- **Code/purpose:** hides BST packages in launch handling, optionally asks the
  host whether a launch is allowed, and reports activity/display events.
- **Review:** **P1 boot-critical**. The GRM host query is correctly default-off
  after prior regression, but any synchronous call in ActivityStarter can
  block launches. PackageInfo lookup also adds work.
- **Performance:** `medium/high` on every activity launch when enabled.
- **Necessity/status:** host activity reporting is `required`; GRM launch
  blocking is `conditional`; ported and Layer2 verified.
- **Tests:** cold boot, host unavailable/slow, same-package launches, system
  apps and kill-switch default.

### `P2-FW-SERVICES-4a.diff`

- **Code/purpose:** adjusts AppOps access for BST device-details behavior and
  reports music volume/mute changes to the host.
- **Review:** **P0/P1**. AppOps exceptions alter a security boundary and must be
  package-signature/UID based, not package-name only. Audio host synchronization
  should remain asynchronous and deduplicated.
- **Performance:** `medium`; volume changes are infrequent but Binder can block
  AudioService.
- **Necessity/status:** audio sync is `conditional`; AppOps exception requires
  explicit product approval. Ported and verified.
- **Tests:** spoofed package name, signature mismatch, user profiles, rapid
  volume changes and host death.

### `P2-FW-SERVICES-5.diff`

- **Code/purpose:** filters installed/enabled accessibility services returned
  to third-party callers.
- **Review:** **P1**. Returning a filtered copy is safer than mutating service
  state. Caller classification must exempt system/settings/accessibility
  components.
- **Performance:** `medium`; list copy/filter per query.
- **Necessity/status:** `conditional` anti-detection feature, ported.
- **Tests:** system versus app UID, empty/null lists, multi-user services and
  consistency with SettingsProvider filters.

### `P2-FW-SERVICES-6.diff`

- **Code/purpose:** lazily obtains `BstHostCallManager` and notifies the host
  whenever the selected IME changes.
- **Review:** **P2/P1**. Lazy null handling is good. Notification should be
  asynchronous and deduplicated so IMMS locks are not held across host IPC.
- **Performance:** `low/medium`; IME changes are infrequent.
- **Necessity/status:** `conditional` host keyboard integration, ported.
- **Tests:** repeated same IME, user switch, host restart and callback failure.

### `P2-FW-SERVICES-6b.diff`

- **Code/purpose:** computes whether text-edit mode should be enabled for the
  current package/activity and synchronizes keyboard-mapper status to the host.
- **Review:** **P1**. It reads top-activity properties and profile policy inside
  IMMS state changes. State deduplication is good; package/activity parsing
  must handle null and stale values.
- **Performance:** `medium`; Binder/profile work on focus and IME transitions.
- **Necessity/status:** `conditional`, ported as core keyboard-mapping behavior.
- **Tests:** focus churn, disabled profile, stale top activity, host death and
  multi-user IME.

## Peripheral Framework Patches

### `P2-FW-PERIPH-1.diff`

- **Code/purpose:** always reports a vibrator and adjusts media-codec
  capability/profile behavior for configured top packages.
- **Review:** **P1**. Synthetic hardware capability can make apps issue
  unsupported operations. Media decisions based on a global top-package
  property can race with task switches.
- **Performance:** `low`; property/branch work on capability queries.
- **Necessity/status:** `optional/conditional`, ported.
- **Tests:** no vibrator backend, task switch during codec selection, system UID
  and target/non-target packages.

### `P2-FW-PERIPH-2.diff`

- **Code/purpose:** grants selected packages exceptions around privileged phone
  state/device-ID permission checks.
- **Review:** **P0**. Package-name-only permission bypass is spoofable unless
  tied to UID and signing certificate. This is not an ordinary compatibility
  change.
- **Performance:** negligible.
- **Necessity/status:** `conditional`, ported historically; production use
  requires a security-approved identity check.
- **Tests:** same-name unsigned package, shared UID, user profiles and denied
  callers.

### `P2-FW-PERIPH-3.diff`

- **Code/purpose:** returns configured/default mobile operator name and numeric
  values to emulate a T-Mobile SIM environment.
- **Review:** **P1**. Global spoofing also affects trusted/system callers and can
  make APIs inconsistent with subscription/service state.
- **Performance:** `low`.
- **Necessity/status:** `conditional` anti-detection feature, ported.
- **Tests:** system versus app UID and consistency with SIM/operator properties.

### `P2-FW-PERIPH-3b.diff`

- **Code/purpose:** unconditionally returns a synthetic software version and
  device ID.
- **Review:** **P0 correctness regression**. It bypasses permission semantics
  and affected boot/system callers.
- **Performance:** negligible.
- **Necessity/status:** `rejected/superseded` after Layer2 regression; replaced
  by the UID-gated PERIPH-5 implementation.
- **Tests:** retain as a negative regression case; never replay.

### `P2-FW-PERIPH-4.diff`

- **Code/purpose:** reports LTE network type when the BST network-type property
  is enabled.
- **Review:** **P1**. The explicit property gate is useful, but caller and other
  telephony APIs can still observe inconsistent state.
- **Performance:** `low`.
- **Necessity/status:** `conditional`, ported.
- **Tests:** property off/on, system callers and consistency with data/service
  state.

### `P2-FW-PERIPH-5.diff`

- **Code/purpose:** returns synthetic device ID/software version only to app
  UIDs (`>= 10000`), fixing PERIPH-3b.
- **Review:** **P1**. UID gating is materially safer, though isolated-process,
  shared-UID and privileged-app cases should use package/permission policy.
- **Performance:** negligible.
- **Necessity/status:** `conditional`, ported and preferred over PERIPH-3b.
- **Tests:** root/system/shell/app/isolated UID matrix and permission behavior.

### `P2-FW-PERIPH-6.diff`

- **Code/purpose:** filters enabled accessibility-service setting values on
  single-key SettingsProvider reads.
- **Review:** **P1**. Correctly complements service-list filtering, but caller
  exemptions and delimiter-preserving serialization are essential.
- **Performance:** `medium`; string parsing/allocation per targeted read.
- **Necessity/status:** `conditional`, ported.
- **Tests:** malformed/empty setting, system and Settings callers, multiple
  hidden services.

### `P2-FW-PERIPH-7.diff`

- **Code/purpose:** applies the same accessibility filtering to SettingsService
  bulk reads.
- **Review:** **P1**. Necessary for consistency with PERIPH-6 and
  AccessibilityManagerService; otherwise apps can bypass filtering through a
  different API.
- **Performance:** `medium`; only targeted key values should be copied.
- **Necessity/status:** `conditional`, ported.
- **Tests:** single versus bulk result parity, caller UID matrix and multi-user
  settings.

### `P2-FW-PERIPH-8.diff`

- **Code/purpose:** constructs and returns a synthetic `SubscriptionInfo` list
  for third-party callers.
- **Review:** **P0/P1 API risk**. The original approach conflicted with Android
  16 permission/API checks and can produce inconsistent subscription objects.
- **Performance:** `low/medium` due object creation per query.
- **Necessity/status:** `superseded` by
  `aosp16__frameworks_base__d8-subscription.patch`, which changes only the
  active count.
- **Tests:** do not replay; use it only to document fake-SIM field requirements.
