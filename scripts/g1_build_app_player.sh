#!/bin/bash
# Run the canonical app-player Android-16 build and packaging flow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BST_OUT_DIR_NAME="${BST_OUT_DIR_NAME:-out_nxt_Baklava64}"
export BST_GOLDFISH_OPENGL_ROOT="${BST_GOLDFISH_OPENGL_ROOT:-$HOME/app-player/ggl/goldfish-opengl-pie}"
export BST_ALLOWED_ROOT_DIRTY_PATHS="${BST_ALLOWED_ROOT_DIRTY_PATHS:-.gitignore}"
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

case "$JOBS" in
  ''|*[!0-9]*) echo "jobs must be an integer from 1 through 8" >&2; exit 2 ;;
esac
[ "$JOBS" -ge 1 ] && [ "$JOBS" -le 8 ] || {
  echo "jobs must be an integer from 1 through 8" >&2
  exit 2
}

bst_android16_preflight
bst_android16_graphics_preflight

APP_ANDROID="$BST_APP_PLAYER_ROOT/android-16"
BUILD_SCRIPT="$BST_APP_PLAYER_ROOT/buildscripts/build.sh"
[ "$(bst_realpath "$APP_ANDROID")" = "$(bst_realpath "$BST_ANDROID16_ROOT")" ] || {
  echo "app-player/android-16 does not resolve to the audited target tree" >&2
  exit 1
}
[ -f "$BUILD_SCRIPT" ] || { echo "missing app-player build script: $BUILD_SCRIPT" >&2; exit 1; }

APP_PLAYER_BRANCH="$(git -C "$BST_APP_PLAYER_ROOT" branch --show-current)"
APP_PLAYER_HEAD="$(git -C "$BST_APP_PLAYER_ROOT" rev-parse HEAD)"
BUILD_MAKEFILE="$BST_APP_PLAYER_ROOT/buildscripts/Makefile"
SFS_SCRIPT="$BST_APP_PLAYER_ROOT/buildscripts/make-baklava-system-sfs.sh"
MOUNTSF_PAYLOAD="$BST_APP_PLAYER_ROOT/bst/bin/mountsf"
for input in "$BUILD_MAKEFILE" "$SFS_SCRIPT" "$MOUNTSF_PAYLOAD"; do
  [ -f "$input" ] || { echo "missing app-player packaging input: $input" >&2; exit 1; }
done
BUILD_SCRIPT_SHA256="$(sha256sum "$BUILD_SCRIPT" | awk '{print $1}')"
BUILD_MAKEFILE_SHA256="$(sha256sum "$BUILD_MAKEFILE" | awk '{print $1}')"
SFS_SCRIPT_SHA256="$(sha256sum "$SFS_SCRIPT" | awk '{print $1}')"
MOUNTSF_SHA256="$(sha256sum "$MOUNTSF_PAYLOAD" | awk '{print $1}')"
BUILD_FLOW_DIFF_SHA256="$(
  git -C "$BST_APP_PLAYER_ROOT" diff --binary -- \
    buildscripts/build.sh buildscripts/Makefile buildscripts/make-baklava-system-sfs.sh |
    sha256sum | awk '{print $1}'
)"
echo "A16DBG:IDENTITY: app_player_branch=$APP_PLAYER_BRANCH"
echo "A16DBG:IDENTITY: app_player_head=$APP_PLAYER_HEAD"
echo "A16DBG:IDENTITY: build_script_sha256=$BUILD_SCRIPT_SHA256"
echo "A16DBG:IDENTITY: build_makefile_sha256=$BUILD_MAKEFILE_SHA256"
echo "A16DBG:IDENTITY: sfs_script_sha256=$SFS_SCRIPT_SHA256"
echo "A16DBG:IDENTITY: build_flow_diff_sha256=$BUILD_FLOW_DIFF_SHA256"
echo "A16DBG:IDENTITY: mountsf_sha256=$MOUNTSF_SHA256"

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "A16DBG:ANDROID16: app-player build CHECK OK; no build started"
  exit 0
fi

TOTAL_CPUS="$(nproc)"
JOB_FACTOR="$(awk -v jobs="$JOBS" -v cpus="$TOTAL_CPUS" 'BEGIN { printf "%.6f", jobs / cpus }')"
export BRANCH=bst-v5.22.210
export OEM=nxt
export ANDROID_IMAGES=Baklava64
export ENABLE_DEXOPT=false
export FORCE_CLEAN=false
export SYNC_SOURCE_CODE=false
export ANDROID_BUILD_NUMBER=local
export ANDROIDOUTPUTLOC="$HOME/releases"
export PARALLEL_NX_PROCESSORS_BUILD_SH="$JOB_FACTOR"
export PARALLEL_NX_PROCESSORS_MAKEFILE="$JOB_FACTOR"
export APP_PLAYER_DIR="$BST_APP_PLAYER_ROOT"
export HD_SOURCE_TOP="$BST_HD_SOURCE_TOP"
export ALLOW_MISSING_DEPENDENCIES=true
export BUILD_EMULATOR_OPENGL=true
export BUILD_EMULATOR_OPENGL_DRIVER=true
export BST_BUILD_EXTERNAL_GOLDFISH=true

echo "A16DBG:ANDROID16: app-player build start $(date -Is) jobs=$JOBS factor=$JOB_FACTOR"
bash "$BUILD_SCRIPT"

SYSTEM_IMG="$BST_RELEASE_ROOT/system.img"
SYSTEM_SFS="$BST_RELEASE_ROOT/system.sfs"
VHD="$BST_RELEASE_ROOT/bst-v5.22.210_Baklava64-local/Root.vhd"
for artifact in "$SYSTEM_IMG" "$SYSTEM_SFS" "$VHD"; do
  [ -f "$artifact" ] || { echo "missing packaged artifact: $artifact" >&2; exit 1; }
done

debugfs -R 'stat /bin/mountsf' "$SYSTEM_IMG" 2>&1 | grep -q 'Inode:' || {
  echo "packaged system.img is missing /bin/mountsf" >&2
  exit 1
}
debugfs -R 'cat /build.prop' "$SYSTEM_IMG" 2>/dev/null |
  grep -q '^ro.build.display.id=BlueStacks-' || {
    echo "packaged system.img is missing the BlueStacks build identity" >&2
    exit 1
  }

bst_write_identity_file "$VHD.identity" "$VHD"
{
  printf 'system_img_sha256=%s\n' "$(sha256sum "$SYSTEM_IMG" | awk '{print $1}')"
  printf 'system_sfs_sha256=%s\n' "$(sha256sum "$SYSTEM_SFS" | awk '{print $1}')"
} >> "$VHD.identity"
{
  printf 'app_player_branch=%s\n' "$APP_PLAYER_BRANCH"
  printf 'app_player_head=%s\n' "$APP_PLAYER_HEAD"
  printf 'build_script_sha256=%s\n' "$BUILD_SCRIPT_SHA256"
  printf 'build_makefile_sha256=%s\n' "$BUILD_MAKEFILE_SHA256"
  printf 'sfs_script_sha256=%s\n' "$SFS_SCRIPT_SHA256"
  printf 'build_flow_diff_sha256=%s\n' "$BUILD_FLOW_DIFF_SHA256"
  printf 'mountsf_sha256=%s\n' "$MOUNTSF_SHA256"
} >> "$VHD.identity"
cat "$VHD.identity"
echo "A16DBG:ANDROID16: app-player build DONE $(date -Is)"
