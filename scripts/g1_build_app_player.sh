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
EXPECTED_APP_PLAYER_BRANCH="${BST_EXPECTED_APP_PLAYER_BRANCH:-bst-v5.22.210}"
EXPECTED_HD_BRANCH="${BST_EXPECTED_HD_BRANCH:-bst-v5.22.210}"
EXPECTED_VBOX_HEAD="${BST_EXPECTED_VBOX_HEAD:-e23c34d1a2f2ce6beda832dfce0c71890fddb798}"
[ "$APP_PLAYER_BRANCH" = "$EXPECTED_APP_PLAYER_BRANCH" ] || {
  echo "unexpected app-player branch: $APP_PLAYER_BRANCH" >&2
  exit 1
}
if [ -n "$(git -C "$BST_APP_PLAYER_ROOT" ls-files -u)" ]; then
  echo "app-player checkout contains unresolved index entries" >&2
  exit 1
fi
HD_ROOT="$(bst_realpath "$BST_HD_SOURCE_TOP")"
VBOX_ROOT="$BST_APP_PLAYER_ROOT/vbox-guest-additions"
git -C "$HD_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "missing HD Git checkout: $HD_ROOT" >&2
  exit 1
}
git -C "$VBOX_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "missing VBox guest additions checkout: $VBOX_ROOT" >&2
  exit 1
}
if [ -n "$(git -C "$HD_ROOT" ls-files -u)" ]; then
  echo "HD checkout contains unresolved index entries" >&2
  exit 1
fi
HD_BRANCH="$(git -C "$HD_ROOT" branch --show-current)"
HD_HEAD="$(git -C "$HD_ROOT" rev-parse HEAD)"
[ "$HD_BRANCH" = "$EXPECTED_HD_BRANCH" ] || {
  echo "unexpected HD branch: $HD_BRANCH" >&2
  exit 1
}
HD_DIFF_SHA256="$(git -C "$HD_ROOT" diff --binary HEAD -- | sha256sum | awk '{print $1}')"
HD_STAGE2_SHA256="$(sha256sum "$HD_ROOT/guest/BootImage/stage2.sh" | awk '{print $1}')"
VBOX_HEAD="$(git -C "$VBOX_ROOT" rev-parse HEAD)"
[ -z "$(git -C "$VBOX_ROOT" ls-files -u)" ] || {
  echo "VBox guest additions checkout contains unresolved index entries" >&2
  exit 1
}
[ "$VBOX_HEAD" = "$EXPECTED_VBOX_HEAD" ] || {
  echo "unexpected VBox guest additions HEAD: $VBOX_HEAD" >&2
  exit 1
}
VBOX_SOURCE="$VBOX_ROOT/amd64/src/vboxguest-7.0.8"
for driver_source in vboxguest vboxsf vboxvideo; do
  [ -d "$VBOX_SOURCE/$driver_source" ] || {
    echo "missing VBox 7.0.8 driver source: $VBOX_SOURCE/$driver_source" >&2
    exit 1
  }
done
BUILD_MAKEFILE="$BST_APP_PLAYER_ROOT/buildscripts/Makefile"
SFS_SCRIPT="$BST_APP_PLAYER_ROOT/buildscripts/make-baklava-system-sfs.sh"
MOUNTSF_PAYLOAD="$BST_APP_PLAYER_ROOT/bst/bin/mountsf"
PACKAGE_INPUT_INSTALLER="$SCRIPT_DIR/prepare_android16_package_inputs.sh"
PACKAGE_INPUT_BUNDLE="${BST_A16_PACKAGE_BUNDLE:-$HOME/a16-package-inputs/bst-v5.22.210-A16-e7a61686}"
for input in "$BUILD_MAKEFILE" "$SFS_SCRIPT" "$MOUNTSF_PAYLOAD" \
    "$PACKAGE_INPUT_INSTALLER" "$PACKAGE_INPUT_BUNDLE/SOURCE.identity" \
    "$PACKAGE_INPUT_BUNDLE/SHA256SUMS"; do
  [ -f "$input" ] || { echo "missing app-player packaging input: $input" >&2; exit 1; }
done
APP_PLAYER_DIR="$BST_APP_PLAYER_ROOT" BST_A16_PACKAGE_BUNDLE="$PACKAGE_INPUT_BUNDLE" \
  bash "$PACKAGE_INPUT_INSTALLER" --verify-only
UNCUBE_APK="$PACKAGE_INPUT_BUNDLE/payload/com.uncube.launcher3.apk"
[ -f "$UNCUBE_APK" ] || { echo "verified bundle is missing uncube: $UNCUBE_APK" >&2; exit 1; }
BUILD_SCRIPT_SHA256="$(sha256sum "$BUILD_SCRIPT" | awk '{print $1}')"
BUILD_MAKEFILE_SHA256="$(sha256sum "$BUILD_MAKEFILE" | awk '{print $1}')"
SFS_SCRIPT_SHA256="$(sha256sum "$SFS_SCRIPT" | awk '{print $1}')"
MOUNTSF_SHA256="$(sha256sum "$MOUNTSF_PAYLOAD" | awk '{print $1}')"
UNCUBE_APK_SHA256="$(sha256sum "$UNCUBE_APK" | awk '{print $1}')"
PACKAGE_SOURCE_IDENTITY_SHA256="$(sha256sum "$PACKAGE_INPUT_BUNDLE/SOURCE.identity" | awk '{print $1}')"
PACKAGE_SUMS_SHA256="$(sha256sum "$PACKAGE_INPUT_BUNDLE/SHA256SUMS" | awk '{print $1}')"
BUILD_FLOW_DIFF_SHA256="$(
  git -C "$BST_APP_PLAYER_ROOT" diff --binary HEAD -- \
    buildscripts/build.sh buildscripts/Makefile buildscripts/make-baklava-system-sfs.sh |
    sha256sum | awk '{print $1}'
)"
echo "A16DBG:IDENTITY: app_player_branch=$APP_PLAYER_BRANCH"
echo "A16DBG:IDENTITY: app_player_head=$APP_PLAYER_HEAD"
echo "A16DBG:IDENTITY: hd_branch=$HD_BRANCH"
echo "A16DBG:IDENTITY: hd_head=$HD_HEAD"
echo "A16DBG:IDENTITY: hd_diff_sha256=$HD_DIFF_SHA256"
echo "A16DBG:IDENTITY: hd_stage2_sha256=$HD_STAGE2_SHA256"
echo "A16DBG:IDENTITY: vbox_head=$VBOX_HEAD"
echo "A16DBG:IDENTITY: build_script_sha256=$BUILD_SCRIPT_SHA256"
echo "A16DBG:IDENTITY: build_makefile_sha256=$BUILD_MAKEFILE_SHA256"
echo "A16DBG:IDENTITY: sfs_script_sha256=$SFS_SCRIPT_SHA256"
echo "A16DBG:IDENTITY: build_flow_diff_sha256=$BUILD_FLOW_DIFF_SHA256"
echo "A16DBG:IDENTITY: mountsf_sha256=$MOUNTSF_SHA256"
echo "A16DBG:IDENTITY: uncube_apk_sha256=$UNCUBE_APK_SHA256"
echo "A16DBG:IDENTITY: package_source_identity_sha256=$PACKAGE_SOURCE_IDENTITY_SHA256"
echo "A16DBG:IDENTITY: package_sums_sha256=$PACKAGE_SUMS_SHA256"

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
export USE_CCACHE="${USE_CCACHE:-1}"
export BST_A16_PACKAGE_INSTALLER="$PACKAGE_INPUT_INSTALLER"
export BST_A16_PACKAGE_BUNDLE="$PACKAGE_INPUT_BUNDLE"

echo "A16DBG:ANDROID16: app-player build start $(date -Is) jobs=$JOBS factor=$JOB_FACTOR"
BUILD_MARKER="$(mktemp)"
cleanup_build_inputs() {
  rm -f "$BUILD_MARKER"
}
trap cleanup_build_inputs EXIT
bash "$BUILD_SCRIPT"

SYSTEM_IMG="$BST_RELEASE_ROOT/system.img"
SYSTEM_SFS="$BST_RELEASE_ROOT/system.sfs"
VHD="$BST_RELEASE_ROOT/bst-v5.22.210_Baklava64-local/Root.vhd"
FASTBOOT_VDI="$BST_RELEASE_ROOT/bst-v5.22.210_Baklava64-local/fastboot.vdi"
for artifact in "$SYSTEM_IMG" "$SYSTEM_SFS" "$VHD" "$FASTBOOT_VDI"; do
  [ -f "$artifact" ] || { echo "missing packaged artifact: $artifact" >&2; exit 1; }
  [ "$artifact" -nt "$BUILD_MARKER" ] || {
    echo "packaged artifact was not regenerated by this build: $artifact" >&2
    exit 1
  }
done

debugfs -R 'stat /bin/mountsf' "$SYSTEM_IMG" 2>&1 | grep -q 'Inode:' || {
  echo "packaged system.img is missing /bin/mountsf" >&2
  exit 1
}
debugfs -R 'stat /priv-app/com.uncube.launcher3/com.uncube.launcher3.apk' "$SYSTEM_IMG" 2>&1 |
  grep -q 'Inode:' || {
    echo "packaged system.img is missing the uncube HOME launcher" >&2
    exit 1
  }
debugfs -R 'stat /priv-app/com.uncube.launcher3/lib/x86_64/libflutter.so' "$SYSTEM_IMG" 2>&1 |
  grep -q 'Inode:' || {
    echo "packaged system.img is missing the uncube launcher native runtime" >&2
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
  printf 'fastboot_vdi_sha256=%s\n' "$(sha256sum "$FASTBOOT_VDI" | awk '{print $1}')"
} >> "$VHD.identity"
{
  printf 'app_player_branch=%s\n' "$APP_PLAYER_BRANCH"
  printf 'app_player_head=%s\n' "$APP_PLAYER_HEAD"
  printf 'hd_branch=%s\n' "$HD_BRANCH"
  printf 'hd_head=%s\n' "$HD_HEAD"
  printf 'hd_diff_sha256=%s\n' "$HD_DIFF_SHA256"
  printf 'hd_stage2_sha256=%s\n' "$HD_STAGE2_SHA256"
  printf 'vbox_head=%s\n' "$VBOX_HEAD"
  printf 'build_script_sha256=%s\n' "$BUILD_SCRIPT_SHA256"
  printf 'build_makefile_sha256=%s\n' "$BUILD_MAKEFILE_SHA256"
  printf 'sfs_script_sha256=%s\n' "$SFS_SCRIPT_SHA256"
  printf 'build_flow_diff_sha256=%s\n' "$BUILD_FLOW_DIFF_SHA256"
  printf 'mountsf_sha256=%s\n' "$MOUNTSF_SHA256"
  printf 'uncube_apk_sha256=%s\n' "$UNCUBE_APK_SHA256"
  printf 'package_source_identity_sha256=%s\n' "$PACKAGE_SOURCE_IDENTITY_SHA256"
  printf 'package_sums_sha256=%s\n' "$PACKAGE_SUMS_SHA256"
} >> "$VHD.identity"
cat "$VHD.identity"
echo "A16DBG:ANDROID16: app-player build DONE $(date -Is)"
