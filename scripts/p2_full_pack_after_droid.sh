#!/bin/bash
# Full G1 pack pipeline AFTER m droid: libs → stage(OUT fold) → apks → r228
set -uo pipefail
LOG=~/p2_full_pack_after_droid.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:full pack after droid start $(date -Is)"
bash ~/bst-aosp/scripts/g1_build_libs.sh
rc=$?
echo "A16DBG:P2:build_libs rc=$rc"
[ "$rc" -eq 0 ] || echo "WARN: build_libs non-zero — continue pack anyway"
bash ~/bst-aosp/scripts/g1_stage_system.sh
bash ~/bst-aosp/scripts/g1_copy_bst_apks.sh
bash ~/r228-pack-root.sh
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
echo "A16DBG:P2:full pack after droid DONE $(date -Is)"
