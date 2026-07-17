#!/bin/bash
# G1 pack (m droid path — NO overlays).
#   g1_build.sh      → m droid (system + vendor/system_ext/product folded into OUT dir)
#   g1_build_libs.sh  → hd guest native libs + goldfish (built into OUT dir via mmm)
#   g1_stage_system.sh → rsync OUT system/ dir → releases/Baklava64/system (the fold)
#   r228-pack-root.sh → make-baklava-system-sfs + Root.fs + create_vdi + clonehd → Root.vhd
#
# Overlays (g1_apply_boot_overlays.sh, g1_fold_m1.sh) are REMOVED — all content comes
# from the build (m droid + hostcall_gcall_libs + goldfish) OR the OUT tree.
# BST tools / launcher APKs (buildscripts Root.vdi recipe lines 152-189) will be
# restored later from BSTTOOLS/apks sources, not from M1 overlays.
set -euo pipefail
LOG=~/g1_pack_mdroid.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: pack-root (m droid, no overlays) start $(date -Is)"

# 0) sanity: system.img exists
IMG=~/aosp16/out_nxt_Baklava64/target/product/qvirt/system.img
[ -f "$IMG" ] || { echo "ERROR: $IMG missing — run g1_build.sh first"; exit 1; }

bash ~/g1_stage_system.sh
# ★ M1-reference content fold (temp_debt: G9 formal fix = buildscripts packaging + build-config adaptation).
# These 165 files (vendor VINTF manifests, system_ext HIDL allocator, launcher, BST tools) are
# in M1's bootable image but NOT produced by G1's `m droid` for `bst_x86_64/qvirt`. Without them
# vendor HALs crash (updatable_crashing loop → no boot_completed). Source: M1 r262b system.img.
# G9 fix: either (a) make the bst_x86_64 build produce them (product config adapt), OR
# (b) port the buildscripts packaging steps (apks, BST tool copies, vintf fragment assembly).
# See G1.md §T1 item A8-A9 + G1-m1-diff-missing.txt.
bash ~/bst-aosp/scripts/g1_fold_m1.sh
bash ~/r228-pack-root.sh

VHD=~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
md5sum "$VHD" ~/releases/Baklava64/system.sfs "$IMG"
echo "A16DBG:G1: pack-root (m droid, no overlays) DONE $(date -Is)"
