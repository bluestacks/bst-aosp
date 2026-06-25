#!/bin/bash
#
# Local Baklava64 (Android 16) build — mirrors Tiramisu64 flow via build.sh.

LOCAL_BUILDSCRIPTS_DIR="${APP_PLAYER_LOCAL_BUILDSCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
for _lib in \
    "${APP_PLAYER_SKILL_DIR:+$APP_PLAYER_SKILL_DIR/scripts/lib/common_env.sh}" \
    "$HOME/.cursor/skills/app-player-android-build/scripts/lib/common_env.sh"
do
    if [ -n "${_lib:-}" ] && [ -f "$_lib" ]; then
        # shellcheck source=/dev/null
        source "$_lib"
        break
    fi
done

if [ -z "${APP_PLAYER_DIR:-}" ]; then
    echo "APP_PLAYER_DIR is not set. Run via build_android.sh or export APP_PLAYER_DIR." >&2
    exit 1
fi
REPO_BUILDSCRIPTS="${APP_PLAYER_DIR}/buildscripts"

get_android_branch() {
    if [ -n "${BRANCH:-}" ]; then
        echo "$BRANCH"
        return
    fi
    git -C "$APP_PLAYER_DIR/android-16" rev-parse --abbrev-ref HEAD
}

cleanup_stale_rootfs_artifacts() {
    local OUT="$1"
    local PKG="${2:-}"
    local PKG_DEBUG="${3:-}"
    local pkg_dir

    [ -d "$OUT" ] || return 0

    echo "Cleaning stale Root.fs / rootFS / VDI artifacts under $OUT"

    rm -f "$OUT"/*.exe "$OUT"/*.exe.md5
    rm -f "$OUT"/*-RootVdiDebug.7z "$OUT"/*-RootVdiDebug.7z.md5

    for pkg_dir in "$OUT/$PKG" "$OUT/$PKG_DEBUG"; do
        [ -d "$pkg_dir" ] || continue
        sudo umount "$pkg_dir/fs-to-vdi-src" 2>/dev/null || true
        sudo umount "$pkg_dir/fs-to-vdi-dst" 2>/dev/null || true
        sudo rm -rf "$pkg_dir/fs-to-vdi-src" "$pkg_dir/fs-to-vdi-dst"
        sudo rm -f "$pkg_dir"/Root*.vdi "$pkg_dir"/Root*.vhd
        sudo rm -f "$pkg_dir"/Data.vhdx
        sudo rm -f "$pkg_dir"/Android.bstk.in "$pkg_dir"/oem_*.cfg "$pkg_dir"/*.dsgn
    done

    sudo umount "$OUT/rootFSDebug" 2>/dev/null || true
    sudo umount "$OUT/rootFS" 2>/dev/null || true
    sudo umount "$OUT/dataFS" 2>/dev/null || true
    sudo rm -rf "$OUT/rootFSDebug" "$OUT/rootFS"
    sudo rm -f "$OUT/Root.fs" "$OUT/Root.fs.debug" "$OUT/Root.fs.rooted"
    sudo rm -rf "$OUT/rooted_system" "$OUT/rooted_root"
}

baklava_build() {
    local IMAGE="$1"

    if [ -z "$IMAGE" ]; then
        echo "IMAGE not set" >&2
        return 1
    fi

    export APP_PLAYER_DIR
    export BRANCH="$(get_android_branch)"
    export OEM="${OEM:-nxt}"
    export ANDROID_IMAGES="$IMAGE"
    export FORCE_CLEAN="${FORCE_CLEAN:-false}"
    export SYNC_SOURCE_CODE="${SYNC_SOURCE_CODE:-false}"
    export ENABLE_DEXOPT="${ENABLE_DEXOPT:-true}"
    export ANDROID_BUILD_NUMBER="${ANDROID_BUILD_NUMBER:-${BUILD_NUMBER}}"

    apply_default_local_paths
    export OUTPUTDIR_PREFIX
    export ANDROIDOUTPUTLOC="${ANDROIDOUTPUTLOC:-$OUTPUTDIR_PREFIX/$BRANCH-$ANDROID_BUILD_NUMBER}"
    export CCACHE_BASE
    export ANDROID_SDK_PATH
    export FLUTTER_ROOT

    export JAVA_HOME
    export PATH="$LOCAL_BUILDSCRIPTS_DIR/bin:$JAVA_HOME/bin:$FLUTTER_ROOT/bin:$PATH"
    export LC_ALL=C
    export LANG=C

    fix_android_sdk_local_properties() {
        local sdk_root="$ANDROID_SDK_PATH"
        local rosen="$APP_PLAYER_DIR/scratch-rosen"
        local dir prop
        for dir in $(find "$rosen" \( -name build.gradle -o -name settings.gradle \) -type f 2>/dev/null | xargs -I{} dirname {} | sort -u); do
            prop="$dir/local.properties"
            if [ -f "$prop" ] && grep -q '^sdk\.dir=' "$prop" 2>/dev/null; then
                sed -i "s|^sdk\.dir=.*|sdk.dir=$sdk_root|" "$prop"
            else
                echo "sdk.dir=$sdk_root" > "$prop"
            fi
        done
    }

    fix_android_sdk_local_properties

    mkdir -p \
        "$OUTPUTDIR_PREFIX" \
        "$CCACHE_BASE/Baklava64" \
        "$(dirname "$ANDROID_SDK_PATH")/tools" \
        "$(dirname "$ANDROID_SDK_PATH")/platform-tools"

    local pkg="${BRANCH}_${IMAGE}-${ANDROID_BUILD_NUMBER}"
    cleanup_stale_rootfs_artifacts "$ANDROIDOUTPUTLOC/$IMAGE" "$pkg" "${pkg}-debug"

    local log_dir="$APP_PLAYER_DIR/out-app-player-Baklava/logs"
    mkdir -p "$log_dir"
    local time_tag
    time_tag="$(date +%y%m%d-%H-%M)"
    local log_file="$log_dir/build_${IMAGE}-${time_tag}.log"

    echo "=== Baklava64 local build (Jenkins-style via build.sh) ==="
    echo "APP_PLAYER_DIR=$APP_PLAYER_DIR"
    echo "LOCAL_BUILDSCRIPTS_DIR=$LOCAL_BUILDSCRIPTS_DIR"
    echo "BRANCH=$BRANCH"
    echo "OEM=$OEM"
    echo "ANDROID_IMAGES=$ANDROID_IMAGES"
    echo "FORCE_CLEAN=$FORCE_CLEAN"
    echo "SYNC_SOURCE_CODE=$SYNC_SOURCE_CODE"
    echo "ENABLE_DEXOPT=$ENABLE_DEXOPT"
    echo "ANDROID_BUILD_NUMBER=$ANDROID_BUILD_NUMBER"
    echo "ANDROIDOUTPUTLOC=$ANDROIDOUTPUTLOC"
    echo "JAVA_HOME=$JAVA_HOME"
    echo "LC_ALL=$LC_ALL LANG=$LANG"
    echo "PARALLEL_NX_PROCESSORS_MAKEFILE=${PARALLEL_NX_PROCESSORS_MAKEFILE:-<unset>}"
    echo "PARALLEL_NX_PROCESSORS_BUILD_SH=${PARALLEL_NX_PROCESSORS_BUILD_SH:-<unset>}"
    echo "LOG=$log_file"

    bash -x "$REPO_BUILDSCRIPTS/build.sh" 2>&1 | tee "$log_file"
    return "${PIPESTATUS[0]}"
}
