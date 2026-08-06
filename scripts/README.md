# Script Stage Index

The script tree is intentionally path-stable. AOSP16 development scripts remain
first-class evidence, including failed and superseded attempts; they are not
bulk-renamed or rewritten because progress logs and checkpoints refer to these
names directly.

The authoritative per-file classification is generated in
[`../docs/project-review/inventory.md`](../docs/project-review/inventory.md).
Static parser results and the historical exception are in
[`../docs/project-review/validation.md`](../docs/project-review/validation.md).

## Android-16 Active Pipeline

These are the maintained promotion/mainline entry points. They require the
active tree to resolve exactly to `~/android-16`, reject unresolved component
indexes, and print the resolved tree, branch, HEAD, product, and `OUT_DIR`
before work starts.

| Entry | Role | Side effects |
|---|---|---|
| `g1_build_app_player.sh` | Canonical full Android-16 build and app-player package | Builds only the linked target tree; records app-player, HD, VBox, graphics and payload identity; stages the validated uncube APK outside the generated APK folder; requires newly generated Root/system/fastboot artifacts and rejects an image missing uncube, `libflutter.so`, `mountsf`, or the BlueStacks build identity |
| `g1_build_android16.sh` | Target-only Layer 1 Android-16 build and graphics stage | Builds under the validated Android-16 root; does not create a release-complete Root |
| `g1_build_libs.sh` | Builds and hashes required HD guest native libraries | Builds under the validated Android-16 root |
| `g1_build_pack.sh` | Orchestrates build, Root packaging, deploy, and complete Layer 2 verification | Builds hash-bound test APKs, then runs boot, property, Launcher/HAL, FPS, app-visible media, ARM64 translation, and fail-closed ADB oracles |
| `g1_pack_root.sh` | Guarded target-only Root repack | Refuses release packaging when app-player system payloads or build identity are absent |
| `g1_stage_system.sh` | Folds target `OUT_DIR` into the release staging tree | Replaces staged system content |
| `g1_apply_boot_overlays.sh` | Applies source-built overlays before packaging | Copies framework, HAL, and graphics files |
| `g1_rebuild_graphics.sh` | Builds `goldfish-opengl-pie` from the target tree | Cleans selected intermediates and rebuilds graphics |
| `g1_copy_bst_apks.sh` | Injects required BlueStacks APK payloads | Copies three required APKs |
| `g8_disable_vendor_hal_rc.sh` | Applies the recorded vendor HAL startup policy | Moves selected RC files to a backup directory |
| `g1_win_deploy.ps1` | Deploys Root with SHA-256 readback | Replaces the Windows engine Root |
| `g1_reset_data_wipe.ps1` | Restores the verified clean Data snapshot with SHA-256 readback | Stops the local instance and replaces `Data.vhdx` |
| `g1_boot_verify.ps1` | Evaluates the Layer 2 boot oracle | Starts/stops the local instance and reads logs |
| `g1_property_verify.ps1` | Compares property payloads with guest runtime values | Temporarily enables the BlueStacks getprop diagnostic switch |
| `g1_runtime_regression.ps1` | Checks Launcher/Settings stability, shared-folder I/O, Houdini, network identity, and HAL registration | Starts activities, writes two fixed temporary probe files, removes them, and reads bounded ADB diagnostics |
| `g1_fps_regression.ps1` | Verifies dynamic `bst.max_fps` frame pacing and bounded renderer CPU | Temporarily changes FPS, measures SurfaceFlinger/composer, and restores the original value |
| `g1_app_runtime_oracle.ps1` | Runs the temporary app-UID property, Wi-Fi, graphics, audio, camera, and DownloadProvider oracle | Installs a hash-bound test APK, grants declared runtime permissions, reads logs, and uninstalls it |
| `g1_nativebridge_runtime_oracle.ps1` | Proves standalone AArch64 binfmt and ARM64 APK execution through Houdini | Pushes a hash-bound temporary ELF, installs a hash-bound test APK, then removes both |
| `g1_adb_policy_regression.ps1` | Proves the guest ADB command policy fails closed | Temporarily installs a restrictive policy, tests denial, and restores the original file by SHA-256 |
| `prepare_android16_package_inputs.sh` | Assembles or verifies the fixed Baklava APK input bundle | Reads immutable Git/LFS inputs and a hash-pinned external Root; optionally installs ignored app-player staging links |
| `lib/android16_env.sh` | Shared tree and artifact identity gate | None when sourced; writes identity only on request |

Run `--check` on the supported pipeline entry before target-tree work. Static
review in this repository does not invoke those checks because this review must
not read either Android source tree.

The app-player and HD checkouts are external packaging inputs on
`bst-v5.22.210`, not Android promotion submissions. The active full-package
entry rejects unresolved indexes, records their content identity, and pins the
A13-compatible VBox 7.0.8 guest-additions revision without committing those
repositories.

## Promotion Audit

| Entry | Role | Default behavior |
|---|---|---|
| `audit_android16_promotion.py freeze` | Captures the AOSP16 project branch, SHA, dirty state, and patch identity | Read-only |
| `audit_android16_promotion.py audit` | Audits Android-16 submodule initialization, branch distribution, gitlinks, remotes, and optional remote SHA presence | Read-only |
| `audit_a16_merge.sh` | Compatibility wrapper for the Python audit | Read-only |
| `generate_android16_patch_inventory.py` | Rebuilds patch and payload review documents | Repository-only |
| `validate_a13_target_commits.py` | Verifies every mapped A13 target SHA exists, is reachable, and has an `[A16]` subject | Read-only Android-16 target inspection |
| `validate_a13_target_states.py` | Verifies commit-free target equivalence, including file layout, regex ordering, LFS and pinned binary SHA-256 state | Read-only Android-16 target inspection |
| `validate_a13_target_states.py` | Executes the structured checks for commit-free Android-16 equivalent states | Read-only Android-16 target inspection |
| `generate_project_review.py` | Rebuilds inventory and history indexes | Repository-only |
| `validate_project_files.py` | Runs Python, JSON, Bash, and PowerShell static parsers | Repository-only |
| `merge_aosp16_to_android16.sh` | Preserved cont.103 merge executor | Refuses to run unless `--apply-historical` is explicit |

The promotion process and branch contract are documented in
[`../docs/development-workflow/promotion.md`](../docs/development-workflow/promotion.md).

## AOSP16 Development Workflows

All other top-level `g1_*`, `p2_*`, `r###-*`, triage, capture, restore, and
diagnostic scripts belong to the AOSP16 development and validation stage unless
their inventory record says otherwise. Their `~/aosp16` paths are historical
facts and must not be mass-replaced.

The main families are:

| Family | Purpose | Evidence |
|---|---|---|
| `g1_*` legacy entries | Early build, staging, packaging, and equivalence loops | G1 checkpoints and cont.1-22 |
| `p2_*` | Framework, native, registry, and mechanical port batches | P2 registries and cont.23-101 |
| `r245` through `r262` | Final boot and functional corrections | Boot guide, porting log, patch registry |
| `remote-capture-a16-*` | Captures the validated source diffs and payloads | `patches/android-16/` |
| `check_*`, `triage_*`, `parse-*` | Windows and guest diagnostic oracles | Boot-debug and checkpoint records |

`p2_mech2_apply.py` is intentionally preserved with its historical truncation.
The successful result is
[`P2-MECH-2-launcher3-manifest.diff`](../patches/android-16/patches/p2-framework-rest/P2-MECH-2-launcher3-manifest.diff)
and cont.65. It is the only expected Python parse failure.

## Historical Archive

[`archive/`](archive/README.md) contains earlier round scripts, staging
experiments, reverted work, and superseded pack chains. Archive means
"historical first-class", not disposable. Exact duplicates are retained until
layout, payload, and checkpoint semantics have been reviewed; the inventory
records hashes and duplicate groups without deleting them.
