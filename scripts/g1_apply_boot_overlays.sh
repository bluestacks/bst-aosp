#!/bin/bash
# G1: after qvirt stage, re-apply M1 boot-proven overlays (HCALL + WMS + graphics).
# g1_stage_system.sh --delete wipes these; must run before every pack.
set -euo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
SYS="$OD/system"
ROOTED="$OD/rooted_system"
OUT_ROOT="$AOSP/out_nxt_Baklava64"
LOG=~/g1_apply_boot_overlays.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: apply-boot-overlays start $(date -Is)"

copy_if_src() {
  local src="$1" dst="$2"
  [ -f "$src" ] || { echo "  skip missing $src"; return 0; }
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  echo "  staged $(basename "$dst") <= $src"
  md5sum "$dst"
}

# 1) M1 patched services.jar (WMS ActivityDisplayed / launcher ready chain)
if [ -f "$ROOTED/framework/services.jar" ]; then
  copy_if_src "$ROOTED/framework/services.jar" "$SYS/framework/services.jar"
else
  echo "WARN: missing $ROOTED/framework/services.jar"
fi

# 1b) M1 hwservicemanager-on-/system overlay
copy_if_src "$ROOTED/bin/hwservicemanager" "$SYS/bin/hwservicemanager"
copy_if_src "$ROOTED/etc/init/hwservicemanager.rc" "$SYS/etc/init/hwservicemanager.rc"

# 1c) vndservicemanager (vendor servicemanager). It is `vendor: true` in
# frameworks/native/cmds/servicemanager/Android.bp, so `m systemimage` (system variant)
# never builds it. Without it every vendor HIDL HAL (composer/allocator/light/power/...)
# fails to register via /dev/vndbinder with UNKNOWN_ERROR (-2147483648) -> crash loop,
# boot never completes. Built standalone via `m vndservicemanager`; rc hardcodes
# /vendor/bin/vndservicemanager which maps to staged system/vendor/bin. (temp_debt: G9
# should bake this into the system product like M1 build_make does for hwservicemanager.)
VND_OUT="$OUT_ROOT/target/product/qvirt/system/vendor"
copy_if_src "$VND_OUT/bin/vndservicemanager"          "$SYS/vendor/bin/vndservicemanager"
copy_if_src "$VND_OUT/bin/vndservice"                 "$SYS/vendor/bin/vndservice"
copy_if_src "$VND_OUT/etc/init/vndservicemanager.rc"  "$SYS/vendor/etc/init/vndservicemanager.rc"
copy_if_src "$VND_OUT/etc/selinux/vndservice_contexts" "$SYS/vendor/etc/selinux/vndservice_contexts"

# 2) libhostcall_jni / libgcall_jni from out (M1 md5-known build artifacts).
# M1 product dir is generic_x86_64 (x86_64 may be a symlink); qvirt may not have rebuilt HCALL yet.
OUT_LIBS=(
  "$OUT_ROOT/target/product/generic_x86_64/system/lib64"
  "$OUT_ROOT/target/product/x86_64/system/lib64"
  "$OUT_ROOT/target/product/qvirt/system/lib64"
)
stage_lib() {
  local name="$1"
  local src=""
  for dir in "${OUT_LIBS[@]}" "$ROOTED/lib64"; do
    [ -f "$dir/$name" ] && src="$dir/$name" && break
  done
  if [ -n "$src" ]; then
    copy_if_src "$src" "$SYS/lib64/$name"
  else
    echo "ERROR: $name not found in out or rooted_system" >&2
    return 1
  fi
}
stage_lib libhostcall_jni.so
stage_lib libgcall_jni.so

# 3) Standard goldfish rebuild + stage (always; no skip / no VHD extract)
bash ~/bst-aosp/scripts/g1_rebuild_graphics.sh

echo "A16DBG:G1: overlay readback:"
for f in framework/services.jar lib64/libgcall_jni.so lib64/libhostcall_jni.so \
         bin/hwservicemanager etc/init/hwservicemanager.rc \
         vendor/bin/vndservicemanager vendor/bin/vndservice \
         vendor/etc/init/vndservicemanager.rc \
         vendor/lib64/egl/libEGL_emulation.so \
         vendor/lib64/hw/gralloc.bst.so vendor/lib64/hw/hwcomposer.default.so; do
  ls -la "$SYS/$f" 2>/dev/null || echo "  MISSING $f"
done
grep -E 'ro.hardware.(gralloc|egl)|ro.product.system.(device|name)' "$SYS/build.prop" 2>/dev/null || true
echo "A16DBG:G1: apply-boot-overlays DONE $(date -Is)"
