#!/bin/bash
# Audited wrapper for the canonical Android-16 app-player build and package flow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BST_OUT_DIR_NAME="${BST_OUT_DIR_NAME:-out_nxt_Baklava64}"
export BST_GOLDFISH_OPENGL_ROOT="${BST_GOLDFISH_OPENGL_ROOT:-$HOME/app-player/ggl/goldfish-opengl-pie}"
export BST_ALLOWED_ROOT_DIRTY_PATHS="${BST_ALLOWED_ROOT_DIRTY_PATHS:-.gitignore}"
# shellcheck source=scripts/lib/android16_env.sh
source "$SCRIPT_DIR/lib/android16_env.sh"

CHECK_ONLY=0
PACKAGE_ONLY=0
RECORD_PACKAGE_ONLY=0
JOBS="${BST_BUILD_JOBS:-8}"
EXPECTED_ROOT_VHD_UUID="${BST_ROOT_VHD_UUID:-54e9ad31-a169-4d5b-a0e0-705d62e96e71}"
EXPECTED_FASTBOOT_VDI_UUID="${BST_FASTBOOT_VDI_UUID:-91b80c95-aa7d-459d-93e4-c479f5babbb7}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --incremental) ;;
    --package-resume|--package-only) PACKAGE_ONLY=1 ;;
    --record-package) RECORD_PACKAGE_ONLY=1 ;;
    --jobs)
      shift
      [ "$#" -gt 0 ] || { echo "--jobs requires a value" >&2; exit 2; }
      JOBS="$1"
      ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

read_vhd_uuid() {
  python3 - "$1" <<'PY'
import pathlib
import sys
import uuid

path = pathlib.Path(sys.argv[1])
with path.open("rb") as stream:
    stream.seek(-512, 2)
    footer = stream.read(512)
if len(footer) != 512 or footer[:8] != b"conectix":
    raise SystemExit(f"invalid VHD footer: {path}")
print(uuid.UUID(bytes_le=footer[68:84]))
PY
}

read_vdi_uuid() {
  python3 - "$1" <<'PY'
import pathlib
import sys
import uuid

path = pathlib.Path(sys.argv[1])
with path.open("rb") as stream:
    stream.seek(64)
    signature = stream.read(4)
    stream.seek(392)
    raw_uuid = stream.read(16)
if signature != b"\x7f\x10\xda\xbe" or len(raw_uuid) != 16:
    raise SystemExit(f"invalid VDI header: {path}")
print(uuid.UUID(bytes_le=raw_uuid))
PY
}

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
CANONICAL_BUILD_ENTRY="$BST_APP_PLAYER_ROOT/buildscripts/build_Baklava64.sh"
CANONICAL_BUILD_COMMON="$BST_APP_PLAYER_ROOT/buildscripts/build_Baklava_common.sh"
BUILD_SCRIPT="$BST_APP_PLAYER_ROOT/buildscripts/build.sh"
BUILD_MAKEFILE="$BST_APP_PLAYER_ROOT/buildscripts/Makefile"
CREATE_VDI_SCRIPT="$BST_APP_PLAYER_ROOT/buildscripts/create_vdi.sh"
SFS_SCRIPT="$BST_APP_PLAYER_ROOT/buildscripts/make-baklava-system-sfs.sh"
MOUNTSF_PAYLOAD="$BST_APP_PLAYER_ROOT/bst/bin/mountsf"
PACKAGE_INPUT_INSTALLER="$SCRIPT_DIR/prepare_android16_package_inputs.sh"
PACKAGE_INPUT_BUNDLE="${BST_A16_PACKAGE_BUNDLE:-$HOME/a16-package-inputs/bst-v5.22.210-A16-e7a61686}"

[ "$(bst_realpath "$APP_ANDROID")" = "$(bst_realpath "$BST_ANDROID16_ROOT")" ] || {
  echo "app-player/android-16 does not resolve to the audited target tree" >&2
  exit 1
}
for input in "$CANONICAL_BUILD_ENTRY" "$CANONICAL_BUILD_COMMON" "$BUILD_SCRIPT" \
    "$BUILD_MAKEFILE" "$CREATE_VDI_SCRIPT" "$SFS_SCRIPT" "$MOUNTSF_PAYLOAD" \
    "$PACKAGE_INPUT_INSTALLER" "$PACKAGE_INPUT_BUNDLE/SOURCE.identity" \
    "$PACKAGE_INPUT_BUNDLE/SHA256SUMS"; do
  [ -f "$input" ] || { echo "missing app-player build input: $input" >&2; exit 1; }
done

APP_PLAYER_BRANCH="$(git -C "$BST_APP_PLAYER_ROOT" branch --show-current)"
APP_PLAYER_HEAD="$(git -C "$BST_APP_PLAYER_ROOT" rev-parse HEAD)"
EXPECTED_APP_PLAYER_BRANCH="${BST_EXPECTED_APP_PLAYER_BRANCH:-bst-v5.22.210-A16}"
[ "$APP_PLAYER_BRANCH" = "$EXPECTED_APP_PLAYER_BRANCH" ] || {
  echo "unexpected app-player branch: $APP_PLAYER_BRANCH" >&2
  exit 1
}
[ -z "$(git -C "$BST_APP_PLAYER_ROOT" ls-files -u)" ] || {
  echo "app-player checkout contains unresolved index entries" >&2
  exit 1
}

app_player_gitlink_head() {
  git -C "$BST_APP_PLAYER_ROOT" ls-files -s -- "$1" |
    awk '$1 == "160000" { print $2; found = 1 } END { if (!found) exit 1 }'
}

HD_ROOT="$(bst_realpath "$BST_HD_SOURCE_TOP")"
VBOX_ROOT="$BST_APP_PLAYER_ROOT/vbox-guest-additions"
EXPECTED_HD_HEAD="${BST_EXPECTED_HD_HEAD:-$(app_player_gitlink_head hd)}"
EXPECTED_VBOX_HEAD="${BST_EXPECTED_VBOX_HEAD:-$(app_player_gitlink_head vbox-guest-additions)}"
EXPECTED_GOLDFISH_HEAD="${BST_EXPECTED_GOLDFISH_HEAD:-$(app_player_gitlink_head ggl/goldfish-opengl-pie)}"
for checkout in "$HD_ROOT" "$VBOX_ROOT" "$BST_GOLDFISH_OPENGL_ROOT"; do
  git -C "$checkout" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "missing Git checkout: $checkout" >&2
    exit 1
  }
  [ -z "$(git -C "$checkout" ls-files -u)" ] || {
    echo "checkout contains unresolved index entries: $checkout" >&2
    exit 1
  }
done
HD_HEAD="$(git -C "$HD_ROOT" rev-parse HEAD)"
VBOX_HEAD="$(git -C "$VBOX_ROOT" rev-parse HEAD)"
GOLDFISH_HEAD="$(git -C "$BST_GOLDFISH_OPENGL_ROOT" rev-parse HEAD)"
[ "$HD_HEAD" = "$EXPECTED_HD_HEAD" ] || {
  echo "HD HEAD does not match app-player gitlink: expected $EXPECTED_HD_HEAD, got $HD_HEAD" >&2
  exit 1
}
[ "$VBOX_HEAD" = "$EXPECTED_VBOX_HEAD" ] || {
  echo "VBox HEAD does not match audited source: expected $EXPECTED_VBOX_HEAD, got $VBOX_HEAD" >&2
  exit 1
}
[ "$GOLDFISH_HEAD" = "$EXPECTED_GOLDFISH_HEAD" ] || {
  echo "goldfish HEAD does not match app-player gitlink: expected $EXPECTED_GOLDFISH_HEAD, got $GOLDFISH_HEAD" >&2
  exit 1
}
HD_DIFF_SHA256="$(git -C "$HD_ROOT" diff --binary HEAD -- | sha256sum | awk '{print $1}')"
VBOX_DIFF_SHA256="$(git -C "$VBOX_ROOT" diff --binary HEAD -- | sha256sum | awk '{print $1}')"
HD_STAGE2_SHA256="$(sha256sum "$HD_ROOT/guest/BootImage/stage2.sh" | awk '{print $1}')"
BUILD_FLOW_DIFF_SHA256="$({
  git -C "$BST_APP_PLAYER_ROOT" diff --binary HEAD -- \
    buildscripts/build.sh buildscripts/build_Baklava64.sh \
    buildscripts/build_Baklava_common.sh buildscripts/Makefile \
    buildscripts/create_vdi.sh buildscripts/make-baklava-system-sfs.sh
} | sha256sum | awk '{print $1}')"

EXPECTED_KERNEL_CLANG_REV="${BST_EXPECTED_KERNEL_CLANG_REV:-r563880c}"
EXPECTED_KERNEL_CLANG_BIN="$BST_ANDROID16_ROOT/prebuilts/clang/host/linux-x86/clang-$EXPECTED_KERNEL_CLANG_REV/bin/clang"
[ -x "$EXPECTED_KERNEL_CLANG_BIN" ] || {
  echo "missing expected kernel clang: $EXPECTED_KERNEL_CLANG_BIN" >&2
  exit 1
}
grep -Fqx "CLANG_PREBUILT_BIN := \$(ANDROIDHOME)/prebuilts/clang/host/linux-x86/clang-${EXPECTED_KERNEL_CLANG_REV}/bin" \
  "$BUILD_MAKEFILE" || {
  echo "app-player Makefile does not use kernel clang $EXPECTED_KERNEL_CLANG_REV" >&2
  exit 1
}
APP_PLAYER_DIR="$BST_APP_PLAYER_ROOT" BST_A16_PACKAGE_BUNDLE="$PACKAGE_INPUT_BUNDLE" \
  bash "$PACKAGE_INPUT_INSTALLER" --verify-only

echo "A16DBG:IDENTITY: app_player_branch=$APP_PLAYER_BRANCH"
echo "A16DBG:IDENTITY: app_player_head=$APP_PLAYER_HEAD"
echo "A16DBG:IDENTITY: android_branch=$(git -C "$BST_ANDROID16_ROOT" branch --show-current)"
echo "A16DBG:IDENTITY: android_head=$(git -C "$BST_ANDROID16_ROOT" rev-parse HEAD)"
echo "A16DBG:IDENTITY: hd_head=$HD_HEAD"
echo "A16DBG:IDENTITY: hd_diff_sha256=$HD_DIFF_SHA256"
echo "A16DBG:IDENTITY: hd_stage2_sha256=$HD_STAGE2_SHA256"
echo "A16DBG:IDENTITY: vbox_head=$VBOX_HEAD"
echo "A16DBG:IDENTITY: vbox_diff_sha256=$VBOX_DIFF_SHA256"
echo "A16DBG:IDENTITY: goldfish_head=$GOLDFISH_HEAD"
echo "A16DBG:IDENTITY: canonical_build_entry_sha256=$(sha256sum "$CANONICAL_BUILD_ENTRY" | awk '{print $1}')"
echo "A16DBG:IDENTITY: canonical_build_common_sha256=$(sha256sum "$CANONICAL_BUILD_COMMON" | awk '{print $1}')"
echo "A16DBG:IDENTITY: build_makefile_sha256=$(sha256sum "$BUILD_MAKEFILE" | awk '{print $1}')"
echo "A16DBG:IDENTITY: build_flow_diff_sha256=$BUILD_FLOW_DIFF_SHA256"
echo "A16DBG:IDENTITY: mountsf_sha256=$(sha256sum "$MOUNTSF_PAYLOAD" | awk '{print $1}')"
echo "A16DBG:IDENTITY: package_source_identity_sha256=$(sha256sum "$PACKAGE_INPUT_BUNDLE/SOURCE.identity" | awk '{print $1}')"
echo "A16DBG:IDENTITY: package_sums_sha256=$(sha256sum "$PACKAGE_INPUT_BUNDLE/SHA256SUMS" | awk '{print $1}')"
echo "A16DBG:IDENTITY: kernel_clang_revision=$EXPECTED_KERNEL_CLANG_REV"
echo "A16DBG:IDENTITY: kernel_clang_sha256=$(sha256sum "$EXPECTED_KERNEL_CLANG_BIN" | awk '{print $1}')"

if [ "$CHECK_ONLY" -eq 1 ]; then
  bash "$CANONICAL_BUILD_ENTRY" --check --jobs "$JOBS"
  echo "A16DBG:ANDROID16: app-player build CHECK OK; no build started"
  exit 0
fi

CANONICAL_MODE=--incremental
CANONICAL_LABEL="incremental build and package"
if [ "$PACKAGE_ONLY" -eq 1 ]; then
  CANONICAL_MODE=--package-only
  CANONICAL_LABEL="package-only resume"
fi
if [ "$RECORD_PACKAGE_ONLY" -eq 1 ]; then
  CANONICAL_LABEL="existing canonical package record"
  echo "A16DBG:ANDROID16: recording existing canonical package; no build started"
else
  echo "A16DBG:ANDROID16: invoking canonical $CANONICAL_LABEL flow"
  bash "$CANONICAL_BUILD_ENTRY" "$CANONICAL_MODE" --jobs "$JOBS"
fi

PACKAGE_BRANCH="${BRANCH:-$APP_PLAYER_BRANCH}"
PACKAGE_BUILD_NUMBER="${ANDROID_BUILD_NUMBER:-${BUILD_NUMBER:-9527}}"
OUTPUT_PREFIX="${OUTPUTDIR_PREFIX:-$(dirname "$BST_APP_PLAYER_ROOT")/releases}"
ANDROID_OUTPUT_LOCATION="${ANDROIDOUTPUTLOC:-$OUTPUT_PREFIX/$PACKAGE_BRANCH-$PACKAGE_BUILD_NUMBER}"
PACKAGE_BASE="$ANDROID_OUTPUT_LOCATION/Baklava64"
PACKAGE_DIR="$PACKAGE_BASE/${PACKAGE_BRANCH}_Baklava64-${PACKAGE_BUILD_NUMBER}"
SYSTEM_IMG="$PACKAGE_BASE/system.img"
SYSTEM_SFS="$PACKAGE_BASE/system.sfs"
VHD="$PACKAGE_DIR/Root.vhd"
FASTBOOT_VDI="$PACKAGE_DIR/fastboot.vdi"
IDENTITY="$VHD.identity"
for artifact in "$SYSTEM_IMG" "$SYSTEM_SFS" "$VHD" "$FASTBOOT_VDI"; do
  [ -f "$artifact" ] || { echo "missing canonical package artifact: $artifact" >&2; exit 1; }
done
for path in /bin/mountsf \
    /vendor/bin/RTVboxGuestService \
    /vendor/etc/init/RTVboxGuestService-vendor.rc \
    /priv-app/com.uncube.launcher3/com.uncube.launcher3.apk \
    /priv-app/com.uncube.launcher3/lib/x86_64/libflutter.so; do
  debugfs -R "stat $path" "$SYSTEM_IMG" 2>&1 | grep -q '^Inode:' || {
    echo "packaged system.img is missing $path" >&2
    exit 1
  }
done
for stale_path in /bin/RTVboxGuestService /etc/init/RTVboxGuestService.rc; do
  if debugfs -R "stat $stale_path" "$SYSTEM_IMG" 2>&1 | grep -q '^Inode:'; then
    echo "stale system RTVbox service survived packaging: $stale_path" >&2
    exit 1
  fi
done
VHD_UUID="$(read_vhd_uuid "$VHD")"
[ "$VHD_UUID" = "$EXPECTED_ROOT_VHD_UUID" ] || {
  echo "Root.vhd UUID mismatch: expected $EXPECTED_ROOT_VHD_UUID, got $VHD_UUID" >&2
  exit 1
}
FASTBOOT_VDI_UUID="$(read_vdi_uuid "$FASTBOOT_VDI")"
[ "$FASTBOOT_VDI_UUID" = "$EXPECTED_FASTBOOT_VDI_UUID" ] || {
  echo "fastboot.vdi UUID mismatch: expected $EXPECTED_FASTBOOT_VDI_UUID, got $FASTBOOT_VDI_UUID" >&2
  exit 1
}

IDENTITY_TMP="$IDENTITY.tmp.$$"
trap 'rm -f "$IDENTITY_TMP"' EXIT
bst_write_identity_file "$IDENTITY_TMP" "$VHD"
{
  printf 'vhd_uuid=%s\n' "$VHD_UUID"
  printf 'fastboot_vdi_uuid=%s\n' "$FASTBOOT_VDI_UUID"
  printf 'system_img_sha256=%s\n' "$(sha256sum "$SYSTEM_IMG" | awk '{print $1}')"
  printf 'system_sfs_sha256=%s\n' "$(sha256sum "$SYSTEM_SFS" | awk '{print $1}')"
  printf 'fastboot_vdi_sha256=%s\n' "$(sha256sum "$FASTBOOT_VDI" | awk '{print $1}')"
  printf 'app_player_branch=%s\n' "$APP_PLAYER_BRANCH"
  printf 'app_player_commit=%s\n' "$APP_PLAYER_HEAD"
  printf 'android_branch=%s\n' "$(git -C "$BST_ANDROID16_ROOT" branch --show-current)"
  printf 'android_commit=%s\n' "$(git -C "$BST_ANDROID16_ROOT" rev-parse HEAD)"
  printf 'hd_head=%s\n' "$HD_HEAD"
  printf 'hd_diff_sha256=%s\n' "$HD_DIFF_SHA256"
  printf 'hd_stage2_sha256=%s\n' "$HD_STAGE2_SHA256"
  printf 'vbox_head=%s\n' "$VBOX_HEAD"
  printf 'vbox_diff_sha256=%s\n' "$VBOX_DIFF_SHA256"
  printf 'goldfish_head=%s\n' "$GOLDFISH_HEAD"
  printf 'canonical_build_entry_sha256=%s\n' "$(sha256sum "$CANONICAL_BUILD_ENTRY" | awk '{print $1}')"
  printf 'canonical_build_common_sha256=%s\n' "$(sha256sum "$CANONICAL_BUILD_COMMON" | awk '{print $1}')"
  printf 'build_makefile_sha256=%s\n' "$(sha256sum "$BUILD_MAKEFILE" | awk '{print $1}')"
  printf 'build_flow_diff_sha256=%s\n' "$BUILD_FLOW_DIFF_SHA256"
  printf 'mountsf_sha256=%s\n' "$(sha256sum "$MOUNTSF_PAYLOAD" | awk '{print $1}')"
  printf 'package_source_identity_sha256=%s\n' "$(sha256sum "$PACKAGE_INPUT_BUNDLE/SOURCE.identity" | awk '{print $1}')"
  printf 'package_sums_sha256=%s\n' "$(sha256sum "$PACKAGE_INPUT_BUNDLE/SHA256SUMS" | awk '{print $1}')"
  printf 'kernel_clang_revision=%s\n' "$EXPECTED_KERNEL_CLANG_REV"
  printf 'kernel_clang_sha256=%s\n' "$(sha256sum "$EXPECTED_KERNEL_CLANG_BIN" | awk '{print $1}')"
  printf 'validation_mode=canonical-app-player-package\n'
  printf 'generated_at=%s\n' "$(date -Is)"
} >> "$IDENTITY_TMP"
mv -f "$IDENTITY_TMP" "$IDENTITY"
trap - EXIT

grep -Fqx "app_player_commit=$APP_PLAYER_HEAD" "$IDENTITY" || {
  echo "package identity does not match app-player HEAD" >&2
  exit 1
}
grep -Fqx "android_commit=$(git -C "$BST_ANDROID16_ROOT" rev-parse HEAD)" "$IDENTITY" || {
  echo "package identity does not match Android HEAD" >&2
  exit 1
}
cat "$IDENTITY"
echo "A16DBG:ANDROID16: canonical $CANONICAL_LABEL flow DONE $(date -Is)"
