# A13 HAL and VINTF Promotion Review

## Scope

This review reconciles the final Android 13 generic-device manifest with the
Android-16 `android_x86_64` product. It distinguishes interface declarations
from implementation libraries, service wrappers, init rc files, framework
compatibility matrices, and module-owned VINTF fragments. A packaged binary is
not considered ported when hwservicemanager will reject its registration.

Authoritative A13 sources:

- baseline manifest and service graph: `47816eea2ce9d94f0606b631b81341bc21aaab59`
- ConfigStore and GNSS: `4facbf0174fcae1c8bf9181544343c16f9e1ea9d`
- Power: `ef2f4da5e521cf04e9d687c24c6bb46d9cc303fc`
- Memtrack: `4498e9e02dfc54b7dfd7871e09a5c8f499d10a7e`
- Light: `874610a60b6e5f431c720a5d49a3206e7500d8f7`
- final Widevine/ClearKey shape: `2521f4b96beca939da7ea2ebe93608156cc14dda`
- final Dumpstate version: `0aae19c5f0f104aaa5b8d0982176ad506a270509`

Target source identity at discovery:

- Android root: `4eb695060852919cdb100617f4880c737bc9bdcf`
- product: `android_x86_64-trunk_staging-eng`
- target component: `device/generic/x86_64`, head
  `00623898eb9bd0afc4374f6c79f805939f873311`
- common service graph: `device/generic/common/treble.mk`

## Entry Review

| A13 declaration | Android-16 provider and declaration owner | Decision | Necessity and evidence |
|---|---|---|---|
| Audio 7.0 | Retained HIDL audio service; common device manifest | Keep existing | FCM 8 accepts HIDL 7.0 and current manifest already declares it. |
| Audio Effect 7.0 | Retained HIDL audio service; common device manifest | Keep existing | FCM 8 accepts HIDL 7.0 and current manifest already declares it. |
| Bluetooth 1.0 | `android.hardware.bluetooth-service.default`; module-owned AIDL fragment | Replaced by AIDL | The current binary has `vintf_fragments`; replaying HIDL would add an unused interface. |
| Camera Provider 2.4 `legacy/0` | Retained 32-bit HIDL provider loading `camera.bst`; no fragment | Add x86_64 declaration and FCM bridge | Binary and rc are installed and the service registers exactly `legacy/0`; FCM 8 accepts only AIDL camera providers. |
| ConfigStore 1.1 | Retained HIDL service; no fragment | Add x86_64 declaration and FCM bridge | Init starts both 1.0/1.1 interfaces and registration is fatal on failure; FCM 8 has no ConfigStore entry. |
| Dumpstate 1.0 | `android.hardware.dumpstate-service.example`; module-owned AIDL fragment | Replaced by AIDL | Preserves developer-options dump behavior without reviving the obsolete HIDL service. |
| GNSS 1.0 | `com.android.hardware.gnss`; APEX-owned AIDL fragment | Replaced by AIDL APEX | `gnss-default.xml` declares AIDL `IGnss/default`; no BST HIDL GNSS implementation remains. |
| Graphics Allocator 2.0 | Retained HIDL goldfish/BlueStacks stack; board fragment | Keep existing bridge | Already attached by `BoardConfig.mk` and allowed by the custom level-8 matrix. |
| Graphics Composer 2.1 | Retained HIDL goldfish/BlueStacks stack; board fragment | Keep existing bridge | Already attached by `BoardConfig.mk` and allowed by the custom level-8 matrix. |
| Graphics Mapper 2.1 | Retained HIDL passthrough implementation; board fragment | Keep existing | Device fragment exists and frozen FCM 8 accepts HIDL mapper 2.1. |
| Light 2.0 | Retained HIDL wrapper loading `lights.bst`; no fragment | Add x86_64 declaration and FCM bridge | Installed binary/rc and 673 rejected registrations in the old log prove the missing contract. |
| Memtrack 1.0 | `com.android.hardware.memtrack`; APEX-owned AIDL fragment loading the selected legacy module | Replaced by AIDL APEX | `memtrack-default.xml` owns `IMemtrack/default`; HIDL replay would duplicate the public contract. |
| Media OMX 1.0 | Retained HIDL media codec service; no fragment | Add x86_64 declaration | Both IOmx interfaces are in frozen FCM 8, so no compatibility bridge is needed. |
| Power 1.3 | Retained HIDL 1.0 wrapper loading `power.bst`, plus Android-16 AIDL example service | Add exact HIDL 1.0 declaration and FCM bridge | The AIDL service owns only AIDL Power 6. The legacy wrapper/rc remain installed and 671 registrations were rejected. Exact 1.0 describes the wrapper actually built on A16. |
| RenderScript 1.0 | Retained passthrough implementation; no fragment | Add x86_64 declaration | Frozen FCM 8 still accepts this exact HIDL interface; metadata preserves the A13 lookup contract. |
| Sensors 1.0 | No selected `sensors.bst`/default module and no HIDL service | Do not replay | The adapter library alone is not a provider. Declaring it would advertise a service the product cannot supply; current AIDL sensor probes remain a separate product capability gap. |
| SoundTrigger 2.3 | Retained impl loaded by the HIDL audio service; no fragment | Add x86_64 declaration | Frozen FCM 8 accepts 2.3; 34 old-log registration failures independently prove the missing device declaration. |
| DRM default 1.0 | Retained generic HIDL service; no fragment | Add x86_64 declaration and FCM bridge | The service registers both default factories and exits fatally if either registration fails. FCM 8 otherwise allows only AIDL DRM. |
| DRM ClearKey 1.4 | Android-16 AIDL ClearKey service | Replaced by AIDL | Do not recreate the obsolete HIDL 1.4 declaration. |
| DRM Widevine 1.3 | Retained HIDL vendor service; no device fragment | Add x86_64 declaration; keep existing FCM bridge | Android-16 source already documents the HIDL bridge but the generated device manifest did not declare either Widevine factory. |
| Keymaster 4.0/4.1 | Android-16 KeyMint, SecureClock, and SharedSecret AIDL services with module-owned fragments | Replaced by AIDL | Replaying Keymaster would expose retired credential interfaces and conflict with the current security service graph. |

## Patch Review

The prepared patch is
[`device-generic-x86_64-legacy-hal-vintf.patch`](../../../patches/android-16/a13-completion/device-generic-x86_64-legacy-hal-vintf.patch).
It changes only `device/generic/x86_64`:

1. `BoardConfig.mk` attaches one board-specific manifest fragment alongside the
   existing graphics fragments.
2. `manifest_bst_legacy_hal.xml` declares only retained legacy providers that
   have an implementation or service path in the current product.
3. `framework_compatibility_matrix.xml` adds optional level-8 bridges only for
   Camera, ConfigStore, DRM, Light, and Power. FCM-accepted interfaces are not
   duplicated there.

The patch does not alter HAL implementation code, service startup order,
SELinux policy, binder transport, product selection, or common/arm products.
It also does not restore qvirt. Patch application, XML parsing, and whitespace
validation pass against component head `00623898`.

### Performance

VINTF parsing occurs during service discovery and boot. The added static XML
has no frame, audio, camera, or binder hot-path work. Successful registration
removes repeated failed lookups and service exits, so the expected net boot and
steady-state effect is neutral to positive.

### Security

Registration makes already packaged legacy HAL endpoints reachable through
hwservicemanager. This retains the A13 guest contract and does not add a new
process or binary, but it preserves legacy native attack surface as explicit
technical debt. The scope is limited to Windows `android_x86_64`; modern AIDL
security and hardware services remain authoritative where replacements exist.

## Acceptance Gates

- active full build completes or fails without source-tree mutation;
- patch is applied on `aosp16-bst-merge` and committed as `[A16] ...`;
- `check-vintf-all` and the affected image targets pass from `~/android-16`;
- generated vendor manifest contains each retained declaration exactly once;
- clean-Data boot keeps `system_server`, Launcher, and SystemUI stable;
- Light, Power, SoundTrigger, Camera, ConfigStore, OMX, and DRM registrations
  show no undeclared-HAL or fatal registration errors;
- AIDL replacement services remain present and no HIDL replacement entry is
  accidentally reintroduced.
