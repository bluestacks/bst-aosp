#!/bin/bash
# R240: Henry — stage audio.primary.bst + alsa configs + repack Root.vhd
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=~/aosp16/out_nxt_Baklava64/target/product/x86_64/system
A13=~/app-player/android-13
BST=~/aosp16/hardware/bst/audio
LOG=~/r240-pack.log
exec > >(tee "$LOG") 2>&1
echo "=== R240 BST audio pack $(date) ==="

PRIMARY="$OUT/lib64/hw/audio.primary.bst.so"
[ -f "$PRIMARY" ] || PRIMARY=$(find ~/aosp16/out_nxt_Baklava64 -path '*/audio.primary.bst.so' -type f | head -1)
[ -f "$PRIMARY" ] || { echo "missing audio.primary.bst.so" >&2; exit 1; }

mkdir -p "$OD/system/lib64/hw" "$OD/system/vendor/lib64/hw" \
  "$OD/system/usr/share/alsa/pcm" "$OD/system/usr/share/alsa/cards" \
  "$OD/system/usr/share/alsa/init" "$OD/system/vendor/etc"

# Henry primary HAL (legacy audio HAL for bstaudio/tinyalsa)
cp -a "$PRIMARY" "$OD/system/lib64/hw/audio.primary.bst.so"
cp -a "$PRIMARY" "$OD/system/vendor/lib64/hw/audio.primary.bst.so"
echo "audio.primary.bst md5=$(md5sum "$PRIMARY" | awk '{print $1}')"

# Policy configs from Henry BST audio tree
cp -a "$BST/audio_policy_configuration.xml" "$OD/system/vendor/etc/"
cp -a "$BST/primary_audio_policy_configuration.xml" "$OD/system/vendor/etc/"

# alsa.conf tree (Henry alsa.mk; A16 blocks alsa-lib Android.mk — copy configs only)
ALSA_SRC="$A13/external/alsa-lib/src/conf"
ALSA_DST="$OD/system/usr/share/alsa"
for f in alsa.conf pcm/dsnoop.conf pcm/modem.conf pcm/dpl.conf pcm/default.conf \
  pcm/surround51.conf pcm/surround41.conf pcm/surround50.conf pcm/dmix.conf \
  pcm/center_lfe.conf pcm/surround40.conf pcm/side.conf pcm/iec958.conf \
  pcm/rear.conf pcm/surround71.conf pcm/front.conf cards/aliases.conf; do
  install -D -m 0644 "$ALSA_SRC/$f" "$ALSA_DST/$f"
done
ALSA_INIT="$A13/external/alsa-utils/alsactl/init"
for f in 00main default hda help info test; do
  install -D -m 0644 "$ALSA_INIT/$f" "$ALSA_DST/init/$f"
done

# libtinyalsa if built alongside
for lib in "$OUT/lib64/libtinyalsa.so" "$OUT/lib/libtinyalsa.so"; do
  [ -f "$lib" ] && cp -a "$lib" "$OD/system/$(basename "$(dirname "$lib")")/" && echo "staged $(basename "$lib")"
done

ls -la "$OD/system/lib64/hw/audio.primary.bst.so" "$OD/system/vendor/lib64/hw/audio.primary.bst.so"

bash ~/app-player/buildscripts/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R240_PACK_DONE
