#!/bin/bash
# R247: Henry 7X-2 installd early start in init.rc → repack Root.vhd
set -eo pipefail
OD=~/releases/Baklava64
LOG=~/r247-pack-root.log
exec > >(tee "$LOG") 2>&1
echo "=== R247 pack $(date) ==="

python3 ~/bst-aosp/scripts/r247-patch-init-installd.py "$OD/system/etc/init/hw/init.rc"
grep -n 'R247 / Henry 7X-2' "$OD/system/etc/init/hw/init.rc"

bash ~/r228-pack-root.sh
echo R247_PACK_DONE
