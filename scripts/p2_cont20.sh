#!/bin/bash
# P2 cont.20: metalava BstUtils + clean fw-base applies + bst_arm64 scaffold
set -euo pipefail
LOG=~/p2_cont20.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:cont20 start $(date -Is)"

A13_BASE=~/app-player/android-13/frameworks/base
A16_BASE=~/aosp16/frameworks/base
DEV=~/aosp16/device/bst/qvirt

# --- 1) BstUtils ---
python3 ~/bst-aosp/scripts/p2_bstutils_metalava.py
# rename any leftover callers
while IFS= read -r f; do
  sed -i 's/BstUtils\.GetCustomDpi/BstUtils.getCustomDpi/g' "$f"
  echo "renamed GetCustomDpi caller: $f"
done < <(rg -l 'BstUtils\.GetCustomDpi' ~/aosp16/frameworks/base --glob '*.java' 2>/dev/null || true)

# --- 2) More clean applies (check-only, no 3way) ---
CLASS=~/bst-aosp/patches/android-16/patches/p2-fw-classify/a13_base_files.txt
ok=0; skip=0
if [ -f "$CLASS" ]; then
  while IFS= read -r f; do
    case "$f" in
      core/java/android/util/BstUtils.java) continue ;;
      services/core/java/com/android/server/wm/WindowManagerService.java) continue ;;
      services/core/java/com/android/server/wm/DisplayRotation.java) continue ;;
      services/core/java/com/android/server/wm/ActivityStarter.java) continue ;;
      cmds/pagefusion/*) continue ;;
      core/java/android/util/Features.java) continue ;;
      core/java/com/bluestacks/internal/*) continue ;;
      libs/hwui/*) continue ;;
      libs/WindowManager/Shell/*) continue ;;
    esac
    [ ! -f "$A16_BASE/$f" ] && continue
    ns=$(cd "$A13_BASE" && git diff --numstat android-13.0.0_r49..HEAD -- "$f" 2>/dev/null | awk '{print $1+$2}')
    [ -z "${ns:-}" ] && continue
    [ "$ns" -gt 200 ] && continue
    (cd "$A13_BASE" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/fw_one.patch
    if (cd "$A16_BASE" && git apply --check /tmp/fw_one.patch 2>/dev/null); then
      if (cd "$A16_BASE" && git apply /tmp/fw_one.patch 2>/dev/null); then
        echo "OK $f ns=$ns"
        ok=$((ok+1))
      else
        skip=$((skip+1))
      fi
    else
      skip=$((skip+1))
    fi
  done < "$CLASS"
fi
echo "clean apply ok=$ok skip=$skip"

# --- 3) bst_arm64 scaffold (do NOT rewrite bst_x86_64) ---
if [ ! -f "$DEV/bst_arm64.mk" ]; then
  cat > "$DEV/bst_arm64.mk" <<'EOF'
#
# BlueStacks unified board — arm64 product (mac path).
# Same device tree (qvirt) as bst_x86_64; arch differences live in BoardConfig.mk.
# Layer2 verification is win-first; this target is for mac same-code builds only.
#
$(warning A16DBG:G1: building unified board bst_arm64 (device=qvirt) mac-same-code)

# 64-bit + generic BST overlay (device.mk has bst_etc/bst_bins/HALs)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, device/generic/common/device.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic.mk)
$(call inherit-product-if-exists, frameworks/base/data/sounds/AudioPackage6.mk)

PRODUCT_NAME := bst_arm64
PRODUCT_BRAND := bst
PRODUCT_DEVICE := qvirt
PRODUCT_MODEL := bst_arm64 on QVIRT
PRODUCT_MANUFACTURER := bst

PRODUCT_PACKAGES += hwservicemanager
PRODUCT_ENFORCE_VINTF_MANIFEST := true
PRODUCT_PROPERTY_OVERRIDES += ro.hardware.gralloc=bst ro.hardware.egl=emulation
EOF
  echo "CREATED $DEV/bst_arm64.mk"
else
  echo "bst_arm64.mk already exists"
fi

# BoardConfig: dispatch by TARGET_PRODUCT
if ! grep -q 'bst_arm64' "$DEV/BoardConfig.mk" 2>/dev/null; then
  cat > "$DEV/BoardConfig.mk" <<'EOF'
#
# Copyright (C) 2026 The BlueStacks Project
#
# G1：qvirt 板配置。arch 按 TARGET_PRODUCT 分派（win bst_x86_64 / mac bst_arm64）。
#

ifneq ($(filter bst_arm64,$(TARGET_PRODUCT)),)
include device/generic/arm64/BoardConfig.mk
else
include device/generic/x86_64/BoardConfig.mk
endif
EOF
  echo "UPDATED BoardConfig.mk for arm64 dispatch"
else
  echo "BoardConfig already has bst_arm64 dispatch"
fi

# AndroidProducts
if ! grep -q 'bst_arm64' "$DEV/AndroidProducts.mk"; then
  # rewrite cleanly
  cat > "$DEV/AndroidProducts.mk" <<'EOF'
#
# Copyright (C) 2026 The BlueStacks Project
#
# 统一板 device/bst/qvirt：win bst_x86_64 + mac bst_arm64（同板、arch 下沉 BoardConfig）。
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/bst_x86_64.mk \
    $(LOCAL_DIR)/bst_arm64.mk

COMMON_LUNCH_CHOICES := \
    bst_x86_64-trunk_staging-eng \
    bst_x86_64-trunk_staging-user \
    bst_x86_64-trunk_staging-userdebug \
    bst_arm64-trunk_staging-eng \
    bst_arm64-trunk_staging-userdebug
EOF
  echo "UPDATED AndroidProducts.mk"
fi

# --- 4) metalava smoke: compile api stubs path that hits BstUtils ---
cd ~/aosp16
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:P2:cont20 metalava smoke m framework $(date -Is)"
# framework jar pulls metalava on public APIs including android.util
m framework -j24
rc=$?
echo "A16DBG:P2:cont20 framework rc=$rc $(date -Is)"

echo "=== device files ==="
ls -la "$DEV"
echo "=== base status (head) ==="
git -C "$A16_BASE" status --short | head -50
echo "A16DBG:P2:cont20 DONE rc=$rc $(date -Is)"
exit "$rc"
