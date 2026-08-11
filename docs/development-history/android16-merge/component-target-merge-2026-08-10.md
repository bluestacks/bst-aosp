# Component Target Merge Closure - 2026-08-10

## Scope

This record closes component publication for Draft PR
[bluestacks/android-16#3](https://github.com/bluestacks/android-16/pull/3).
It covers 42 changed existing root gitlinks plus nine added components: three
media repositories and six legacy ALSA/HAL repositories whose URLs were moved
from temporary forks to BlueStacks. App-player auxiliary modules and
`scratch-gaurav` remain outside scope.

The operation used only `~/android-16` component worktrees. It did not build,
deploy, read artifacts from `~/aosp16/out*`, or affect another user's process.
No force push or destructive reset was used.

## Procedure And Result

1. Freeze the root target at
   `33cdca5464ea1a50e98058a40c36bf3121dbe2b7` and the promotion root at
   `2be2bd594015046288f67420c72ac3d964595d14`.
2. Resolve each root gitlink to its canonical BlueStacks repository and verify
   the local `aosp16-bst-merge` object.
3. Fast-forward components whose target tip was an ancestor.
4. For divergent components, inspect target-only commits and final-tree paths
   before selecting a normal or history-only merge.
5. Push only ancestry-preserving updates to both the source merge branch and
   the BlueStacks `bst-v5.22.210-A16` branch.
6. Read both remote tips back for all 51 components.
7. Update the 14 root gitlinks whose final merge SHA changed and publish root
   `d3e80def2ce05594d50cee4819e8a85c20757617`.

Final readback: `51/51` BlueStacks target tips and `51/51` source merge tips
equal the reviewed local tip. All final subjects start with `[A16]`.

## Final Component Matrix

| Project | Final tip | Method |
| --- | --- | --- |
| `art` | `81a67a9daf668addd86d47a05ced385d52ba8c62` | fast-forward/exact |
| `bionic` | `d81403cc6575a977d75481d246a0f7b2b0589c39` | normal merge |
| `bootable/newinstaller` | `87fd724fae85f521d5822485e6c9128cf9128323` | fast-forward/exact |
| `build/make` | `00662ca14601ede1e77bbe1427159b5f060bee54` | normal merge |
| `build/soong` | `1e54115ae44db963b582c562349a1b3988604ae2` | reviewed history merge |
| `device/generic/common` | `3c87025c3d564b8f6de9b6fbd5d780ceebd92e54` | reviewed history merge |
| `device/generic/goldfish` | `f4da18aa4ad5388c4556f48b8e31bf0c13317d95` | fast-forward/exact |
| `device/generic/x86_64` | `fb8dac73447426c2b46d30c74fa75bcc21ea79db` | reviewed history merge |
| `external/boringssl` | `3408a53df9dfc88f18405e3d22a4cd5b92654282` | fast-forward/exact |
| `external/e2fsprogs` | `d1bad9cd14446d8b131b8de59a6e8655a4b4f6d4` | fast-forward/exact |
| `external/efibootmgr` | `eee7124f21cec5d3cad6c6861f145c57445ce856` | fast-forward/exact |
| `external/efivar` | `01b2f0acb905e95cece29dc47d34bd39d44a6dd2` | fast-forward/exact |
| `external/libjxl` | `013bc4a360c10dcc4ea43b3dc3ef33633b3fbfff` | fast-forward/exact |
| `external/libva` | `313d3c0dbf612914d17cd1a02927c72a78e87d81` | fast-forward/exact |
| `external/libxml2` | `c724771c911ee8730f829e2d6bcb513bf0038945` | fast-forward/exact |
| `external/selinux` | `2de70bcb678ae554a9c1e770f0a1f848c144cda6` | fast-forward/exact |
| `external/skia` | `0b9c6137b24954b6a3452adeb2f305c77f50e0dc` | fast-forward/exact |
| `frameworks/av` | `2f98cd4347f9f0e542c3eeda5967c0daa62c17b1` | fast-forward/exact |
| `frameworks/base` | `764e09df1af78ea0cd70b63d35b3cc7b03daf918` | reviewed history merge |
| `frameworks/native` | `58665c720140f614849a92aad57efb5a28904ba2` | reviewed history merge |
| `frameworks/opt/telephony` | `b06a887a526981cbc0b23fd2bf469334df9b9f9d` | fast-forward/exact |
| `hardware/interfaces` | `1d05864e9ddc1333391204b21e002491a8fbcc58` | normal merge |
| `hardware/libhardware` | `32f3fbad346cd2e320f01b2c2d9ba4a967af0b5d` | reviewed history merge |
| `kernel-a16` | `fa4841ba588b94daa441c2f1a3a043be46fcde73` | target-first 6.12 merge |
| `libcore` | `a11d197a9cf7771a80d9b8a8cd7d477bab1f5889` | fast-forward/exact |
| `packages/apps/Launcher3` | `e930681134529262fd94fbc3c7b548563ee40a80` | reviewed history merge |
| `packages/apps/Settings` | `4011bdb53de5b9a96a965b98004d8a03672596c4` | fast-forward/exact |
| `packages/inputmethods/LatinIME` | `30cede3a4b41fabeb621af09301882d9750e8d05` | fast-forward/exact |
| `packages/modules/Bluetooth` | `7f96b596a749046fefd1fe87c683ecc2cdb48bc7` | fast-forward/exact |
| `packages/modules/Connectivity` | `6a0d7d31ef103414f9b782fa2fa785a809eb3551` | reviewed history merge |
| `packages/modules/NetworkStack` | `6d7e4d175654da4b8155da5916cf63d99c6cdf0c` | fast-forward/exact |
| `packages/modules/Wifi` | `025929cf5db85fea57847db7b6e29b5f224c035d` | fast-forward/exact |
| `packages/modules/adb` | `361c29e743452cf1a6d944aa2d836de5fa776c1f` | fast-forward/exact |
| `packages/providers/DownloadProvider` | `db61a3d4e87ab1312486fdb481573b990f22de53` | fast-forward/exact |
| `packages/services/Telephony` | `5d2c366658ee6222d1d7d1fc8d71f17937e78e06` | fast-forward/exact |
| `system/core` | `6f63393e80b8c2fb8753c2bd4eb1e7e26c7303e8` | reviewed history merge |
| `system/extras` | `2e0a75a42df3f785c500711ddada805d70e07ff2` | fast-forward/exact |
| `system/hwservicemanager` | `2a4d237ff8248a7818def0d2900d95a77914f7ae` | reviewed history merge |
| `system/libhidl` | `e88169530f766269173fa668ba444c411d59f276` | fast-forward/exact |
| `system/security` | `6443d21a351b50b343ea7f037cb045585c4d0f26` | fast-forward/exact |
| `system/sepolicy` | `acff98d684732d0ca05aff5f2799dfd3b32ed921` | fast-forward/exact |
| `system/vold` | `bf57a99ee447bc089e29ff52ac3624fae61a5fde` | fast-forward/exact |
| `external/ffmpeg` | `b58396a9a465ec3875e01d1719bd0beea971b359` | fast-forward/exact |
| `external/stagefright-plugins` | `6462e1ed74e9c91b4bf336713c8f928afeb3a4fc` | fast-forward/exact |
| `external/v86d` | `49e046362296556bc38b45bb4d971965eab21dfe` | fast-forward/exact |
| `hardware/bst/audio` | `ac13f7b60680f60a3b0efc031aaa42019be254be` | fast-forward/exact |
| `hardware/bst/lights` | `d7fb147bdaf6c5675ba98c308c0411c8f6762bdd` | fast-forward/exact |
| `hardware/bst/memtrack` | `d3596f32d4f042ccbb17653ab84132cfa07080d0` | fast-forward/exact |
| `hardware/bst/power` | `2b2e3e1dd69985937d122b400dded54532e8519f` | fast-forward/exact |
| `external/alsa-lib` | `e54ae1267d274487fbe06df176eeca0147edd7c3` | fast-forward/exact |
| `external/alsa-utils` | `12f8c54f77f40bacd87bc0ec4c9f3c6bfb66d47f` | fast-forward/exact |

## Submodule Ownership Closure

The final `.gitmodules` audit found six remaining `mark-bst` URLs. Each
BlueStacks repository already existed and its `bst-v5.22.210-A16` tip was the
direct parent of the root-pinned `[A16]` adaptation. The six target branches
were fast-forwarded and read back before the URLs changed:

- `bluestacks/hardware-bst-audio-a13`
- `bluestacks/hardware-bst-lights-a13`
- `bluestacks/hardware-bst-memtrack-a13`
- `bluestacks/hardware-bst-power-a13`
- `bluestacks/external-alsa-lib-a13`
- `bluestacks/external-alsa-utils-a13`

Root `90f87eed8d0bbd1bed49f077f775309bd9f2d843` contains zero `mark-bst`
submodule URLs. Every URL belongs to the BlueStacks organization. At that
checkpoint, eight explicit branch fields tracked `bst-v5.22.210-A16`; root
`7470f85005bebe91becf3e66c8183107aae4f6f0` subsequently removed every branch
key so gitlinks remain the only component revision authority. Neither metadata
follow-up changes a component gitlink.

## Divergent Component Review

The three normal merges retained distinct target behavior:

- `bionic`: integrated target changes in `libc/bionic/pthread_internal.h` and
  `tests/struct_layout_test.cpp`.
- `build/make`: integrated target changes in `target/product/base_system.mk`
  and `target/product/generic/Android.bp`.
- `hardware/interfaces`: both sides merged cleanly; the resulting tree had no
  additional content delta after equivalent changes were reconciled.

Ten components conflicted because the target branch carried earlier versions
of the same port. Their target-only commits and final-tree paths were reviewed
before recording both parents while retaining the validated promotion tree:

- `build/soong`: earlier Android.mk allowlist and out-of-tree scanning work was
  superseded by the promotion implementation.
- `device/generic/common`: old binfmt payloads were superseded by the reviewed
  Houdini layout; the tracked market keystore was intentionally excluded.
- `device/generic/x86_64`: target product-definition changes and their revert
  left no target-only final file.
- `frameworks/base`: the target service, permission, biometric, window, and
  package changes were present or superseded in the promotion tree.
- `frameworks/native`: old duplicate Binder headers and a renamed disabled
  null-driver file were not restored over the current layout.
- `hardware/libhardware`: old disabled gralloc/hwcomposer files conflicted with
  the reviewed provider selection and remained excluded.
- `packages/apps/Launcher3`: HOME and null-safety changes were already present
  in the promoted final tree.
- `packages/modules/Connectivity`: the Ethernet identity behavior was already
  represented by the promotion implementation.
- `system/core`: target fstab, init, SELinux, property, and rootdir changes were
  represented or superseded by the reviewed Android 16 implementation.
- `system/hwservicemanager`: the target install-location change was already
  represented by the promoted service layout.

These ten merge commits change history only relative to their promotion first
parent. They add no runtime or performance cost. Their necessity is provenance:
the BlueStacks target history is retained without reintroducing superseded
files or unreviewed secrets.

## Kernel Decision

The source and target kernel histories were not ordinary peers. Their merge
base was `d1a66e79429a07256ae93b73d0253283bcc01bd9`; the source had 20,383 unique
commits while the target had 291,998. Replacing the target with the source tree
would delete about 19,903 target files and regress Android 16 from kernel 6.12.

The source's surviving product changes touched only
`arch/x86/kernel/setup.c` and `arch/x86/configs/bst-x86_64_defconfig`. The
target already had the correct Android 16 identity,
`bstandroid=baklava64`, but lacked SquashFS support required to mount
`system.sfs`. Commit `fa3cde1aa20733c4f07349dbd8cfe6275ef52027` enables:

- `CONFIG_SQUASHFS`
- `CONFIG_SQUASHFS_FILE_CACHE`
- `CONFIG_SQUASHFS_DECOMP_SINGLE`
- `CONFIG_SQUASHFS_XATTR`
- `CONFIG_SQUASHFS_ZLIB`

All symbols exist in the 6.12 Kconfig. Merge commit
`fa4841ba588b94daa441c2f1a3a043be46fcde73` then records the older development
ancestry while keeping the 6.12 first-parent tree. The feature can increase
kernel image size and allocates decompression resources when SquashFS is used;
there is no per-frame cost. It is necessary for the current compressed system
image and preserves a read-only filesystem plus xattr support.

## Validation Boundary

The previous build, package, clean-Data 7/7 boot, Launcher, and Settings
evidence is bound to root
`2be2bd594015046288f67420c72ac3d964595d14`. Root
`d3e80def2ce05594d50cee4819e8a85c20757617` changes component identities and
includes real target deltas in `bionic`, `build/make`, and the kernel config.
Root `90f87eed8d0bbd1bed49f077f775309bd9f2d843` adds only the final canonical
submodule URL/branch metadata. No build or boot test was run during this
publication operation, so the older artifacts cannot validate the current
component content.

Draft PR #3 must remain unmerged until a target-only incremental build and
focused boot/runtime regression pass. The existing exact `bst.*` lookup and
shared-folder blocker also remains open.

The remote build workspace was fast-forwarded to
`90f87eed8d0bbd1bed49f077f775309bd9f2d843` through a verified 2 KB root
bundle with recursive submodule fetching disabled. Its index is empty, its
component worktrees contain the published final tips, and its only ordinary
tracked-file change is the pre-existing `.gitignore`. The target identity
preflight remains mandatory before the next build.
