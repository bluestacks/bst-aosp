#!/bin/bash
# Run the canonical incremental app-player Android-16 build and packaging flow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BST_OUT_DIR_NAME="${BST_OUT_DIR_NAME:-out_nxt_Baklava64}"
export BST_GOLDFISH_OPENGL_ROOT="${BST_GOLDFISH_OPENGL_ROOT:-$HOME/app-player/ggl/goldfish-opengl-pie}"
export BST_ALLOWED_ROOT_DIRTY_PATHS="${BST_ALLOWED_ROOT_DIRTY_PATHS:-.gitignore}"
# shellcheck source=scripts/lib/android16_env.sh
source "$SCRIPT_DIR/lib/android16_env.sh"

CHECK_ONLY=0
PACKAGE_RESUME=0
JOBS="${BST_BUILD_JOBS:-8}"
EXPECTED_ROOT_VHD_UUID="${BST_ROOT_VHD_UUID:-54e9ad31-a169-4d5b-a0e0-705d62e96e71}"
EXPECTED_FASTBOOT_VDI_UUID="${BST_FASTBOOT_VDI_UUID:-91b80c95-aa7d-459d-93e4-c479f5babbb7}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --incremental) ;;
    --package-resume) PACKAGE_RESUME=1 ;;
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

write_vdi_uuid() {
  python3 - "$1" "$2" <<'PY'
import pathlib
import sys
import uuid

path = pathlib.Path(sys.argv[1])
with path.open("r+b") as stream:
    stream.seek(64)
    if stream.read(4) != b"\x7f\x10\xda\xbe":
        raise SystemExit(f"invalid VDI header: {path}")
    stream.seek(392)
    stream.write(uuid.UUID(sys.argv[2]).bytes_le)
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
VBOX_DIFF_SHA256="$(git -C "$VBOX_ROOT" diff --binary HEAD -- | sha256sum | awk '{print $1}')"
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
EXPECTED_KERNEL_CLANG_REV="${BST_EXPECTED_KERNEL_CLANG_REV:-r563880c}"
EXPECTED_KERNEL_CLANG_BIN="$BST_ANDROID16_ROOT/prebuilts/clang/host/linux-x86/clang-$EXPECTED_KERNEL_CLANG_REV/bin/clang"
PACKAGE_INPUT_INSTALLER="$SCRIPT_DIR/prepare_android16_package_inputs.sh"
PACKAGE_INPUT_BUNDLE="${BST_A16_PACKAGE_BUNDLE:-$HOME/a16-package-inputs/bst-v5.22.210-A16-e7a61686}"
for input in "$BUILD_MAKEFILE" "$SFS_SCRIPT" "$MOUNTSF_PAYLOAD" \
    "$PACKAGE_INPUT_INSTALLER" "$PACKAGE_INPUT_BUNDLE/SOURCE.identity" \
    "$PACKAGE_INPUT_BUNDLE/SHA256SUMS"; do
  [ -f "$input" ] || { echo "missing app-player packaging input: $input" >&2; exit 1; }
done
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
UNCUBE_APK="$PACKAGE_INPUT_BUNDLE/payload/com.uncube.launcher3.apk"
[ -f "$UNCUBE_APK" ] || { echo "verified bundle is missing uncube: $UNCUBE_APK" >&2; exit 1; }
BUILD_SCRIPT_SHA256="$(sha256sum "$BUILD_SCRIPT" | awk '{print $1}')"
BUILD_MAKEFILE_SHA256="$(sha256sum "$BUILD_MAKEFILE" | awk '{print $1}')"
SFS_SCRIPT_SHA256="$(sha256sum "$SFS_SCRIPT" | awk '{print $1}')"
MOUNTSF_SHA256="$(sha256sum "$MOUNTSF_PAYLOAD" | awk '{print $1}')"
UNCUBE_APK_SHA256="$(sha256sum "$UNCUBE_APK" | awk '{print $1}')"
PACKAGE_SOURCE_IDENTITY_SHA256="$(sha256sum "$PACKAGE_INPUT_BUNDLE/SOURCE.identity" | awk '{print $1}')"
PACKAGE_SUMS_SHA256="$(sha256sum "$PACKAGE_INPUT_BUNDLE/SHA256SUMS" | awk '{print $1}')"
KERNEL_CLANG_SHA256="$(sha256sum "$EXPECTED_KERNEL_CLANG_BIN" | awk '{print $1}')"
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
echo "A16DBG:IDENTITY: vbox_diff_sha256=$VBOX_DIFF_SHA256"
echo "A16DBG:IDENTITY: build_script_sha256=$BUILD_SCRIPT_SHA256"
echo "A16DBG:IDENTITY: build_makefile_sha256=$BUILD_MAKEFILE_SHA256"
echo "A16DBG:IDENTITY: sfs_script_sha256=$SFS_SCRIPT_SHA256"
echo "A16DBG:IDENTITY: build_flow_diff_sha256=$BUILD_FLOW_DIFF_SHA256"
echo "A16DBG:IDENTITY: mountsf_sha256=$MOUNTSF_SHA256"
echo "A16DBG:IDENTITY: uncube_apk_sha256=$UNCUBE_APK_SHA256"
echo "A16DBG:IDENTITY: package_source_identity_sha256=$PACKAGE_SOURCE_IDENTITY_SHA256"
echo "A16DBG:IDENTITY: package_sums_sha256=$PACKAGE_SUMS_SHA256"
echo "A16DBG:IDENTITY: kernel_clang_revision=$EXPECTED_KERNEL_CLANG_REV"
echo "A16DBG:IDENTITY: kernel_clang_sha256=$KERNEL_CLANG_SHA256"

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
export BST_BUILD_JOBS="$JOBS"
# Some legacy app-player mmm calls omit an explicit -j value. Soong appends
# NINJA_ARGS after its inferred default, keeping those nested builds capped.
export NINJA_ARGS="${NINJA_ARGS:+$NINJA_ARGS }-j$JOBS"
export APP_PLAYER_DIR="$BST_APP_PLAYER_ROOT"
export HD_SOURCE_TOP="$BST_HD_SOURCE_TOP"
export ALLOW_MISSING_DEPENDENCIES=true
export BUILD_EMULATOR_OPENGL=true
export BUILD_EMULATOR_OPENGL_DRIVER=true
export BST_BUILD_EXTERNAL_GOLDFISH=true
export USE_CCACHE="${USE_CCACHE:-1}"
export BST_A16_PACKAGE_INSTALLER="$PACKAGE_INPUT_INSTALLER"
export BST_A16_PACKAGE_BUNDLE="$PACKAGE_INPUT_BUNDLE"

echo "A16DBG:ANDROID16: incremental app-player build start $(date -Is) jobs=$JOBS factor=$JOB_FACTOR"
BUILD_MARKER="$(mktemp)"
PACKAGED_BUILD_PROP=""
cleanup_build_inputs() {
  rm -f "$BUILD_MARKER"
  [ -z "$PACKAGED_BUILD_PROP" ] || rm -f "$PACKAGED_BUILD_PROP"
}
trap cleanup_build_inputs EXIT

# Keep the audited Android output tree intact. Rebuild the changed dependency
# closure through init, systemimage and kernel before repackaging the guest artifacts.
if [ "$PACKAGE_RESUME" -eq 0 ]; then
  (
    set +u
    cd "$BST_ANDROID16_ROOT"
    export OUT_DIR="$BST_OUT_DIR_NAME"
    # shellcheck disable=SC1091
    source build/envsetup.sh >/dev/null
    lunch android_x86_64-trunk_staging-eng >/dev/null
    m -j"$JOBS" init systemimage kernel
  )
else
  echo "A16DBG:ANDROID16: resume packaging from existing Android output"
fi

# The legacy app-player "android" target deletes every image before invoking
# iso_img. Android was updated above, so mark only that dependency as satisfied
# and incrementally rebuild the packaging-side libraries, APKs, Root and
# fastboot artifacts.
ANDROID_SYSTEM_STAGING_SOURCE="$BST_ANDROID16_ROOT/$BST_OUT_DIR_NAME/target/product/x86_64/system"
SYSTEM_STAGING="$BST_RELEASE_ROOT/system"
[ -d "$ANDROID_SYSTEM_STAGING_SOURCE" ] || {
  echo "missing Android system staging source: $ANDROID_SYSTEM_STAGING_SOURCE" >&2
  exit 1
}
[ "$(bst_realpath "$SYSTEM_STAGING")" = "$(bst_realpath "$BST_RELEASE_ROOT")/system" ] || {
  echo "refusing to reset unexpected system staging path: $SYSTEM_STAGING" >&2
  exit 1
}
if [ "$PACKAGE_RESUME" -eq 1 ]; then
  [ -d "$SYSTEM_STAGING" ] && [ ! -L "$SYSTEM_STAGING" ] || {
    echo "system staging is unavailable for package resume: $SYSTEM_STAGING" >&2
    exit 1
  }
  STALE_STAGING_FILES=0
elif [ -e "$SYSTEM_STAGING" ]; then
  [ -d "$SYSTEM_STAGING" ] && [ ! -L "$SYSTEM_STAGING" ] || {
    echo "system staging is not a real directory: $SYSTEM_STAGING" >&2
    exit 1
  }
  ! mountpoint -q "$SYSTEM_STAGING" || {
    echo "refusing to reset mounted system staging: $SYSTEM_STAGING" >&2
    exit 1
  }
  STALE_STAGING_FILES="$(find "$SYSTEM_STAGING" -xdev -type f | wc -l)"
  sudo -n find "$SYSTEM_STAGING" -xdev -mindepth 1 -delete || {
    echo "unable to reset generated system staging with non-interactive sudo" >&2
    exit 1
  }
else
  STALE_STAGING_FILES=0
  mkdir -p "$SYSTEM_STAGING"
fi
echo "A16DBG:ANDROID16: reset generated system staging files=$STALE_STAGING_FILES"

# Stage the verified goldfish closure immediately before Root packaging. This
# also normalizes Android OUT because the legacy Makefile merges that directory
# into release staging after this point.
bash "$SCRIPT_DIR/g1_rebuild_graphics.sh" --stage-only

MAKE_OLD_TARGETS=(-o android)
if [ "$PACKAGE_RESUME" -eq 1 ]; then
  MAKE_OLD_TARGETS+=(-o libs -o apks -o datafs)
fi
make -j"$JOBS" "${MAKE_OLD_TARGETS[@]}" -f "$BUILD_MAKEFILE" vbox \
  OEM="$OEM" \
  IMAGE=Baklava64 \
  ANDROIDOUTPUTLOC="$ANDROIDOUTPUTLOC" \
  PKG="${BRANCH}_Baklava64-${ANDROID_BUILD_NUMBER}" \
  ENABLE_DEXOPT="$ENABLE_DEXOPT" \
  IS_HYPERV_BUILD=0 \
  PARALLEL_NX_PROC="$JOB_FACTOR" \
  ANDROID_SDK_PATH="${ANDROID_SDK_PATH:-/home/build/workspace/android-sdk/sdk}"

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
VHD_UUID="$(read_vhd_uuid "$VHD")"
[ "$VHD_UUID" = "$EXPECTED_ROOT_VHD_UUID" ] || {
  echo "Root.vhd UUID mismatch: expected $EXPECTED_ROOT_VHD_UUID, got $VHD_UUID" >&2
  exit 1
}
FASTBOOT_VDI_UUID="$(read_vdi_uuid "$FASTBOOT_VDI")"
[ "$FASTBOOT_VDI_UUID" = "$EXPECTED_FASTBOOT_VDI_UUID" ] || {
  write_vdi_uuid "$FASTBOOT_VDI" "$EXPECTED_FASTBOOT_VDI_UUID"
  FASTBOOT_VDI_UUID="$(read_vdi_uuid "$FASTBOOT_VDI")"
}
[ "$FASTBOOT_VDI_UUID" = "$EXPECTED_FASTBOOT_VDI_UUID" ] || {
  echo "fastboot.vdi UUID mismatch: expected $EXPECTED_FASTBOOT_VDI_UUID, got $FASTBOOT_VDI_UUID" >&2
  exit 1
}

debugfs -R 'stat /bin/mountsf' "$SYSTEM_IMG" 2>&1 | grep 'Inode:' >/dev/null || {
  echo "packaged system.img is missing /bin/mountsf" >&2
  exit 1
}
debugfs -R 'stat /priv-app/com.uncube.launcher3/com.uncube.launcher3.apk' "$SYSTEM_IMG" 2>&1 |
  grep 'Inode:' >/dev/null || {
    echo "packaged system.img is missing the uncube HOME launcher" >&2
    exit 1
  }
debugfs -R 'stat /priv-app/com.uncube.launcher3/lib/x86_64/libflutter.so' "$SYSTEM_IMG" 2>&1 |
  grep 'Inode:' >/dev/null || {
    echo "packaged system.img is missing the uncube launcher native runtime" >&2
    exit 1
  }
TARGET_BUILD_PROP="$BST_ANDROID16_ROOT/$BST_OUT_DIR_NAME/target/product/x86_64/system/build.prop"
[ -f "$TARGET_BUILD_PROP" ] || { echo "missing target build.prop: $TARGET_BUILD_PROP" >&2; exit 1; }
PACKAGED_BUILD_PROP="$(mktemp)"
debugfs -R 'cat /build.prop' "$SYSTEM_IMG" 2>/dev/null > "$PACKAGED_BUILD_PROP"
grep '^ro.build.display.id=BlueStacks-' "$PACKAGED_BUILD_PROP" >/dev/null || {
  echo "packaged system.img is missing the BlueStacks build identity" >&2
  exit 1
}
PLATFORM_SDK_PROPERTIES='ro.build.version.sdk ro.build.version.preview_sdk ro.build.version.preview_sdk_fingerprint ro.build.version.codename ro.build.version.all_codenames ro.build.version.known_codenames'
for prop in $PLATFORM_SDK_PROPERTIES; do
  target_value="$(grep -m1 "^${prop}=" "$TARGET_BUILD_PROP" || true)"
  packaged_value="$(grep -m1 "^${prop}=" "$PACKAGED_BUILD_PROP" || true)"
  [ -n "$target_value" ] && [ "$packaged_value" = "$target_value" ] || {
    echo "packaged platform SDK identity mismatch for $prop: target='$target_value' packaged='$packaged_value'" >&2
    exit 1
  }
done
EARLY_BOOT_PROPERTIES='sys.use_memfd'
for prop in $EARLY_BOOT_PROPERTIES; do
  target_value="$(grep -m1 "^${prop}=" "$TARGET_BUILD_PROP" || true)"
  packaged_value="$(grep -m1 "^${prop}=" "$PACKAGED_BUILD_PROP" || true)"
  [ -n "$target_value" ] && [ "$packaged_value" = "$target_value" ] || {
    echo "packaged early-boot property mismatch for $prop: target='$target_value' packaged='$packaged_value'" >&2
    exit 1
  }
done
PLATFORM_SDK_IDENTITY_SHA256="$({
  for prop in $PLATFORM_SDK_PROPERTIES; do
    grep -m1 "^${prop}=" "$PACKAGED_BUILD_PROP"
  done
} | sha256sum | awk '{print $1}')"

bst_write_identity_file "$VHD.identity" "$VHD"
{
  printf 'vhd_uuid=%s\n' "$VHD_UUID"
  printf 'fastboot_vdi_uuid=%s\n' "$FASTBOOT_VDI_UUID"
  printf 'platform_sdk_identity_sha256=%s\n' "$PLATFORM_SDK_IDENTITY_SHA256"
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
  printf 'vbox_diff_sha256=%s\n' "$VBOX_DIFF_SHA256"
  printf 'build_script_sha256=%s\n' "$BUILD_SCRIPT_SHA256"
  printf 'build_makefile_sha256=%s\n' "$BUILD_MAKEFILE_SHA256"
  printf 'sfs_script_sha256=%s\n' "$SFS_SCRIPT_SHA256"
  printf 'build_flow_diff_sha256=%s\n' "$BUILD_FLOW_DIFF_SHA256"
  printf 'mountsf_sha256=%s\n' "$MOUNTSF_SHA256"
  printf 'uncube_apk_sha256=%s\n' "$UNCUBE_APK_SHA256"
  printf 'package_source_identity_sha256=%s\n' "$PACKAGE_SOURCE_IDENTITY_SHA256"
  printf 'package_sums_sha256=%s\n' "$PACKAGE_SUMS_SHA256"
  printf 'kernel_clang_revision=%s\n' "$EXPECTED_KERNEL_CLANG_REV"
  printf 'kernel_clang_sha256=%s\n' "$KERNEL_CLANG_SHA256"
} >> "$VHD.identity"
cat "$VHD.identity"
echo "A16DBG:ANDROID16: incremental app-player build DONE $(date -Is)"
