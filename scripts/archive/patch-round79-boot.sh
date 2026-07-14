#!/bin/bash
# Round 79: initrd art-libs (art-only) + /data/art-libs cat staging for zygote
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
ART_SRC="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/obj/PACKAGING/check_vintf_all_intermediates/apex/com.android.art/lib64"
SYS_LIB="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/lib64"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"

mkdir -p "$BOOT/art-libs"
rm -f "$BOOT/art-libs"/*.so
# Pack art-only libs (exclude system/lib64 overlap — libbase/libc++ etc needed by init)
for f in "$ART_SRC"/*.so; do
    base=$(basename "$f")
    if [ -f "$SYS_LIB/$base" ]; then
        continue
    fi
    cp "$f" "$BOOT/art-libs/$base"
done
ls -la "$BOOT/art-libs/libnativeloader.so" "$BOOT/art-libs/libart.so"
echo "art-only count=$(ls "$BOOT/art-libs"/*.so | wc -l)"

I18N_SRC="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/obj/PACKAGING/check_vintf_all_intermediates/apex/com.android.i18n/lib64"
mkdir -p "$BOOT/i18n-libs"
rm -f "$BOOT/i18n-libs"/*.so
for f in "$I18N_SRC"/*.so; do
    base=$(basename "$f")
    if [ -f "$SYS_LIB/$base" ]; then
        continue
    fi
    cp "$f" "$BOOT/i18n-libs/$base"
done
ls -la "$BOOT/i18n-libs/libicu.so"
echo "i18n-only count=$(ls "$BOOT/i18n-libs"/*.so | wc -l)"

python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
i18n_block = """
\tmkdir -p initrd/boot/i18n-libs
\t@test -f i18n-libs/libicu.so && cp -a i18n-libs/. initrd/boot/i18n-libs/ || (echo "missing i18n-libs/libicu.so" && exit 1)"""
art_anchor = "\tcp art-payload.img initrd/boot/art-payload.img"
if "initrd/boot/i18n-libs" not in text:
    if "initrd/boot/art-libs" in text:
        text = text.replace(
            "\t@test -f art-libs/libnativeloader.so && cp -a art-libs/. initrd/boot/art-libs/ || (echo \"missing art-libs/libnativeloader.so\" && exit 1)",
            "\t@test -f art-libs/libnativeloader.so && cp -a art-libs/. initrd/boot/art-libs/ || (echo \"missing art-libs/libnativeloader.so\" && exit 1)" + i18n_block,
            1,
        )
    elif art_anchor in text:
        text = text.replace(art_anchor, art_anchor + i18n_block, 1)
    else:
        raise SystemExit("Makefile anchor not found for i18n-libs")
    mk.write_text(text)
    print("Makefile: added i18n-libs COPY")
else:
    print("Makefile: i18n-libs already present")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -8
zcat initrd.img | cpio -t 2>/dev/null | grep 'art-libs/libnativeloader'
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND79_DONE
