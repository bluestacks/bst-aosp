#!/bin/bash
# Explicit one-time clean Android-16 baseline build. Subsequent builds are incremental.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BST_OUT_DIR_NAME="${BST_OUT_DIR_NAME:-out_nxt_Baklava64}"
export BST_ALLOWED_ROOT_DIRTY_PATHS="${BST_ALLOWED_ROOT_DIRTY_PATHS:-.gitignore}"
# shellcheck source=scripts/lib/android16_env.sh
source "$SCRIPT_DIR/lib/android16_env.sh"

EXPECTED_HEAD=""
JOBS=8
while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-head)
      shift
      EXPECTED_HEAD="${1:-}"
      ;;
    --jobs)
      shift
      JOBS="${1:-}"
      ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$EXPECTED_HEAD" ] || { echo "--expected-head is required" >&2; exit 2; }
case "$JOBS" in
  ''|*[!0-9]*) echo "jobs must be an integer from 1 through 8" >&2; exit 2 ;;
esac
[ "$JOBS" -ge 1 ] && [ "$JOBS" -le 8 ] || { echo "jobs must be from 1 through 8" >&2; exit 2; }

bst_android16_preflight
ROOT="$(bst_realpath "$BST_ANDROID16_ROOT")"
OUT="$ROOT/$BST_OUT_DIR_NAME"
[ "$ROOT" = "/home/clouddev/bst/workspace/markxu/android-16" ] || {
  echo "refusing unexpected Android root: $ROOT" >&2
  exit 1
}
[ "$(bst_realpath "$OUT")" = "$ROOT/out_nxt_Baklava64" ] || {
  echo "refusing unexpected OUT path: $OUT" >&2
  exit 1
}
[ "$(git -C "$ROOT" rev-parse HEAD)" = "$EXPECTED_HEAD" ] || {
  echo "Android HEAD changed from the authorized clean baseline" >&2
  exit 1
}
if ps -eo args= | grep -F "$ROOT" | grep -E '[s]oong_ui|[n]inja|build/soong/bin/m ' >/dev/null; then
  echo "a markxu Android build is already running" >&2
  exit 1
fi
mountpoint -q "$OUT" && { echo "refusing to remove mounted OUT: $OUT" >&2; exit 1; }

LOG_ROOT="$(dirname "$ROOT")/build-logs"
mkdir -p "$LOG_ROOT"
LOG="$LOG_ROOT/a16-clean-${EXPECTED_HEAD:0:12}-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$LOG") 2>&1

echo "A16_CLEAN_BUILD_START=$(date -Is)"
echo "A16_ROOT=$ROOT"
echo "A16_ROOT_HEAD=$EXPECTED_HEAD"
echo "A16_OUT=$OUT"
echo "A16_PRODUCT=$BST_LUNCH_TARGET"
echo "A16_TARGETS=init systemimage kernel"
echo "A16_JOBS=$JOBS"

rm -rf --one-file-system -- "$OUT"
[ ! -e "$OUT" ] || { echo "failed to clear OUT: $OUT" >&2; exit 1; }

export OUT_DIR="$BST_OUT_DIR_NAME"
export APP_PLAYER_DIR="/home/clouddev/bst/workspace/markxu/app-player"
export HD_SOURCE_TOP="$APP_PLAYER_DIR/hd"
export ALLOW_MISSING_DEPENDENCIES=true
export WITHOUT_CHECK_API=true
export BUILD_FROM_SOURCE_STUB=true
export BST_BUILD_EXTERNAL_GOLDFISH=true
export BUILD_EMULATOR_OPENGL=true
export BUILD_EMULATOR_OPENGL_DRIVER=true
export NINJA_ARGS="-j$JOBS"
unset USE_CCACHE

cd "$ROOT"
set +u
# shellcheck disable=SC1091
source build/envsetup.sh >/dev/null
lunch "$BST_LUNCH_TARGET" >/dev/null
set -u
m -j"$JOBS" init systemimage kernel

SYSTEM_IMG="$OUT/target/product/x86_64/system.img"
for _ in $(seq 1 60); do
  [ -f "$SYSTEM_IMG" ] && break
  sleep 1
done
[ -f "$SYSTEM_IMG" ] || { echo "clean build did not produce system.img" >&2; exit 1; }
bst_write_identity_file "$LOG.identity" "$SYSTEM_IMG"
printf 'log=%s\n' "$LOG" >> "$LOG.identity"
printf 'build_mode=authorized-clean-once\n' >> "$LOG.identity"
cat "$LOG.identity"
echo "A16_CLEAN_BUILD_DONE=$(date -Is)"
