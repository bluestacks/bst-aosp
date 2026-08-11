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
- pre-regression published root: `cff3fa6662d36951d289bf21d1a69323f9712b1d`
- runtime-validated root: `abf041cae9dfe1c32a150d8d2b97898b8c63529b`
- current published metadata root: `7470f85005bebe91becf3e66c8183107aae4f6f0`
  (same component gitlinks; removes the eight `.gitmodules` branch keys)
- system/core: `95459cc5d51c568baf9c4f816cf247b77f9bacfc`
- kernel-a16: `7df56582487e17e5737d5c3c2f567722335a15bc`
- device/generic/common: `bc5c95abb9d3d35cc131ffdac488593edaf3c981`
- device/generic/x86_64: `efd29005bbfaf29d13d8e8de952cb10faa7e71ff`
- product: `android_x86_64`
- lunch: `android_x86_64-trunk_staging-eng`
- output: `~/android-16/out_nxt_Baklava64`
- allowed root dirty path: pre-existing `.gitignore` only

The reviewed component publications and root metadata, including the current
kernel, product, and kernel-build setup commits, are represented by Draft PR
#4. The runtime gates below still prevent that PR from becoming merge-ready.

## Repository Ownership Readback

Root commit `90f87eed8d0bbd1bed49f077f775309bd9f2d843`,
`[A16] Point all submodules to BlueStacks`, changed every `.gitmodules` URL to
the formal BlueStacks repository. A readback at root
`cff3fa6662d36951d289bf21d1a69323f9712b1d` confirmed:

- `.gitmodules` declarations: 1025
- declarations owned by `bluestacks`: 1025
- declarations owned by `mark-bst`: 0
- declarations outside `bluestacks`: 0
- root fetch/push owner: `bluestacks/android-16`
- root local and remote `aosp16-bst-merge` tip: identical

The full promotion audit also requires each initialized component's actual
publication remote to belong to `bluestacks`. Personal-fork remotes are a gate
failure even when the corresponding `.gitmodules` declaration is correct. The
three regression component tips were published and read back from BlueStacks:

- `kernel-common-a16`: `7df56582487e17e5737d5c3c2f567722335a15bc`
- `device-generic-x86_64-a16`: `efd29005bbfaf29d13d8e8de952cb10faa7e71ff`
- `device-generic-common-a16`: `bc5c95abb9d3d35cc131ffdac488593edaf3c981`

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

## Kernel 6.12 Investigation And Resolution

The temporary 6.12 AHCI diagnostics and force-32-bit DMA experiments were
removed before the formal build. The remaining patch is the direct A13
`ROB-9272` register adaptation in `Kconfig`, `ahci.h`, `libahci.c`, and the BST
defconfig. `drivers/ata/ahci.c` has no diagnostic or device-specific DMA delta.

Kernel commit:

- `b56e2f13df6e8a9df2b0b86bd1193b52290be728`
  `[A16] Restore BlueStacks AHCI registers`

The first full new Root plus full new 6.12 fastboot failed boot:

- `ata1` and `ata2` reached SATA link-up;
- ATA IDENTIFY command `0xec` timed out at 5, 10, and 30 seconds;
- both ports reported `failed to IDENTIFY (I/O error, err_mask=0x4)`;
- no Android boot oracle was reached;
- init exited and the kernel panicked at about 96 seconds.

The exact A13 register port was necessary but not sufficient for the 6.12/host
storage contract. The previously tested high-DMA, force-32-bit DMA,
standard-AHCI, and BST-register combinations all failed at the same command
consumption boundary. No speculative DMA workaround is retained.

The remaining cause was interrupt destination mode, not DMA. Linux commit
`838ba7733e4e` removed logical flat APIC mode and made x86_64 use physical
destination delivery. The legacy BlueStacks/VirtualBox host did not deliver
the AHCI MSI correctly in that mode. Restoring the prior upstream logical flat
implementation for systems with at most eight CPUs, while retaining physical
flat selection for larger or explicitly physical systems, restored command
completion. The ICH8M device also keeps the A13 no-debounce behavior.

Final kernel component commit:

- `7df56582487e17e5737d5c3c2f567722335a15bc`
  `[A16] Restore logical flat APIC routing`

Static and build evidence:

- four-file final diff only: `apic.h`, `apic_flat_64.c`, `ahci.c`, and
  `libata-sata.c`;
- strict checkpatch: zero errors, warnings, or checks;
- incremental kernel build: success;
- bzImage SHA256:
  `0cf4c3b44c1edd098892dc7240de1c2392e7135302fedb54e4253ea9b60c2291`;
- fastboot VDI SHA256:
  `4b7c6a31d8c6996dbf65c4d722d508bebecc16a416463f27f99bbeedb24e7086`;
- fastboot UUID: `91b80c95-aa7d-459d-93e4-c479f5babbb7`;
- runtime readback reached Android with the guest disk mounted and showed no
  AHCI timeout or missing IRQ-handler error.

## SurfaceFlinger Ashmem Regression

Once the 6.12 storage path entered Android, SurfaceFlinger restarted in a loop
and the Player remained black. The terminal fatal check in RenderEngine was
`output buffer not gpu writeable`, but the earlier allocation error was the
causal event:

- `gralloc_bst: gralloc_alloc failed to create ashmem region: No such file or directory`
- `GraphicBufferAllocator: Failed to allocate (384 x 384) ... usage 300: 5`

The BlueStacks gralloc source still calls `ashmem_create_region()`. Android 13
provided `/dev/ashmem` and explicitly kept `sys.use_memfd=false`. Linux 6.12 no
longer exposes that device. The BST defconfig requested `CONFIG_RUST=y` and
`CONFIG_ASHMEM=y`, but the Android kernel task did not provide Rust, bindgen,
the matching `libclang`, or the Rust library source. Kconfig therefore silently
removed both options from the actual generated `.config`; the source-level
defconfig check had produced a false positive.

`device/generic/common` now passes the AOSP Rust 1.88.0 and bindgen tools,
clang `r563880c` library path, and Rust source path to both kernel build entry
points. The regenerated `.config` contains both options, and `vmlinux` exports
`ashmem_memfd_ioctl`. This activates the existing kernel compatibility ioctls;
no new kernel shim or graphics-library change is required.

The minimal target-only fix sets `sys.use_memfd=true` in the Windows
`android_x86_64` product. libcutils then creates a memfd and uses the existing
kernel ashmem compatibility path for the legacy gralloc caller.

Component and root commits:

- `efd29005bbfaf29d13d8e8de952cb10faa7e71ff`
  `[A16] Enable memfd-backed legacy gralloc`
- `bc5c95abb9d3d35cc131ffdac488593edaf3c981`
  `[A16] Configure the kernel Rust toolchain`
- `abf041cae9dfe1c32a150d8d2b97898b8c63529b`
  `[A16] Record the kernel Rust build setup`

The narrow incremental generation used `system-build.prop` followed by
`systemimage-nodeps`, both at `-j8`. The generated and installed build.prop
contain `sys.use_memfd=true`. The target sparse system image was regenerated as
SHA256 `e849ae108ec752c9efa36b74a33f4df935e08520a50333157c1fad5eadda3455`.
The first direct Ninja attempt lacked the AOSP JDK environment and failed in
host metalava; rerunning the same bounded target after `envsetup` and lunch
succeeded. No clean or full Android build was run.

The first package attempt exposed a separate build-flow omission. The
app-player Root recipe copies the Android staging tree, then replaces
`/system/build.prop` with the release template and restores only selected SDK
identity properties. The resulting raw system image therefore omitted
`sys.use_memfd` even though Android OUT contained it. The existing Baklava
property restore loop was minimally extended to preserve `sys.use_memfd` from
the target build.prop. This is a local app-player build-flow adaptation only;
it is recorded by the package-input diff hash and is not part of the tracked
Android-16 component submission. `g1_build_app_player.sh` now also fails the
package if this early-boot property differs between Android OUT and the raw
packaged image.

The corrected kernel was rebuilt incrementally at `-j8`. Its bzImage SHA256 is
`166d74107143cd6d31d2dcd650a2fc27b46caf11822a17eb3f40b187246e50b9`.
For rapid causal validation, only `fastboot.vdi` was regenerated and deployed;
its SHA256 is
`f7152a98e7c81b719aadc0ddf68294d67c26273aac23b94c65bb28cb6574d445`.
The Root remained the formally packaged artifact with SHA256
`93d88dc3cbce1aa09ef714d1476f53d3c5c982f30a2000b87d60989c415b289b`.
This combination is a fastboot-only diagnostic identity, not the final
publishable package.

The diagnostic combination passed all seven boot oracles in 97 seconds and a
95-second stabilization window. The current `Player.log` contains zero matches
for the four prior causal signatures: `no ashmem-memfd compat support`,
`Unable to stat ashmem`, `gralloc_alloc failed`, and
`output buffer not gpu writeable`.

## Historical Mixed-Kernel Regression

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
entries below. Launcher HOME resolution and resume, Houdini presence, guest
IPv4, Wi-Fi MAC readback, telephony identity, retained HIDL registration,
Bluetooth, system_server PID, boot ID, and process stability did not fail.

| Area | Result | Evidence |
| --- | --- | --- |
| Explicit BST properties | pass | FPS, shared-folder list, Wi-Fi MAC exact reads valid |
| Bulk property hiding | pass | zero BST entries with debug switch off |
| Launcher | pass | HOME resolves to `com.uncube.launcher3` |
| Stability | pass | boot ID and system_server stable for 95 seconds |
| Dynamic FPS | pass | Scheduler period changed `16666666 -> 33333334 -> 16666666` ns; renderer processes remained stable |
| Renderer CPU | pass | 15-second jiffies: SF/composer `3/4` at 30 FPS and `6/9` at 60 FPS; limit 6000 |
| ADB policy | pass | deny/restore oracle; policy SHA256 `afaa1ab10855378ffbeaa544f8d3c0de705bee4ebc271d0974ac19a5a2f8be92` |
| Shared-folder mount | fail | `shared_folder`, `shared_folder_adb_push` |
| IME bridge | fail | `imeservice_state:stopped` |
| GMS/Play Store compatibility | fail | startup crashes in old GMS biometrics and Play Store foreground-service paths |

### FPS Oracle And Board Path

The first FPS run incorrectly used the first line of
`dumpsys SurfaceFlinger --latency`. On the Windows `android_x86_64` board this
is the native goldfish HWC2 display's fixed 60 Hz nominal period, not the
Scheduler override controlled by `bst.max_fps`. The test therefore reported a
false failure at 30 FPS even though the Scheduler changed its work duration.

The Android 13/A16 `HWC2OnFbAdapter` polling code in `hardware/interfaces` is
present in target commit `bf800caa090008c2fbbc1723c6fe814ece6f7eb9`, but it is
a framebuffer fallback. The active board loads
`hwcomposer.android_x86_64.so` as a native HWC2 device, so that adapter is not
the runtime authority. The active A16 implementation is the existing
SurfaceFlinger Scheduler override in `frameworks/native`.

`g1_fps_regression.ps1` now reads the Scheduler `app duration` from the normal
SurfaceFlinger dump. It still verifies property readback, restores the original
value in `finally`, checks boot/process identity, and measures bounded CPU. The
corrected oracle passed 60 -> 30 -> 60 FPS without restarting SurfaceFlinger,
composer, or system_server.

### Shared-Folder Contract Gap

The current 6.12 run cannot treat the failure as a source regression or a pass.
The unprivileged shell cannot stat the mountpoint parent and cannot create the
probe file; ADB push is rejected with `Permission denied`. A host-visible
round-trip has therefore not been demonstrated.

Earlier mixed-kernel diagnostics found that the active host config and guest
property both report
`bst.status.hypervisor=hyperv`. In that mode `mountsf` selects filesystem type
`bstfolder`, but the tested 5.15 kernel had no such filesystem and reported
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
  config, product package, and mount orchestration change plus a host-visible
  transfer oracle.

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

Keep PR #4 in Draft. Required remaining gates are:

1. run the canonical incremental package-resume flow once more so Root and the
   Rust/ASHMEM-enabled 6.12 fastboot share one formal identity;
2. deploy that non-diagnostic pair and repeat boot, property, FPS, Launcher,
   Houdini, HAL, ADB-policy, and stability gates;
3. establish and validate the intended Hyper-V or VBox shared-folder contract;
4. start the host IME listener or formally change its lifecycle contract;
5. resolve or explicitly accept the old GMS biometric and Play Store
   foreground-service crashes on Android 16;
6. run the packaged ARM64 native-bridge application oracle, not only Houdini
   payload and binfmt presence checks;

Component publication is complete: all three tips above exist on BlueStacks
`bst-v5.22.210-A16`, and root `aosp16-bst-merge` was published and read back at
`abf041cae9dfe1c32a150d8d2b97898b8c63529b` before this record was finalized.
Metadata successor `7470f85005bebe91becf3e66c8183107aae4f6f0`
removes only the eight `.gitmodules` branch keys and does not change a component
gitlink or claim a new runtime validation.
