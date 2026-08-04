# A13 Authority Completion Review

## Scope And Identity

This review treats `~/app-player/android-13` branch `bst-v5.22.210` as the
product customization authority. `~/aosp16` is read-only implementation and
historical validation evidence, not the authority for deciding whether an A13
patch is required.

- Target tree: `~/android-16`
- Target branch: `aosp16-bst-merge`
- Target product: `android_x86_64-trunk_staging-eng`
- Current root: `9ae09dd212ac1ecedfa7e41782e92d8f7a640d24`
- Build output: target-local `~/android-16/out`
- AOSP16 output use: none
- Push or PR: none
- Current-tree boot validation: not run
- Current-tree full `m droid`: passed; packaging and boot are not yet run

The prior PR #2 root `298403a` and its 7/7 boot result are historical. They do
not validate the current authority-completion commits.

## Confirmed Missing Patch Groups

### Android Userspace SELinux State

- Authority: `external/selinux`
  `d42add96533decac77101c314e5abceae20070d7`.
- Finding: AOSP16 and the initial Android-16 promotion kept upstream
  `is_selinux_enabled()`, despite already forcing init permissive and relaxing
  domain-transition/property checks.
- A16 component: `62b46b73374cc636e3e0aeb0d492ee077cc2210b`.
- Root pointer: `8dc66a08a561d746c8a26c39435eb52827104793`.
- Adaptation: Android builds report disabled; host libselinux keeps upstream
  detection.
- Necessity: restores the A13 paths used by `installd`, `cmd`, restorecon and
  Android libselinux helpers.
- Performance: skips context and restorecon work; no new cost.
- Security: broad defense-in-depth reduction. Android userspace suppresses
  SELinux handling even though the kernel remains permissive.
- Validation: `libselinux`, `init`, `installd` and host tests built; host tests
  passed 12/12 for both host variants; 32/64 target disassembly returns zero.

Artifact hashes:

- `system/lib64/libselinux.so`:
  `2c4cb4e5f7e1dac4420c91dbd034fd71f0e037b126535d2687d6a44eb7f0aa51`
- `system/lib/libselinux.so`:
  `924cc4ca2f8401ddf3533dcfd5bbb44e61842ffd7dd049c61881c49d0fce36a0`

### PRNG Seeder Startup

- Authority: `system/security`
  `ef05d6c885bc1a74ff8bf37d322b0b9c1d86d31a`.
- Finding: AOSP16 and Android-16 still registered `prng_seeder.rc`, although
  the App Player VM does not expose the hardware random device expected by the
  early-init service.
- A16 component: `6443d21a351b50b343ea7f037cb045585c4d0f26`.
- Root pointer: `53eb20abecc1b8b1a2d7e55fc1f3637e34a4fc39`.
- Adaptation: disable the `init_rc` property in A16 defaults while preserving
  the regular binary, Microdroid variant, source and tests.
- Performance: removes a possible early-boot entropy wait.
- Security: removes this daemon reseed path and therefore requires a boot-time
  kernel entropy-source readback.
- Validation: binary and 32/64 tests built; independent install-tree readback
  found `system/bin/prng_seeder` and confirmed that
  `system/etc/init/prng_seeder.rc` is absent.

Artifact hashes:

- `system/bin/prng_seeder`:
  `388f66f80b3e8950227babf3b010402b2adb4013023111c3fdb0eaad3f7d0dfe`
- 64-bit test:
  `9918993a423f521d0514bd24a258bb58a3a222e55daeecef391ddd40ba951599`
- 32-bit test:
  `62bdcd88be0fcf7d9de1630ec2eee831c21609a5ce42f6a6bf9f5b11de1b421e`

### Connectivity Presentation And Policy

The previous A16 component commit `204b126ff740dfa008a2b05023cce520a8052e6d`
contained only the static-IP portion of A13. Five final A13 commits still had
missing semantics.

#### Ethernet And Wi-Fi Presentation

- Authorities:
  `eb7ce30646385250ec05e673aafedee4c33363b5`,
  `6bbe6af294c67c9af56f4d3e7c8a4553f2b6483f`, and the network-agent part of
  `d86f187aea77c164213462d377884fa3473d1e47`.
- A16 component: `2f0481f305cadd2280cee75506be803219ad6629`.
- Root pointer: `36afb8e5b225e9c46bc8fbc9a5917816eca9cfa0`.
- Adaptation: A16 transport selection moved into `EthernetConfigParser`; the
  already-started `BstFilterAppsService` is queried there. Legacy type policy
  moved into the refactored `EthernetNetworkFactory` and is exposed through a
  dependency method for deterministic tests.
- Performance: one binder call per configured interface at startup and one
  property read when provisioning.
- Security: intentionally changes the network identity visible to apps and
  policy code; it adds no new privilege.

#### DSCP Program Loading

- Authority: `56a3aff5be6304f88eba2fcdee09cde8ad42fd5c`.
- A16 component: `ce5d67fa66f1f56450a22f274ccc39a6207108a6`.
- Root pointer: `01328ab7feb121873313529116b460cc6073d481`.
- Adaptation: apply `#pragma unroll` to the relocated A16
  `bpf/progs/dscpPolicy.c` loop.
- Performance: larger generated BPF instruction stream in exchange for less
  verifier loop analysis; packet matching semantics are unchanged.
- Security: no policy matching or packet mutation change.

#### China Captive Portal Default

- Authorities: `33b855c9022604cec5944afbbffad06ff85eb50e` and API-fix follow-up
  `f082bfff816777d3b0133e249038aac079dcbd43`.
- A16 component: `b3f8ca2c95e4c5f4211b8e6bccb0a0a7d9e92ed6`.
- Root pointer: `6f242cafabcd7271ecd78cc72d99498fbf988da5`.
- Adaptation: retain the A16 `NetworkAgentInfo` Wear/Bluetooth exception and
  use `IGNORE` only as the `nxt_cn` default. An explicit global setting still
  wins.
- Performance: property lookup only when portal mode is evaluated.
- Security: `nxt_cn` can suppress portal prompting by default, which is an
  intentional A13 product policy with interception risk.

Combined Connectivity validation:

- `FrameworksNetTests` and `ConnectivityUnitTestsLib` built successfully.
- Dedicated Wi-Fi transport and legacy-type tests are present in the compiled
  unit-test jar; tests were compiled but not executed on a device.
- `dscpPolicy.o` built with `-Werror`; APEX and system copies are identical.
- Service jars independently contain `bstfilterapps`, `isEtherNetType`,
  `bst.config.modify_network`, `bst.oem`, `nxt_cn` and `captivePortalMode`.

Artifact hashes:

- Connectivity test library:
  `7fcb380b07d6e2c1a7e7d0da3e7ebb4414d513b8b82d5387a820d2c711405e20`
- Tiramisu service jar:
  `459c71f4bdc9c7523b5b388a133d67e0b661c25fc609f5cff07b4ea54caea92b`
- Core service jar:
  `642b557cdb4a1b997ad8021035445b2d96230b3d53e21bc8ea56c66831768771`
- Installed BPF object:
  `6796c9c678c6134130bf8e8cd549081783c4264dd2fd687f5541b8e7f8ff74f2`

### Project Quota Compatibility

- Authority: `system/vold`
  `fb129833c9b27047bd529da67ce56fe248969075`.
- Finding: both AOSP16 and the initial Android-16 promotion still issued
  `FS_IOC_GETFLAGS`, `FS_IOC_SETFLAGS`, `FS_IOC_FSGETXATTR` and
  `FS_IOC_FSSETXATTR`. The final A13 tree intentionally treats project-quota
  setup as successful because App Player storage does not implement these
  ioctls.
- A16 component: `bf57a99ee447bc089e29ff52ac3624fae61a5fde`.
- Root pointer: `f0947d915915e45d69a683679895553780161a61`.
- Adaptation: preserve the A13 no-op semantics without carrying its dead
  `#if 0` implementation. Both helpers explicitly consume their arguments and
  return zero; all directory creation and shared-folder mount behavior remains
  unchanged.
- Necessity: prevents unsupported project-quota operations from failing app
  directory preparation on the virtual storage backend.
- Performance: removes two opens and up to four ioctls per affected quota
  setup path; no new work is introduced.
- Security: project IDs and inheritance are not applied by vold. Isolation must
  therefore come from the App Player storage model, UID/GID ownership and
  mount boundaries; this matches the final A13 product policy but requires
  runtime storage-isolation verification.
- Validation: `vold`, `vold_prepare_subdirs` and both 32/64-bit `vold_tests`
  built successfully in 607 actions. The x86_64 object disassembly for both
  helpers is `xor eax,eax; ret`. The tests were compiled, not run on a guest.

Artifact hashes:

- `system/bin/vold`:
  `9bc12768510f5cb5326a4bbe707465c61fad21d6f6a4031338a59705f575dd1a`
- `system/bin/vold_prepare_subdirs`:
  `da4dfce68a5d4bf29d1201570b26687229d678793ee41b4e87cc5fd64e6370c3`
- 64-bit test:
  `798b98dc750b6af62436562de2ad698416c8f7aeabf6a12d80471d3cef0c0a4e`
- 32-bit test:
  `3c6a0873a0a54a8fcc3046f916e7870060906e64281796f57382bf2c450e3d9a`

### Host IME Bridge Client

- Authority: root-owned A13 `system/bstime/Main.cpp`, SHA-256
  `fef2e02131d7912d467b354c80e71993749ab78d001864dcf3d9ddfe1284d0a2`.
- Finding: both AOSP16 and the initial Android-16 promotion selected `bstime`
  in `device/generic/common/packages.mk` and declared the `imeservice` init
  service, but neither tree contained the module source. The service therefore
  referenced a missing `/system/bin/bstime` client while `BstImeBridge` still
  provided the loopback socket endpoint.
- A16 root commit: `643b1d9a8a8bd69b3ce335a099f0927b15e343d2`.
- Adaptation: retain the A13 C++ source byte-for-byte and replace only the
  blocked legacy `Android.mk` with an eight-line `cc_binary` definition.
- Necessity: restores the guest `/dev/bst_ime` to framework IME bridge required
  by the already active init and Java-side protocol.
- Performance: one existing oneshot daemon and its blocking device/socket loop;
  no new polling path or protocol work was added.
- Security: the authority source trusts the `/dev/bst_ime` message length and
  loopback peer. Its fixed 256-byte buffer, retry accounting and signal-handler
  behavior remain review debt; changing them here would diverge from the
  authority protocol without runtime evidence.
- Validation: `m bstime -j8` completed 80 actions. The installed x86_64 PIE is
  `out/target/product/x86_64/system/bin/bstime`, SHA-256
  `438d978a682546fbaa68ea5a2d816d53ce2c1c41e87754c4491ee97d1bafe448`.
  It was compiled but not exercised against a guest or host IME bridge.

### VA-API Driver Discovery

- Authority: A13 root commit `c71e618e0c99d17ff903fce579b7e12ef46f9ec1`
  installs `i965_drv_video` under `vendor/lib64/dri` and compiles libva with
  `VA_DRIVERS_PATH=/vendor/lib64/dri`.
- Finding: Android-16 correctly replaces the old root-vendored libva source
  with current `external/libva`, and already carries the i965 driver and product
  package. Its x86_64 libva variant instead embedded `/vendor/lib64`, so runtime
  discovery did not match the installed driver directory.
- A16 component: `external/libva`
  `313d3c0dbf612914d17cd1a02927c72a78e87d81`.
- Root pointer: `27488f4954b2c2fc81c7715969cf1439ff05de0f`.
- Adaptation: change only the modern Soong `VA_DRIVERS_PATH` constant; do not
  import A13's obsolete libva copy or change the i965 source/install layout.
- Necessity: permits libva's default loader to find the product-selected i965
  backend without an environment override.
- Performance: no steady-state cost; it removes a failed directory probe and
  allows the existing hardware decode path to load.
- Security: narrows discovery to the vendor DRI directory containing the
  packaged driver. No writable or host-controlled search path is added.
- Validation: `m i965_drv_video -j8` completed successfully. The installed
  `libva.so` contains `/vendor/lib64/dri`; `i965_drv_video.so` remains under that
  directory and links to `libva.so` and `libva-android.so`.

Artifact hashes:

- `system/vendor/lib64/libva.so`:
  `c02c9eb1160779b5911160d242265829f9114412d52050e6e4d89dce629bd7ec`
- `system/vendor/lib64/libva-android.so`:
  `98482769c0ac3645a1d1604eb6870c695b048973ca75b41ceb1eaf7a822e738b`
- `system/vendor/lib64/dri/i965_drv_video.so`:
  `dd983486ba8fed3ef98713c4abc420defb5fd9d0319d98fdaa8fb5a26ce4bf34`

### Widevine FCM 8 Compatibility Bridge

- Authority: A13 Widevine service commit
  `bb15209c81865750681a87e371fa645797818492`, which serves
  `android.hardware.drm@1.3::{ICryptoFactory,IDrmFactory}/widevine`.
- Finding: the A13 service, manifest and restricted plugin were restored by
  A16 component commit `0edb96a328b99742a8c3583e3d1aafc501308252`, but Android
  16 FCM level 8 rejects that HIDL 1.3 declaration as deprecated. The first
  full `m droid` therefore failed only at `check_vintf_compatible`, after
  102,504 of 109,977 actions.
- A16 component: `device/generic/x86_64`
  `00623898eb9bd0afc4374f6c79f805939f873311`.
- Root pointer: `9ae09dd212ac1ecedfa7e41782e92d8f7a640d24`.
- Component patch:
  [`device-generic-x86_64-widevine-fcm-bridge.patch`](../../../patches/android-16/a13-completion/device-generic-x86_64-widevine-fcm-bridge.patch).
- Root-pointer patch:
  [`root-widevine-vintf-pointer.patch`](../../../patches/android-16/a13-completion/root-widevine-vintf-pointer.patch).
- Adaptation: add only the two Widevine HIDL 1.3 instances to the existing
  level-8 device framework compatibility matrix. This is the same explicit
  compatibility mechanism already used for the validated Windows goldfish
  HIDL graphics stack. The service and vendor manifest remain installed.
- Necessity: deleting the manifest would make the build green while leaving a
  binderized HIDL service that cannot reliably register. Lowering the product
  FCM or disabling VINTF checking would weaken the whole target. An AIDL
  Widevine service cannot be fabricated from the A13-only vendor plugin.
- Performance: XML-only build/runtime metadata; no steady-state code path or
  extra process is introduced.
- Security and maintenance: the bridge preserves the restricted A13 DRM
  implementation and its existing attack surface. It is explicit technical
  debt and must be removed when an authorized Android 16 AIDL Widevine plugin
  is available.
- Validation: `m check-vintf-all -j8` returned zero and printed `COMPATIBLE`;
  its dependent API/ABI checks also completed. The subsequent `m droid -j8`
  returned zero and regenerated `system.img`.

Artifact hashes:

- Widevine service:
  `d325b5c14a93fefdce4a4f928c9097313114f07e58ab23f6a3878ffc8978525b`
- Restricted plugin:
  `3ce02cd40b4daf0eea672917ec3e8a7611a2245437b346106fa970f7154552e4`

### Promotion Closure And Layer 1 Build

The root gitlink audit found 17 reviewed component heads that had not been
recorded by the superproject. Root commit
`63eb48e49985e0a861536f3341daf4134548cb72` records exactly those component
SHAs; its reviewable export is
[`root-completed-a13-authority-gitlinks.patch`](../../../patches/android-16/a13-completion/root-completed-a13-authority-gitlinks.patch).
A fresh audit at `9ae09dd212ac1ecedfa7e41782e92d8f7a640d24`
reports 1,026 initialized repositories, 975 on `aosp16-bst`, 50 on
`aosp16-bst-merge`, no detached HEADs, no gitlink or remote mismatches and no
nonconforming commit subjects. The only dirty repository is the root because
of the pre-existing unstaged Houdini `.gitignore` change. Fifteen publication
topology errors remain for missing base branches/remotes/forks; they do not
change the local source or build result.

Target-only Layer 1 evidence:

- Tree/branch/commit: `~/android-16`, `aosp16-bst-merge`,
  `9ae09dd212ac1ecedfa7e41782e92d8f7a640d24`.
- Product/output: `android_x86_64-trunk_staging-eng`, `~/android-16/out`.
- `m droid -j8`: passed; final incremental completion took 1 minute 57
  seconds after the three-hour first run and VINTF correction.
- `system.img`: 2,148,761,600 bytes, SHA-256
  `f9b0ef01717ff18b5c134603fde4c4ad5408819801fe0c18b7a27afa6683dcea`.
- Initial failed log SHA-256:
  `8096b6f9c09e809e8ca7e3f65d88708d433eea6305352c1bf40890359b45c9ac`.
- VINTF validation log SHA-256:
  `4937b3b727b06f455589dd9a2ca4e546b5782e088782dfe74c2e71bc08ec9eb2`.
- Successful final log SHA-256:
  `2ae7f7f30605e72e6d7758b435e99b9131536f431285af69ab9def2b2fd40dd9`.
- Audit JSON SHA-256:
  `c2c24f704af197788471b1cbd0212bdabdb3060ee1c29916d11b96ff4fea6a23`.

This is build evidence only. It does not prove init, system_server, host
state-machine, graphics, IME, shared-folder, network or launcher behavior.

### Restricted Widevine Payload Evidence

The A13 Widevine commit `bb15209c81865750681a87e371fa645797818492`
contains both source changes and a 1,250,188-byte prebuilt. The review
repository keeps one `git format-patch --no-binary` code record and the exact
source/target blob and SHA-256 mapping in
`patches/android-16/a13-authority/restricted-binary-evidence.json`. Two
equivalent patch exports with embedded binary data had stable patch ID
`cecfbbfa2d6a65e1764e40e4ab0172986eace92d` and were excluded. The target
component still contains the authority blob introduced by A16 commit
`0edb96a328b99742a8c3583e3d1aafc501308252`; publication remains subject to
provenance and redistribution authorization.

## Reviewed Equivalent Or Superseded Areas

### Root Payload Closure

A fresh root-owned file check at Android-16 root
`27488f4954b2c2fc81c7715969cf1439ff05de0f` found 290 A13 paths without the
same filesystem path in the target. Every path is assigned below; there is no
unclassified remainder.

| Paths | A13 area | Disposition |
| ---: | --- | --- |
| 155 | `external/arm-runtime` | Explicitly obsolete reference source; superseded by Houdini/native bridge |
| 104 | `hardware/intel/common/libva` | Replaced by current `external/libva`; driver path compatibility fixed and built |
| 15 | `packages/apps/BstFolder` | Build disabled in final A13; successor daemon later deleted |
| 10 | `hardware/qcom/{sdm845,sm7150,sm7250,sm8150,sm8150p}` | QCOM-only Android.bp/Android.mk selector symlinks; target board is `android-x86` |
| 2 | `hardware/intel/audio_media/hdmi` | Inactive `BOARD_USES_ALSA_AUDIO` module; product uses `audio.primary.bst` |
| 1 | `system/bstime/Android.mk` | Functionally replaced by tracked `Android.bp`; source and active module restored |
| 1 | root `Makefile` | Legacy `build/core/root.mk` convenience symlink; current `m` flow does not use it |
| 1 | `tools/bazel` | Legacy `build/bazel/bazel.sh` convenience symlink, not guest/product payload |
| 1 | empty root `README` | Zero-byte metadata only |

The check compares root-owned A13 paths against target filesystem presence, so
submodule content already present at the same path is not falsely counted.
Path absence is not treated as semantic absence when current build metadata or
a reviewed replacement provides the behavior.

- `external/boringssl`: A13 RSA-PSS Widevine wrappers are present in the A16
  decrepit RSA implementation. Vendor self-test rc registration is already
  absent; no code change is required.
- `external/icu`: current tzdata `2025b` already ends the Tehran transition at
  the required 2022 boundary. The A13 hand-edited timezone workaround must not
  override current authoritative data.
- `device/google/cuttlefish`: the 36 A13 deleted Cuttlefish APEX files are
  already absent upstream in A16.
- `hardware/bst/{audio,camera,lights,memtrack,power}`: product C/C++ sources are
  exact or high-coverage A16 adaptations; build metadata differs only where
  Soong/header migration requires it.
- `packages/apps/BstFolder`: not an active A13 product module. Authority commit
  `389d5dbd065a9ef3cb20b7ffaafffd0e76419438` renamed its build file to
  `Android.mk.orig` while moving behavior to `bstfolderd`; commit `f619dd04`
  later removed that daemon. The final A13 and A16 trees instead carry
  byte-identical `external/bluestacks/bstfolder` native helpers. Restoring the
  disabled APK would reintroduce superseded property polling and Binder code.
- `hardware/intel/audio_media/hdmi`: gated by `BOARD_USES_ALSA_AUDIO=true`,
  which neither the A13 nor A16 `device/generic` product sets. Both products
  inherit `hardware/bst/audio/alsa.mk` and build `audio.primary.bst`; the unused
  Intel HDMI HAL is not promoted.
- `external/arm-runtime`: its only build file is `Android.mk.bak`, introduced by
  A13 commit `6864ee09` as an explicitly obsolete reference. Android-16 uses the
  reviewed Houdini/native-bridge integration instead of reviving this QEMU-era
  translator.
- `.github` deletion, deinitialized third-party links and bulk external sync
  commits are repository hygiene, not guest runtime patches.

## Required Next Gates

1. Stage and package only the successful root
   `9ae09dd212ac1ecedfa7e41782e92d8f7a640d24`, with identity-bound hashes.
2. Run Windows boot, FPS, network-presentation, captive-portal, SELinux and
   entropy readback oracles.
3. Run focused IME, shared-folder, camera, audio, fake-Wi-Fi and Widevine
   runtime oracles that are not covered by a 7/7 boot result.
4. Resolve the 15 publication-topology errors and verify remote SHA
   reachability before any
   push or replacement PR.

No current commit is eligible for publication or completion claims until these
gates pass.
