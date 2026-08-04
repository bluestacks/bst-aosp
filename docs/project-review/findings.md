# Project Review Findings

> Generated findings are evidence-backed candidates. Historical failures remain first-class records and are not automatically rewritten.

## P0

Findings: **0**.

## P1

Findings: **0**.

## P2

Findings: **1**.

### `scripts/p2_mech2_apply.py`: Syntax or parse failure

- Status: `accepted-historical`
- Evidence: unexpected indent at line 20
- Action: Preserve the failed source; use `patches/android-16/patches/p2-framework-rest/P2-MECH-2-launcher3-manifest.diff` as the successful replacement.

## P3

Findings: **16**.

### `patches/android-16/a13-authority/frameworks-base/0161-A13-Pie-Android11-code-sync-change-includes-106.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 17 paths share SHA-256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855; 0 duplicate bytes. Related: `patches/android-16/patches/aosp16__art.status`, `patches/android-16/patches/aosp16__build_make.status`, `patches/android-16/patches/aosp16__build_soong.status`, `patches/android-16/patches/aosp16__device_generic_common.status`, `patches/android-16/patches/aosp16__device_generic_goldfish.status`, `patches/android-16/patches/aosp16__device_generic_x86_64.status`, `patches/android-16/patches/aosp16__external_boringssl.status`, `patches/android-16/patches/aosp16__frameworks_base.status`, `patches/android-16/patches/aosp16__frameworks_native.status`, `patches/android-16/patches/aosp16__hardware_google_aemu.status`, `patches/android-16/patches/aosp16__hardware_interfaces.status`, `patches/android-16/patches/aosp16__hardware_libhardware.status`, `patches/android-16/patches/aosp16__packages_apps_Launcher3.status`, `patches/android-16/patches/aosp16__system_core.status`, `patches/android-16/patches/aosp16__system_hwservicemanager.status`, `patches/android-16/patches/aosp16__system_security.status`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/bootimage/hd/guest/BootImage/bstsetconf.sh`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 76a2af292cd32b066f533f929b6c80cd7b38428d511b1d6653f17bb8a287d6b1; 7080 duplicate bytes. Related: `references/henry-hd-guest/BootImage/bstsetconf.sh`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/bootimage/hd/guest/Makefile`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 6dc3f5e29a8d60cd880f96927a6734ba05496481bfa23d68600b1d82b5c582b9; 288 duplicate bytes. Related: `references/henry-hd-guest/Makefile`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/patches/aosp16__frameworks_base.base`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 4 paths share SHA-256 1c7c79cf838f05e651cfc1bade886cc89cac8086553ab94c3478266049873537; 123 duplicate bytes. Related: `patches/android-16/patches/aosp16__frameworks_base__d8-subscription.base`, `patches/android-16/patches/aosp16__frameworks_base__pagefusion.base`, `patches/android-16/patches/aosp16__frameworks_base__r262-temp-disable-shell-transitions.base`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/patches/aosp16__frameworks_native.base`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d016563484fc61f973db5f39e266bafe45540197e985b363d5779755ebb9dd28; 41 duplicate bytes. Related: `patches/android-16/patches/aosp16__frameworks_native_libs_binder.base`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/idc/AlpsPS_2_ALPS_DualPoint_TouchPad.idc`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 4 paths share SHA-256 dc389a47bcba391441586bb7753a8fa22471cacdd4de8cd56092ebd63f71477a; 240 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/idc/AlpsPS_2_ALPS_GlidePoint.idc`, `patches/android-16/untracked-src/aosp16__device_generic_common/idc/ETPS_2_Elantech_Touchpad.idc`, `patches/android-16/untracked-src/aosp16__device_generic_common/idc/Microsoft_Surface_Type_Cover_UNKNOWN.idc`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/idc/QEMU_QEMU_USB_Tablet.idc`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f67464e53a848bc592dc6594df843dd88fbd459fc5c1ee8c9a4d510354144473; 28 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/idc/VirtualBox_USB_Tablet.idc`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/Android.mk`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 67bd463e443d2bb1b3d34a695f7a9b625a2db231a97c96df7d8b88611d9889cb; 663 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/Android.mk`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/OEMBlackList`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9332c71c704c5e0536078d5de88a87d2c6f28eaaa7f614756b0cc2afff4cf85e; 25 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/OEMBlackList`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/OEMWhiteList`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 39df4ac04bae7937aa64dc7ab6782d2f10e7a8a5c9ef4076fc6a89801bddbca9; 21 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/OEMWhiteList`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/ThirdPartySO`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f739d8c0018baee216c575707b793249121b4a4db4ef9208ed48e9b28994dea2; 3386 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/ThirdPartySO`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/libnb.cpp`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 af812312fc8abf0e27264730dcb52338df7ec3c75a8af352223cd542af35c087; 25812 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/libnb.cpp`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge.mk`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 faca38f67b3745a206c7fcbf811b3d78dfec5f3dea56462111dc8f00e990a727; 1167 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/nativebridge.mk`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__frameworks_base/core/java/android/util/BstUtils.java`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 22d0f9cbc2c3f876eff7cb9b1ac6b658fc876e6cf060f054327822e91a30c577; 3006 duplicate bytes. Related: `scripts/_ref_BstUtils_a16.java`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `references/henry-hd-guest/BootImage/init.sh`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 df335419be7d116fc93ee00b11b2c37f9399d5189e7f324a90d937b0f4630344; 9085 duplicate bytes. Related: `references/henry-hd-guest/init.sh`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `references/henry-hd-guest/BootImage/stage2.sh`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e57e6eb264e27959a387f2a51eb355fcca197215714830fd496d726dc7be9618; 2861 duplicate bytes. Related: `references/henry-hd-guest/stage2.sh`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.
