#!/bin/bash
# G1 equivalence readback: dump product config vars for android_x86_64 vs bst_x86_64,
# prove bst_x86_64 (unified board) == booted android_x86_64 modulo identity strings.
set -e
cd ~/aosp16
export ALLOW_MISSING_DEPENDENCIES=true OUT_DIR=out_nxt_Baklava64 APP_PLAYER_DIR=~/app-player BST_BUILD_WITH_DEXPREOPT=true
VARS="PRODUCT_PACKAGES PRODUCT_COPY_FILES PRODUCT_PACKAGES_DEBUG DEVICE_MANIFEST_FILE BOARD_SEPOLICY_DIRS TARGET_ARCH TARGET_2ND_ARCH PRODUCT_CHARACTERISTICS DEVICE_PACKAGE_OVERLAYS BOARD_KERNEL_CMDLINE"
dump() {
  local prod="$1" out="$2"
  build/soong/soong_ui.bash --dumpvars-mode \
    --abs-vars="$VARS" > "$out" 2>/dev/null || \
  TARGET_PRODUCT="$prod" TARGET_BUILD_VARIANT=eng \
    build/soong/soong_ui.bash --dumpvars-mode --vars="$VARS" > "$out" 2>/dev/null
}
# soong dumpvars uses TARGET_PRODUCT env
TARGET_PRODUCT=android_x86_64 TARGET_RELEASE=trunk_staging TARGET_BUILD_VARIANT=eng build/soong/soong_ui.bash --dumpvars-mode --vars="$VARS" > /tmp/g1_android.txt 2>/tmp/g1_android.err
TARGET_PRODUCT=bst_x86_64    TARGET_RELEASE=trunk_staging TARGET_BUILD_VARIANT=eng build/soong/soong_ui.bash --dumpvars-mode --vars="$VARS" > /tmp/g1_bst.txt     2>/tmp/g1_bst.err
echo "=== android_x86_64 lines: $(wc -l < /tmp/g1_android.txt)  bst_x86_64 lines: $(wc -l < /tmp/g1_bst.txt) ==="
echo "=== DIFF (expect empty for equivalence) ==="
diff /tmp/g1_android.txt /tmp/g1_bst.txt && echo "EQUIVALENT: config-level identical" || echo "DIFFERENCES ABOVE"
