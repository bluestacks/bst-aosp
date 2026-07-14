#!/bin/bash
# Sync Henry reference boot scripts into app-player hd/guest BootImage.
set -euo pipefail

APP_PLAYER_DIR="${APP_PLAYER_DIR:-$HOME/app-player}"
REF_DIR="${REF_DIR:-$HOME/bst-aosp-patches/henry-hd-guest}"
BOOT="$APP_PLAYER_DIR/hd/guest/BootImage"

if [[ ! -d "$REF_DIR/BootImage" ]]; then
  echo "Missing reference BootImage: $REF_DIR/BootImage" >&2
  exit 1
fi

for f in init.sh stage2.sh bstsetup.env 4-dpi bstsetconf.sh; do
  if [[ -f "$REF_DIR/BootImage/$f" ]]; then
    cp -f "$REF_DIR/BootImage/$f" "$BOOT/$f"
  fi
done

# Keep R177 lesson: do not blindly replace if caller already adapted init.sh.
echo "BOOTIMAGE_SYNC_OK files=$(ls -1 $BOOT/init.sh $BOOT/stage2.sh $BOOT/bstsetup.env 2>/dev/null | wc -l)"
