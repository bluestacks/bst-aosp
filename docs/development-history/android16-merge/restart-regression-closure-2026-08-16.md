# Android 16 Restart Regression Closure, 2026-08-16

## Scope and constraints

This record follows the restart black-screen report after the Android 16
promotion. All source, build, package, and guest evidence in this cycle is
bound to the `markxu` Android 16 and app-player workspaces. No AOSP16 tree or
output was read or reused, no A13 build/runtime validation was run, and no
Henry process or workspace was inspected or changed.

The Windows host was locked throughout the checks. Graphics validation uses
guest ADB framebuffer readback, SurfaceFlinger state, service logs, and cold
boot state only; Windows screenshots are not evidence.

## Source identity at investigation start

| Item | Identity |
| --- | --- |
| Android root | `/home/clouddev/bst/workspace/markxu/android-16` |
| Android branch/HEAD | `aosp16-bst-merge` / `eb146d4c3b26dbd8447e74f343020015ee85ced7` |
| app-player branch/HEAD | `bst-v5.22.210-A16` / `86b26bd6c26e2145995afd746c957dc81f087f94` |
| goldfish branch/HEAD | `bst-v5.22.210-A16` / `a899e765559bdbddf07270675410a106c70e0c47` |
| Android OUT | `/home/clouddev/bst/workspace/markxu/android-16/out_nxt_Baklava64` |
| PR | merged promotion PR `#4`; follow-up Draft PR `#5` into `bst-v5.22.210-A16` |

The Android root includes device/generic/x86_64 commit
`20b180160890870891672920172317d8939a0340`, which installs the
`/vendor/bin/hw/hwservicemanager` compatibility link. Root commit
`eb146d4c3b26dbd8447e74f343020015ee85ced7` publishes that component pointer.

## Black-screen status

The graphics route was restored to the Intel host path and the
hwservicemanager compatibility link was published. The final clean-derived,
incrementally packaged image passed ten consecutive cold boots. All eight boot
oracles passed after every 95-second stabilization window, with no RCU stall
signature. Guest framebuffer readback remained non-black on all ten boots;
representative ratios were `0.997611`, `0.974381`, and `0.999425`. The current
post-restart frame is 1600x900 with ratio `0.974425` and SHA-256
`0566ab3357c18ed7855ec26a24af6acab7b44ea36ca2e4605b47a4023694ca9e`.
The HOME resolver, focused
activity, and top-resumed activity all identify
`com.uncube.launcher3/com.bluestacks.launcher.activity.HomeActivity`.

This closes the reported restart black screen for the identity below. No
Windows screenshot was used.

The pre-clean package evidence was:

| Artifact | SHA-256 |
| --- | --- |
| `Root.vhd` | `c2fdc085fbdc15c3e7855014fbd741c90320153641d49cdf64c07ce98edf0f10` |
| `system.img` | `fe5d0ed082e577bba8785a7c1ec6ba3dd98d3d93c50c181104e16623634ce0f9` |
| `system.sfs` | `3fe9845ca7675d0e195aa15d5fbe7c4f57d7681686c8cbc7218eb3469321d5c7` |

## One-time clean baseline

The requested one-time clean build started at
`2026-08-15T21:50:43+08:00`. Its preflight required the exact Android root,
branch, root HEAD, initialized submodules, and clean project state before
removing only `out_nxt_Baklava64`; only the known pre-existing root
`.gitignore` change was allowlisted. It built `init`, `systemimage`, and
`kernel` with eight jobs and completed all 164,735 Ninja actions in 5:08:17.
The wrapper now waits for the post-build `system.img` publication race and
hashes the log only after `tee` has closed.

| Clean-build item | Identity |
| --- | --- |
| Android root | `eb146d4c3b26dbd8447e74f343020015ee85ced7` |
| `system.img` | `feddcc92076f481cf5eb3a34a0dcdde4aa1c91fb39d5fb2b50b99f882f9b67fc` |
| build log | `93147dd195cc3127e9a09ecf37433fb21ee831918c243bd65f526ae60e3b5d00` |
| completed identity | `f4c5104124238bd25a78586646cad7b172fac72967349ef39c702e528734fb62` |

After this baseline, all source changes in this cycle use the canonical
incremental build and package flow. A second OUT deletion or full build is not
permitted.

## Final regression results

| Gate | Result | Evidence and disposition |
| --- | --- | --- |
| Exact guest properties | PASS | 455 exact values; no missing, exact, or critical mismatch. |
| ADB policy | PASS | Restored policy SHA-256 `afaa1ab10855378ffbeaa544f8d3c0de705bee4ebc271d0974ac19a5a2f8be92`. |
| Launcher/services | PASS | Runtime regression reached Launcher and required services; only shared-folder checks failed. |
| Houdini/JNI/binfmt | PASS | ARM64 JNI, regular/Fast/Critical native calls, `libhoudini.so`, translated maps, ARM64 cpuinfo, and standalone binfmt passed. |
| Runtime app oracle | PASS | Wi-Fi, network presentation, direct bionic property read, Skia, AudioTrack, Camera2 frame, and DownloadProvider denial passed under an ordinary app UID. |
| Dynamic FPS | PASS | Idle-state `60 -> 30 -> 60` periods were exact; SurfaceFlinger/composer CPU deltas remained bounded. |
| Camera frame | PASS | `/dev/video0` exists, both 6.12 modules are loaded, and Camera2 returned a 320x240, 115,200-byte YUV frame. |
| IME | PASS | `init.svc.imeservice=running`, `bstime` is alive, and the loopback listener is bound on port 40143. |
| Play Store / GMS | PASS | Play resolved and launched; Vending and GMS remained alive for 60 seconds without target crash-buffer, fatal, or ANR evidence. |
| RCU cold-boot rate | PASS | The current final package completed 10/10 cold boots with zero RCU stall signatures. |
| Shared folder | BLOCKED-EXTERNAL | Hyper-V selects `bstfolder`. Historical guest source was recovered, but its retired UHD transport and a matching modern host service are absent. |

The final incremental package is bound to app-player `5f38c99f71667ce69fdf7c5489db7b078bdb2d84`
and Android root `eb146d4c3b26dbd8447e74f343020015ee85ced7`.
`Root.vhd` SHA-256 is
`5b67d0ab844c8001ce9413a8f0e74104232cdf56b303d95e1ab28f4d1f2909b9`
with UUID `54e9ad31-a169-4d5b-a0e0-705d62e96e71`.
`fastboot.vdi` SHA-256 is
`ae4769fee31a31c3fcf6bd9a442a538df4ad8437b2c092cc963d42fdd73eee535`
with UUID `91b80c95-aa7d-459d-93e4-c479f5babbb7`. The release archive contains
only the six expected files; stale diagnostic VHD/VDI backups are excluded.

## Oracle corrections

The first app-oracle failures mixed product defects with invalid test
assumptions. Production behavior was reviewed before changing the oracle:

1. Ordinary apps must receive the redacted Wi-Fi MAC
   `02:00:00:00:00:00`; the app-visible `wlan0` retains a valid configured
   address. The oracle now declares `INTERNET`, which Android requires before
   exposing ordinary network interfaces.
2. The A13 network contract independently configures the modern transport and
   legacy network type. The oracle accepts one configured Wi-Fi or Ethernet
   capability and a connected legacy Wi-Fi or Ethernet type instead of
   forcing both to Wi-Fi.
3. A static `AudioTrack` starts in `STATE_NO_STATIC_DATA`. The oracle writes
   samples first, then requires `STATE_INITIALIZED` and `PLAYSTATE_PLAYING`.
4. Child `/system/bin/getprop` uses property-find and cannot exercise a
   synthetic missing-property hook. The APK now contains a minimal x86_64 JNI
   library linked to the Android LLNDK libc stub and directly calls
   `__system_property_get`. It proves app-UID
   `ro.board.platform2=ngg-client` without installing a global property.
5. Houdini 16 supplies `AArch64 Processor` in its generated cpuinfo. The
   native-bridge oracle accepts this and the older `ARMv8 processor` spelling,
   while still requiring `CPU architecture: 8`.
6. Android 16 hides a broadcast sender identity unless the sender opts in.
   The DownloadProvider oracle now sends with
   `BroadcastOptions.setShareIdentityEnabled(true)`, allowing the receiver to
   reject and log the actual ordinary-app UID instead of `Process.INVALID_UID`.

Both oracle APKs compile with Android 16 target-tree prebuilts. The final
runtime APK SHA-256 is
`10153ba78f3677115fcb284abfd7eb7e766287e6a67b8750c698c0256dcb187b`;
all app checks pass. The native-bridge APK
`72a87bfbb543d91b563addb2f10983f4f36bc4fdb2f5fe6f74139ec3fd0379a6`
and standalone binfmt ELF
`611c2386fca304aae14b64718f176266c6a479ad35f6404950d989dd37f3de0c`
also pass.

## Dynamic FPS root cause and required fix

`bst.max_fps` is present and mutable. During UI activity, EmuHWC2 observes a
change to 30 FPS and SurfaceFlinger reports a 33,333,334 ns application frame
duration; restoring 60 FPS returns it to 16,666,666 ns. The current goldfish
thread, however, calls `syncBstMaxFpsLocked()` only while hardware VSync is
enabled. SurfaceFlinger normally leaves hardware VSync disabled at idle, so a
property change can remain unapplied indefinitely.

Goldfish commit `09383b110ce5dc925614ff74d70ddb46f16fe4e0`
implements the minimal correction: retain the one-second bounded poll and wait-time
update regardless of `mVsyncEnabled`, issue the refresh callback outside both
state locks when the period changes, and continue to emit VSync callbacks only
while enabled. This preserves the A13 mechanism and adds at most one property
read per second to an already-running VSync thread. The runtime oracle observed
16,666,666 ns at 60 FPS, 33,333,334 ns at 30 FPS, and 16,666,666 ns after
restore, each with 0.00% reported delta.

## Camera root cause and recovery authority

The guest enumerates PCI `1002:b574`, matching the existing bstcamera table,
and the Windows host log enumerates physical/virtual cameras. The camera HAL
and provider are installed, but `/dev/video0` is absent and CameraService has
zero devices.

The HD worktree contains temporary Baklava64 conditions that skip building and
copying `bstcamera.ko` and `videobuf-core.ko`. Linux 6.12 removed the legacy
videobuf API used by the A13 camera driver. Local pre-update history preserves
an A16-compiled compatibility pair:

- HD stash tree `7592c3221d` contains `videobuf-core.c`,
  `videobuf-core.h`, and both 6.12 modules.
- The compatibility source is byte-identical to the A13 implementation except
  for including its local header.
- HD stash commit `8699ab6f55` records the local include and two-module Kbuild
  change.
- Both preserved modules report `vermagic: 6.12.90+ SMP preempt mod_unload`,
  matching the running kernel release.

The disciplined recovery restored that source, enabled it only for
Baklava64 so A13 Kbuild behavior remains unchanged, removed the temporary skip,
rebuilt both modules against the clean Android 16 kernel output, packaged them
in the initrd, and required a non-empty Camera2 frame. The packaged module
hashes are `31bfb0b77775f105dc790969f8cf1be0a4d5ced36d50237fe84c5debc429eb9d`
for `bstcamera.ko` and
`ff562da1b04a6dd1f158807cdc7b1ce65bbc1a33c591e004900fd5faaa8e76e5`
for `videobuf-core.ko`; both report
`6.12.90+ SMP preempt mod_unload`. HD remains explicitly
outside the tracked/submitted component set; its local recovery and evidence
must not be staged accidentally.

## Shared-folder external dependency

The exact shared-folder property now loads correctly, so the earlier
post-data property bug is not the cause. Hyper-V selects filesystem type
`bstfolder`, but the guest advertises only `virtiofs` and `vboxsf`; it has no
virtio-fs device and no installed `bstfolder` implementation. A fixed,
read-only historical source was recovered from
`bluestacks/scratch-backup` commit
`af7c35682e563b17beea5622eb7d22f0495d5ffb` under
`daver/hyperDroid/Linux/Modules/bstfolder`. The nine-file implementation is
useful protocol history, but it depends on the retired UHD message APIs and
headers (`linux/hd_guest.h` or `asm/mesg.h`) that are not present in the
current guest. The same historical tree also contains its old host-side
`Source/Core/SharedFolder` implementation; that code is bound to the same UHD
protocol and is not part of current HD. Current HD history records its complete
removal in `7afd5274d9` (`Xpl refactoring (#4705)`), including 6,045 host-side
lines. Restoring it would reverse an architectural removal rather than perform
an Android 16 compatibility port.

Current HD uses the `bstvmsg` transport. Its host registers only `gcall`,
`hcall`, and `inp` services; there is no shared-folder service ID or
registration. The guest kernel API exports `vmsgConnect()` but no kernel
request/send interface sufficient to adapt the historical filesystem. HD
contains VBox clients, while the Hyper-V host does not publish a VBox
shared-folder export. The installed `Tiramisu64.bstk` does contain valid
`InputMapper` and `BstSharedFolder` host paths, and the guest loads `vboxsf`
successfully, but mount requests report `vboxsf: No shared folder specified`.
Current HD routes shared-folder management only through
`Source/vmmgr/vbox`; the Hyper-V backend has no equivalent registration path.
Therefore recovering the old filesystem source or changing the guest mount
command alone cannot restore the end-to-end contract.

The A13 tree also contains a second, unintegrated experiment at
`external/bluestacks/bstfolder/Main.cpp`. It connects `AF_VSOCK` to host CID 2,
port 50000, then mounts 9P with `trans=fd`. It is not an A13 production
baseline: no product makefile includes the executable, both A13 and A16 BST
kernel defconfigs disable VSOCK and 9P, and a read-only full scan of the saved
A13 `Root.vhd` and fastboot image found only the `mountsf` shell script, with
no `bstfolder.ko`, daemon, or 9P/VSOCK payload. Current HD source and the
installed player binary contain no Plan9 service implementation; Windows has
no corresponding Hyper-V guest communication service registration. Enabling
the A13 client alone would therefore add an unsupported protocol endpoint and
cannot be accepted as a minimal port.

This cannot be repaired honestly by changing permissions, falsifying the
hypervisor property, or treating an empty guest directory as a mount. Closure
requires either a maintained host and guest `bstfolder` transport pair, or a
host change that publishes a supported virtio-fs/VBox transport. Until that
contract is supplied, the two shared-folder gates remain an external blocker
and must not be reported as passing.

## Publication and remaining gates

Goldfish commit `09383b11` and app-player gitlink commit `5f38c99f7` were
pushed to and read back from their BlueStacks `bst-v5.22.210-A16` branches.
The original root PR #4 was already merged. Its target is root
`a94003163555d715df85fdc486ff09d037597253`, while the validated source root is
four commits ahead at `eb146d4c3b26dbd8447e74f343020015ee85ced7` with six gitlink
updates. Draft PR [#5](https://github.com/bluestacks/android-16/pull/5) carries
that exact follow-up delta.

Remaining gates:

1. Review and merge Draft PR #5 after accepting the documented external gate.
2. Supply a maintained Hyper-V host/guest shared-folder transport pair. This
   is the sole runtime gate that cannot be closed inside the submitted Android
   16 and goldfish component scope.

The requested clean baseline has been consumed. Every later Android build must
be incremental; `out_nxt_Baklava64` must not be cleared again.
