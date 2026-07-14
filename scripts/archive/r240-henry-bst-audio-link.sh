#!/bin/bash
# R240: Henry standard — link BST HAL + alsa deps from app-player/android-13 into aosp16
set -euo pipefail
AOSP=~/aosp16
A13=~/app-player/android-13
LOG=~/r240-bst-link.log
exec > >(tee "$LOG") 2>&1
echo "=== R240 Henry BST HAL link $(date) ==="

for d in hardware/bst external/alsa-lib external/alsa-utils external/alsa-ucm-conf; do
  src="$A13/$d"
  dst="$AOSP/$d"
  if [ ! -d "$src" ]; then
    echo "missing Henry source: $src" >&2
    exit 1
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "refusing to replace non-symlink: $dst" >&2
    exit 1
  fi
  rm -f "$dst"
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
done

echo "--- verify ---"
ls -la "$AOSP/hardware/bst"
ls "$AOSP/hardware/bst/audio"
test -f "$AOSP/hardware/bst/audio/Android.mk"
test -f "$AOSP/external/alsa-lib/android/Android.mk"
echo R240_BST_LINK_DONE
