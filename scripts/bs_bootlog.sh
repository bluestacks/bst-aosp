#!/boot/bin/sh
# Henry bs_bootlog: pipe logcat to kmsg for Player.log (boot mid-way, no adb required)
LOGCAT=/boot/bin/logcat
[ -x "$LOGCAT" ] || LOGCAT=/data/system_bin/logcat
[ -x "$LOGCAT" ] || LOGCAT=/data/local/tmp/logcat
[ -x "$LOGCAT" ] || LOGCAT=/system/bin/logcat
echo "<0>A16DBG: henry-7AJ bs_bootlog start logcat=$LOGCAT" > /dev/kmsg
i=0
while [ $i -lt 120 ]; do
    [ -S /dev/socket/logd ] && break
    /boot/bin/busybox sleep 1 2>/dev/null || sleep 1
    i=$((i + 1))
done
if [ ! -S /dev/socket/logd ]; then
    echo "<3>A16DBG: henry-7AJ bs_bootlog no logd after ${i}s" > /dev/kmsg
    exit 1
fi
echo "<0>A16DBG: henry-7AJ bs_bootlog logd ok after ${i}s" > /dev/kmsg
LINKER=/boot/bin/linker64
[ -x "$LINKER" ] || LINKER=/data/system_bin/linker64
[ -x "$LINKER" ] || LINKER=/system/bin/bootstrap/linker64
[ -x "$LINKER" ] || LINKER=/apex/com.android.runtime/bin/linker64
LINKER_LOG=/system/bin/bootstrap/linker64
[ -x "$LINKER_LOG" ] || LINKER_LOG="$LINKER"
export LD_LIBRARY_PATH=/apex/com.android.runtime/lib64/bionic:/data/system_lib64:/system/lib64
if [ -x "$LINKER_LOG" ] && [ -x "$LOGCAT" ]; then
    echo "<0>A16DBG: henry-7AJ bs_bootlog linker=$LINKER_LOG logcat=$LOGCAT" > /dev/kmsg
    exec "$LINKER_LOG" "$LOGCAT" -v threadtime -b all \
        odsign:V odrefresh:V dex2oat:V keystore2:V vold:V ServiceManager:V \
        PackageManager:I SystemServerTiming:I ActivityManager:I PackageManagerService:I \
        installd:I Installer:W init:I ServiceManager:I \
        gralloc:E HostConnection:E EmuHWC2:E allocator:E PGA:E hst:E art:E \
        AndroidRuntime:E libc:F zygote:E DEBUG:F linker:E AccessPersistence:W *:E \
        2>/data/bs_bootlog.stderr |
    while IFS= read -r line; do
        echo "<0>A16DBG: ZYGLOG: $line" > /dev/kmsg
    done
fi
echo "<3>A16DBG: henry-7AJ bs_bootlog fail linker=$LINKER logcat=$LOGCAT" > /dev/kmsg
exit 1