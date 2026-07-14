#!/bin/bash
# R241: stage real audio@7.1-impl + BST audio.primary.bst → system.sfs → Root.vhd
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=~/aosp16/out_nxt_Baklava64/target/product/x86_64/system
BST=~/aosp16/hardware/bst/audio
A13=~/app-player/android-13
LOG=~/r241-pack.log
exec > >(tee "$LOG") 2>&1
echo "=== R241 audio HIDL pack $(date) ==="

VENDOR_LIB="$OUT/vendor/lib64"
VENDOR_HW="$OUT/vendor/lib64/hw"
VENDOR_BIN="$OUT/vendor/bin/hw"
for f in \
  "$VENDOR_HW/android.hardware.audio@7.1-impl.so" \
  "$VENDOR_HW/android.hardware.audio@7.0-impl.so" \
  "$VENDOR_HW/android.hardware.audio.effect@7.0-impl.so" \
  "$VENDOR_BIN/android.hardware.audio.service" \
  "$OUT/lib64/hw/audio.primary.bst.so" \
  "$VENDOR_LIB/android.hardware.audio@7.1.so" \
  "$VENDOR_LIB/android.hardware.audio@7.1-util.so" \
  "$VENDOR_LIB/android.hardware.audio.common@7.1-enums.so" \
  "$VENDOR_LIB/android.hardware.audio.common@7.1-util.so"; do
  [ -f "$f" ] || { echo "missing build artifact: $f" >&2; exit 1; }
done

mkdir -p "$OD/system/vendor/lib64/hw" "$OD/system/vendor/lib64" "$OD/system/vendor/bin/hw" \
  "$OD/system/lib64/hw" "$OD/system/vendor/etc" \
  "$OD/system/usr/share/alsa/pcm" "$OD/system/usr/share/alsa/cards" \
  "$OD/system/usr/share/alsa/init"

# HIDL passthrough stack (real 7.1 — no R239 filename alias)
cp -a "$VENDOR_HW/android.hardware.audio@7.1-impl.so" "$OD/system/vendor/lib64/hw/"
cp -a "$VENDOR_HW/android.hardware.audio@7.0-impl.so" "$OD/system/vendor/lib64/hw/"
cp -a "$VENDOR_HW/android.hardware.audio.effect@7.0-impl.so" "$OD/system/vendor/lib64/hw/"
cp -a "$VENDOR_BIN/android.hardware.audio.service" "$OD/system/vendor/bin/hw/"
# HIDL transport libs required for dlopen of @7.1-impl (missing in R241a pack)
cp -a "$VENDOR_LIB/android.hardware.audio@7.1.so" "$OD/system/vendor/lib64/"
cp -a "$VENDOR_LIB/android.hardware.audio@7.1-util.so" "$OD/system/vendor/lib64/"
cp -a "$VENDOR_LIB/android.hardware.audio.common@7.1-enums.so" "$OD/system/vendor/lib64/"
cp -a "$VENDOR_LIB/android.hardware.audio.common@7.1-util.so" "$OD/system/vendor/lib64/"

# BST legacy primary HAL
cp -a "$OUT/lib64/hw/audio.primary.bst.so" "$OD/system/lib64/hw/"
cp -a "$OUT/lib64/hw/audio.primary.bst.so" "$OD/system/vendor/lib64/hw/"

# Remove stale R239 fake 7.1 alias if present
rm -f "$OD/system/vendor/lib64/hw/android.hardware.audio@7.1-impl.so.r239"

# Policy configs
cp -a "$BST/audio_policy_configuration.xml" "$OD/system/vendor/etc/"
cp -a "$BST/primary_audio_policy_configuration.xml" "$OD/system/vendor/etc/"

# alsa conf tree (Henry alsa.mk; copy-only on A16)
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

ls -la "$OD/system/vendor/lib64/hw/android.hardware.audio@"* \
  "$OD/system/vendor/bin/hw/android.hardware.audio.service" \
  "$OD/system/lib64/hw/audio.primary.bst.so"
md5sum "$OD/system/vendor/lib64/hw/android.hardware.audio@"*.so \
  "$OD/system/lib64/hw/audio.primary.bst.so"

# SELinux exec label: incremental pack lacks mkuserimg file_contexts → vendor.audio-hal
# stays kernel domain and cannot register HIDL (FactoryHal: Found no HAL version).
set_selinux() {
  local ctx="$1" f="$2"
  [ -f "$f" ] || return 0
  if ! setfattr -n security.selinux -v "$ctx" "$f" 2>/dev/null; then
    chcon "$ctx" "$f" 2>/dev/null || echo "warn: no selinux xattr on $f" >&2
  fi
}
set_selinux u:object_r:hal_audio_default_exec:s0 "$OD/system/vendor/bin/hw/android.hardware.audio.service"
for f in "$OD/system/vendor/lib64/hw/android.hardware.audio@"*.so \
         "$OD/system/vendor/lib64/hw/android.hardware.audio.effect@"*.so; do
  set_selinux u:object_r:same_process_hal_file:s0 "$f"
done
set_selinux u:object_r:same_process_hal_file:s0 "$OD/system/lib64/hw/audio.primary.bst.so"
set_selinux u:object_r:same_process_hal_file:s0 "$OD/system/vendor/lib64/hw/audio.primary.bst.so"

# init.rc: vendor HALs need restorecon when system.sfs lacks SELinux xattrs (incremental pack).
INIT_RC="$OD/system/etc/init/hw/init.rc"
if [ -f "$INIT_RC" ] && ! grep -q 'BS-A16: restorecon /vendor for HAL exec domains' "$INIT_RC"; then
  sed -i '/^on boot$/a\    # BS-A16: restorecon /vendor for HAL exec domains\n    mount -o remount,rw /system\n    restorecon_recursive /vendor\n    restorecon_recursive /system/vendor\n    mount -o remount,ro /system' "$INIT_RC"
  echo "patched $INIT_RC for vendor restorecon (rw remount)"
fi

ls -laZ "$OD/system/vendor/bin/hw/android.hardware.audio.service" 2>/dev/null || \
  ls -la "$OD/system/vendor/bin/hw/android.hardware.audio.service"

bash ~/app-player/buildscripts/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R241_PACK_DONE
