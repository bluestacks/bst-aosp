#!/bin/bash
# cont.22 authoritative pack after m droid:
# stage OUT fold → BST apks → make system.sfs → pack_fast (VDI without dirsync)
set -uo pipefail
LOG=~/p2_cont22_pack.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:cont22 pack start $(date -Is)"

# g1_build_stable already did goldfish mmm; libs script is still part of G1 authority
if [ -x ~/bst-aosp/scripts/g1_build_libs.sh ]; then
  bash ~/bst-aosp/scripts/g1_build_libs.sh || echo "WARN: build_libs rc=$?"
fi

bash ~/bst-aosp/scripts/g1_stage_system.sh
bash ~/bst-aosp/scripts/g1_copy_bst_apks.sh

# rebuild system.sfs from staged $OD/system (pack_fast alone reuses stale sfs — wrong)
OD=~/releases/Baklava64
BS=~/app-player/buildscripts
bash -x "$BS/make-baklava-system-sfs.sh" "$OD"
md5sum "$OD/system.sfs"
# verify power HAL landed in staged tree
echo "A16DBG:P2: power HAL readback:"
ls -la "$OD/system/vendor/bin/hw/android.hardware.power-service.example" 2>/dev/null \
  || ls -la "$OD/system/bin/hw/android.hardware.power-service.example" 2>/dev/null \
  || echo "WARN: power-service.example NOT in staged system"
rg -n 'ENABLE_SHELL_TRANSITIONS' ~/aosp16/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java | head -3

bash ~/bst-aosp/scripts/p2_cont21_pack_fast.sh
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
echo "A16DBG:P2:cont22 pack DONE $(date -Is)"
