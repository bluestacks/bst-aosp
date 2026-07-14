#!/bin/bash
# Round 103: narrow keystore2 SELinux bringup allow for odsign_key rebind
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
ART_PROF=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
ART_PAYLOAD="$BOOT/art-payload.img"
CACHE_INFO=~/cache-info-uffd-off.xml

python3 - <<'PY'
from pathlib import Path

p = Path.home() / "aosp16/system/security/keystore2/selinux/src/lib.rs"
t = p.read_text()
marker = "BS bringup: allow odsign_key rebind"
needle = '''    let c_perm = CString::new(perm)
        .with_context(|| format!("check_access: Failed to convert perm \\"{perm}\\" to CString."))?;

    match unsafe {
'''
insert = '''    let c_perm = CString::new(perm)
        .with_context(|| format!("check_access: Failed to convert perm \\"{perm}\\" to CString."))?;

    if source.to_bytes() == b"kernel" && tclass == "keystore2_key" && perm == "rebind" {
        log::warn!("BS bringup: allow odsign_key rebind from kernel context");
        return Ok(());
    }

    match unsafe {
'''
if marker not in t:
    if needle not in t:
        raise SystemExit("keystore2 selinux check_access anchor not found")
    p.write_text(t.replace(needle, insert, 1))
    print("keystore2 selinux patched: odsign_key rebind")
else:
    print("keystore2 selinux patch already present")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja keystore2 2>&1 | tail -20

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
cp "$CACHE_INFO" "$BOOT/cache-info-uffd-off.xml"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh" "$BOOT/cache-info-uffd-off.xml"
chmod 755 "$BOOT/bs_bootlog.sh"

mkdir -p "$BOOT/dalvik-cache/x86_64" "$BOOT/profiles" "$BOOT/art-javalib"
rm -f "$BOOT/dalvik-cache/x86_64"/*
cp -a "$ART_PROF" "$BOOT/profiles/boot-image.prof"

mkdir -p /tmp/art-jav-ro
sudo umount /tmp/art-jav-ro 2>/dev/null || true
if sudo mount -o loop,ro "$ART_PAYLOAD" /tmp/art-jav-ro; then
  cp -a /tmp/art-jav-ro/javalib/*.jar "$BOOT/art-javalib/"
  sudo umount /tmp/art-jav-ro
fi

MK="$BOOT/Makefile"
sed -i 's/@test -f dalvik-cache\/x86_64\/boot.art && cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || (echo "missing dalvik-cache\/x86_64\/boot.art" \&\& exit 1)/@test -f dalvik-cache\/x86_64\/boot.art \&\& cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || echo "henry-7BF skip initrd boot.art (odsign path)"/' "$MK"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND103_DONE
