#!/bin/bash
# G8: remove vendor HAL init rc that crash before boot_completed (M1 §7V pattern)
# A16 init ParseConfigDir loads ALL regular files in vendor/etc/init — *.rc.disabled still parsed.
set -euo pipefail
SYSTEM="${1:-$HOME/releases/Baklava64/system}"
INIT="$SYSTEM/vendor/etc/init"
BACKUP="$SYSTEM/vendor/etc/init.disabled_by_g8"
LOG="${G8_LOG:-$HOME/g8_disable_vendor_hal_rc.log}"
exec > >(tee -a "$LOG") 2>&1

if [ ! -d "$INIT" ]; then
  echo "A16DBG:G8: missing vendor init dir: $INIT"
  exit 1
fi

mkdir -p "$BACKUP"

# Layer2 blockers (G1) + M1 known missing-HAL services + new configstore crash
DISABLE=(
  android.hardware.health@2.1-service.rc
  android.hardware.drm@1.0-service.rc
  android.hardware.camera.provider@2.4-service.rc
  android.hardware.configstore@1.1-service.rc
  android.hardware.memtrack@1.0-service.rc
  android.hardware.gnss@1.0-service.rc
  android.hardware.usb@1.0-service.rc
  android.hardware.keymaster@4.1-service.rc
  vendor.gnss_service.rc
  vendor.memtrack-hal-1-0.rc
)

echo "A16DBG:G8: remove vendor HAL rc start system=$SYSTEM $(date -Is)"
n=0
for rc in "${DISABLE[@]}"; do
  for src in "$INIT/$rc" "$INIT/${rc}.disabled"; do
    if [ -f "$src" ]; then
      mv "$src" "$BACKUP/"
      echo "  moved $(basename "$src") -> init.disabled_by_g8/"
      n=$((n + 1))
    fi
  done
done
# A16 ParseConfigDir loads every regular file — sweep stray *.rc.disabled too.
for src in "$INIT"/*.rc.disabled; do
  [ -f "$src" ] || continue
  mv "$src" "$BACKUP/"
  echo "  moved $(basename "$src") -> init.disabled_by_g8/"
  n=$((n + 1))
done

echo "A16DBG:G8: removed $n rc files; active vendor init rc:"
ls -1 "$INIT"/*.rc 2>/dev/null || echo "  (none)"
echo "A16DBG:G8: remove vendor HAL rc DONE"
