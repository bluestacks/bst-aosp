#!/bin/bash
# G1: after android_x86_64 stage, add target-built HD JNI and graphics artifacts.
# Product-owned framework and service-manager files must already come from this
# Android-16 build; do not replace them with an older rooted-system snapshot.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/android16_env.sh"
bst_android16_preflight
[ "${1:-}" != "--check" ] || {
  echo "A16DBG:ANDROID16: overlays CHECK OK; no files copied"
  exit 0
}
AOSP="$BST_ANDROID16_ROOT"
OD="$BST_RELEASE_ROOT"
SYS="$OD/system"
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

# 1) Product-owned boot files must survive the OUT fold unchanged. These
# checks prevent a stale release snapshot from masking an incomplete product.
for required in \
  framework/services.jar \
  system_ext/bin/hwservicemanager \
  system_ext/etc/init/hwservicemanager.rc \
  vendor/bin/vndservicemanager \
  vendor/bin/vndservice \
  vendor/etc/init/vndservicemanager.rc \
  vendor/etc/selinux/vndservice_contexts; do
  [ -f "$SYS/$required" ] || {
    echo "ERROR: target-built product file is missing: $SYS/$required" >&2
    exit 1
  }
done
[ -L "$SYS/bin/hwservicemanager" ] &&
  [ "$(readlink "$SYS/bin/hwservicemanager")" = "/system/system_ext/bin/hwservicemanager" ] || {
    echo "ERROR: Android 16 hwservicemanager compatibility symlink is missing or invalid" >&2
    exit 1
  }

# 2) libhostcall_jni / libgcall_jni from this Android-16 product OUT only.
OUT_LIBS="$OUT_ROOT/target/product/x86_64/system/lib64"
stage_lib() {
  local name="$1"
  local src="$OUT_LIBS/$name"
  [ -f "$src" ] || {
    echo "ERROR: target-built JNI library is missing: $src" >&2
    return 1
  }
  copy_if_src "$src" "$SYS/lib64/$name"
}
stage_lib libhostcall_jni.so
stage_lib libgcall_jni.so

# 3) Stage graphics produced by g1_build_android16.sh. A manual rebuild remains
# available, but the normal pipeline compiles this chain once.
bash "$SCRIPT_DIR/g1_rebuild_graphics.sh" --stage-only

echo "A16DBG:G1: overlay readback:"
for f in framework/services.jar lib64/libgcall_jni.so lib64/libhostcall_jni.so \
         bin/hwservicemanager system_ext/bin/hwservicemanager \
         system_ext/etc/init/hwservicemanager.rc \
         vendor/bin/vndservicemanager vendor/bin/vndservice \
         vendor/etc/init/vndservicemanager.rc \
         vendor/lib64/egl/libEGL_emulation.so \
         vendor/lib64/hw/gralloc.bst.so vendor/lib64/hw/hwcomposer.default.so; do
  ls -la "$SYS/$f" 2>/dev/null || echo "  MISSING $f"
done
grep -E 'ro.hardware.(gralloc|egl)|ro.product.system.(device|name)' "$SYS/build.prop" 2>/dev/null || true
echo "A16DBG:G1: apply-boot-overlays DONE $(date -Is)"
