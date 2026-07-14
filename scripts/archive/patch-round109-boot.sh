#!/bin/bash
# Round 109: allow odsign_key use from kernel context and keep patched odsign diagnostics
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
ART_PROF=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
ART_PAYLOAD="$BOOT/art-payload.img"
CACHE_INFO=~/cache-info-uffd-off.xml
ADBC="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.adbd/lib64/libadbconnection_client.so"

python3 - <<'PY'
from pathlib import Path

selinux = Path.home() / "aosp16/system/security/keystore2/selinux/src/lib.rs"
t = selinux.read_text()
old = '''    if source.to_bytes() == b"kernel" && tclass == "keystore2_key" && perm == "rebind" {
        log::warn!("BS bringup: allow odsign_key rebind from kernel context");
        return Ok(());
    }
'''
new = '''    if source.to_bytes() == b"kernel"
        && tclass == "keystore2_key"
        && (perm == "rebind" || perm == "use")
    {
        log::warn!("BS bringup: allow odsign_key {perm} from kernel context");
        return Ok(());
    }
'''
if "(perm == \"rebind\" || perm == \"use\")" not in t:
    if old not in t:
        raise SystemExit("keystore2 selinux rebind allow anchor not found")
    selinux.write_text(t.replace(old, new, 1))
    print("keystore2 selinux patched: odsign_key rebind/use")
else:
    print("keystore2 selinux rebind/use patch already present")

base = Path.home() / "aosp16/system/security/ondevice-signing"
ks = base / "KeystoreKey.cpp"
t = ks.read_text()
old = '''    auto signature = mHmacKey.sign(publicKeyString);
    if (!signature.ok()) {
        return Error() << "Failed to sign public key.";
    }
'''
new = '''    auto signature = mHmacKey.sign(publicKeyString);
    if (!signature.ok()) {
        return Error() << "Failed to sign public key: " << signature.error().message();
    }
'''
if "Failed to sign public key: " not in t:
    if old not in t:
        raise SystemExit("KeystoreKey signature error anchor not found")
    ks.write_text(t.replace(old, new, 1))
    print("odsign patched: expose HMAC public-key signature error")
else:
    print("odsign signature error patch already present")

hmac = base / "KeystoreHmacKey.cpp"
t = hmac.read_text()
patches = [
    (
'''    status = operation->update({message.begin(), message.end()}, &out);
    if (!status.isOk()) {
        return Error() << "Failed to call keystore update operation.";
    }
''',
'''    status = operation->update({message.begin(), message.end()}, &out);
    if (!status.isOk()) {
        return Error() << "Failed to call keystore update operation: " << status;
    }
''',
    ),
    (
'''    status = operation->finish({}, {}, &signature);
    if (!status.isOk()) {
        return Error() << "Failed to call keystore finish operation.";
    }
''',
'''    status = operation->finish({}, {}, &signature);
    if (!status.isOk()) {
        return Error() << "Failed to call keystore finish operation: " << status;
    }
''',
    ),
]
changed = False
for old, new in patches:
    if old in t:
        t = t.replace(old, new, 1)
        changed = True
if changed:
    hmac.write_text(t)
    print("odsign patched: expose HMAC operation status")
elif "Failed to call keystore update operation: " in t and "Failed to call keystore finish operation: " in t:
    print("odsign HMAC status patch already present")
else:
    raise SystemExit("KeystoreHmacKey status anchors not found")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja keystore2 odsign

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
echo "keystore2 bytes=$(wc -c < "$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/keystore2")"
echo "odsign-patched bytes=$(wc -c < odsign-patched)"
make initrd.img KDIR=~/aosp16/kernel-a16
zcat initrd.img | cpio -t 2>/dev/null | grep -E 'boot/bin/(keystore2|odsign)'
make build_fastboot KDIR=~/aosp16/kernel-a16
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND109_DONE
