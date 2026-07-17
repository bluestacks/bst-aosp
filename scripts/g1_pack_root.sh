#!/bin/bash
# G1: pack Root.vhd from staged system (Layer2 oracle input)
set -euo pipefail
LOG=~/g1_pack_root.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: pack-root start $(date -Is)"
bash ~/g1_stage_system.sh
bash ~/bst-aosp/scripts/g1_apply_boot_overlays.sh
bash ~/bst-aosp/scripts/g8_disable_vendor_hal_rc.sh
bash ~/r228-pack-root.sh
VHD=~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
md5sum "$VHD" ~/releases/Baklava64/system.sfs ~/aosp16/out_nxt_Baklava64/target/product/qvirt/system.img
echo "A16DBG:G1: pack-root DONE $(date -Is)"
