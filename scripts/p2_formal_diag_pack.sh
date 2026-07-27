#!/bin/bash
# Phase2 P0 verify pack: DO NOT re-stage / apply M1 overlays / g8.
# Preserves staged: hwservicemanager (no DIAG) + vendor manifest target-level=8
# + launcher apk + gralloc=bst already in build.prop.
set -euo pipefail
LOG=~/p2_diag_pack_$(date +%Y%m%d-%H%M%S).log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2: pack-minimal start $(date -Is) log=$LOG"

STAGE=~/releases/Baklava64/system
test -f "$STAGE/bin/hwservicemanager"
test -f "$STAGE/vendor/etc/vintf/manifest.xml"
md5sum "$STAGE/bin/hwservicemanager"
grep target-level "$STAGE/vendor/etc/vintf/manifest.xml" | head -1
grep -E 'ro.hardware.gralloc|ro.hardware.egl' "$STAGE/build.prop"
test -f "$STAGE/priv-app/com.uncube.launcher3/com.uncube.launcher3.apk"

# Ensure target-level still 8 (idempotent)
sed -i 's/target-level="legacy"/target-level="8"/' "$STAGE/vendor/etc/vintf/manifest.xml"
grep target-level "$STAGE/vendor/etc/vintf/manifest.xml" | head -1

# Free any stale nbd before create_vdi
for n in /dev/nbd*; do
  sudo qemu-nbd -d "$n" 2>/dev/null || true
done
sleep 2

bash ~/r228-pack-root.sh
rc=$?
VHD=~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
ls -la "$VHD"
md5sum "$VHD"
echo "A16DBG:P2: pack-minimal DONE rc=$rc $(date -Is) log=$LOG"
