#!/bin/bash
# 远程 aosp16 各 dirty project git commit(合规:正式/temp_debt + A16DBG + BST 溯源 + 可恢复)
# 每个 commit 与本地 bst-aosp patch 一致(干净 aosp git apply 可恢复)。
set -uo pipefail
cd ~/aosp16
A=" patches/android-16/patches/ (git apply on clean aosp16.0.0_r4).\n\nCo-Authored-By: Claude <noreply@anthropic.com>"

commit_proj() {
  local dir="$1" mid="$2" tempdeb="$3" src="$4" a16dbg="$5" key="$6" patch="$7"
  if [ ! -d "$dir" ]; then echo "SKIP $dir (no dir)"; return; fi
  cd ~/aosp16/$dir
  # skip if nothing to commit
  if git diff --quiet HEAD 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "SKIP $dir (clean)"; cd ~/aosp16; return
  fi
  git add -A
  msg="BlueStacks android-16 (aosp16) port: $dir

Source: $src. $tempdeb
Key change: $key
A16DBG 打点: $a16dbg
Verification: Layer1 build + Layer2 boot to launcher (G1 Phase 1, porting-log cont.4/cont.5).
Restorable via bst-aosp/$patch (git apply on clean aosp16.0.0_r4).

Co-Authored-By: Claude <noreply@anthropic.com>"
  git commit -q -m "$msg" && echo "COMMIT $dir ($(git rev-parse --short HEAD))" || echo "FAIL $dir"
  cd ~/aosp16
}

commit_proj system/hwservicemanager hwsm "TEMP_DEBT: service.cpp if(false) DIAG bypass (A16 hwsm self-disable on getTransport==EMPTY); Phase 2 fix = device manifest target-level (VINTF level patch runtime-insufficient at target-level=legacy)." "G1 Phase 1 (2026-07) + BST -a13 fork" "yes (A16DBG:HWSM transport outside dead branch)" "hwsm install /system (Android.bp rc /system/bin + service.cpp DIAG). PRODUCT_PACKAGES driven from device/bst/qvirt/bst_x86_64.mk" "patches/android-16/patches/aosp16__system_hwservicemanager.patch"

commit_proj system/libhidl vintf "FORMAL build-time (framework manifest hidl.manager/allocator/token max-level=8). NOTE: runtime INSUFFICIENT — device target-level=legacy filters it; service.cpp DIAG is the runtime mechanism." "G1 Phase 1 (2026-07)" "no (data file)" "framework vintfdata/manifest.xml +3 HIDL hal declarations (build-time check_vintf_all pass)" "patches/android-16/patches/aosp16__system_libhidl_vintf.patch"

commit_proj build/make bldmk "FORMAL (hwsm system_ext->/system migration; Root.vhd has no system_ext). NOTE: system_image_defaults hwsm dep redundant (actual build driven by PRODUCT_PACKAGES in bst_x86_64.mk)." "BST -a13 fork + G1" "no (build-time)" "core/* + target/product/* hwsm migration + PRODUCT_ENFORCE_VINTF_MANIFEST=false" "patches/android-16/patches/aosp16__build_make.patch"

commit_proj frameworks/base fwbase "TEMP_DEBT: r262 disable shell transitions (BLAST commit callback; Phase 2 P2-TEMP-BLAST) + SystemServer HAL skip (memtrack/power/gatekeeper)." "BST -a13 fork (R248-R261) + G1" "yes (A16DBG:FwBase-HALSkip memtrack/power)" "BstHostCall/FilterApps BST services + r262 shell transitions off + SystemServer HAL skip" "patches/android-16/patches/aosp16__frameworks_base.patch"

commit_proj frameworks/native fwnat "FORMAL." "BST -a13 fork" "no" "RTVboxMM manual binder + delete vulkan/nulldrv Android.bp" "patches/android-16/patches/aosp16__frameworks_native.patch"

commit_proj system/core syscore "TEMP_DEBT: SELinux permissive (IsEnforcing=false) + first-stage mount skip + cgroup skip. Phase 2 = BST sepolicy enforcing." "BST -a13 fork (R173/R247/R260)" "yes (9: A16DBG coldboot/ueventd)" "first-stage mount skip + CheckMacPerms bypass + SELinux permissive + cgroup" "patches/android-16/patches/aosp16__system_core.patch"

commit_proj system/security syssec "TEMP_DEBT: keystore EarlyBootEnded permission bypass (TODO restore). Phase 2 = restore check." "BST -a13 fork" "yes (A16DBG:SEC-EARLYBOOT-BYPASS)" "keystore2 maintenance.rs EarlyBootEnded bypass" "patches/android-16/patches/aosp16__system_security.patch"

commit_proj art art "TEMP_DEBT: ZygoteVerificationTask skip null APEX dex_cache (TODO restore). Phase 2 = restore." "BST -a13 fork" "yes (A16DBG:ART-DEXCACHE-SKIP)" "jit.cc null dex_cache skip" "patches/android-16/patches/aosp16__art.patch"

commit_proj hardware/interfaces hwif "FORMAL." "BST -a13 fork" "no" "gnss/memtrack default service disabled: false" "patches/android-16/patches/aosp16__hardware_interfaces.patch"

commit_proj hardware/libhardware hwlh "FORMAL." "BST -a13 fork" "no" "gralloc.default/hwcomposer.default .bp disabled (use gralloc.bst/hwcomposer from goldfish)" "patches/android-16/patches/aosp16__hardware_libhardware.patch"

commit_proj hardware/google/aemu aemu "FORMAL." "BST -a13 fork" "no" "gfxstream_defaults disabled (conflict with goldfish modules)" "patches/android-16/patches/aosp16__hardware_google_aemu.patch"

commit_proj build/soong soong "FORMAL." "BST -a13 fork" "no" "allowlist + external Android.mk finder (hd/ggl)" "patches/android-16/patches/aosp16__build_soong.patch"

commit_proj external/boringssl bssl "FORMAL." "BST -a13 fork" "no" "init_rc disabled (no 32-bit bringup)" "patches/android-16/patches/aosp16__external_boringssl.patch"

commit_proj packages/apps/Launcher3 lch "FORMAL (BST product customization)." "BST -a13 fork (R256/R257)" "no" "HOME removal + Overview hardcode + NPE guard" "patches/android-16/patches/aosp16__packages_apps_Launcher3.patch"

commit_proj device/generic/common dgcommon "FORMAL (BST device overlay: init.sh/init.x86.rc/manifest/bst_bins/nativebridge/media). NOTE: should migrate to device/bst/qvirt (Phase 2 structural debt)." "BST -a13 fork (android-x86 overlay)" "no" "bdroid_buildcfg + BST overlay (init/ueventd/manifest/VINTF/bst_bins/etc)" "patches/android-16/patches/aosp16__device_generic_common.patch + untracked-src/"

commit_proj device/generic/x86_64 dgx86 "FORMAL." "BST -a13 fork" "no" "android_x86_64 product + include common BoardConfig" "patches/android-16/patches/aosp16__device_generic_x86_64.patch"

commit_proj device/generic/goldfish dggold "FORMAL." "BST -a13 fork" "no" "hwservicemanager remove + graphics manifest" "patches/android-16/patches/aosp16__device_generic_goldfish.patch"

echo "=== ALL DONE ==="
