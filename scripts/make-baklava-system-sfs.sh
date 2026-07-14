#!/bin/bash
# Pack staged OUTPUTDIR/system -> system.img (ext4) -> system.sfs (henry / tiramisu layout)
# Applies SELinux file_contexts via e2fsdroid so vendor HALs get correct exec domains
# (without this, android.hardware.audio.service stays unlabeled → kernel domain →
#  HIDL register fails → audioserver FactoryHal null → SIGSEGV).
set -euo pipefail
OUTPUTDIR="${1:?OUTPUTDIR required}"
SYSTEM="$OUTPUTDIR/system"
AOSP="${AOSP:-$HOME/aosp16}"
MKUSERIMG="${MKUSERIMG:-$HOME/aosp16/out_nxt_Baklava64/host/linux-x86/bin/mkuserimg_mke2fs}"
[ -x "$MKUSERIMG" ] || MKUSERIMG="$HOME/aosp16/out/host/linux-x86/bin/mkuserimg_mke2fs"
[ -d "$SYSTEM" ] || { echo "missing $SYSTEM" >&2; exit 1; }
[ -x "$MKUSERIMG" ] || { echo "missing mkuserimg_mke2fs" >&2; exit 1; }

BYTES=$(du -sb "$SYSTEM" | awk '{print $1}')
SIZE=$(( BYTES * 120 / 100 + 67108864 ))
SIZE=$(( (SIZE + 4096 - 1) / 4096 * 4096 ))

# Minimal valid file_contexts for e2fsdroid:
# - /system root label (required by e2fsdroid -a /system)
# - plat vendor/system defaults from private/file_contexts (no board_api macros)
# - vendor_file_contexts from staged image (HAL exec labels)
FC_MERGED=$(mktemp)
SFS_STAGE=""
cleanup() {
  rm -f "$FC_MERGED"
  [ -n "${SFS_STAGE:-}" ] && rm -rf "$SFS_STAGE"
}
trap cleanup EXIT

{
  echo '/system		u:object_r:system_file:s0'
  echo '/system(/.*)?		u:object_r:system_file:s0'
  echo '/(vendor|system/vendor)(/.*)?                  u:object_r:vendor_file:s0'
  # Filter plat contexts: drop comments, empty lines, and board_api macro blocks
  if [ -f "$AOSP/system/sepolicy/private/file_contexts" ]; then
    awk '
      /^[[:space:]]*#/ { next }
      /^[[:space:]]*$/ { next }
      /starting_at_board_api/ { skip=1; next }
      skip && /^'\''\)/ { skip=0; next }
      skip { next }
      /`/ { next }
      { print }
    ' "$AOSP/system/sepolicy/private/file_contexts"
  fi
  VFC="$SYSTEM/vendor/etc/selinux/vendor_file_contexts"
  if [ -f "$VFC" ]; then
    grep -v '^[[:space:]]*#' "$VFC" | grep -v '^[[:space:]]*$' || true
  fi
} > "$FC_MERGED"
[ -s "$FC_MERGED" ] || { echo "empty file_contexts" >&2; exit 1; }
echo "make-baklava-system-sfs: file_contexts lines=$(wc -l < "$FC_MERGED") bytes=$BYTES img_size=$SIZE"

rm -f "$OUTPUTDIR/system.img" "$OUTPUTDIR/system.sfs" "$OUTPUTDIR/system.sparse.img"
"$MKUSERIMG" -s "$SYSTEM" "$OUTPUTDIR/system.sparse.img" ext4 system "$SIZE" "$FC_MERGED"
SIMG2IMG="${SIMG2IMG:-$HOME/aosp16/out_nxt_Baklava64/host/linux-x86/bin/simg2img}"
[ -x "$SIMG2IMG" ] || SIMG2IMG="$HOME/aosp16/out/host/linux-x86/bin/simg2img"
"$SIMG2IMG" "$OUTPUTDIR/system.sparse.img" "$OUTPUTDIR/system.img"
rm -f "$OUTPUTDIR/system.sparse.img"

# Verify audio.service got the right label
TMP=$(mktemp -d)
if sudo mount -o loop,ro "$OUTPUTDIR/system.img" "$TMP"; then
  if command -v getfattr >/dev/null; then
    getfattr -n security.selinux --only-values \
      "$TMP/vendor/bin/hw/android.hardware.audio.service" 2>/dev/null \
      | tee /dev/stderr | grep -q 'hal_audio_default_exec' \
      && echo "SELINUX_OK: audio.service=hal_audio_default_exec" \
      || echo "SELINUX_WARN: audio.service label missing/wrong" >&2
  fi
  sudo umount "$TMP"
fi
rmdir "$TMP" 2>/dev/null || true

SFS_STAGE=$(mktemp -d)
cp -a "$OUTPUTDIR/system.img" "$SFS_STAGE/system.img"
mksquashfs "$SFS_STAGE" "$OUTPUTDIR/system.sfs" -noappend -comp gzip
ls -la "$OUTPUTDIR/system.img" "$OUTPUTDIR/system.sfs"
echo SYSTEM_SFS_DONE
