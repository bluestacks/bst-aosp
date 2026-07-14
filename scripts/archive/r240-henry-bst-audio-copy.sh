#!/bin/bash
# R240: Henry standard — copy BST HAL + alsa deps into aosp16 tree (symlinks outside TOP fail mm)
set -euo pipefail
AOSP=~/aosp16
A13=~/app-player/android-13
LOG=~/r240-bst-copy.log
exec > >(tee "$LOG") 2>&1
echo "=== R240 Henry BST HAL copy into aosp16 $(date) ==="

copy_tree() {
  local rel="$1"
  local src="$A13/$rel"
  local dst="$AOSP/$rel"
  [ -d "$src" ] || { echo "missing $src" >&2; exit 1; }
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  rsync -a --delete "$src/" "$dst/"
  echo "copied $rel"
}

for d in hardware/bst external/alsa-lib external/alsa-utils external/alsa-ucm-conf; do
  copy_tree "$d"
done

echo "--- verify under TOP ---"
test -f "$AOSP/hardware/bst/audio/Android.mk"
test -f "$AOSP/external/alsa-lib/android/Android.mk"
! readlink -f "$AOSP/hardware/bst" | grep -q app-player/android-13 || {
  echo "still symlinked outside tree" >&2; exit 1;
}
echo R240_BST_COPY_DONE
