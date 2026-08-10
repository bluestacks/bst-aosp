# Android-16 Runtime Regression - 2026-08-11

## Scope And Discipline

This regression used only the promoted target tree at
`markxu@172.16.6.191:~/android-16` and its
`out_nxt_Baklava64` output. The `~/aosp16` tree and its products were not read,
built, copied, or modified. Android work was incremental, capped at `-j8`, and
did not clean the existing output. App-player, HD, VirtualBox additions, and
`scratch-gaurav` remain outside the tracked Android-16 submission boundary.

The tested Android identity was:

- root branch: `aosp16-bst-merge`
- pre-validation root: `79c454e9f5acde60ecb1055e56228df33001f0cc`
- post-validation root: `725e4bf76345b3634050a66213a51d9d97e476e6`
- system/core: `95459cc5d51c568baf9c4f816cf247b77f9bacfc`
- kernel-a16: `b56e2f13df6e8a9df2b0b86bd1193b52290be728`
- product: `android_x86_64`
- lunch: `android_x86_64-trunk_staging-eng`
- output: `~/android-16/out_nxt_Baklava64`
- allowed root dirty path: pre-existing `.gitignore` only

No component or root commit from this regression has been pushed. Draft PR #3
therefore still represents the previously published root, not the local SHAs
above.

## Initial Runtime Baseline

The first runtime used the then-current Android-16 Root with the known-green
historical 5.15 fastboot. It reached all seven boot oracles and completed the
stability window. The first full runtime regression failed only these checks:

- `bst_max_fps`
- `bst_shared_folders`
- `shared_folder`
- `shared_folder_adb_push`
- `wifi_mac_property`

`/data/.bstconf.prop` existed and contained valid values, including
`bst.max_fps=60`, all four shared-folder names, and a valid Wi-Fi MAC. Bulk
`getprop` enumeration showed those properties, but exact named reads returned
empty values while `bst.debug.show_prop=0`.

## Explicit Getprop Root Cause And Fix

Android-16 had moved the BlueStacks property filter into the common
`PrintProperty()` path in `system/core/toolbox/getprop.cpp`. This unintentionally
filtered both bulk enumeration and explicit `getprop NAME` calls. Android 13
authority commit `f76bac392` filters only the bulk enumeration loop; named
queries remain available regardless of the debug enumeration switch.

The minimal correction restores that placement:

- bulk `getprop` hides the bounded BlueStacks name list when
  `bst.debug.show_prop=0`;
- exact `getprop bst.max_fps`, `getprop bst.shared_folders`, and
  `getprop bst.wifi_mac_addr` return their values;
- `bst.debug.show_prop=1` still exposes the properties in bulk enumeration;
- no property-service access control or source-file loading behavior changed.

Component commit:

- `95459cc5d51c568baf9c4f816cf247b77f9bacfc`
  `[A16] Preserve explicit BlueStacks property reads`

Root gitlink commit:

- `725e4bf76345b3634050a66213a51d9d97e476e6`
  `[A16] Record BlueStacks property validation`

The earlier component SHA `0c3d1a8150e6f08513b2c08b28f67e30bebd84f7`
was amended only to replace pending validation text with the evidence below.

## Incremental Build And Package Evidence

An attempted canonical `m init systemimage kernel` entry expanded to about
44,207 Ninja actions after an environment transition. It was stopped by exact
process group before producing a package because it no longer met the
incremental-only requirement. No clean was run and the output was preserved.

The replacement flow used narrow targets:

1. `toolbox toolbox_vendor toolbox.recovery toolbox_ramdisk -j8`
2. `m kernel -j8`, seven Ninja actions
3. `mmm ../ggl/goldfish-opengl-pie -j8`
4. `mmm ../ggl/goldfish-opengl-pie/system/hwc2 -j8`
5. `g1_build_app_player.sh --package-resume --jobs 8`

Build logs:

- `~/a16-toolbox-explicit-prop-20260811-r2.log`
- `~/a16-kernel-only-20260811-r2.log`
- `~/a16-graphics-targeted-20260811.log`
- `~/a16-package-resume-20260811.log`

All 18 representative 32/64-bit goldfish install files were restored in OUT
before packaging, including gralloc, GLES encoders, OpenglSystemCommon,
PgaLogger, renderControl, libdrm, and Vulkan encoders.

Artifact identity:

- packaged `/bin/toolbox`:
  `b262d80d9ebe7eac39e2fdfa91d1502318ef435590df797245894b51645fee3e`
- `Root.vhd`:
  `6ab600a5f2f39f64a3d6c485224ca47907651f7371248b4907d4855033094354`
- `system.img`:
  `85e44cd1d8a17ba82d78d439859b79d9cdacfadf83a871e6d2c4809c3016c5df`
- `system.sfs`:
  `261f910af909896931d2183d8d93ba6c320a9490db3c0d52985827bb5e83bca2`
- 6.12 `fastboot.vdi`:
  `514bf66dced6cab477f19e0d2be959533c553ea82135f0108e07f10ed1519abc`

`debugfs` extraction proved that the packaged toolbox matched Android OUT and
that the packaged image contained the expected gralloc/GLES/renderControl and
`mountsf` payloads.

## Kernel 6.12 Result

The temporary 6.12 AHCI diagnostics and force-32-bit DMA experiments were
removed before the formal build. The remaining patch is the direct A13
`ROB-9272` register adaptation in `Kconfig`, `ahci.h`, `libahci.c`, and the BST
defconfig. `drivers/ata/ahci.c` has no diagnostic or device-specific DMA delta.

Kernel commit:

- `b56e2f13df6e8a9df2b0b86bd1193b52290be728`
  `[A16] Restore BlueStacks AHCI registers`

The full new Root plus full new 6.12 fastboot failed boot:

- `ata1` and `ata2` reached SATA link-up;
- ATA IDENTIFY command `0xec` timed out at 5, 10, and 30 seconds;
- both ports reported `failed to IDENTIFY (I/O error, err_mask=0x4)`;
- no Android boot oracle was reached;
- init exited and the kernel panicked at about 96 seconds.

The exact A13 register port is therefore necessary but not sufficient for the
6.12/host storage contract. The previously tested high-DMA, force-32-bit DMA,
standard-AHCI, and BST-register combinations all failed at the same command
consumption boundary. No further speculative DMA quirk is retained.

## Known-Green Kernel Regression

For Android userspace validation only, the new Root was combined with the
known-green 5.15 fastboot:

- runtime fastboot SHA256:
  `3d80f8748019808d076d6f1a49c9e8491e26e544c138df740b04450ad86463c8`
- deployment identity: `mixed-diagnostic`
- 6.12 candidate hash remains recorded separately in the local identity file

This mixed baseline reached all seven boot oracles in 104 seconds and completed
an additional 95-second fatal-pattern stability window:

- system mounted: pass
- second-stage init: pass
- on-device signing: pass
- `sys.boot_completed`: pass
- activity displayed: pass
- player ready: pass
- boot progress hidden: pass

This is valid userspace regression evidence but is not a publishable final
artifact because the target 6.12 kernel did not boot.

## Property Verification Result

The updated verifier reads the running instance through the configured
`status.adb_port`, so an unrelated stale `emulator-5554 offline` entry no longer
causes a false no-device result.

Default verification result:

- required files missing: 0
- exact properties compared: 377
- exact named lookup mismatches: 0
- hidden bulk-enumeration leaks: 0
- critical runtime mismatches: 0
- duplicate source entries: 15 warnings
- immutable `ro.*` template differences: 84 warnings
- mutable media plugin differences: 2 warnings

The 84 read-only differences are mostly A13/release-template values compared
with the active Baklava eng identity. They must not be force-applied after
property initialization. The two mutable warnings are the empty runtime values
for `media.sf.omx-plugin` and `media.sf.extractor-plugin`; they remain a
separate media integration review item.

## Runtime Regression Matrix

The 95-second runtime regression passed all tested areas except the three
entries below. Launcher HOME resolution, Houdini/native bridge, guest IPv4,
Wi-Fi MAC readback, telephony identity, retained HIDL registration, Bluetooth,
system_server PID, boot ID, fatal logs, and process stability did not fail.

| Area | Result | Evidence |
| --- | --- | --- |
| Explicit BST properties | pass | FPS, shared-folder list, Wi-Fi MAC exact reads valid |
| Bulk property hiding | pass | zero BST entries with debug switch off |
| Launcher | pass | HOME resolves to `com.uncube.launcher3` |
| Stability | pass | boot ID and system_server stable for 95 seconds |
| Shared-folder mount | fail | `shared_folder`, `shared_folder_adb_push` |
| IME bridge | fail | `imeservice_state:stopped` |

### Shared-Folder Contract Gap

The failure is not a shell permission regression. The directories are only
unmounted placeholders (`root:root`, mode `0770`), so shell access is expected
to fail.

The active host config and guest property both report
`bst.status.hypervisor=hyperv`. In that mode `mountsf` selects filesystem type
`bstfolder`, but the running 5.15 kernel has no such filesystem and reports
`No such device` for all four exports. A diagnostic guest-only switch to
`vbox` selected the installed `vboxsf` module, but the Hyper-V host had not
registered VirtualBox shared-folder names, producing `No shared folder
specified`.

A13 code review does not provide a safe missing patch to copy:

- A13 `bst-x86_64_defconfig` disables Hyper-V, VSOCK, and 9P;
- A16 kernel-a16 currently does the same;
- A13 and A16 contain the same dormant
  `external/bluestacks/bstfolder` 9P/VSOCK helper, but neither product package
  installs it;
- enabling that helper would require a coordinated host protocol, kernel
  config, product package, and mount orchestration change that cannot be
  runtime-tested while 6.12 cannot boot.

The next decision must come from the current app-player Hyper-V shared-folder
contract: either provide the intended `bstfolder` kernel/protocol source, or
run this image under the supported VBox contract with host exports registered.
No speculative Android-only replacement was added.

### IME Listener Contract Gap

`bst.config.ime_listenerport=40457` is nonzero, but Windows has no listener on
that port. `bstime` therefore exits after `connect()` returns `ECONNREFUSED`,
leaving `init.svc.imeservice=stopped`. A13 and A16 `system/bstime/Main.cpp` have
the same connection behavior. This is a host listener lifecycle gap, not an
A13-to-A16 source omission. App-player/HD changes remain outside this
submission and were not modified.

## Publication Gate

Do not publish or update PR #3 yet. Required remaining gates are:

1. resolve the 6.12 ATA command-consumption failure and boot the complete
   target artifact;
2. establish and validate the intended Hyper-V or VBox shared-folder contract;
3. start the host IME listener or formally change its lifecycle contract;
4. rerun boot, property, shared-folder, Launcher, Houdini, HAL, and stability
   regression on one non-mixed artifact;
5. publish component SHAs to BlueStacks `bst-v5.22.210-A16` branches before
   updating the root PR gitlinks.
