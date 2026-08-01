#!/bin/bash
# G1: stage OUT android_x86_64/system/ (fold: vendor/system_ext/product) → releases/Baklava64/system
# Per G1-RESTORE §2: rsync OUT directory — do NOT mount system.img (loses folded subdirs).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/android16_env.sh"
bst_android16_preflight
AOSP="$BST_ANDROID16_ROOT"
OD="$BST_RELEASE_ROOT"
SRC="$AOSP/$BST_OUT_DIR_NAME/target/product/x86_64/system"
SYSTEM_IMG="$AOSP/$BST_OUT_DIR_NAME/target/product/x86_64/system.img"
[ -d "$SRC" ] || { echo "missing staged source directory: $SRC" >&2; exit 1; }
bst_verify_identity_file "$BST_BUILD_IDENTITY_FILE" "$SYSTEM_IMG"
[ "${1:-}" != "--check" ] || {
  echo "A16DBG:ANDROID16: stage CHECK OK; build identity verified; no files copied"
  exit 0
}
LOG=~/g1_stage_system.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: stage-system start $(date -Is) (OUT dir fold, not system.img mount)"
[ -d "$SRC" ] || { echo "missing $SRC"; exit 1; }
[ -f "$SRC/build.prop" ] || { echo "missing $SRC/build.prop"; exit 1; }

mkdir -p "$OD/system"
echo "staging from $SRC ($(du -sh "$SRC" | awk '{print $1}'))"
# Prefer rsync without sudo if we own OUT; fall back to sudo for mixed perms
if [ -w "$SRC/build.prop" ] && [ -w "$OD" ]; then
  rsync -a --delete --numeric-ids "$SRC"/ "$OD/system/"
else
  sudo rsync -a --delete --numeric-ids "$SRC"/ "$OD/system/"
  sudo chown -R "$(id -u):$(id -g)" "$OD/system"
fi

echo "A16DBG:G1: staged system bytes=$(du -sb "$OD/system" | awk '{print $1}')"
echo "A16DBG:G1: fold readback:"
echo -n "  vendor files="; find "$OD/system/vendor" -type f 2>/dev/null | wc -l
echo -n "  system_ext files="; find "$OD/system/system_ext" -type f 2>/dev/null | wc -l
echo -n "  product files="; find "$OD/system/product" -type f 2>/dev/null | wc -l
ls -la "$OD/system/build.prop" "$OD/system/vendor/bin/vndservicemanager" 2>/dev/null | head -5
grep -E 'ro.product.device|ro.product.name|ro.hardware.gralloc|ro.hardware.egl' "$OD/system/build.prop" || true
test -f "$OD/system/vendor/bin/vndservicemanager" && echo "  vndservicemanager OK" || echo "  WARN: vndservicemanager missing (m droid fold incomplete?)"
echo "A16DBG:G1: stage-system DONE"
bst_write_identity_file "$OD/system.identity" "$SYSTEM_IMG"
cat "$OD/system.identity"
