#!/bin/bash
# Build the promoted Android-16 tree. This entry point must never fall back to
# the historical AOSP16 development tree or its output directory.
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/android16_env.sh
source "$SCRIPT_DIR/lib/android16_env.sh"

CHECK_ONLY=0
JOBS="${BST_BUILD_JOBS:-8}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --jobs)
      shift
      [ "$#" -gt 0 ] || { echo "--jobs requires a value" >&2; exit 2; }
      JOBS="$1"
      ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

bst_android16_preflight
bst_android16_graphics_preflight
[ "$CHECK_ONLY" -eq 0 ] || {
  echo "A16DBG:ANDROID16: CHECK OK; no build started"
  exit 0
}

cd "$BST_ANDROID16_ROOT"
GOLDFISH_MODULE_PATH="$(bst_android16_graphics_module_path)"
export OEM=nxt IMAGE=Baklava64 OUT_DIR="$BST_OUT_DIR_NAME" IS_64_BUILD=1
export APP_PLAYER_DIR="$BST_APP_PLAYER_ROOT" HD_SOURCE_TOP="$BST_HD_SOURCE_TOP"
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true
export USE_OPENGL_RENDERER=true
export BST_BUILD_EXTERNAL_GOLDFISH=true
export BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true

set +u
source build/envsetup.sh
lunch "$BST_LUNCH_TARGET"
set -u

[ "$(pwd -P)" = "$(bst_realpath "$BST_ANDROID16_ROOT")" ] || {
  echo "A16DBG:ANDROID16: cwd changed away from Android-16 root" >&2
  exit 1
}
[ "${TARGET_PRODUCT:-}" = "$BST_PRODUCT" ] || {
  echo "A16DBG:ANDROID16: TARGET_PRODUCT=${TARGET_PRODUCT:-unset}, expected $BST_PRODUCT" >&2
  exit 1
}

echo "A16DBG:ANDROID16: build start (m droid) $(date -Is)"
bst_print_android16_identity
echo "A16DBG:ANDROID16: cwd=$(pwd -P) OUT_DIR=$OUT_DIR TARGET_PRODUCT=$TARGET_PRODUCT"

set +e
m droid -j"$JOBS"
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "A16DBG:ANDROID16: mmm $GOLDFISH_MODULE_PATH (graphics chain)"
  mmm "$GOLDFISH_MODULE_PATH" -j"$JOBS"
  rc=$?
fi
if [ "$rc" -eq 0 ]; then
  echo "A16DBG:ANDROID16: mmm $GOLDFISH_MODULE_PATH/system/hwc2"
  mmm "$GOLDFISH_MODULE_PATH/system/hwc2" -j"$JOBS"
  rc=$?
fi
set -e

IMG="$BST_ANDROID16_ROOT/$BST_OUT_DIR_NAME/target/product/x86_64/system.img"
IDENTITY="$BST_BUILD_IDENTITY_FILE"
echo "A16DBG:ANDROID16: artifacts:"
if [ "$rc" -eq 0 ]; then
  [ -f "$IMG" ] || {
    echo "A16DBG:ANDROID16: build returned 0 but system.img is missing: $IMG" >&2
    rc=1
  }
fi
if [ -f "$IMG" ]; then
  ls -la "$IMG"
  md5sum "$IMG"
  sha256sum "$IMG"
fi
if [ "$rc" -eq 0 ]; then
  bst_write_identity_file "$IDENTITY" "$IMG"
  cat "$IDENTITY"
fi
ls "$BST_ANDROID16_ROOT/$BST_OUT_DIR_NAME/target/product/x86_64/system/vendor/bin/vndservicemanager" \
  2>/dev/null && echo vnd_OK || echo vnd_MISSING
echo "A16DBG:ANDROID16: DONE rc=$rc $(date -Is)"
exit "$rc"
