#!/bin/bash
# Round 150: add os.statsd + cellbroadcast + extservices to mainline-javalib batch
set -e
BOOT=~/app-player/hd/guest/BootImage
APEX_DIR=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/apex
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
ML_DIR="$BOOT/mainline-javalib"
rm -rf "$ML_DIR"
mkdir -p "$ML_DIR"
MODULES="adservices appsearch bt cellbroadcast configinfrastructure conscrypt crashrecovery devicelock extservices healthfitness ipsec media mediaprovider neuralnetworks nfcservices ondevicepersonalization os.statsd permission profiling rkpd scheduling sdkext telephonycore tethering uprobestats uwb virt wifi"
for mod in $MODULES; do
    capex="$APEX_DIR/com.android.$mod.capex"
    apex="$APEX_DIR/com.android.$mod.apex"
    inner=""
    if [ -f "$capex" ]; then
        unzip -q -p "$capex" original_apex > "/tmp/${mod}-inner.apex"
        inner="/tmp/${mod}-inner.apex"
    elif [ -f "$apex" ]; then
        inner="$apex"
    else
        continue
    fi
    MP="/tmp/ml-mp-$$"
    mkdir -p "$MP"
    LP=$(sudo losetup -o 4096 -f --show "$inner") || continue
    if sudo mount -t erofs -o ro "$LP" "$MP" 2>/dev/null; then
        if [ -d "$MP/javalib" ] && [ -n "$(ls -A "$MP/javalib"/*.jar 2>/dev/null)" ]; then
            mkdir -p "$ML_DIR/com.android.$mod"
            cp "$MP/javalib"/*.jar "$ML_DIR/com.android.$mod/"
            echo "  $mod: $(ls "$ML_DIR/com.android.$mod" | wc -l) jars"
        fi
        sudo umount "$MP"
    fi
    sudo losetup -d "$LP" 2>/dev/null || true
    rm -f "/tmp/${mod}-inner.apex"
done
du -sh "$ML_DIR"
ls "$ML_DIR" | wc -l
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND150_DONE
