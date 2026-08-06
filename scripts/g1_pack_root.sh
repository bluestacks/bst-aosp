#!/bin/bash
# Pack a Root.vhd from the promoted Android-16 tree and bind it to source identity.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/android16_env.sh"
bst_android16_preflight
ROOT_PACK_SCRIPT="${BST_ROOT_PACK_SCRIPT:-$HOME/r228-pack-root.sh}"
if [ "${1:-}" = "--check" ]; then
  [ -x "$ROOT_PACK_SCRIPT" ] || [ -f "$ROOT_PACK_SCRIPT" ] || {
    echo "missing root pack script: $ROOT_PACK_SCRIPT" >&2
    exit 1
  }
  bash "$SCRIPT_DIR/g1_stage_system.sh" --check
  bash "$SCRIPT_DIR/g1_copy_bst_apks.sh" --check
  bash "$SCRIPT_DIR/g1_apply_boot_overlays.sh" --check
  bash "$SCRIPT_DIR/g8_disable_vendor_hal_rc.sh" --check
  echo "A16DBG:ANDROID16: pack CHECK OK; no files copied or packed"
  exit 0
fi
LOG=~/g1_pack_root.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: pack-root start $(date -Is)"
bash "$SCRIPT_DIR/g1_stage_system.sh"
bash "$SCRIPT_DIR/g1_copy_bst_apks.sh"
bash "$SCRIPT_DIR/g1_apply_boot_overlays.sh"
bash "$SCRIPT_DIR/g8_disable_vendor_hal_rc.sh"
STAGED_SYSTEM="$BST_RELEASE_ROOT/system"
[ -x "$STAGED_SYSTEM/bin/mountsf" ] || {
  echo "release staging is missing app-player payload bin/mountsf" >&2
  echo "run g1_build_app_player.sh for a release-complete Android-16 package" >&2
  exit 1
}
grep -q '^ro.build.display.id=BlueStacks-' "$STAGED_SYSTEM/build.prop" || {
  echo "release staging is missing the app-player BlueStacks build identity" >&2
  echo "run g1_build_app_player.sh for a release-complete Android-16 package" >&2
  exit 1
}
PACK_HOST_TOOLS="$BST_ANDROID16_ROOT/$BST_OUT_DIR_NAME/host/linux-x86/bin"
MKUSERIMG="$PACK_HOST_TOOLS/mkuserimg_mke2fs"
SIMG2IMG="$PACK_HOST_TOOLS/simg2img"
[ -x "$MKUSERIMG" ] || { echo "missing target-built pack tool: $MKUSERIMG" >&2; exit 1; }
[ -x "$SIMG2IMG" ] || { echo "missing target-built pack tool: $SIMG2IMG" >&2; exit 1; }
AOSP="$BST_ANDROID16_ROOT" MKUSERIMG="$MKUSERIMG" SIMG2IMG="$SIMG2IMG" \
  bash "$ROOT_PACK_SCRIPT"
VHD="$BST_RELEASE_ROOT/bst-v5.22.210_Baklava64-local/Root.vhd"
SYSTEM_IMG="$BST_ANDROID16_ROOT/$BST_OUT_DIR_NAME/target/product/x86_64/system.img"
[ -f "$VHD" ] || { echo "missing packed Root.vhd: $VHD" >&2; exit 1; }
md5sum "$VHD" "$BST_RELEASE_ROOT/system.sfs" "$SYSTEM_IMG"
sha256sum "$VHD" "$BST_RELEASE_ROOT/system.sfs" "$SYSTEM_IMG"
bst_write_identity_file "$VHD.identity" "$VHD"
{
  printf 'system_img_sha256=%s\n' "$(sha256sum "$SYSTEM_IMG" | awk '{print $1}')"
  printf 'system_sfs_sha256=%s\n' "$(sha256sum "$BST_RELEASE_ROOT/system.sfs" | awk '{print $1}')"
} >> "$VHD.identity"
cat "$VHD.identity"
echo "A16DBG:G1: pack-root DONE $(date -Is)"
