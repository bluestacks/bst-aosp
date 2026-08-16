# A13 runtime gaps and final promotion disposition

> **Historical candidate:** the property and feature blockers described below
> were subsequently fixed and validated. The final A13 behavior disposition is
> in [`a13-runtime-oracle-matrix.md`](a13-runtime-oracle-matrix.md) and
> [`runtime-oracle-closure-2026-08-16.md`](runtime-oracle-closure-2026-08-16.md).

## Identity

- Stage: `android16-promotion`
- Source authority: final `~/app-player/android-13` code, reviewed read-only
- Development authority: validated AOSP16 behavior, reviewed read-only
- Target tree: `~/android-16`
- Target branch: `aosp16-bst-merge`
- Target product: `android_x86_64-trunk_staging-eng`
- Target output: `~/android-16/out_nxt_Baklava64`
- Current root candidate: `2be2bd594015046288f67420c72ac3d964595d14`
- Result: boot qualified; extended runtime regression has an open property lookup blocker

## Current Candidate

The final candidate contains these focused corrections:

| Project | Commit | Purpose |
| --- | --- | --- |
| `bionic` | `e1a8019c761dfe82c9d4f352d0836f76eddcc733` | Preserve A13 protected-property callback semantics for all nonzero callback results |
| `device/generic/common` | `03f76fc1492ab6044762649137a478bb09fb0631` | Keep one post-data guest-property load path |
| `frameworks/base` | `172d2f4cbce76a7018dda6bbe3171c400c19317b` | Restore trusted package visibility for non-application callers |
| `system/core` | `fa631e4f7ffa131b9fca4b6ef4fef4487ff0d9e0` | Load generated BlueStacks properties only after `/data` is mounted |
| `system/sepolicy` | `acff98d684732d0ca05aff5f2799dfd3b32ed921` | Declare the complete `bst.` prefix as string-valued exported system properties |

The root pointer commit is `[A16] Use post-data BlueStacks property namespace`
at `2be2bd594015046288f67420c72ac3d964595d14`.

## Build And Package Evidence

The canonical incremental command completed successfully with at most eight
jobs and without cleaning or replacing `out_nxt_Baklava64`:

```bash
bash scripts/g1_build_app_player.sh --incremental --jobs 8
```

Evidence bound to root `2be2bd594015046288f67420c72ac3d964595d14`:

| Artifact | SHA-256 |
| --- | --- |
| `Root.vhd` | `c13024b449ed2bf6cce7ac4e7e7dae0289b116f5c57ff858416074ebf2063976` |
| `system.img` | `e8a4866d9652f3ed6a6a257e6aa0b661de414c67d60b2a3449eee7c45cb4ce16` |
| `system.sfs` | `73e2d5a535b19b346645f3c70e3f419963d5d69914e35809ce974e32183279c3` |
| `fastboot.vdi` | `3d80f8748019808d076d6f1a49c9e8491e26e544c138df740b04450ad86463c8` |

The installed property context contains exactly:

```text
bst. u:object_r:exported_system_prop:s0 prefix string
```

The promotion-only early `/data` reads are absent. Guest properties are loaded
through the AOSP16-matching post-data path.

## Runtime Evidence

The candidate was deployed to the local `Tiramisu64` instance. A clean-Data
boot reached all seven host/guest boot oracles in 170 seconds and remained
stable for the following 95-second observation window. Total verifier time was
267 seconds. Launcher produced a visible frame and no SystemUI crash loop,
system-server watchdog, zygote termination, or RescueParty reboot was observed.

This is valid minimum Layer 2 boot evidence. It is not a full feature pass.

## Open Property Lookup Blocker

`/data/.bstconf.prop` exists and contains the expected generated values,
including:

- `bst.max_fps=60`
- `bst.shared_folders=Documents,Pictures,InputMapper,BstSharedFolder`
- `bst.wifi_mac_addr=25:75:61:72:63:36`
- `bst.config.mountsf=1`

A no-argument `getprop` enumeration also prints all four values. Exact lookup,
however, still returns an empty string for `bst.max_fps`,
`bst.shared_folders`, and `bst.wifi_mac_addr`. `getprop -T` reports the values
as strings but does not make exact lookup succeed.

This breaks a real consumer. The packaged `mountsf` script reads
`getprop bst.shared_folders`; it therefore receives an empty list, exits, and
leaves `init.svc.mountsf=stopped`. `/mnt/windows/BstSharedFolder` is absent and
the read/write shared-folder oracle fails. Host placeholder replacement,
`vboxguest`, `vboxsf`, and the `/system/bin/mountsf` payload have been checked,
so they are not the current cause.

The source-side timing and namespace omissions are fixed, but runtime evidence
shows that the exact property-area/trie lookup problem is not closed. It must
remain a publication-visible blocker until exact lookup and a real shared-file
write/read pass on the same artifact identity.

## Feature Declaration Disposition

The earlier candidate restored 33 A13 feature XML declarations literally.
That candidate was rejected. The packaging staging directory retained stale
XML outputs across incremental builds, which changed the advertised feature
set, caused framework instability, and led to RescueParty/black-screen boots.

The active package flow now resets only the generated release `system` staging
directory before restaging the current Android output. The target device
declarations remain aligned with the validated AOSP16 `android_x86_64`
baseline: Ethernet, USB host, and Wi-Fi declarations are retained; the broad
A13 tablet/Bluetooth declaration set is not introduced without matching
runtime providers. Bluetooth process validation is conditional on the package
manager advertising a Bluetooth feature, while the selected AIDL HAL remains
independently required.

This is not a unified-board change. Windows continues to use
`android_x86_64`, and common/remote board settings are not reintroduced.

## Package Visibility

`frameworks/base` commit `172d2f4cbce76a7018dda6bbe3171c400c19317b`
restores the A13 `null` sentinel for trusted non-application callers. The clean
boot confirms that `com.bluestacks.settings` is published, the uncube HOME
resolver works, BlueStacks Settings can cold-start and return to Launcher, and
the earlier stale resolver/package-state crash no longer reproduces.

The scan-order change remains documented as a tested but disproven root-cause
hypothesis in `package-scan-order-2026-08-07.md`; it must not be cited as the
package-visibility fix.

## Performance, Security, And Necessity

- Post-data loading is necessary because `/data` is unavailable during the
  second-stage early property load. It adds no polling and runs once per boot.
- Prefix property typing removes per-property declarations and matches the
  intended BlueStacks namespace. It does not itself grant a service permission.
- The bionic callback correction is a one-branch security-semantic restoration
  and has no measurable common-path cost.
- Deterministic package staging performs bounded file deletion only under the
  generated release staging directory. This costs packaging time, not guest
  runtime performance, and prevents stale files from receiving false credit.
- The unresolved exact property lookup affects FPS configuration, shared
  folders, Wi-Fi identity, and any other exact `bst.*` consumer. It is a
  functional correctness issue, not documentation-only debt.

## Required Follow-up

1. Reproduce exact lookup with the published candidate and capture property
   area/trie diagnostics without changing the AOSP16 source or using its output.
2. Prove exact reads for `bst.max_fps`, `bst.shared_folders`, and
   `bst.wifi_mac_addr`.
3. Prove `mountsf` remains running and a host/guest shared-folder write/read
   succeeds.
4. Repeat the bounded Launcher, Settings, SystemUI, HAL, network, Houdini,
   audio, camera, and Widevine regressions on the corrected identity.
5. Keep interactive host navigation, real media playback/capture, translated
   ARM64 app execution, and protected Widevine playback as explicit manual
   acceptance gates.
