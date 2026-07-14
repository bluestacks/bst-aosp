#!/bin/bash
# R243: Henry — restore audio@7.0 + effect@7.0 into device VINTF so FactoryHal
# getTransport() is not EMPTY (root cause of audioserver SIGSEGV death spiral).
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
AOSP=~/aosp16
LOG=~/r243-pack.log
exec > >(tee "$LOG") 2>&1
echo "=== R243 audio VINTF pack $(date) ==="

# 1) Permanent source: device/generic/common/manifest.xml (Henry a13 content for audio/effect)
MANIFEST="$AOSP/device/generic/common/manifest.xml"
cp -a "$MANIFEST" "$MANIFEST.bak-r243-$(date +%H%M%S)"
cat > "$MANIFEST" <<'EOF'
<!-- Henry a13 audio/effect + keep A16 target-level; graphics HALs live in manifest/ fragments -->
<manifest version="1.0" type="device" target-level="8">
    <hal format="hidl">
        <name>android.hardware.audio</name>
        <transport>hwbinder</transport>
        <version>7.0</version>
        <interface>
            <name>IDevicesFactory</name>
            <instance>default</instance>
        </interface>
    </hal>
    <hal format="hidl">
        <name>android.hardware.audio.effect</name>
        <transport>hwbinder</transport>
        <version>7.0</version>
        <interface>
            <name>IEffectsFactory</name>
            <instance>default</instance>
        </interface>
    </hal>
</manifest>
EOF
echo "updated $MANIFEST"

# 2) Incremental: vendor VINTF fragment (merged at runtime; no full rebuild needed)
FRAG_DIR="$OD/system/vendor/etc/vintf/manifest"
mkdir -p "$FRAG_DIR"
FRAG="$FRAG_DIR/android.hardware.audio@7.0.xml"
cat > "$FRAG" <<'EOF'
<!--
    Henry / R243: audio@7.0 + effect@7.0 (from a13 device/generic/common/manifest.xml)
    Without this, FactoryHal getTransport() returns EMPTY → Found no HAL version →
    audioserver SIGSEGV → init kills vendor.audio-hal (death spiral).
-->
<manifest version="1.0" type="device">
    <hal format="hidl">
        <name>android.hardware.audio</name>
        <transport>hwbinder</transport>
        <version>7.0</version>
        <interface>
            <name>IDevicesFactory</name>
            <instance>default</instance>
        </interface>
    </hal>
    <hal format="hidl">
        <name>android.hardware.audio.effect</name>
        <transport>hwbinder</transport>
        <version>7.0</version>
        <interface>
            <name>IEffectsFactory</name>
            <instance>default</instance>
        </interface>
    </hal>
</manifest>
EOF
echo "staged $FRAG"
cat "$FRAG"

# Keep Henry audio artifacts present
test -f "$OD/system/vendor/bin/hw/android.hardware.audio.service"
test -f "$OD/system/vendor/lib64/hw/android.hardware.audio@7.0-impl.so"
test -f "$OD/system/lib64/hw/audio.primary.bst.so"

# Henry-align treble: prefer 7.0 only in product (optional note; image may still have 7.1)
if grep -q 'android.hardware.audio@7.1-impl' "$AOSP/device/generic/common/treble.mk"; then
  sed -i '/android.hardware.audio@7.1-impl/d' "$AOSP/device/generic/common/treble.mk"
  echo "removed audio@7.1-impl from treble.mk (Henry uses 7.0)"
fi

cp -a ~/make-baklava-system-sfs.sh ~/app-player/buildscripts/make-baklava-system-sfs.sh
sed -i 's/\r$//' ~/app-player/buildscripts/make-baklava-system-sfs.sh
bash ~/app-player/buildscripts/make-baklava-system-sfs.sh "$OD"

# Verify fragment + labels inside ext4
TMP=$(mktemp -d)
sudo mount -o loop,ro "$OD/system.img" "$TMP"
test -f "$TMP/vendor/etc/vintf/manifest/android.hardware.audio@7.0.xml"
grep -q IDevicesFactory "$TMP/vendor/etc/vintf/manifest/android.hardware.audio@7.0.xml"
getfattr -n security.selinux --only-values \
  "$TMP/vendor/bin/hw/android.hardware.audio.service" 2>/dev/null | grep -q hal_audio_default_exec \
  && echo "SELINUX_OK+VINTF_OK"
sudo umount "$TMP"
rmdir "$TMP"

md5sum "$OD/system.sfs" "$OD/system.img"
export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R243_PACK_DONE
ls -la ~/releases/Baklava64/$PKG/Root.vhd
md5sum ~/releases/Baklava64/$PKG/Root.vhd
