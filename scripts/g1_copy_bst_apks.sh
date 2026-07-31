#!/bin/bash
# G1: pre-install BST custom APKs into /system/priv-app (from apks_Baklava64 prebuilt = M1/BST source).
# APKs are PREBUILT (compiled once); this only COPIES + extracts native libs — no recompile.
# Reason: APPCONFFILE classifies these as Priv-Downloads (installed via dataFS on first boot).
# G1 removed dataFS (no apk data), so we FORCE pre-install into system/priv-app instead →
# launcher becomes HOME on every boot (proven via adb install) → host ActivityDisplayed → [Ready].
# Run AFTER g1_stage_system.sh (rsync --delete) and BEFORE r228-pack-root.sh.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/android16_env.sh"
bst_android16_preflight
APKFOLDER="$BST_APP_PLAYER_ROOT/bst/apks_Baklava64"
OUT="$BST_RELEASE_ROOT/system"        # staged system root
LOG=~/g1_copy_bst_apks.log
[ "${1:-}" != "--check" ] || {
  [ -d "$APKFOLDER" ] || { echo "missing $APKFOLDER"; exit 1; }
  [ -f "$OUT/build.prop" ] || { echo "missing $OUT/build.prop"; exit 1; }
  echo "A16DBG:ANDROID16: copy-apks CHECK OK; no files copied"
  exit 0
}
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: copy_bst_apks (force priv-app pre-install) start $(date -Is)"

# ro.hardware.gralloc=bst + ro.hardware.egl=emulation — RELIABLE mechanism (early build.prop load).
# NOTE: init.sh init_hal_gralloc() was tried as the formal fix but PROVEN INEFFECTIVE (2026-07-20):
# init.sh runs AFTER hwcomposer inits -> gralloc unset at hwcomposer init -> hwcomposer SIGSEGV ×830.
# build.prop is loaded by init VERY early (before HALs) -> append here is reliable.
# FORMAL fix DONE (2026-07-20 cont.12): PRODUCT_PROPERTY_OVERRIDES in bst_x86_64.mk bakes into OUT build.prop.
# Append below is idempotent safety-net only (skip if already present from bake).
# in device/bst/qvirt/bst_x86_64.mk (bakes into build.prop at build time). Until that rebuild,
# this post-stage append is the working mechanism.
PROP="$OUT/build.prop"
grep -q '^ro.hardware.gralloc=' "$PROP" 2>/dev/null || echo "ro.hardware.gralloc=bst" >> "$PROP"
grep -q '^ro.hardware.egl=' "$PROP" 2>/dev/null || echo "ro.hardware.egl=emulation" >> "$PROP"
echo "  build.prop: ro.hardware.gralloc=$(grep '^ro.hardware.gralloc=' "$PROP") , egl=$(grep '^ro.hardware.egl=' "$PROP")"

# Boot-critical BST custom apks (HOME launcher + host redirect target). Pre-installed to priv-app.
APKS=(com.uncube.launcher3.apk com.bluestacks.gamecenter.apk com.bluestacks.bsxlauncher.apk)
copied=0
for apk in "${APKS[@]}"; do
  src="$APKFOLDER/$apk"
  [ -f "$src" ] || { echo "ERROR: required APK missing: $src" >&2; exit 1; }
  pkg=$(basename -s .apk "$apk")
  dest="$OUT/priv-app/$pkg"
  mkdir -p "$dest"
  cp -a "$src" "$dest/$apk"
  chmod 664 "$dest/$apk"
  # pre-extract native libs (system scans priv-app; pre-extract ensures libs available without
  # relying on first-boot extraction). unzip lib/x86_64 + lib/x86 from the apk.
  tmp=$(mktemp -d)
  ( cd "$tmp" && unzip -o -q "$src" 'lib/x86_64/*' 'lib/x86/*' 2>/dev/null )
  if [ -d "$tmp/lib" ]; then
    cp -a "$tmp/lib" "$dest/"
    echo "  $apk -> priv-app/$pkg/ (+lib: $(find "$dest/lib" -type f | wc -l) sos)"
  else
    echo "  $apk -> priv-app/$pkg/ (no native libs in apk)"
  fi
  rm -rf "$tmp"
  copied=$((copied+1))
done

echo "A16DBG:G1: copy_bst_apks DONE copied=$copied $(date -Is)"
[ "$copied" -eq "${#APKS[@]}" ] || {
  echo "ERROR: copied $copied/${#APKS[@]} required APKs" >&2
  exit 1
}
echo "=== readback: launcher in staged priv-app? ==="
ls -la "$OUT/priv-app/com.uncube.launcher3/" 2>/dev/null
find "$OUT/priv-app/com.uncube.launcher3/lib" -type f 2>/dev/null | head
