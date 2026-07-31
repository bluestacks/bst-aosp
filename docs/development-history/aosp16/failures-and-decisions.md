# AOSP16 Failures and Decisions

Failures are retained because they explain why the final design looks the way it
does. The full round-by-round record is indexed in
[`timeline.md`](timeline.md).

## Major Decision Chain

| Area | Failed or superseded approach | Evidence learned | Adopted direction |
|---|---|---|---|
| Source layout | Build from mismatched root Android trees and detached submodule pins | Missing files, duplicate modules, inaccessible non-fork repositories, and branch-tip drift made the baseline invalid | Use the app-player tree layout, initialize required submodules, then checkout declared branches |
| Device model | Treat win and mac as unrelated boards | Both hosts expose the qvirt contract while differing mainly by architecture | Share `device/bst/qvirt`; use x86_64 for win and arm64 for mac |
| Runtime staging | Overlay a generic AOSP image at runtime | R1-R177 exposed linker, APEX, ART, odsign, keystore, zygote, and ABI failures; generic `libandroid_runtime` remained incompatible | Move to a complete source-built BlueStacks guest |
| System packaging | Mount/copy only `system.img` | vendor/system_ext/product folds disappeared and produced incomplete images | Stage the complete product directory and use the buildscripts-compatible single-image layout |
| Boot verification | Trust command success, cached VBox metadata, or stale oracle strings | False positives and false negatives hid bad UUIDs, wrong source trees, and successful boots | Verify by independent log, file footer, artifact hash, and host/guest readback |
| Shell transitions | Carry a broad temporary disable indefinitely | It unblocked G1 but hid a graphics/commit-callback contract issue | Restore the feature after targeted power/HAL work; retain the temporary patch only as history |
| SELinux | Apply broad upstream-style enforcing work during bring-up | The product contract and available policy were not ready; some attempts broke boot | Preserve the explicitly chosen permissive product behavior and treat enforcement as a separate design task |
| Framework import | Apply the 4.8 MiB Batch B old-source overlay | It deleted unrelated Android 16 APIs and caused system_server risk | Port focused CORE-APP, SERVICES, PERIPH, WM, and mechanical patches |
| Device identifiers | Apply unconditional Telephony device-ID override | The first PERIPH-3b variant broke boot | Use caller/UID-gated behavior and verify through a full boot loop |
| Build/make customization | Apply Android 13 make-layer changes directly | Android 16 release-config semantics broke | Prefer device/product-layer removal and Android 16-native build behavior |

## Boot-Debug Milestones

- R1-R5: init and VM heartbeat stabilized.
- R6-R30: linker, SELinux, servicemanager, and `/system` mount path established.
- R31-R76: data, APEX, ART, odsign, and keymint chains became observable.
- R77-R126: logd/logcat evidence isolated keystore permission and boot-level
  failures; R126 crossed `BOOT_LEVEL_EXCEEDED`.
- R127-R164: odrefresh, mainline boot class path, dex2oat, and read-barrier
  behavior were isolated.
- R165-R177: the remaining generic-runtime ABI mismatch proved that source-built
  convergence was necessary.

Detailed evidence:
[`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md).

## Replay Policy

- `failed` and `superseded` records may be inspected but never replayed without
  the replacement decision.
- `temporary` fixes require an explicit debt owner and removal criterion.
- Aggregate patches marked `audit-only` or `rejected` are coverage references,
  not an application sequence.
- The accepted source of replay truth is the combination of focused patch,
  registry entry, checkpoint, source commit where available, and validation
  evidence.
