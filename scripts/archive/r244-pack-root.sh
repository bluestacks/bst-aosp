#!/bin/bash
# R244: pack Root.vhd with Henry-path init (FC-aware sfs + r228)
set -eo pipefail
OD=~/releases/Baklava64
LOG=~/r244-pack.log
exec > >(tee "$LOG") 2>&1
echo "=== R244 pack $(date) ==="
md5sum "$OD/system/bin/init"
strings "$OD/system/bin/init" | grep -E 'R174 skip odsign|R174 skip init_user0|R173 skip wait_for_coldboot|skip exec \(vdc\)|R173h skip critical' \
  && { echo STRINGS_FAIL; exit 2; } || echo STRINGS_OK

# Ensure FC-aware make-baklava is in buildscripts
cp -a ~/make-baklava-system-sfs.sh ~/app-player/buildscripts/make-baklava-system-sfs.sh
sed -i 's/\r$//' ~/app-player/buildscripts/make-baklava-system-sfs.sh

bash ~/r228-pack-root.sh
echo "=== pack outputs ==="
md5sum "$OD/system.sfs" "$OD/bst-v5.22.210_Baklava64-local/Root.vhd" 2>/dev/null || \
  md5sum "$OD"/bst-v5.22.210_Baklava64-local/Root.vhd
ls -la "$OD"/bst-v5.22.210_Baklava64-local/Root.vhd
echo PACK_DONE
