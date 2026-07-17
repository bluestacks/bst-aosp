#!/bin/bash
# G1: fold M1-specific content into staged system that the OUT qvirt/system/ build lacks.
# M1's image = Henry's manual assembly (BST tools, composer/allocator VINTF manifests,
# system_ext HIDL allocator, launcher, HAL rcs, power_supply, etc. — the 165-file M1-vs-G1
# diff at patches/android-16/checkpoints/G1-m1-diff-missing.txt). Source = M1 system.img
# (extracted to /tmp/m1_sfs/system.img). Complements g1_stage_system.sh (OUT-dir fold).
set -euo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
SYS="$OD/system"
M1_IMG=/tmp/m1_sfs/system.img
MISSING=/tmp/missing_in_g1.txt
LOG=~/g1_fold_m1.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: fold-m1 start $(date -Is)"

# Ensure M1 system.img is extracted
if [ ! -f "$M1_IMG" ]; then
  echo "extracting M1 system.sfs -> system.img"
  M1_SFS=/tmp/m1_system.sfs
  [ -f "$M1_SFS" ] || { echo "missing $M1_SFS (re-extract from M1 Root.vhd)"; exit 1; }
  rm -rf /tmp/m1_sfs; mkdir -p /tmp/m1_sfs
  sudo unsquashfs -d /tmp/m1_sfs -f "$M1_SFS" >/dev/null
fi
[ -f "$MISSING" ] || { echo "missing $MISSING"; exit 1; }

M=$(mktemp -d)
sudo mount -o ro,loop "$M1_IMG" "$M"
MR="$M"; [ -d "$M/system" ] && MR="$M/system"

n=0; fail=0
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  if sudo test -e "$MR/$rel"; then
    sudo mkdir -p "$(dirname "$SYS/$rel")"
    sudo cp -a "$MR/$rel" "$SYS/$rel" && n=$((n+1)) || fail=$((fail+1))
  else
    fail=$((fail+1))
  fi
done < "$MISSING"

sudo umount "$M" 2>/dev/null || true; rmdir "$M" 2>/dev/null || true
# e2fsdroid (make-baklava-system-sfs) runs as the build user; chown so it can read all files
sudo chown -R "$(id -u):$(id -g)" "$SYS"
echo "A16DBG:G1: fold-m1 copied=$n failed=$fail"
echo "A16DBG:G1: fold-m1 DONE $(date -Is)"
