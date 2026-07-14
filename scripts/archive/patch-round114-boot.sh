#!/bin/bash
# Round 114: expose KeystoreKey initialization failure detail
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
ART_PROF=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
ART_PAYLOAD="$BOOT/art-payload.img"
CACHE_INFO=~/cache-info-uffd-off.xml
ADBC="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.adbd/lib64/libadbconnection_client.so"

python3 - <<'PY'
from pathlib import Path

p = Path.home() / "aosp16/system/security/ondevice-signing/KeystoreKey.cpp"
t = p.read_text()
patches = [
    (
'''    if (sm == nullptr) {
        return false;
    }
''',
'''    if (sm == nullptr) {
        LOG(ERROR) << "Failed to initialize keystore key: defaultServiceManager is null";
        return false;
    }
''',
    ),
    (
'''    if (service == nullptr) {
        return false;
    }
''',
'''    if (service == nullptr) {
        LOG(ERROR) << "Failed to initialize keystore key: keystore2 service is null";
        return false;
    }
''',
    ),
    (
'''    if (mService == nullptr) {
        return false;
    }
''',
'''    if (mService == nullptr) {
        LOG(ERROR) << "Failed to initialize keystore key: interface_cast returned null";
        return false;
    }
''',
    ),
    (
'''    if (!status.isOk()) {
        return false;
    }
''',
'''    if (!status.isOk()) {
        LOG(ERROR) << "Failed to initialize keystore key: getSecurityLevel failed: " << status;
        return false;
    }
''',
    ),
]
changed = False
for old, new in patches:
    if new not in t:
        if old not in t:
            raise SystemExit("KeystoreKey init diagnostic anchor not found")
        t = t.replace(old, new, 1)
        changed = True
if changed:
    p.write_text(t)
    print("KeystoreKey patched: initialize diagnostics")
else:
    print("KeystoreKey initialize diagnostics already present")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja odsign

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
cp "$CACHE_INFO" "$BOOT/cache-info-uffd-off.xml"
cp "$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/odsign" "$BOOT/odsign-patched"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh" "$BOOT/cache-info-uffd-off.xml"
chmod 755 "$BOOT/bs_bootlog.sh" "$BOOT/odsign-patched"

mkdir -p "$BOOT/art-libs" "$BOOT/dalvik-cache/x86_64" "$BOOT/profiles" "$BOOT/art-javalib"
cp -a "$ADBC" "$BOOT/art-libs/libadbconnection_client.so"
rm -f "$BOOT/dalvik-cache/x86_64"/*
cp -a "$ART_PROF" "$BOOT/profiles/boot-image.prof"

mkdir -p /tmp/art-jav-ro
sudo umount /tmp/art-jav-ro 2>/dev/null || true
if sudo mount -o loop,ro "$ART_PAYLOAD" /tmp/art-jav-ro; then
  cp -a /tmp/art-jav-ro/javalib/*.jar "$BOOT/art-javalib/"
  sudo umount /tmp/art-jav-ro
fi

MK="$BOOT/Makefile"
if ! grep -q 'odsign-patched initrd/boot/bin/odsign' "$MK"; then
  sed -i '/cp .*vdc initrd\/boot\/bin\/vdc/a\\tcp odsign-patched initrd/boot/bin/odsign\n\tchmod 755 initrd/boot/bin/odsign' "$MK"
fi
sed -i 's/@test -f dalvik-cache\/x86_64\/boot.art && cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || (echo "missing dalvik-cache\/x86_64\/boot.art" \&\& exit 1)/@test -f dalvik-cache\/x86_64\/boot.art \&\& cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || echo "henry-7BF skip initrd boot.art (odsign path)"/' "$MK"

cd "$BOOT"
echo "odsign-patched bytes=$(wc -c < odsign-patched)"
make initrd.img KDIR=~/aosp16/kernel-a16
zcat initrd.img | cpio -t 2>/dev/null | grep -E 'boot/bin/(keystore2|odsign)'
make build_fastboot KDIR=~/aosp16/kernel-a16
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND114_DONE
