#!/bin/sh
# stage2 with good Root.vhd — patched init via /tmp/init only, no per-file bind
log_echo() { echo "$@" > /dev/kmsg; }
exec >/dev/kmsg 2>/dev/kmsg
umask 022
die() { log_echo "<2>ERROR: $@"; exit 1; }
warn_if_error() { if [ $? -ne 0 ]; then log_echo "<3>WARNING: $@"; fi; }
die_if_error() { if [ $? -ne 0 ]; then die "$@"; fi; }

log_echo "Mounting file systems"
mkdir -p /mnt/tmp
echo "<0>A16DBG: stage2 start" > /dev/kmsg
PATH=/boot/sbin:/boot/bin
export PATH

# Writable mountpoints — try real data partition before tmpfs (apexd needs ext4 /data for O_DIRECT loop)
/boot/bin/busybox mkdir -p /tmp /cache /data /apex /linkerconfig /bootstrap-apex /metadata /vendor 2>/dev/null
mount_tmpfs_mp() {
    mp="$1"
    /boot/bin/busybox umount "$mp" 2>/dev/null || true
    /boot/bin/busybox mount -t tmpfs tmpfs "$mp" -o size=256m
}
# metadata/cache may lack block dev; data must not be tmpfs if sdb1 is available
for mp in /cache /metadata; do
    mount_tmpfs_mp "$mp"
done

ensure_sdb1_nodes() {
    /boot/bin/busybox mdev -s 2>/dev/null || true
    if [ ! -e /dev/sdb1 ] && [ -r /sys/block/sdb/sdb1/dev ]; then
        set -- $(cat /sys/block/sdb/sdb1/dev)
        /boot/bin/busybox mknod /dev/sdb1 b $1 $2
    fi
    /boot/bin/busybox mkdir -p /dev/block
    if [ -e /dev/sdb1 ] && [ ! -e /dev/block/sdb1 ]; then
        /boot/bin/busybox ln -sf ../sdb1 /dev/block/sdb1
    fi
    if [ -e /dev/sdb1 ]; then
        echo "<0>A16DBG: sdb1 block dev ready dev=$(cat /sys/block/sdb/sdb1/dev 2>&1)" > /dev/kmsg
    else
        echo "<3>A16DBG: sdb1 block dev missing" > /dev/kmsg
    fi
}
ensure_sdb1_nodes

source /boot/bstsetup.env
source /boot/4-dpi
die_if_error() { log_echo "NON-FATAL: $@"; return 0; }

if [ ${BST_0DCT:-0} -ne 0 ]; then zerofree_data; fi
mount_data
if mountpoint -q /data; then
    echo "<0>A16DBG: /data mounted from block device" > /dev/kmsg
else
    mount_tmpfs_mp /data
    echo "<3>A16DBG: /data fallback tmpfs (apexd CAPEX may fail)" > /dev/kmsg
fi
echo "<0>A16DBG: data/cache/metadata ready" > /dev/kmsg

# Henry 7P/7Q: patch build.prop BEFORE /system/{bin,lib64} bind (bind blocks file overlay)
patch_system_build_prop() {
    propf=/system/build.prop
    [ -f "$propf" ] || return 1
    patched=/data/build.prop.patched
    _vndk_before=$(/boot/bin/busybox grep '^ro\.vndk\.version=' "$propf" 2>/dev/null || true)
    _apex_before=$(/boot/bin/busybox grep '^ro\.apex\.updatable=' "$propf" 2>/dev/null || true)
    echo "<0>A16DBG: henry-7P/7Q before vndk=[$_vndk_before] apex=[$_apex_before]" > /dev/kmsg
    /boot/bin/busybox grep -v '^ro\.vndk\.version=' "$propf" > "$patched"
    # R169: removed ro.dalvik.vm.enable_uffd_gc=0 force (conflicts with CC libart)
    if ! /boot/bin/busybox grep -q '^ro\.apex\.updatable=' "$patched" 2>/dev/null; then
        echo 'ro.apex.updatable=true' >> "$patched"
    else
        /boot/bin/busybox sed -i 's/^ro\.apex\.updatable=.*/ro.apex.updatable=true/' "$patched" 2>/dev/null || true
    fi
    if /boot/bin/busybox mount --bind "$patched" "$propf" 2>/dev/null; then
        _after=$(/boot/bin/busybox grep -E 'ro\.vndk|ro\.apex\.updatable' "$propf" 2>/dev/null | /boot/bin/busybox tr '\n' ' ')
        echo "<0>A16DBG: henry-7P/7Q build.prop bind ok after=[$_after]" > /dev/kmsg
        return 0
    fi
    _mounts_sys=$(/boot/bin/busybox grep -E '[[:space:]](/system|system)[[:space:]]' /proc/mounts 2>/dev/null | /boot/bin/busybox head -1)
    echo "<0>A16DBG: henry-7P/7Q mounts_sys=[$_mounts_sys]" > /dev/kmsg
    _sys_dev=$(printf '%s\n' "$_mounts_sys" | /boot/bin/busybox cut -d' ' -f1)
    _sys_mp=$(printf '%s\n' "$_mounts_sys" | /boot/bin/busybox cut -d' ' -f2)
    [ -z "$_sys_mp" ] && _sys_mp=/system
    echo "<0>A16DBG: henry-7P/7Q remount $_sys_mp dev=[$_sys_dev]" > /dev/kmsg
    _remount_ok=0
    if [ -n "$_sys_dev" ] && /boot/bin/busybox mount -o remount,rw "$_sys_dev" "$_sys_mp" 2>/dev/null; then
        _remount_ok=1
    elif /boot/bin/busybox mount -o remount,rw "$_sys_mp" 2>/dev/null; then
        _remount_ok=1
    fi
    if [ "$_remount_ok" -eq 1 ]; then
        /boot/bin/busybox cat "$patched" > "$propf" 2>/dev/null || \
            { /boot/bin/busybox rm -f "$propf"; /boot/bin/busybox cp -f "$patched" "$propf"; }
        /boot/bin/busybox mount -o remount,ro /system 2>/dev/null || true
    fi
    _after=$(/boot/bin/busybox grep -E 'ro\.vndk|ro\.apex\.updatable' "$propf" 2>/dev/null | /boot/bin/busybox tr '\n' ' ')
    if /boot/bin/busybox grep -q '^ro\.apex\.updatable=true' "$patched" 2>/dev/null && \
       ! /boot/bin/busybox grep -q '^ro\.vndk\.version=' "$propf" 2>/dev/null; then
        echo "<0>A16DBG: henry-7P/7Q build.prop rw ok after=[$_after]" > /dev/kmsg
        return 0
    fi
    if /boot/bin/busybox mount --bind "$patched" "$propf" 2>/dev/null; then
        _after=$(/boot/bin/busybox grep -E 'ro\.vndk|ro\.apex\.updatable' "$propf" 2>/dev/null | /boot/bin/busybox tr '\n' ' ')
        echo "<0>A16DBG: henry-7P/7Q build.prop bind ok after=[$_after]" > /dev/kmsg
        return 0
    fi
    echo "<3>A16DBG: henry-7P/7Q build.prop patch failed" > /dev/kmsg
    return 1
}
if mountpoint -q /data; then
    patch_system_build_prop
fi

find_free_loop_early() {
    n=10
    while [ $n -lt 64 ]; do
        if [ ! -f "/sys/block/loop$n/loop/backing_file" ]; then
            echo /dev/loop$n
            return 0
        fi
        n=$((n + 1))
    done
    /boot/bin/busybox losetup -f 2>/dev/null
}

# loop-mounted ext4-in-squashfs breaks stat on /system/{bin,lib64} → execv ENOENT; stage to ext4 + bind
stage_system_tree() {
    STAGE_BIN=/data/system_bin
    STAGE_LIB=/data/system_lib64
    if [ ! -f "$STAGE_BIN/.staged_v4" ]; then
        /boot/bin/busybox umount /system/bin 2>/dev/null || true
        /boot/bin/busybox rm -rf "$STAGE_BIN"
        /boot/bin/busybox mkdir -p "$STAGE_BIN"
        echo "<0>A16DBG: copying /system/bin to ext4 (preserve symlinks)" > /dev/kmsg
        /boot/bin/busybox cp -a /system/bin/. "$STAGE_BIN/" 2>/dev/null
        echo ok > "$STAGE_BIN/.staged_v4"
    fi
    if [ ! -f "$STAGE_LIB/.staged_v3" ]; then
        /boot/bin/busybox umount /system/lib64 2>/dev/null || true
        /boot/bin/busybox rm -rf "$STAGE_LIB"
        /boot/bin/busybox mkdir -p "$STAGE_LIB"
        echo "<0>A16DBG: copying /system/lib64 to ext4 (v3 refresh)" > /dev/kmsg
        /boot/bin/busybox cp -a /system/lib64/. "$STAGE_LIB/" 2>/dev/null
        echo ok > "$STAGE_LIB/.staged_v3"
    fi
    if [ -f /boot/bin/app_process64 ]; then
        /boot/bin/busybox cat /boot/bin/app_process64 > "$STAGE_BIN/app_process64"
        /boot/bin/busybox chmod 755 "$STAGE_BIN/app_process64"
        echo "<0>A16DBG: app_process64 from initrd ($(/boot/bin/busybox wc -c < $STAGE_BIN/app_process64) bytes)" > /dev/kmsg
    fi
    if [ -f /boot/bin/linker64 ]; then
        /boot/bin/busybox rm -f "$STAGE_BIN/linker64"
        /boot/bin/busybox cat /boot/bin/linker64 > "$STAGE_BIN/linker64"
        /boot/bin/busybox chmod 755 "$STAGE_BIN/linker64"
        echo "<0>A16DBG: linker64 from initrd ($(/boot/bin/busybox wc -c < $STAGE_BIN/linker64) bytes)" > /dev/kmsg
    fi
    # R173 fix: overwrite unpatched /system/bin/init with patched init.
    # ueventd -> /system/bin/ueventd -> init symlink; fresh system init is UPSTREAM (unpatched)
    # -> ueventd crashes on selinux -> coldboot never completes -> wait_for_coldboot_done hang.
    if [ -f /boot/init-patched ]; then
        /boot/bin/busybox cat /boot/init-patched > "$STAGE_BIN/init"
        /boot/bin/busybox chmod 755 "$STAGE_BIN/init"
        echo "<0>A16DBG: R173 init patched overwrite ($(/boot/bin/busybox wc -c < $STAGE_BIN/init) bytes) ueventd->patched" > /dev/kmsg
    fi
    # Henry 7BH: vold pulls libapexsupport from /system/lib64; make its bionic sidecar visible.
    for _lib in libdl_android.so; do
        for _src in /apex/com.android.runtime/lib64/bionic/$_lib /system/lib64/bootstrap/$_lib; do
            if [ -f "$_src" ]; then
                /boot/bin/busybox rm -f "$STAGE_LIB/$_lib"
                /boot/bin/busybox cat "$_src" > "$STAGE_LIB/$_lib"
                /boot/bin/busybox chmod 755 "$STAGE_LIB/$_lib"
                echo "<0>A16DBG: henry-7BH system_lib64 $_lib=$(/boot/bin/busybox wc -c < "$STAGE_LIB/$_lib" 2>/dev/null)B src=$_src" > /dev/kmsg
                break
            fi
        done
    done
    # R121 (henry §7R): stock `vdc keymaster earlyBootEnded` ESTABLISHES boot level keys
    # (set_up_boot_level_cache) — do NOT intercept it. Earlier rounds wrongly blocked it,
    # which prevented odsign from generating boot.art. Wrapper still routes vdc.real via the
    # bootstrap linker (stock /system/bin/vdc needs the staged linker env).
    if [ -x "$STAGE_BIN/vdc" ]; then
        if [ ! -x "$STAGE_BIN/vdc.real" ]; then
            /boot/bin/busybox mv "$STAGE_BIN/vdc" "$STAGE_BIN/vdc.real" 2>/dev/null || true
        fi
        cat > "$STAGE_BIN/vdc" <<'VDCEOF'
#!/boot/bin/sh
echo "<0>A16DBG: henry-7BK vdc passthrough args=$*" > /dev/kmsg
LINKER=/system/bin/bootstrap/linker64
[ -x "$LINKER" ] || LINKER=/apex/com.android.runtime/bin/linker64
exec "$LINKER" /data/system_bin/vdc.real "$@"
VDCEOF
        /boot/bin/busybox chmod 755 "$STAGE_BIN/vdc"
        echo "<0>A16DBG: henry-7BI vdc passthrough installed real=$(/boot/bin/busybox wc -c < "$STAGE_BIN/vdc.real" 2>/dev/null)B" > /dev/kmsg
    fi
    if /boot/bin/busybox mount --bind "$STAGE_BIN" /system/bin 2>/dev/null; then
        echo "<0>A16DBG: /system/bin staged bind ok" > /dev/kmsg
    else
        echo "<3>A16DBG: /system/bin staged bind failed" > /dev/kmsg
    fi
    if /boot/bin/busybox mount --bind "$STAGE_LIB" /system/lib64 2>/dev/null; then
        echo "<0>A16DBG: /system/lib64 staged bind ok" > /dev/kmsg
    else
        echo "<3>A16DBG: /system/lib64 staged bind failed" > /dev/kmsg
    fi
    # R161 henry-7AJ: crash_dump64 @ /system/bin (A16: runtime apex only, not in system.img)
    if [ -f /boot/bin/crash_dump64 ]; then
        /boot/bin/busybox cat /boot/bin/crash_dump64 > "$STAGE_BIN/crash_dump64"
        /boot/bin/busybox chmod 755 "$STAGE_BIN/crash_dump64"
        echo "<0>A16DBG: henry-7AJ crash_dump64 initrd bytes=$(/boot/bin/busybox wc -c < $STAGE_BIN/crash_dump64 2>/dev/null)B" > /dev/kmsg
    elif [ -f /apex/com.android.runtime/bin/crash_dump64 ]; then
        /boot/bin/busybox cat /apex/com.android.runtime/bin/crash_dump64 > "$STAGE_BIN/crash_dump64"
        /boot/bin/busybox chmod 755 "$STAGE_BIN/crash_dump64"
        echo "<0>A16DBG: henry-7AJ crash_dump64 apex bytes=$(/boot/bin/busybox wc -c < $STAGE_BIN/crash_dump64 2>/dev/null)B" > /dev/kmsg
    elif [ ! -x "$STAGE_BIN/crash_dump64" ]; then
        echo "<3>A16DBG: henry-7AJ crash_dump64 missing" > /dev/kmsg
    fi
    # libc execs CRASH_DUMP_PATH=/apex/com.android.runtime/bin/crash_dump64 (not /system/bin)
    _rt_mp=/apex/com.android.runtime
    for _d in /apex/com.android.runtime@*; do
        [ -d "$_d" ] && _rt_mp="$_d" && break
    done
    _rtcd="$_rt_mp/bin/crash_dump64"
    if [ -f /boot/bin/crash_dump64 ] && [ -d "$_rt_mp/bin" ]; then
        _rt_ov=/data/runtime-bin-ov
        /boot/bin/busybox mkdir -p "$_rt_ov"
        if [ ! -f "$_rt_ov/.populated" ]; then
            for _bf in "$_rt_mp/bin"/*; do
                [ -f "$_bf" ] || continue
                _bn=$(/boot/bin/busybox basename "$_bf")
                [ -f "$_rt_ov/$_bn" ] || /boot/bin/busybox cat "$_bf" > "$_rt_ov/$_bn" 2>/dev/null
            done
            /boot/bin/busybox touch "$_rt_ov/.populated"
        fi
        /boot/bin/busybox cat /boot/bin/crash_dump64 > "$_rt_ov/crash_dump64"
        /boot/bin/busybox chmod 755 "$_rt_ov/crash_dump64"
        /boot/bin/busybox umount "$_rt_mp/bin" 2>/dev/null
        if /boot/bin/busybox mount --bind "$_rt_ov" "$_rt_mp/bin" 2>/dev/null; then
            echo "<0>A16DBG: henry-7AJ apex-bin overlay crash_dump=$(/boot/bin/busybox wc -c < $_rtcd 2>/dev/null)B" > /dev/kmsg
        else
            echo "<3>A16DBG: henry-7AJ apex-bin overlay fail" > /dev/kmsg
        fi
    fi
    # Henry 7Z: cat-copy ART libs to /data/art-libs (NOT system_lib64 — libc mutual exclusion @ R79)
    if [ -d /boot/art-libs ]; then
        _art_dir=/data/art-libs
        /boot/bin/busybox mkdir -p "$_art_dir"
        # R164: force libart.so re-stage. R163 patched libart (ZygoteVerificationTask skips NULL
        # dex_cache) but the patched .so is the SAME SIZE as the old one, so the size-check below
        # silently skipped it -> patch never reached the running zygote. rm forces re-copy.
        /boot/bin/busybox rm -f "$_art_dir/libart.so"
        _art_n=0
        for _af in /boot/art-libs/*.so; do
            [ -f "$_af" ] || continue
            _an=$(/boot/bin/busybox basename "$_af")
            _src=$(/boot/bin/busybox wc -c < "$_af")
            _cur=0
            [ -f "$_art_dir/$_an" ] && _cur=$(/boot/bin/busybox wc -c < "$_art_dir/$_an")
            if [ "$_cur" -ne "$_src" ]; then
                /boot/bin/busybox cat "$_af" > "$_art_dir/$_an"
                /boot/bin/busybox chmod 755 "$_art_dir/$_an"
                _art_n=$((_art_n + 1))
            fi
        done
        for _af in /boot/art-libs/*.so; do
            [ -f "$_af" ] || continue
            _an=$(/boot/bin/busybox basename "$_af")
            [ -L "$STAGE_LIB/$_an" ] && /boot/bin/busybox rm -f "$STAGE_LIB/$_an"
        done
        echo "<0>A16DBG: henry-7Z art-libs staged dir=$_art_dir n=$_art_n nativeloader=$(/boot/bin/busybox wc -c < $_art_dir/libnativeloader.so 2>/dev/null)B libart=$(/boot/bin/busybox wc -c < $_art_dir/libart.so 2>/dev/null)B" > /dev/kmsg
    else
        _art_mp=/apex/com.android.art@990091000
        if [ ! -f "$_art_mp/lib64/libart.so" ] && [ -f /boot/art-payload.img ]; then
            /boot/bin/busybox mkdir -p "$_art_mp"
            _loop=$(find_free_loop_early)
            if [ -n "$_loop" ] && /boot/bin/busybox losetup "$_loop" /boot/art-payload.img 2>/dev/null &&
               /boot/bin/busybox mount -t erofs -o ro "$_loop" "$_art_mp" 2>/dev/null; then
                echo "<0>A16DBG: art payload mounted early on $_loop" > /dev/kmsg
            fi
        fi
        _art_lib=""
        for _d in /apex/com.android.art/lib64 "$_art_mp/lib64"; do
            [ -d "$_d" ] && _art_lib="$_d" && break
        done
        if [ -n "$_art_lib" ]; then
            _new=0
            for lib in "$_art_lib"/*.so; do
                [ -f "$lib" ] || continue
                name=$(/boot/bin/busybox basename "$lib")
                if [ ! -e "$STAGE_LIB/$name" ]; then
                    /boot/bin/busybox ln -sf "$_art_lib/$name" "$STAGE_LIB/$name"
                    _new=$((_new + 1))
                fi
            done
            echo "<0>A16DBG: henry-7O early art symlinks: $_new new" > /dev/kmsg
            echo "<0>A16DBG: henry-7O libnativeloader=$(/boot/bin/busybox ls -l $STAGE_LIB/libnativeloader.so 2>&1)" > /dev/kmsg
        else
            echo "<3>A16DBG: henry-7O early: no art lib64 dir" > /dev/kmsg
        fi
    fi
    # Henry 7Z-i18n: cat-copy i18n libs to /data/i18n-libs (apex symlinks fail @ R80 libicu)
    if [ -d /boot/i18n-libs ]; then
        _i18n_dir=/data/i18n-libs
        /boot/bin/busybox mkdir -p "$_i18n_dir"
        _i18n_n=0
        for _if in /boot/i18n-libs/*.so; do
            [ -f "$_if" ] || continue
            _in=$(/boot/bin/busybox basename "$_if")
            _src=$(/boot/bin/busybox wc -c < "$_if")
            _cur=0
            [ -f "$_i18n_dir/$_in" ] && _cur=$(/boot/bin/busybox wc -c < "$_i18n_dir/$_in")
            if [ "$_cur" -ne "$_src" ]; then
                /boot/bin/busybox cat "$_if" > "$_i18n_dir/$_in"
                /boot/bin/busybox chmod 755 "$_i18n_dir/$_in"
                _i18n_n=$((_i18n_n + 1))
            fi
        done
        for _if in /boot/i18n-libs/*.so; do
            [ -f "$_if" ] || continue
            _in=$(/boot/bin/busybox basename "$_if")
            [ -L "$STAGE_LIB/$_in" ] && /boot/bin/busybox rm -f "$STAGE_LIB/$_in"
        done
        echo "<0>A16DBG: henry-7Z-i18n staged dir=$_i18n_dir n=$_i18n_n libicu=$(/boot/bin/busybox wc -c < $_i18n_dir/libicu.so 2>/dev/null)B" > /dev/kmsg
    elif [ -d /apex/com.android.i18n/lib64 ]; then
        _i18n_new=0
        for lib in /apex/com.android.i18n/lib64/*.so; do
            [ -f "$lib" ] || continue
            name=$(/boot/bin/busybox basename "$lib")
            if [ ! -e "$STAGE_LIB/$name" ]; then
                /boot/bin/busybox ln -sf "/apex/com.android.i18n/lib64/$name" "$STAGE_LIB/$name"
                _i18n_new=$((_i18n_new + 1))
            fi
        done
        echo "<0>A16DBG: henry-7O-i18n symlinks: $_i18n_new new; libandroidicu=$(/boot/bin/busybox ls -l $STAGE_LIB/libandroidicu.so 2>&1)" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7O-i18n skip: no i18n lib64" > /dev/kmsg
    fi
    # Henry 7AE: colocate libart NEEDED deps inside art-libs bind target (statspull + system overlap)
    enrich_art_libs() {
        [ -d /data/art-libs ] || return 0
        _added=0
        for _lib in libstatspull.so libstatssocket.so; do
            [ -f /data/art-libs/$_lib ] && continue
            for _src in /data/statsd-libs/$_lib /boot/statsd-libs/$_lib; do
                if [ -f "$_src" ]; then
                    /boot/bin/busybox cat "$_src" > "/data/art-libs/$_lib"
                    /boot/bin/busybox chmod 755 "/data/art-libs/$_lib"
                    _added=$((_added + 1))
                    break
                fi
            done
        done
        for _lib in libbase.so libc++.so libexpat.so liblz4.so liblzma.so libunwindstack.so libdl_android.so heapprofd_client_api.so; do
            [ -f /data/art-libs/$_lib ] && continue
            for _src in /system/lib64/$_lib /data/system_lib64/$_lib; do
                if [ -f "$_src" ]; then
                    /boot/bin/busybox cat "$_src" > "/data/art-libs/$_lib"
                    /boot/bin/busybox chmod 755 "/data/art-libs/$_lib"
                    _added=$((_added + 1))
                    break
                fi
            done
        done
        # R171d: dex2oat (CC, from corrected art-payload) NEEDs libz.so + liblog.so for linking.
        # They are NOT in art-payload lib64; must come from /system (or bionic for liblog).
        # Add them at runtime (not in initrd) to avoid VBox initrd-size boot stall (R171c).
        for _lib in libz.so liblog.so; do
            [ -f /data/art-libs/$_lib ] && continue
            for _src in /system/lib64/$_lib /data/system_lib64/$_lib /apex/com.android.runtime/lib64/bionic/$_lib; do
                if [ -f "$_src" ]; then
                    /boot/bin/busybox cat "$_src" > "/data/art-libs/$_lib"
                    /boot/bin/busybox chmod 755 "/data/art-libs/$_lib"
                    _added=$((_added + 1))
                    break
                fi
            done
        done
        _total=$(/boot/bin/busybox ls /data/art-libs/*.so 2>/dev/null | /boot/bin/busybox wc -l)
        echo "<0>A16DBG: henry-7AE art-libs enriched added=$_added total=$_total libz=$(/boot/bin/busybox wc -c < /data/art-libs/libz.so 2>/dev/null)B liblog=$(/boot/bin/busybox wc -c < /data/art-libs/liblog.so 2>/dev/null)B" > /dev/kmsg
    }
    # Henry 7AB: bind staged libs onto versioned APEX lib64 (JniInvocation dlopen libart.so)
    bind_staged_apex_libs() {
        enrich_art_libs
        _art_mp=/apex/com.android.art@990091000
        for _d in /apex/com.android.art@*; do
            [ -d "$_d" ] && _art_mp="$_d" && break
        done
        if [ -d /data/art-libs ] && [ -f /data/art-libs/libart.so ]; then
            /boot/bin/busybox mkdir -p "$_art_mp"
            /boot/bin/busybox umount "$_art_mp/lib64" 2>/dev/null || true
            /boot/bin/busybox mkdir -p "$_art_mp/lib64"
            if /boot/bin/busybox mount --bind /data/art-libs "$_art_mp/lib64" 2>/dev/null; then
                echo "<0>A16DBG: henry-7AB art bind $_art_mp/lib64 art=$(/boot/bin/busybox wc -c < $_art_mp/lib64/libart.so 2>/dev/null)B" > /dev/kmsg
            else
                echo "<3>A16DBG: henry-7AB art bind failed mp=$_art_mp" > /dev/kmsg
            fi
            /boot/bin/busybox ln -sfn "$_art_mp" /apex/com.android.art
        fi
        _i18n_mp=/apex/com.android.i18n@1
        for _d in /apex/com.android.i18n@*; do
            [ -d "$_d" ] && _i18n_mp="$_d" && break
        done
        if [ -d /data/i18n-libs ] && [ -f /data/i18n-libs/libicu.so ]; then
            /boot/bin/busybox mkdir -p "$_i18n_mp"
            /boot/bin/busybox umount "$_i18n_mp/lib64" 2>/dev/null || true
            /boot/bin/busybox mkdir -p "$_i18n_mp/lib64"
            # Henry 7BM (R119): enrich /data/i18n-libs with bundled deps BEFORE the bind.
            # initrd /boot/i18n-libs ships only 5 libs (libandroidicu/icu/icuuc/icui18n/icu_jni),
            # but libicu_jni.so NEEDES libbase.so + libc++.so which the REAL i18n APEX lib64
            # bundles, plus libnativehelper.so (art/system). The bind hides the real lib64, so
            # without this libicu_jni → libbase.so fails in com_android_i18n namespace (R118 abort).
            _i18n_added=0
            for _rl in "$_i18n_mp"/lib64/*.so; do
                [ -f "$_rl" ] || continue
                _rn=$(/boot/bin/busybox basename "$_rl")
                if [ ! -f "/data/i18n-libs/$_rn" ]; then
                    /boot/bin/busybox cat "$_rl" > "/data/i18n-libs/$_rn"
                    /boot/bin/busybox chmod 755 "/data/i18n-libs/$_rn"
                    _i18n_added=$((_i18n_added + 1))
                fi
            done
            if [ ! -f /data/i18n-libs/libnativehelper.so ]; then
                for _nh_src in /apex/com.android.art/lib64/libnativehelper.so \
                               /apex/com.android.art@*/lib64/libnativehelper.so \
                               /data/art-libs/libnativehelper.so /system/lib64/libnativehelper.so; do
                    if [ -f "$_nh_src" ]; then
                        /boot/bin/busybox cat "$_nh_src" > /data/i18n-libs/libnativehelper.so
                        /boot/bin/busybox chmod 755 /data/i18n-libs/libnativehelper.so
                        _i18n_added=$((_i18n_added + 1))
                        break
                    fi
                done
            fi
            echo "<0>A16DBG: henry-7BM i18n-libs enriched added=$_i18n_added libbase=$(/boot/bin/busybox wc -c < /data/i18n-libs/libbase.so 2>/dev/null)B libc++=$(/boot/bin/busybox wc -c < /data/i18n-libs/libc++.so 2>/dev/null)B nativehelper=$(/boot/bin/busybox wc -c < /data/i18n-libs/libnativehelper.so 2>/dev/null)B" > /dev/kmsg
            if /boot/bin/busybox mount --bind /data/i18n-libs "$_i18n_mp/lib64" 2>/dev/null; then
                echo "<0>A16DBG: henry-7AB i18n bind $_i18n_mp/lib64 icu=$(/boot/bin/busybox wc -c < $_i18n_mp/lib64/libicu.so 2>/dev/null)B" > /dev/kmsg
            else
                echo "<3>A16DBG: henry-7AB i18n bind failed mp=$_i18n_mp" > /dev/kmsg
            fi
            /boot/bin/busybox ln -sfn "$_i18n_mp" /apex/com.android.i18n
        fi
    }
    bind_staged_apex_libs
    for d in /apex/com.android.os.statsd@*; do
        [ -d "$d/lib64" ] && /boot/bin/busybox ln -sfn "$d" /apex/com.android.os.statsd && break
    done
    _statsd_src=""
    if [ -f /boot/statsd-libs/libstatspull.so ]; then
        _statsd_src=/boot/statsd-libs
    elif [ -f /apex/com.android.os.statsd/lib64/libstatspull.so ]; then
        _statsd_src=/apex/com.android.os.statsd/lib64
    else
        for _d in /apex/com.android.os.statsd@*/lib64; do
            [ -f "$_d/libstatspull.so" ] && _statsd_src="$_d" && break
        done
    fi
    if [ -n "$_statsd_src" ]; then
        /boot/bin/busybox mkdir -p /data/statsd-libs
        for _lib in libstatspull.so libstatssocket.so; do
            [ -f "$_statsd_src/$_lib" ] || continue
            /boot/bin/busybox cat "$_statsd_src/$_lib" > "/data/statsd-libs/$_lib"
            /boot/bin/busybox chmod 755 "/data/statsd-libs/$_lib"
        done
        echo "<0>A16DBG: henry-7O-statsd staged src=$_statsd_src pull=$(/boot/bin/busybox wc -c < /data/statsd-libs/libstatspull.so 2>/dev/null)B" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7O-statsd skip: no source" > /dev/kmsg
    fi
    # Henry 7W: pre-stage boot.art chain for zygote (odsign bypass)
    for _p in /data/system_lib64/libstatspull.so /data/system_lib64/libstatssocket.so \
        /data/system_lib64/arm64/libstatspull.so; do
        /boot/bin/busybox rm -f "$_p"
    done
    _dalvik=/data/dalvik-cache/x86_64
    # Henry 7AC: drop stale henry a13 boot.art (815104B) — mismatched with A16 art-libs
    if [ -f "$_dalvik/boot.art" ]; then
        _old_sz=$(/boot/bin/busybox wc -c < "$_dalvik/boot.art" 2>/dev/null)
        if [ "$_old_sz" = "815104" ]; then
            for _df in "$_dalvik"/*; do
                [ -e "$_df" ] || continue
                /boot/bin/busybox rm -f "$_df"
            done
            echo "<0>A16DBG: henry-7AC removed stale a13 boot.art chain" > /dev/kmsg
        fi
    fi
    if [ -f /boot/dalvik-cache/x86_64/boot.art ] && [ -f /boot/dalvik-cache/x86_64/boot-framework.oat ]; then
        _initrd_sz=$(/boot/bin/busybox wc -c < /boot/dalvik-cache/x86_64/boot.art)
        if [ "$_initrd_sz" = "815104" ]; then
            echo "<3>A16DBG: henry-7AC skip initrd a13 boot.art (${_initrd_sz}B)" > /dev/kmsg
        else
        /boot/bin/busybox mkdir -p "$_dalvik"
        _dalvik_n=0
        for _df in /boot/dalvik-cache/x86_64/*; do
            [ -f "$_df" ] || continue
            _dn=$(/boot/bin/busybox basename "$_df")
            if [ ! -s "$_dalvik/$_dn" ]; then
                /boot/bin/busybox cat "$_df" > "$_dalvik/$_dn"
                /boot/bin/busybox chmod 644 "$_dalvik/$_dn"
                _dalvik_n=$((_dalvik_n + 1))
            fi
        done
        echo "<0>A16DBG: henry-7W dalvik staged files=$_dalvik_n boot.art=$(/boot/bin/busybox wc -c < $_dalvik/boot.art 2>/dev/null)B" > /dev/kmsg
        echo "<0>A16DBG: henry-7AK boot.oat=$(/boot/bin/busybox wc -c < $_dalvik/boot.oat 2>/dev/null)B boot.vdex=$(/boot/bin/busybox wc -c < $_dalvik/boot.vdex 2>/dev/null)B" > /dev/kmsg
        fi
    elif [ -f /boot/dalvik-cache/x86_64/boot.art ]; then
        echo "<3>A16DBG: henry-7BF skip 7W dalvik: boot-framework.oat missing, defer to odsign" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7W dalvik skip: no initrd boot.art" > /dev/kmsg
    fi
    # Henry 7AS: stage boot-image.prof for ART compound boot image
    if [ -f /boot/profiles/boot-image.prof ]; then
        /boot/bin/busybox mkdir -p /data/boot-profiles
        if [ ! -s /data/boot-profiles/boot-image.prof ]; then
            /boot/bin/busybox cat /boot/profiles/boot-image.prof > /data/boot-profiles/boot-image.prof
            /boot/bin/busybox chmod 644 /data/boot-profiles/boot-image.prof
        fi
        echo "<0>A16DBG: henry-7AS prof staged bytes=$(/boot/bin/busybox wc -c < /data/boot-profiles/boot-image.prof 2>/dev/null)" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7AS prof skip: no initrd boot-image.prof" > /dev/kmsg
    fi
    # Henry 7AT: mirror boot chain into apexdata dalvik-cache (ART prefers when odsign.verification.success)
    _apexdc=/data/misc/apexdata/com.android.art/dalvik-cache/x86_64
    if [ -f "$_dalvik/boot.art" ] && [ -f "$_dalvik/boot-framework.oat" ]; then
        /boot/bin/busybox mkdir -p "$_apexdc"
        _apex_n=0
        for _df in "$_dalvik"/*; do
            [ -f "$_df" ] || continue
            _dn=$(/boot/bin/busybox basename "$_df")
            if [ ! -s "$_apexdc/$_dn" ]; then
                /boot/bin/busybox cat "$_df" > "$_apexdc/$_dn"
                /boot/bin/busybox chmod 644 "$_apexdc/$_dn"
                _apex_n=$((_apex_n + 1))
            fi
        done
        echo "<0>A16DBG: henry-7AT apexdc staged files=$_apex_n boot.art=$(/boot/bin/busybox wc -c < $_apexdc/boot.art 2>/dev/null)B fw-oat=$(/boot/bin/busybox wc -c < $_apexdc/boot-framework.oat 2>/dev/null)B" > /dev/kmsg
    elif [ -f "$_dalvik/boot.art" ]; then
        echo "<3>A16DBG: henry-7BF skip 7AT apexdc: boot-framework.oat missing, defer to odsign" > /dev/kmsg
    fi
    # R169: do NOT stage force_disable_uffd cache-info. It was for the old uffd libart;
    # with the R168 consistent-CC libart it forces boot.oat non-read-barrier (false) and
    # mismatches the CC runtime (true) -> ValidateOatFile read barrier state mismatch.
    # Let the CC runtime default to read-barrier=true so odrefresh compiles a CC boot.oat.
    _cache_info=/data/misc/apexdata/com.android.art/dalvik-cache/cache-info.xml
    /boot/bin/busybox mkdir -p /data/misc/apexdata/com.android.art/dalvik-cache
    /boot/bin/busybox rm -f "$_cache_info"
    echo "<0>A16DBG: henry-7BB cache-info removed (R169 CC default, no force_disable_uffd)" > /dev/kmsg
}
# R161 henry-7j: disable system boringssl self-test rc (A13 不装, 64-only 无 test32)
disable_boringssl_rc() {
    _bs7j_hw=/data/init-hw-7j
    /boot/bin/busybox rm -rf "$_bs7j_hw"
    /boot/bin/busybox mkdir -p "$_bs7j_hw"
    _n=0
    for _f in /system/etc/init/hw/*; do
        [ -f "$_f" ] || [ -L "$_f" ] || continue
        _bn=$(/boot/bin/busybox basename "$_f")
        case "$_bn" in
            init.boringssl.*)
                echo "# henry-7j boringssl disabled (BS 64-only bringup)" > "$_bs7j_hw/$_bn"
                _n=$((_n + 1))
                ;;
            *)
                if [ -L "$_f" ]; then
                    _lnk=$(/boot/bin/busybox readlink "$_f")
                    /boot/bin/busybox ln -sfn "$_lnk" "$_bs7j_hw/$_bn"
                else
                    /boot/bin/busybox cat "$_f" > "$_bs7j_hw/$_bn" 2>/dev/null || true
                fi
                ;;
        esac
    done
    if [ "$_n" -gt 0 ] && [ -d /system/etc/init/hw ]; then
        /boot/bin/busybox umount /system/etc/init/hw 2>/dev/null
        if /boot/bin/busybox mount --bind "$_bs7j_hw" /system/etc/init/hw 2>/dev/null; then
            echo "<0>A16DBG: henry-7j boringssl-rc disabled n=$_n hw-bind=ok" > /dev/kmsg
        else
            echo "<3>A16DBG: henry-7j boringssl-rc hw-bind-fail n=$_n" > /dev/kmsg
        fi
    else
        echo "<3>A16DBG: henry-7j boringssl-rc skip n=$_n" > /dev/kmsg
    fi
}
if mountpoint -q /data; then
    stage_system_tree
    disable_boringssl_rc
fi

prepare_bst_filesystems
setup_dpi
set_propfile_permissions
setup_memory_allocator
mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null

mkdir /dev/log
for i in main events system radio; do
    if [ -f /sys/devices/virtual/misc/log_$i/dev ]; then
        nums=$(cat /sys/devices/virtual/misc/log_$i/dev | tr ":" " ")
        mknod /dev/log/$i c $nums
    fi
done

echo 1 > /proc/sys/net/ipv6/conf/eth0/disable_ipv6
ifconfig eth0 10.0.2.15 netmask 255.255.255.0 up
/boot/bin/busybox route add default gw $WINDOWSGATEWAY dev eth0
ip route add $WINDOWSGATEWAY dev eth0 table local
echo "nameserver 8.8.8.8" > /boot/resolv.conf
log_echo "Welcome to BlueStacks Android"

grep SHELL_BEFORE_INIT= /proc/cmdline > /dev/null && { env HAS_CTTY=Yes setsid /boot/bin/cttyhack /boot/bin/ash; }

log_echo "Starting Android"
mkdir -p /data/misc/adb 2>/dev/null
if [ -f /boot/adbkey.pub ]; then
    /boot/bin/busybox cp /boot/adbkey.pub /data/misc/adb/adb_keys 2>/dev/null
    /boot/bin/busybox chmod 640 /data/misc/adb/adb_keys 2>/dev/null
    echo "<0>A16DBG: adb key installed" > /dev/kmsg
else
    echo "<3>A16DBG: adbkey.pub missing in initrd" > /dev/kmsg
fi

# Writable data when sdb1 mount failed — do not stomp ext4 /data with tmpfs
if ! mountpoint -q /data; then
    mount_tmpfs_mp /data
    echo "<3>A16DBG: /data re-tmpfs before init (no sdb1)" > /dev/kmsg
fi
/boot/bin/busybox mkdir -p /data/misc/keystore /data/misc/vold /data/system /data/vendor /data/anr /data/tombstones 2>/dev/null
# Writable vendor overlay (good VHD may lack vendor partition / fstab)
/boot/bin/busybox touch /vendor/.w 2>/dev/null || \
    /boot/bin/busybox mount -t tmpfs tmpfs /vendor -o size=32m
/boot/bin/busybox mkdir -p /vendor/etc/init/hw /vendor/bin/hw /vendor/lib64 /vendor/etc/vintf/manifest /product /system_ext
stage_keymint_hal() {
    if [ ! -x /boot/vendor_hw/android.hardware.security.keymint-service ]; then
        echo "<3>A16DBG: keymint HAL missing in initrd" > /dev/kmsg
        return 1
    fi
    /boot/bin/busybox cp /boot/vendor_hw/android.hardware.security.keymint-service /vendor/bin/hw/
    /boot/bin/busybox chmod 755 /vendor/bin/hw/android.hardware.security.keymint-service
    for lib in libkeymint.so libpuresoftkeymasterdevice.so lib_android_keymaster_keymint_utils.so; do
        if [ -f "/boot/vendor_lib64/$lib" ]; then
            /boot/bin/busybox cp "/boot/vendor_lib64/$lib" /vendor/lib64/ && \
                echo "<0>A16DBG: keymint lib staged $lib" > /dev/kmsg || \
                echo "<3>A16DBG: keymint lib cp failed $lib" > /dev/kmsg
            /boot/bin/busybox chmod 755 "/vendor/lib64/$lib"
        else
            echo "<3>A16DBG: keymint lib missing in initrd $lib" > /dev/kmsg
        fi
    done
    if [ -f /boot/vendor_hw/android.hardware.security.keymint-service.xml ]; then
        /boot/bin/busybox cp /boot/vendor_hw/android.hardware.security.keymint-service.xml \
            /vendor/etc/vintf/manifest/
    fi
    echo "<0>A16DBG: keymint HAL staged ($(/boot/bin/busybox wc -c < /vendor/bin/hw/android.hardware.security.keymint-service) bytes) libs=$(/boot/bin/busybox ls /vendor/lib64 2>&1 | /boot/bin/busybox tr '\n' ' ')" > /dev/kmsg
}
stage_odsign_vendor() {
    if [ -s /data/statsd-libs/libstatspull.so ]; then
        for _lib in libstatspull.so libstatssocket.so; do
            /boot/bin/busybox cat "/data/statsd-libs/$_lib" > "/vendor/lib64/$_lib"
            /boot/bin/busybox chmod 755 "/vendor/lib64/$_lib"
        done
    fi
    _odsign_src=/system/bin/odsign
    [ -x /boot/bin/odsign ] && _odsign_src=/boot/bin/odsign
    if [ -f "$_odsign_src" ]; then
        /boot/bin/busybox cat "$_odsign_src" > /vendor/bin/odsign
        /boot/bin/busybox chmod 755 /vendor/bin/odsign
        echo "<0>A16DBG: henry-7R odsign vendor staged src=$_odsign_src odsign=$(/boot/bin/busybox wc -c < /vendor/bin/odsign 2>/dev/null)B statsd=$(/boot/bin/busybox wc -c < /vendor/lib64/libstatspull.so 2>/dev/null)B" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7R skip: odsign missing" > /dev/kmsg
    fi
}
stage_keymint_hal
stage_odsign_vendor
cat > /vendor/bin/bs-keymint.sh <<'KMEOF'
#!/boot/bin/sh
echo "<0>A16DBG: keymint-wrapper start" > /dev/kmsg
LOG=/data/keymint.stderr
/boot/bin/busybox rm -f "$LOG"
export LD_LIBRARY_PATH=/vendor/lib64:/system/lib64:/apex/com.android.runtime/lib64/bionic
/vendor/bin/hw/android.hardware.security.keymint-service "$@" 2>"$LOG"
rc=$?
if [ -s "$LOG" ]; then
    /boot/bin/busybox head -20 "$LOG" | while IFS= read -r line; do
        echo "<0>A16DBG: keymint: $line" > /dev/kmsg
    done
fi
echo "<0>A16DBG: keymint-wrapper exit rc=$rc" > /dev/kmsg
exit $rc
KMEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-keymint.sh
cat > /vendor/bin/bs-keystore2.sh <<'KSEOF'
#!/boot/bin/sh
echo "<0>A16DBG: keystore2-wrapper start" > /dev/kmsg
LOG=/data/keystore2.stderr
/boot/bin/busybox rm -f "$LOG"
export LD_LIBRARY_PATH=/system/lib64:/apex/com.android.i18n/lib64:/apex/com.android.runtime/lib64/bionic
KS=/boot/bin/keystore2
[ -x "$KS" ] || KS=/system/bin/keystore2
echo "<0>A16DBG: keystore2-wrapper bin=$KS" > /dev/kmsg
"$KS" "$@" 2>"$LOG"
rc=$?
if [ -s "$LOG" ]; then
    /boot/bin/busybox head -20 "$LOG" | while IFS= read -r line; do
        echo "<0>A16DBG: keystore2: $line" > /dev/kmsg
    done
fi
echo "<0>A16DBG: keystore2-wrapper exit rc=$rc" > /dev/kmsg
exit $rc
KSEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-keystore2.sh
cat > /vendor/bin/bs-earlyboot.sh <<'EBEOF'
#!/boot/bin/sh
# Henry 7BG+: vdc earlyBootEnded via bootstrap linker with bounded retries.
echo "<0>A16DBG: henry-7BG earlyBootEnded start uid=$(/boot/bin/busybox id 2>/dev/null)" > /dev/kmsg
LOGBASE=/data/earlyboot.stderr
/boot/bin/busybox rm -f "$LOGBASE" "$LOGBASE".*
VDC=/data/system_bin/vdc
[ -x /data/system_bin/vdc.real ] && VDC=/data/system_bin/vdc.real
[ -x "$VDC" ] || VDC=/system/bin/vdc
LINKER=/system/bin/bootstrap/linker64
[ -x "$LINKER" ] || LINKER=/apex/com.android.runtime/bin/linker64
export LD_LIBRARY_PATH=/system/lib64:/vendor/lib64:/apex/com.android.runtime/lib64/bionic

run_vdc_once() {
    _attempt="$1"
    _log="$LOGBASE.$_attempt"
    echo "<0>A16DBG: henry-7BG attempt=$_attempt vdc=$VDC linker=$LINKER" > /dev/kmsg
    "$LINKER" "$VDC" keymaster earlyBootEnded 2>"$_log" &
    _pid=$!
    _sec=0
    while /boot/bin/busybox kill -0 "$_pid" 2>/dev/null; do
        if [ "$_sec" -ge 12 ]; then
            echo "<3>A16DBG: henry-7BG attempt=$_attempt timeout pid=$_pid" > /dev/kmsg
            /boot/bin/busybox kill "$_pid" 2>/dev/null
            /boot/bin/busybox sleep 1
            /boot/bin/busybox kill -9 "$_pid" 2>/dev/null
            return 124
        fi
        /boot/bin/busybox sleep 1
        _sec=$((_sec + 1))
    done
    wait "$_pid"
    return $?
}

attempt=1
rc=1
while [ "$attempt" -le 5 ]; do
    run_vdc_once "$attempt"
    rc=$?
    LOG="$LOGBASE.$attempt"
    if [ -s "$LOG" ]; then
        /boot/bin/busybox head -40 "$LOG" | while IFS= read -r line; do
            echo "<0>A16DBG: henry-7BG vdc[$attempt]: $line" > /dev/kmsg
        done
    fi
    echo "<0>A16DBG: henry-7BG attempt=$attempt rc=$rc" > /dev/kmsg
    [ "$rc" = "0" ] && break
    /boot/bin/busybox sleep 2
    attempt=$((attempt + 1))
done
echo "<0>A16DBG: henry-7BG earlyBootEnded exit rc=$rc attempts=$attempt" > /dev/kmsg
# R123: signal bs-odsign to proceed (boot level key establishment attempted). odsign gates on
# this to avoid the class-core-vs-post-fs-data ordering race that let odsign run before keys.
SETPROP=/data/system_bin/setprop
[ -x "$SETPROP" ] || SETPROP=/system/bin/setprop
[ -x "$SETPROP" ] && "$SETPROP" sys.bs.earlyboot.done 1
exit $rc
EBEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-earlyboot.sh
cat > /vendor/bin/bs-odsign.sh <<'ODEOF'
#!/boot/bin/sh
# Henry 7BD: real odsign — odrefresh generates boot-framework.* (henry 7R path)
echo "<0>A16DBG: henry-7BD odsign real start" > /dev/kmsg
# R123: gate on bs-earlyboot having run earlyBootEnded (boot level keys). init action ordering
# does NOT guarantee odsign (class core, on boot) runs after bs-earlyboot (post-fs-data) —
# observed odsign @13s racing ahead of bs-earlyboot @15s → BOOT_LEVEL_EXCEEDED. Wait explicitly.
GETPROP=/data/system_bin/getprop
[ -x "$GETPROP" ] || GETPROP=/system/bin/getprop
_w=0
while [ $_w -lt 180 ]; do
    if [ -x "$GETPROP" ] && [ "$("$GETPROP" sys.bs.earlyboot.done 2>/dev/null)" = "1" ]; then break; fi
    /boot/bin/busybox sleep 1 2>/dev/null || sleep 1
    _w=$((_w + 1))
done
echo "<0>A16DBG: henry-7BD odsign post-earlyboot wait=${_w}s done=$("$GETPROP" sys.bs.earlyboot.done 2>/dev/null)" > /dev/kmsg
LOG=/data/odsign.stderr
/boot/bin/busybox rm -f "$LOG"
ODS=/vendor/bin/odsign
[ -x "$ODS" ] || ODS=/system/bin/odsign
LINKER=/system/bin/bootstrap/linker64
[ -x "$LINKER" ] || LINKER=/apex/com.android.runtime/bin/linker64
_apexdc=/data/misc/apexdata/com.android.art/dalvik-cache/x86_64
for _f in boot-framework.art boot-framework.oat boot-framework.vdex; do
    /boot/bin/busybox rm -f "$_apexdc/$_f" /data/dalvik-cache/x86_64/$_f 2>/dev/null
done
# R127/R128 probe found /apex/com.android.art GONE at odsign time (apexd cleared stage2's
# art-payload mount). R129/R130: re-establish the art APEX here so odsign->odrefresh can run.
_art_mp=/apex/com.android.art@990091000
for _d in /apex/com.android.art@* /apex/com.android.art.debug@*; do [ -d "$_d" ] && _art_mp="$_d" && break; done
_apimg=$([ -f /boot/art-payload.img ] && echo yes || echo no)
_mntpaths=$(/boot/bin/busybox grep "com.android.art" /proc/mounts 2>/dev/null | /boot/bin/busybox cut -d' ' -f1-2 | /boot/bin/busybox tr '\n' ';')
if [ ! -f "$_art_mp/bin/odrefresh" ] && [ "$_apimg" = yes ]; then
    /boot/bin/busybox umount "$_art_mp/lib64" 2>/dev/null
    /boot/bin/busybox umount "$_art_mp" 2>/dev/null
    /boot/bin/busybox mkdir -p "$_art_mp"
    _mrc=1
    echo "<0>A16DBG: henry-7BO art-remount apimg=$_apimg mnts=$_mntpaths" > /dev/kmsg
    # R130: direct erofs mount first (avoids losetup -f → loop0 clash with /system)
    if /boot/bin/busybox mount -t erofs -o ro /boot/art-payload.img "$_art_mp" 2>/dev/null; then
        _mrc=0
        echo "<0>A16DBG: henry-7BO art-remount direct-erofs mrc=0" > /dev/kmsg
    else
        _lp=""; _n=10
        while [ $_n -lt 64 ]; do
            if [ ! -f "/sys/block/loop$_n/loop/backing_file" ]; then _lp=/dev/loop$_n; break; fi
            _n=$((_n + 1))
        done
        if [ -n "$_lp" ] && /boot/bin/busybox losetup "$_lp" /boot/art-payload.img 2>/dev/null &&
           /boot/bin/busybox mount -t erofs -o ro "$_lp" "$_art_mp" 2>/dev/null; then
            _mrc=0
        fi
        echo "<0>A16DBG: henry-7BO art-remount loop=$_lp mrc=$_mrc" > /dev/kmsg
    fi
fi
# R131: copy odrefresh NEEDED libs from payload lib64 before art-libs bind hides them
if [ -f "$_art_mp/bin/odrefresh" ] && [ -d /data/art-libs ] && [ -d "$_art_mp/lib64" ]; then
    _oen=0
    for _lib in libarttools.so libdexfile.so libartbase.so libprofile.so libnativebridge.so; do
        if [ -f "$_art_mp/lib64/$_lib" ] && [ ! -f "/data/art-libs/$_lib" ]; then
            /boot/bin/busybox cat "$_art_mp/lib64/$_lib" > "/data/art-libs/$_lib"
            /boot/bin/busybox chmod 755 "/data/art-libs/$_lib"
            _oen=$((_oen + 1))
        fi
    done
    echo "<0>A16DBG: henry-7BP art-libs payload-enrich n=$_oen arttools=$(/boot/bin/busybox wc -c < /data/art-libs/libarttools.so 2>/dev/null)B dexfile=$(/boot/bin/busybox wc -c < /data/art-libs/libdexfile.so 2>/dev/null)B" > /dev/kmsg
fi
# R132: do NOT bind art-libs over payload lib64 for odsign — odrefresh linker needs native
# libarttools.so from payload; art-libs bind hides it from com_android_art namespace (R130/R131).
/boot/bin/busybox rm -rf /apex/com.android.art 2>/dev/null
/boot/bin/busybox ln -sfn "$_art_mp" /apex/com.android.art
echo "<0>A16DBG: henry-7BO art-fix art_mp=$_art_mp odrefresh=$([ -f "$_art_mp/bin/odrefresh" ] && echo yes || echo no) arttools_mp=$(/boot/bin/busybox wc -c < $_art_mp/lib64/libarttools.so 2>/dev/null)B artlink=$(/boot/bin/busybox readlink /apex/com.android.art 2>&1)" > /dev/kmsg
# R145: i18n APEX javalib @ odsign — odrefresh primary BCP needs core-icu4j.jar (lib64-only bind hides javalib)
_i18n_mp=/apex/com.android.i18n@1
for _d in /apex/com.android.i18n@*; do [ -d "$_d" ] && _i18n_mp="$_d" && break; done
if [ ! -f "$_i18n_mp/javalib/core-icu4j.jar" ]; then
    _iapex=/system/apex/com.android.i18n.apex
    /boot/bin/busybox umount "$_i18n_mp/lib64" 2>/dev/null
    /boot/bin/busybox umount "$_i18n_mp" 2>/dev/null
    /boot/bin/busybox mkdir -p "$_i18n_mp"
    _imrc=1
    _ilp=""; _n=10
    while [ $_n -lt 64 ]; do
        if [ ! -f "/sys/block/loop$_n/loop/backing_file" ]; then _ilp=/dev/loop$_n; break; fi
        _n=$((_n + 1))
    done
    if [ -n "$_ilp" ] && [ -f "$_iapex" ] &&
       /boot/bin/busybox losetup -o 4096 "$_ilp" "$_iapex" 2>/dev/null &&
       /boot/bin/busybox mount -t erofs -o ro "$_ilp" "$_i18n_mp" 2>/dev/null; then
        _imrc=0
    elif [ -f /boot/i18n-javalib/core-icu4j.jar ]; then
        /boot/bin/busybox mkdir -p "$_i18n_mp/javalib"
        /boot/bin/busybox cat /boot/i18n-javalib/core-icu4j.jar > "$_i18n_mp/javalib/core-icu4j.jar"
        /boot/bin/busybox chmod 644 "$_i18n_mp/javalib/core-icu4j.jar"
        _imrc=0
    fi
    /boot/bin/busybox ln -sfn "$_i18n_mp" /apex/com.android.i18n
    echo "<0>A16DBG: henry-7BW i18n-remount loop=$_ilp mrc=$_imrc icu4j=$(/boot/bin/busybox wc -c < $_i18n_mp/javalib/core-icu4j.jar 2>/dev/null)B" > /dev/kmsg
else
    echo "<0>A16DBG: henry-7BW i18n-ok icu4j=$(/boot/bin/busybox wc -c < $_i18n_mp/javalib/core-icu4j.jar 2>/dev/null)B" > /dev/kmsg
fi
if [ -d /data/i18n-libs ] && [ -f /data/i18n-libs/libicu.so ]; then
    /boot/bin/busybox mkdir -p "$_i18n_mp/lib64"
    /boot/bin/busybox umount "$_i18n_mp/lib64" 2>/dev/null
    /boot/bin/busybox mount --bind /data/i18n-libs "$_i18n_mp/lib64" 2>/dev/null || true
fi
# R147/R148: mainline APEX javalib @ odsign — odrefresh mainline BCP needs framework/service-*.jar
_ml_n=0
_ml_miss=0
for _mj_dir in /boot/mainline-javalib/com.android.*; do
    [ -d "$_mj_dir" ] || continue
    _mod=$(/boot/bin/busybox basename "$_mj_dir")
    _mp="/apex/${_mod}@1"
    for _d in /apex/${_mod}@*; do [ -d "$_d" ] && _mp="$_d" && break; done
    _probe=$(/boot/bin/busybox ls "$_mj_dir"/*.jar 2>/dev/null | /boot/bin/busybox head -1)
    [ -n "$_probe" ] || continue
    _need=0
    for _pj in "$_mj_dir"/*.jar; do
        [ -f "$_pj" ] || continue
        _pbn=$(/boot/bin/busybox basename "$_pj")
        [ -f "$_mp/javalib/$_pbn" ] || _need=1
    done
    if [ "$_need" = "1" ]; then
        /boot/bin/busybox umount "$_mp" 2>/dev/null
        /boot/bin/busybox mkdir -p "$_mp/javalib"
        for _pj in "$_mj_dir"/*.jar; do
            [ -f "$_pj" ] || continue
            _pbn=$(/boot/bin/busybox basename "$_pj")
            /boot/bin/busybox cat "$_pj" > "$_mp/javalib/$_pbn"
            /boot/bin/busybox chmod 644 "$_mp/javalib/$_pbn"
        done
        /boot/bin/busybox ln -sfn "$_mp" "/apex/$_mod"
    fi
    _fc=$(/boot/bin/busybox ls "$_mp/javalib"/*.jar 2>/dev/null | /boot/bin/busybox wc -l)
    if [ "$_fc" -gt 0 ] 2>/dev/null; then
        _ml_n=$((_ml_n + 1))
    else
        _ml_miss=$((_ml_miss + 1))
    fi
done
echo "<0>A16DBG: henry-7BY mainline-javalib n=$_ml_n miss=$_ml_miss appsearch=$(/boot/bin/busybox wc -c < /apex/com.android.appsearch/javalib/framework-appsearch.jar 2>/dev/null)B adservices=$(/boot/bin/busybox wc -c < /apex/com.android.adservices/javalib/framework-adservices.jar 2>/dev/null)B" > /dev/kmsg
# R149: classpath vs apex package name mismatches (odrefresh expects btservices, image ships com.android.bt)
for _aspec in com.android.btservices:com.android.bt; do
    _alias=${_aspec%%:*}
    _src=${_aspec##*:}
    _src_mp=""
    for _d in /apex/${_src}@*; do [ -d "$_d/javalib" ] && _src_mp="$_d" && break; done
    if [ -n "$_src_mp" ]; then
        /boot/bin/busybox ln -sfn "$_src_mp" "/apex/$_alias"
        echo "<0>A16DBG: henry-7BZ apex-alias $_alias=$_src_mp bt-jar=$(/boot/bin/busybox wc -c < /apex/$_alias/javalib/framework-bluetooth.jar 2>/dev/null)B" > /dev/kmsg
    fi
done
# R138/R139: /apex/apex-info-list.xml missing → odrefresh "Could not get APEX info" (bind, not cp)
_ail=/apex/apex-info-list.xml
_meta=/data/apex-meta/apex-info-list.xml
/boot/bin/busybox mkdir -p /data/apex-meta
printf '%s\n' \
  '<?xml version="1.0" encoding="utf-8"?>' \
  '<apex-info-list>' \
  '  <apex-info' \
  "      moduleName=\"com.android.art\"" \
  "      modulePath=\"$_art_mp\"" \
  '      preinstalledModulePath="/system/apex/com.android.art.debug.capex"' \
  '      versionCode="990091000"' \
  '      versionName="36"' \
  '      isFactory="false"' \
  '      isActive="true"' \
  '      lastUpdateMillis="0">' \
  '  </apex-info>' \
  '  <apex-info' \
  '      moduleName="com.android.adservices"' \
  "      modulePath=\"$_ads_mp\"" \
  '      preinstalledModulePath="/system/apex/com.android.adservices.capex"' \
  '      versionCode="360499999"' \
  '      versionName="16"' \
  '      isFactory="false"' \
  '      isActive="true"' \
  '      lastUpdateMillis="0">' \
  '  </apex-info>' \
  '</apex-info-list>' > "$_meta"
/boot/bin/busybox umount "$_ail" 2>/dev/null
if /boot/bin/busybox mount --bind "$_meta" "$_ail" 2>/dev/null; then
    echo "<0>A16DBG: henry-7BT apex-info-list bind bytes=$(/boot/bin/busybox wc -c < $_meta 2>/dev/null)B" > /dev/kmsg
else
    /boot/bin/busybox cp "$_meta" "$_ail" 2>/dev/null
    echo "<0>A16DBG: henry-7BT apex-info-list cp bytes=$(/boot/bin/busybox wc -c < $_ail 2>/dev/null)B rc=$?" > /dev/kmsg
fi
# R142/R143/R151: dex2oat64 + odrefresh wrappers — logwrapper spawn needs linker64 (libc in namespace)
_D2O="$_art_mp/bin/dex2oat64"
_D2O_REAL=/data/dex2oat64.real
_D2O_WRAP=/data/dex2oat64.wrap
_ODR_REAL=/data/odrefresh.real
_ODR_WRAP=/data/odrefresh.wrap
_BIN_OV=/data/art-bin-ov
if [ -f "$_D2O" ] || [ -f "$_art_mp/bin/odrefresh" ]; then
    if [ -f "$_D2O" ] && [ ! -s "$_D2O_REAL" ]; then
        /boot/bin/busybox cat "$_D2O" > "$_D2O_REAL"
        /boot/bin/busybox chmod 755 "$_D2O_REAL"
    fi
    if [ -f "$_art_mp/bin/odrefresh" ] && [ ! -s "$_ODR_REAL" ]; then
        /boot/bin/busybox cat "$_art_mp/bin/odrefresh" > "$_ODR_REAL"
        /boot/bin/busybox chmod 755 "$_ODR_REAL"
    fi
    printf '%s\n' '#!/boot/bin/sh' \
      'export LD_LIBRARY_PATH="/apex/com.android.runtime/lib64/bionic:/system/lib64:'"$_art_mp"'/lib64:/vendor/lib64:/data/statsd-libs:/data/art-libs"' \
      'exec /system/bin/bootstrap/linker64 /data/dex2oat64.real "$@"' > "$_D2O_WRAP"
    /boot/bin/busybox chmod 755 "$_D2O_WRAP"
    printf '%s\n' '#!/boot/bin/sh' \
      'export LD_LIBRARY_PATH="/apex/com.android.runtime/lib64/bionic:/system/lib64:'"$_art_mp"'/lib64:/vendor/lib64:/data/statsd-libs:/data/art-libs"' \
      'exec /system/bin/bootstrap/linker64 /data/odrefresh.real "$@"' > "$_ODR_WRAP"
    /boot/bin/busybox chmod 755 "$_ODR_WRAP"
    /boot/bin/busybox rm -rf "$_BIN_OV"
    /boot/bin/busybox mkdir -p "$_BIN_OV"
    for _bf in "$_art_mp/bin"/*; do
        [ -e "$_bf" ] || continue
        _bn=$(/boot/bin/busybox basename "$_bf")
        case "$_bn" in
            dex2oat|dex2oat64)
                /boot/bin/busybox cp "$_D2O_WRAP" "$_BIN_OV/$_bn"
                ;;
            odrefresh)
                /boot/bin/busybox cp "$_ODR_WRAP" "$_BIN_OV/$_bn"
                ;;
            dex2oat.real|dex2oat64.real|odrefresh.real)
                ;; # reals live at /data/*.real
            *)
                if [ -f "$_bf" ]; then
                    /boot/bin/busybox cp "$_bf" "$_BIN_OV/$_bn"
                elif [ -L "$_bf" ]; then
                    _lt=$(/boot/bin/busybox readlink "$_bf")
                    /boot/bin/busybox ln -sf "$_lt" "$_BIN_OV/$_bn"
                fi
                ;;
        esac
    done
    /boot/bin/busybox cp "$_D2O_WRAP" "$_BIN_OV/dex2oat64" "$_BIN_OV/dex2oat" 2>/dev/null
    _real_sz=$(/boot/bin/busybox wc -c < "$_D2O_REAL" 2>/dev/null)
    _odr_sz=$(/boot/bin/busybox wc -c < "$_ODR_REAL" 2>/dev/null)
    /boot/bin/busybox umount "$_art_mp/bin" 2>/dev/null
    if /boot/bin/busybox mount --bind "$_BIN_OV" "$_art_mp/bin" 2>/dev/null; then
        echo "<0>A16DBG: henry-7BV dex2oat bin-ov bind ok n=$(/boot/bin/busybox ls "$_BIN_OV" 2>/dev/null | /boot/bin/busybox wc -l) real=${_real_sz}B" > /dev/kmsg
        echo "<0>A16DBG: henry-7CA odrefresh-wrap bind ok odr=${_odr_sz}B" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7BV dex2oat bin-ov bind fail" > /dev/kmsg
    fi
    if [ -f "$_D2O_REAL" ]; then
        _D2LOG=/data/dex2oat-probe.stderr
        /boot/bin/busybox rm -f "$_D2LOG"
        LD_LIBRARY_PATH="/apex/com.android.runtime/lib64/bionic:/system/lib64:$_art_mp/lib64:/vendor/lib64:/data/statsd-libs:/data/art-libs" \
            "$LINKER" "$_D2O_REAL" --version >>"$_D2LOG" 2>&1
        echo "<0>A16DBG: henry-7BV dex2oat-probe linker rc=$? log=$(/boot/bin/busybox wc -c < $_D2LOG 2>/dev/null)B" > /dev/kmsg
        if [ -s "$_D2LOG" ]; then
            /boot/bin/busybox head -3 "$_D2LOG" | while IFS= read -r line; do
                echo "<0>A16DBG: henry-7BV probe: $line" > /dev/kmsg
            done
        fi
    fi
    if [ -x "$_art_mp/bin/odrefresh" ]; then
        "$_art_mp/bin/odrefresh" --check >/data/odrefresh-wrap.probe 2>&1
        echo "<0>A16DBG: henry-7CA odrefresh-wrap probe rc=$? log=$(/boot/bin/busybox wc -c < /data/odrefresh-wrap.probe 2>/dev/null)B" > /dev/kmsg
    fi
fi
# R135–R151: odrefresh pre-run via bin/ wrapper (same path odsign logwrapper uses)
export LD_LIBRARY_PATH="/apex/com.android.runtime/lib64/bionic:/system/lib64:$_art_mp/lib64:/vendor/lib64:/data/statsd-libs"
echo "<0>A16DBG: henry-7BR odsign LD_LIBRARY_PATH=bionic:system:$_art_mp/lib64:..." > /dev/kmsg
_ODREF="$_art_mp/bin/odrefresh"
if [ -x "$_ODREF" ]; then
    _ODLOG=/data/odrefresh-pre.stderr
    _ODLC=/data/odrefresh-pre.logcat
    /boot/bin/busybox rm -f "$_ODLOG" "$_ODLC"
    /boot/bin/busybox rm -rf /data/misc/odrefresh 2>/dev/null
    # R169: do NOT stage force_disable_uffd cache-info (conflicts with CC libart; see R169 note above).
    _cache_info=/data/misc/apexdata/com.android.art/dalvik-cache/cache-info.xml
    /boot/bin/busybox rm -f "$_cache_info"
    echo "<0>A16DBG: henry-7CD cache-info removed pre-odrefresh (R169 CC default)" > /dev/kmsg
    # R153: drop stale partial boot chain (boot.art without oat/vdex poisons odrefresh)
    if [ -s "$_apexdc/boot.art" ]; then
        if [ ! -s "$_apexdc/boot.oat" ] || [ ! -s "$_apexdc/boot.vdex" ]; then
            /boot/bin/busybox rm -f "$_apexdc/boot.art" "$_apexdc/boot.oat" "$_apexdc/boot.vdex"
            echo "<3>A16DBG: henry-7CC stale boot chain cleared art-only" > /dev/kmsg
        fi
    fi
    "$_ODREF" --check >>"$_ODLOG" 2>&1
    _ocr=$?
    echo "<0>A16DBG: henry-7BS odrefresh-pre --check rc=$_ocr" > /dev/kmsg
    if [ "$_ocr" != "0" ]; then
        # R169: fresh compile, NO force_disable_uffd props (let CC libart default to read-barrier=true;
        # force_disable conflicts with the R168 consistent-CC libart, causing boot.oat non-read-barrier mismatch).
        /boot/bin/busybox rm -f "$_apexdc/boot.art" "$_apexdc/boot.oat" "$_apexdc/boot.vdex"
        echo "<0>A16DBG: henry-7CD boot chain cleared for barrier-safe recompile" > /dev/kmsg
        # R157: --only-boot-images — rc=80 was kCompilationFailed from system_server
        # after primary boot chain succeeded; skip SS jars in pre-run.
        "$_ODREF" --only-boot-images --force-compile >>"$_ODLOG" 2>&1
        _ocr=$?
        echo "<0>A16DBG: henry-7BS odrefresh-pre --only-boot-images --force-compile rc=$_ocr" > /dev/kmsg
    fi
    if command -v logcat >/dev/null 2>&1; then
        logcat -d -s odrefresh:* dex2oat:* odsign:* >>"$_ODLC" 2>/dev/null
    elif [ -x /system/bin/logcat ]; then
        "$LINKER" /system/bin/logcat -d -s odrefresh:* dex2oat:* odsign:* >>"$_ODLC" 2>/dev/null
    fi
    if [ -s "$_ODLOG" ]; then
        /boot/bin/busybox head -100 "$_ODLOG" | while IFS= read -r line; do
            echo "<0>A16DBG: henry-7BS pre: $line" > /dev/kmsg
        done
    fi
    if [ -s "$_ODLC" ]; then
        /boot/bin/busybox tail -30 "$_ODLC" | while IFS= read -r line; do
            echo "<0>A16DBG: henry-7BS lc: $line" > /dev/kmsg
        done
    fi
    echo "<0>A16DBG: henry-7BS odrefresh-log bytes=$(/boot/bin/busybox wc -c < $_ODLOG 2>/dev/null)B lc=$(/boot/bin/busybox wc -c < $_ODLC 2>/dev/null)B" > /dev/kmsg
    echo "<0>A16DBG: henry-7BS pre boot-art=$(/boot/bin/busybox wc -c < $_apexdc/boot.art 2>/dev/null)B boot-oat=$(/boot/bin/busybox wc -c < $_apexdc/boot.oat 2>/dev/null)B boot-vdex=$(/boot/bin/busybox wc -c < $_apexdc/boot.vdex 2>/dev/null)B fw-oat=$(/boot/bin/busybox wc -c < $_apexdc/boot-framework.oat 2>/dev/null)B fw-art=$(/boot/bin/busybox wc -c < $_apexdc/boot-framework.art 2>/dev/null)B" > /dev/kmsg
    if [ -d /data/misc/odrefresh ]; then
        for _orf in /data/misc/odrefresh/*; do
            [ -f "$_orf" ] || continue
            /boot/bin/busybox head -5 "$_orf" 2>/dev/null | while IFS= read -r line; do
                echo "<0>A16DBG: henry-7CC odrefresh-meta $(/boot/bin/busybox basename "$_orf"): $line" > /dev/kmsg
            done
        done
    fi
fi
# R157 henry-7CF: A16/U+ boot image inventory — framework is in primary boot.art
# (--single-image); mainline extensions are boot-framework-<module>.* not boot-framework.*
_cf_ml=0
_cf_comp=0
for _cf in "$_apexdc"/*; do
    [ -f "$_cf" ] || continue
    _cfn=$(/boot/bin/busybox basename "$_cf")
    case "$_cfn" in
        boot-framework-*.oat)
            _cf_ml=$((_cf_ml + 1))
            echo "<0>A16DBG: henry-7CF ml-oat $_cfn bytes=$(/boot/bin/busybox wc -c < "$_cf" 2>/dev/null)B" > /dev/kmsg
            ;;
        boot-apache-xml.oat|boot-bouncycastle.oat|boot-conscrypt.oat|boot-core-icu4j.oat|boot-core-libart.oat|boot-okhttp.oat)
            _cf_comp=$((_cf_comp + 1))
            echo "<0>A16DBG: henry-7CF comp-oat $_cfn bytes=$(/boot/bin/busybox wc -c < "$_cf" 2>/dev/null)B" > /dev/kmsg
            ;;
    esac
done
echo "<0>A16DBG: henry-7CF apexdc-inventory boot-art=$(/boot/bin/busybox wc -c < $_apexdc/boot.art 2>/dev/null)B ml-oat=$_cf_ml comp-oat=$_cf_comp legacy-fw-oat=$(/boot/bin/busybox wc -c < $_apexdc/boot-framework.oat 2>/dev/null)B" > /dev/kmsg
# R176e: backup boot chain BEFORE ml-retry (retry re-runs odrefresh --force-compile
# which wipes previously generated boot.art). Without this backup, n=0 at the later
# boot-chain-backup and zygote sees boot.art=0B even though odrefresh succeeded.
if [ -s "$_apexdc/boot.art" ]; then
    /boot/bin/busybox rm -rf "$_bakd"
    /boot/bin/busybox mkdir -p "$_bakd"
    for _bf in boot.art boot.oat boot.vdex boot-framework.art boot-framework.oat boot-framework.vdex; do
        if [ -s "$_apexdc/$_bf" ]; then
            /boot/bin/busybox cat "$_apexdc/$_bf" > "$_bakd/$_bf"
            /boot/bin/busybox chmod 644 "$_bakd/$_bf"
        fi
    done
    echo "<0>A16DBG: henry-7CC pre-retry-backup art=$(/boot/bin/busybox wc -c < $_bakd/boot.art 2>/dev/null)B oat=$(/boot/bin/busybox wc -c < $_bakd/boot.oat 2>/dev/null)B" > /dev/kmsg
fi
# Retry mainline extension compile if primary ok but no mainline oat
if [ -s "$_apexdc/boot.art" ] && [ "$_cf_ml" -eq 0 ] && [ -x "$_ODREF" ]; then
    _MLLOG=/data/odrefresh-ml.stderr
    /boot/bin/busybox rm -f "$_MLLOG"
    "$_ODREF" --only-boot-images --force-compile >>"$_MLLOG" 2>&1
    _ml_rc=$?
    echo "<0>A16DBG: henry-7CF odrefresh-ml-retry rc=$_ml_rc log=$(/boot/bin/busybox wc -c < $_MLLOG 2>/dev/null)B" > /dev/kmsg
    if [ -s "$_MLLOG" ]; then
        /boot/bin/busybox head -20 "$_MLLOG" | while IFS= read -r line; do
            echo "<0>A16DBG: henry-7CF ml: $line" > /dev/kmsg
        done
    fi
    _cf_ml=0
    for _cf in "$_apexdc"/boot-framework-*.oat; do
        [ -f "$_cf" ] || continue
        _cfn=$(/boot/bin/busybox basename "$_cf")
        _cf_ml=$((_cf_ml + 1))
        echo "<0>A16DBG: henry-7CF ml-oat-post $_cfn bytes=$(/boot/bin/busybox wc -c < "$_cf" 2>/dev/null)B" > /dev/kmsg
    done
    echo "<0>A16DBG: henry-7CF ml-oat-post n=$_cf_ml" > /dev/kmsg
    # R176e: if retry wiped boot.art, restore from pre-retry backup
    if [ ! -s "$_apexdc/boot.art" ] && [ -s "$_bakd/boot.art" ]; then
        for _bf in boot.art boot.oat boot.vdex; do
            [ -s "$_bakd/$_bf" ] && /boot/bin/busybox cat "$_bakd/$_bf" > "$_apexdc/$_bf"
        done
        echo "<0>A16DBG: henry-7CC post-retry-restore art=$(/boot/bin/busybox wc -c < $_apexdc/boot.art 2>/dev/null)B" > /dev/kmsg
    fi
fi
# R153: backup full boot chain before odsign (inner odrefresh may wipe dalvik-cache)
_bakd=/data/boot-chain-bak
/boot/bin/busybox rm -rf "$_bakd"
/boot/bin/busybox mkdir -p "$_bakd"
_bak_n=0
for _bf in boot.art boot.oat boot.vdex boot-framework.art boot-framework.oat boot-framework.vdex; do
    if [ -s "$_apexdc/$_bf" ]; then
        /boot/bin/busybox cat "$_apexdc/$_bf" > "$_bakd/$_bf"
        /boot/bin/busybox chmod 644 "$_bakd/$_bf"
        _bak_n=$((_bak_n + 1))
    fi
done
echo "<0>A16DBG: henry-7CC boot-chain-backup n=$_bak_n art=$(/boot/bin/busybox wc -c < $_bakd/boot.art 2>/dev/null)B oat=$(/boot/bin/busybox wc -c < $_bakd/boot.oat 2>/dev/null)B vdex=$(/boot/bin/busybox wc -c < $_bakd/boot.vdex 2>/dev/null)B" > /dev/kmsg
"$LINKER" "$ODS" "$@" 2>"$LOG"
rc=$?
# R153: restore full boot chain only when oat+vdex present; mirror + framework overlay
_chain_ok=0
if [ -s "$_bakd/boot.art" ] && [ -s "$_bakd/boot.oat" ] && [ -s "$_bakd/boot.vdex" ]; then
    _chain_ok=1
fi
if [ ! -s "$_apexdc/boot.oat" ] && [ "$_chain_ok" = "1" ]; then
    /boot/bin/busybox mkdir -p "$_apexdc"
    for _bf in boot.art boot.oat boot.vdex boot-framework.art boot-framework.oat boot-framework.vdex; do
        [ -s "$_bakd/$_bf" ] || continue
        /boot/bin/busybox cat "$_bakd/$_bf" > "$_apexdc/$_bf"
        /boot/bin/busybox chmod 644 "$_apexdc/$_bf"
    done
    echo "<0>A16DBG: henry-7CC boot-chain-restored art=$(/boot/bin/busybox wc -c < $_apexdc/boot.art 2>/dev/null)B oat=$(/boot/bin/busybox wc -c < $_apexdc/boot.oat 2>/dev/null)B vdex=$(/boot/bin/busybox wc -c < $_apexdc/boot.vdex 2>/dev/null)B" > /dev/kmsg
elif [ ! -s "$_apexdc/boot.oat" ] && [ -s "$_apexdc/boot.art" ]; then
    /boot/bin/busybox rm -f "$_apexdc/boot.art"
    echo "<3>A16DBG: henry-7CC drop incomplete boot.art post-odsign" > /dev/kmsg
fi
_dlv=/data/dalvik-cache/x86_64
_fw=/system/framework
_fw_ov=/data/system-framework-overlay
/boot/bin/busybox mkdir -p "$_dlv" "$_fw_ov/x86_64"
for _bf in boot.art boot.oat boot.vdex; do
    _src="$_apexdc/$_bf"
    [ -f "$_src" ] || continue
    /boot/bin/busybox cat "$_src" > "$_dlv/$_bf" 2>/dev/null
    /boot/bin/busybox chmod 644 "$_dlv/$_bf"
done
for _src in "$_apexdc"/*; do
    [ -f "$_src" ] || continue
    _bn=$(/boot/bin/busybox basename "$_src")
    case "$_bn" in
        boot*.art|boot*.oat|boot*.vdex)
            /boot/bin/busybox cat "$_src" > "$_dlv/$_bn" 2>/dev/null
            /boot/bin/busybox chmod 644 "$_dlv/$_bn"
            /boot/bin/busybox cat "$_src" > "$_fw_ov/x86_64/$_bn" 2>/dev/null
            /boot/bin/busybox cat "$_src" > "$_fw_ov/$_bn" 2>/dev/null
            /boot/bin/busybox chmod 644 "$_fw_ov/x86_64/$_bn" "$_fw_ov/$_bn" 2>/dev/null
            ;;
    esac
done
if [ -d "$_fw" ]; then
    for _sf in "$_fw"/*; do
        [ -f "$_sf" ] || continue
        _sn=$(/boot/bin/busybox basename "$_sf")
        [ -f "$_fw_ov/$_sn" ] || /boot/bin/busybox cat "$_sf" > "$_fw_ov/$_sn" 2>/dev/null
    done
    if [ -d "$_fw/x86_64" ]; then
        for _sf in "$_fw/x86_64"/*; do
            [ -f "$_sf" ] || continue
            _sn=$(/boot/bin/busybox basename "$_sf")
            [ -f "$_fw_ov/x86_64/$_sn" ] || /boot/bin/busybox cat "$_sf" > "$_fw_ov/x86_64/$_sn" 2>/dev/null
        done
    fi
    /boot/bin/busybox umount "$_fw" 2>/dev/null
    if /boot/bin/busybox mount --bind "$_fw_ov" "$_fw" 2>/dev/null; then
        _ml_ov=$(/boot/bin/busybox ls "$_fw/x86_64"/boot-framework-*.oat 2>/dev/null | /boot/bin/busybox wc -l)
        echo "<0>A16DBG: henry-7CC framework-overlay ok boot-art=$(/boot/bin/busybox wc -c < $_fw/x86_64/boot.art 2>/dev/null)B boot-oat=$(/boot/bin/busybox wc -c < $_fw/x86_64/boot.oat 2>/dev/null)B ml-oat=$_ml_ov" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7CC framework-overlay fail" > /dev/kmsg
    fi
fi
# R169: do NOT re-stage force_disable_uffd cache-info after odsign (conflicts with CC libart).
_cache_info=/data/misc/apexdata/com.android.art/dalvik-cache/cache-info.xml
/boot/bin/busybox rm -f "$_cache_info"
if [ -s "$LOG" ]; then
    /boot/bin/busybox head -100 "$LOG" | while IFS= read -r line; do
        echo "<0>A16DBG: henry-7BD odsign: $line" > /dev/kmsg
    done
fi
echo "<0>A16DBG: henry-7BD odsign exit rc=$rc apex-boot=$(/boot/bin/busybox wc -c < $_apexdc/boot.art 2>/dev/null)B fw-oat=$(/boot/bin/busybox wc -c < $_apexdc/boot-framework.oat 2>/dev/null)B" > /dev/kmsg
exit $rc
ODEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-odsign.sh
cat > /vendor/bin/bs-netd.sh <<'NETEOF'
#!/boot/bin/sh
# Henry 7AF: netd stub — stock netd exit 1 → onrestart restart zygote → SIGKILL @ R83b
echo "<0>A16DBG: henry-7AF netd stub start" > /dev/kmsg
exec /boot/bin/busybox sleep 86400
NETEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-netd.sh
cat > /vendor/bin/bs-surfaceflinger.sh <<'SFEOF'
#!/boot/bin/sh
# Henry 7AG: surfaceflinger stub — stock exit 1 → class main cascade SIGKILL zygote @ R84
echo "<0>A16DBG: henry-7AG surfaceflinger stub start" > /dev/kmsg
exec /boot/bin/busybox sleep 86400
SFEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-surfaceflinger.sh
cat > /vendor/bin/bs-audioserver.sh <<'ASEOF'
#!/boot/bin/sh
# Henry 7AH: audioserver stub — class main boot batch failure @ R84
echo "<0>A16DBG: henry-7AH audioserver stub start" > /dev/kmsg
exec /boot/bin/busybox sleep 86400
ASEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-audioserver.sh
cat > /vendor/bin/bs-logd.sh <<'LOGDEOF'
#!/boot/bin/sh
# Henry 7AM: logd via bootstrap linker (stock logd exit 1 @ R85)
echo "<0>A16DBG: henry-7AM logd-wrapper start" > /dev/kmsg
LOG=/data/logd.stderr
/boot/bin/busybox rm -f "$LOG"
LOGD=/data/system_bin/logd
[ -x "$LOGD" ] || LOGD=/system/bin/logd
LINKER=/boot/bin/linker64
[ -x "$LINKER" ] || LINKER=/data/system_bin/linker64
[ -x "$LINKER" ] || LINKER=/system/bin/bootstrap/linker64
[ -x "$LINKER" ] || LINKER=/apex/com.android.runtime/bin/linker64
export LD_LIBRARY_PATH=/system/lib64:/apex/com.android.runtime/lib64/bionic:/data/system_lib64
echo "<0>A16DBG: henry-7AM logd-prep linker=$LINKER logd=$LOGD" > /dev/kmsg
"$LINKER" "$LOGD" "$@" 2>"$LOG"
rc=$?
if [ -s "$LOG" ]; then
    /boot/bin/busybox head -30 "$LOG" | while IFS= read -r line; do
        echo "<0>A16DBG: henry-7AM logd: $line" > /dev/kmsg
    done
fi
echo "<0>A16DBG: henry-7AM logd-wrapper exit rc=$rc" > /dev/kmsg
exit $rc
LOGDEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-logd.sh
cat > /vendor/bin/bs-zygote.sh <<'ZYGEOF'
#!/boot/bin/sh
echo "<0>A16DBG: zygote-wrapper start" > /dev/kmsg
LOG=/data/zygote.stderr
/boot/bin/busybox rm -f "$LOG"
# Henry 7AE: merge statsd + system overlap into art-libs before apex bind
for _lib in libstatspull.so libstatssocket.so; do
    [ -f /data/art-libs/$_lib ] && continue
    for _src in /data/statsd-libs/$_lib /boot/statsd-libs/$_lib; do
        [ -f "$_src" ] && /boot/bin/busybox cat "$_src" > "/data/art-libs/$_lib" && break
    done
done
for _lib in libbase.so libc++.so libexpat.so liblz4.so liblzma.so libunwindstack.so libdl_android.so heapprofd_client_api.so; do
    [ -f /data/art-libs/$_lib ] && continue
    for _src in /system/lib64/$_lib /data/system_lib64/$_lib; do
        [ -f "$_src" ] && /boot/bin/busybox cat "$_src" > "/data/art-libs/$_lib" && break
    done
done
# Henry 7AB: re-bind staged libs before JniInvocation dlopen(libart.so)
_art_mp=/apex/com.android.art@990091000
for _d in /apex/com.android.art@*; do
    [ -d "$_d" ] && _art_mp="$_d" && break
done
# Henry 7AVb: restore shim symlink if bs-apex already built it
if [ -f /data/apex-art-shim/etc/boot-image.prof ]; then
    /boot/bin/busybox ln -sfn /data/apex-art-shim /apex/com.android.art
    echo "<0>A16DBG: henry-7AVb restore-shim link=$(/boot/bin/busybox readlink /apex/com.android.art 2>/dev/null)" > /dev/kmsg
fi
if [ -d /data/art-libs ] && [ -f /data/art-libs/libart.so ]; then
    /boot/bin/busybox mkdir -p "$_art_mp/lib64"
    /boot/bin/busybox umount "$_art_mp/lib64" 2>/dev/null || true
    /boot/bin/busybox mount --bind /data/art-libs "$_art_mp/lib64" 2>/dev/null || true
    # Henry 7AVb: reapply art shim — 7AB ln -sfn $_art_mp clobbered shim @ R93
    _prof_src=""
    for _p in /data/boot-profiles/boot-image.prof /boot/profiles/boot-image.prof; do
        [ -f "$_p" ] && _prof_src="$_p" && break
    done
    if [ -n "$_prof_src" ]; then
        _shim=/data/apex-art-shim
        if [ ! -f "$_shim/etc/boot-image.prof" ]; then
            /boot/bin/busybox rm -rf "$_shim"
            /boot/bin/busybox mkdir -p "$_shim/etc"
            if [ -d "$_art_mp/etc" ]; then
                for _ef in "$_art_mp/etc"/*; do
                    [ -f "$_ef" ] || continue
                    _en=$(/boot/bin/busybox basename "$_ef")
                    /boot/bin/busybox cat "$_ef" > "$_shim/etc/$_en"
                done
            fi
            [ -f "$_shim/etc/boot-image.prof" ] || /boot/bin/busybox cat "$_prof_src" > "$_shim/etc/boot-image.prof"
            /boot/bin/busybox chmod 644 "$_shim/etc/boot-image.prof"
            for _sub in bin lib lib64; do
                [ -d "$_art_mp/$_sub" ] && /boot/bin/busybox ln -sf "$_art_mp/$_sub" "$_shim/$_sub"
            done
        fi
        if [ ! -f "$_shim/javalib/core-oj.jar" ]; then
            /boot/bin/busybox mkdir -p "$_shim/javalib"
            _mp_oj=$(/boot/bin/busybox wc -c < "$_art_mp/javalib/core-oj.jar" 2>/dev/null)
            echo "<0>A16DBG: henry-7AY zygote art_mp core-oj=${_mp_oj:-0}B" > /dev/kmsg
            _jav_src=""
            if [ -n "$_mp_oj" ] && [ "$_mp_oj" -gt 0 ] 2>/dev/null; then
                _jav_src="$_art_mp/javalib"
            elif [ -f /boot/art-javalib/core-oj.jar ]; then
                _jav_src=/boot/art-javalib
            fi
            if [ -n "$_jav_src" ]; then
                for _j in core-oj.jar core-libart.jar okhttp.jar bouncycastle.jar apache-xml.jar service-art.jar; do
                    [ -f "$_jav_src/$_j" ] && /boot/bin/busybox cat "$_jav_src/$_j" > "$_shim/javalib/$_j"
                done
                echo "<0>A16DBG: henry-7AY zygote staged src=$_jav_src core-oj=$(/boot/bin/busybox wc -c < $_shim/javalib/core-oj.jar 2>/dev/null)B" > /dev/kmsg
            else
                echo "<3>A16DBG: henry-7AY zygote javalib stage failed" > /dev/kmsg
            fi
        fi
        /boot/bin/busybox ln -sfn "$_shim" /apex/com.android.art
        echo "<0>A16DBG: henry-7AVb zygote-shim prof=$(/boot/bin/busybox wc -c < $_shim/etc/boot-image.prof 2>/dev/null)B core-oj=$(/boot/bin/busybox wc -c < $_shim/javalib/core-oj.jar 2>/dev/null)B link=$(/boot/bin/busybox readlink /apex/com.android.art 2>/dev/null)" > /dev/kmsg
    else
        /boot/bin/busybox ln -sfn "$_art_mp" /apex/com.android.art
    fi
fi
_i18n_mp=/apex/com.android.i18n@1
for _d in /apex/com.android.i18n@*; do
    [ -d "$_d" ] && _i18n_mp="$_d" && break
done
if [ -d /data/i18n-libs ] && [ -f /data/i18n-libs/libicu.so ]; then
    /boot/bin/busybox mkdir -p "$_i18n_mp/lib64"
    /boot/bin/busybox umount "$_i18n_mp/lib64" 2>/dev/null || true
    /boot/bin/busybox mount --bind /data/i18n-libs "$_i18n_mp/lib64" 2>/dev/null || true
    /boot/bin/busybox ln -sfn "$_i18n_mp" /apex/com.android.i18n
fi
# R159 henry-7CG: tzdata ICU @ zygote — IcuRegistration needs etc/tz/versioned/9/icu
_tzd_mp=/apex/com.android.tzdata@370499999
for _d in /apex/com.android.tzdata@*; do
    [ -d "$_d" ] && _tzd_mp="$_d" && break
done
_tzd_icu="$_tzd_mp/etc/tz/versioned/9/icu/zoneinfo64.res"
echo "<0>A16DBG: henry-7CG tzdata-pre icu=$(/boot/bin/busybox wc -c < $_tzd_icu 2>/dev/null)B initrd=$(/boot/bin/busybox wc -c < /boot/tzdata-etc/tz/versioned/9/icu/zoneinfo64.res 2>/dev/null)B" > /dev/kmsg
if [ ! -f "$_tzd_icu" ]; then
    _tzapex=/system/apex/com.android.tzdata.apex
    /boot/bin/busybox umount "$_tzd_mp/lib64" 2>/dev/null
    /boot/bin/busybox umount "$_tzd_mp" 2>/dev/null
    /boot/bin/busybox mkdir -p "$_tzd_mp"
    _tzmrc=1
    if [ -f "$_tzapex" ] && /boot/bin/busybox mount -t erofs -o ro "$_tzapex" "$_tzd_mp" 2>/dev/null; then
        _tzmrc=0
        echo "<0>A16DBG: henry-7CG tzdata-direct-erofs mrc=0" > /dev/kmsg
    else
        _tlp=""; _n=10
        while [ $_n -lt 64 ]; do
            if [ ! -f "/sys/block/loop$_n/loop/backing_file" ]; then _tlp=/dev/loop$_n; break; fi
            _n=$((_n + 1))
        done
        if [ -n "$_tlp" ] && [ -f "$_tzapex" ] &&
           /boot/bin/busybox losetup -o 4096 "$_tlp" "$_tzapex" 2>/dev/null &&
           /boot/bin/busybox mount -t erofs -o ro "$_tlp" "$_tzd_mp" 2>/dev/null; then
            _tzmrc=0
            echo "<0>A16DBG: henry-7CG tzdata-remount loop=$_tlp mrc=0" > /dev/kmsg
        else
            echo "<3>A16DBG: henry-7CG tzdata-remount fail loop=$_tlp apex=$([ -f "$_tzapex" ] && echo ok || echo missing)" > /dev/kmsg
        fi
    fi
fi
if [ ! -f "$_tzd_icu" ] && [ -f /boot/tzdata-etc/tz/versioned/9/icu/zoneinfo64.res ]; then
    for _tzf in tzdata tz_version; do
        [ -f "/boot/tzdata-etc/tz/$_tzf" ] || continue
        /boot/bin/busybox mkdir -p "$_tzd_mp/etc/tz"
        /boot/bin/busybox cat "/boot/tzdata-etc/tz/$_tzf" > "$_tzd_mp/etc/tz/$_tzf"
        /boot/bin/busybox chmod 644 "$_tzd_mp/etc/tz/$_tzf"
    done
    for _ver in 8 9; do
        _tzvd="$_tzd_mp/etc/tz/versioned/$_ver"
        /boot/bin/busybox mkdir -p "$_tzvd/icu"
        for _tzf in tzdata tz_version tzlookup.xml telephonylookup.xml; do
            [ -f "/boot/tzdata-etc/tz/versioned/$_ver/$_tzf" ] || continue
            /boot/bin/busybox cat "/boot/tzdata-etc/tz/versioned/$_ver/$_tzf" > "$_tzvd/$_tzf"
            /boot/bin/busybox chmod 644 "$_tzvd/$_tzf"
        done
        for _tzf in /boot/tzdata-etc/tz/versioned/$_ver/icu/*; do
            [ -f "$_tzf" ] || continue
            _bn=$(/boot/bin/busybox basename "$_tzf")
            /boot/bin/busybox cat "$_tzf" > "$_tzvd/icu/$_bn"
            /boot/bin/busybox chmod 644 "$_tzvd/icu/$_bn"
        done
    done
    echo "<0>A16DBG: henry-7CG tzdata-initrd-staged icu9=$(/boot/bin/busybox wc -c < $_tzd_mp/etc/tz/versioned/9/icu/zoneinfo64.res 2>/dev/null)B" > /dev/kmsg
fi
/boot/bin/busybox ln -sfn "$_tzd_mp" /apex/com.android.tzdata
_tzd_icu="/apex/com.android.tzdata/etc/tz/versioned/9/icu/zoneinfo64.res"
echo "<0>A16DBG: henry-7CG tzdata-icu bytes=$(/boot/bin/busybox wc -c < $_tzd_icu 2>/dev/null)B path=$_tzd_icu link=$(/boot/bin/busybox readlink /apex/com.android.tzdata 2>/dev/null)" > /dev/kmsg
export ANDROID_ART_ROOT=/apex/com.android.art
export ANDROID_I18N_ROOT=/apex/com.android.i18n
export ANDROID_TZDATA_ROOT=/apex/com.android.tzdata
export LD_LIBRARY_PATH=/data/art-libs:/data/statsd-libs:/data/i18n-libs:/apex/com.android.runtime/lib64/bionic:/system/lib64
AP=/data/system_bin/app_process64
[ ! -x "$AP" ] && AP=/system/bin/app_process64
echo "<0>A16DBG: henry-7CE app_process64 bytes=$(/boot/bin/busybox wc -c < "$AP" 2>/dev/null)B path=$AP" > /dev/kmsg
LINKER=/system/bin/bootstrap/linker64
[ -x /apex/com.android.runtime/bin/linker64 ] && LINKER=/apex/com.android.runtime/bin/linker64
echo "<0>A16DBG: zygote-prep exe=$AP linker=$LINKER apex_art=$(/boot/bin/busybox wc -c < /apex/com.android.art/lib64/libart.so 2>/dev/null)B statspull=$(/boot/bin/busybox wc -c < /data/art-libs/libstatspull.so 2>/dev/null)B boot.art=$(/boot/bin/busybox wc -c < /data/dalvik-cache/x86_64/boot.art 2>/dev/null)B" > /dev/kmsg
_db=/data/dalvik-cache/x86_64
_apexdc=/data/misc/apexdata/com.android.art/dalvik-cache/x86_64
# Henry 7AR/7CC: framework dir overlay (VHD has no boot.* placeholders for per-file bind)
_fw=/system/framework
_fw_ov=/data/system-framework-overlay
if ! /boot/bin/busybox mountpoint -q "$_fw" 2>/dev/null || [ ! -f "$_fw/x86_64/boot.art" ]; then
    /boot/bin/busybox mkdir -p "$_fw_ov/x86_64" "$_db"
    for _bf in boot.art boot.oat boot.vdex; do
        _src="$_db/$_bf"
        [ -f "$_src" ] || _src="$_apexdc/$_bf"
        [ -f "$_src" ] || continue
        /boot/bin/busybox cat "$_src" > "$_db/$_bf" 2>/dev/null
        /boot/bin/busybox cat "$_src" > "$_fw_ov/x86_64/$_bf"
        /boot/bin/busybox cat "$_src" > "$_fw_ov/$_bf"
        /boot/bin/busybox chmod 644 "$_fw_ov/x86_64/$_bf" "$_fw_ov/$_bf"
    done
    # R157: stage all boot-* components (mainline extensions + sub-images) for ART
    for _src in "$_apexdc"/*; do
        [ -f "$_src" ] || continue
        _bn=$(/boot/bin/busybox basename "$_src")
        case "$_bn" in
            boot*.art|boot*.oat|boot*.vdex)
                /boot/bin/busybox cat "$_src" > "$_fw_ov/x86_64/$_bn" 2>/dev/null
                /boot/bin/busybox cat "$_src" > "$_fw_ov/$_bn" 2>/dev/null
                /boot/bin/busybox chmod 644 "$_fw_ov/x86_64/$_bn" "$_fw_ov/$_bn" 2>/dev/null
                ;;
        esac
    done
    if [ -d "$_fw" ]; then
        for _sf in "$_fw"/*; do
            [ -f "$_sf" ] || continue
            _sn=$(/boot/bin/busybox basename "$_sf")
            [ -f "$_fw_ov/$_sn" ] || /boot/bin/busybox cat "$_sf" > "$_fw_ov/$_sn" 2>/dev/null
        done
        if [ -d "$_fw/x86_64" ]; then
            for _sf in "$_fw/x86_64"/*; do
                [ -f "$_sf" ] || continue
                _sn=$(/boot/bin/busybox basename "$_sf")
                [ -f "$_fw_ov/x86_64/$_sn" ] || /boot/bin/busybox cat "$_sf" > "$_fw_ov/x86_64/$_sn" 2>/dev/null
            done
        fi
        /boot/bin/busybox umount "$_fw" 2>/dev/null
        if /boot/bin/busybox mount --bind "$_fw_ov" "$_fw" 2>/dev/null; then
            echo "<0>A16DBG: henry-7CC zygote framework-overlay ok boot-art=$(/boot/bin/busybox wc -c < $_fw/x86_64/boot.art 2>/dev/null)B boot-oat=$(/boot/bin/busybox wc -c < $_fw/x86_64/boot.oat 2>/dev/null)B" > /dev/kmsg
        else
            echo "<3>A16DBG: henry-7CC zygote framework-overlay fail" > /dev/kmsg
        fi
    fi
else
    # R158: refresh boot-* from apexdata even when overlay already mounted
    for _src in "$_apexdc"/*; do
        [ -f "$_src" ] || continue
        _bn=$(/boot/bin/busybox basename "$_src")
        case "$_bn" in
            boot*.art|boot*.oat|boot*.vdex)
                /boot/bin/busybox cat "$_src" > "$_fw_ov/x86_64/$_bn" 2>/dev/null
                /boot/bin/busybox cat "$_src" > "$_fw_ov/$_bn" 2>/dev/null
                /boot/bin/busybox chmod 644 "$_fw_ov/x86_64/$_bn" "$_fw_ov/$_bn" 2>/dev/null
                ;;
        esac
    done
    echo "<0>A16DBG: henry-7CC zygote framework-overlay reuse boot-art=$(/boot/bin/busybox wc -c < $_fw/x86_64/boot.art 2>/dev/null)B ml-oat=$(/boot/bin/busybox ls $_fw/x86_64/boot-framework-*.oat 2>/dev/null | /boot/bin/busybox wc -l)" > /dev/kmsg
fi
for _f in boot.art boot.oat boot.vdex; do
    _p="$_fw/x86_64/$_f"
    if [ -f "$_p" ]; then
        echo "<0>A16DBG: henry-7AR $_f bytes=$(/boot/bin/busybox wc -c < "$_p" 2>/dev/null)" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7AR $_f missing" > /dev/kmsg
    fi
done
for _f in boot-framework.art boot-framework.oat boot-framework.vdex; do
  _dst="$_fw/$_f"
  if [ -f "$_dst" ]; then
    echo "<0>A16DBG: henry-7AR stock $_f bytes=$(/boot/bin/busybox wc -c < "$_dst" 2>/dev/null)" > /dev/kmsg
  else
    echo "<3>A16DBG: henry-7AR stock $_f missing (U+ expected)" > /dev/kmsg
  fi
done
_zml=0
for _mf in "$_fw/x86_64"/boot-framework-*.oat "$_fw"/boot-framework-*.oat; do
    [ -f "$_mf" ] || continue
    _zml=$((_zml + 1))
    echo "<0>A16DBG: henry-7CF zygote ml-oat $(/boot/bin/busybox basename "$_mf") bytes=$(/boot/bin/busybox wc -c < "$_mf" 2>/dev/null)B" > /dev/kmsg
done
echo "<0>A16DBG: henry-7CF zygote ml-oat-n=$_zml" > /dev/kmsg
# Henry 7AS: system etc overlay for boot-image.prof (apex prof via 7AV shim)
_prof=/data/boot-profiles/boot-image.prof
if [ -f "$_prof" ] && [ -d /system/etc ]; then
    _sys_etc_ov=/data/system-etc-overlay
    /boot/bin/busybox mkdir -p "$_sys_etc_ov"
    for _ef in /system/etc/*; do
        [ -f "$_ef" ] || continue
        _en=$(/boot/bin/busybox basename "$_ef")
        [ "$_en" = "boot-image.prof" ] && continue
        [ -f "$_sys_etc_ov/$_en" ] || /boot/bin/busybox cat "$_ef" > "$_sys_etc_ov/$_en" 2>/dev/null || true
    done
    /boot/bin/busybox cat "$_prof" > "$_sys_etc_ov/boot-image.prof"
    /boot/bin/busybox umount /system/etc 2>/dev/null || true
    if /boot/bin/busybox mount --bind "$_sys_etc_ov" /system/etc 2>/dev/null; then
        echo "<0>A16DBG: henry-7AS system etc overlay ok prof=$(/boot/bin/busybox wc -c < /system/etc/boot-image.prof 2>/dev/null)B" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7AS system etc overlay fail" > /dev/kmsg
    fi
else
    echo "<3>A16DBG: henry-7AS system etc skip prof=$([ -f "$_prof" ] && echo ok || echo missing)" > /dev/kmsg
fi
# Henry 7AW: readback oracles before ART init
_apex_prof=/apex/com.android.art/etc/boot-image.prof
if [ -f "$_apex_prof" ]; then
    echo "<0>A16DBG: henry-7AW apex-prof ok bytes=$(/boot/bin/busybox wc -c < "$_apex_prof" 2>/dev/null)" > /dev/kmsg
else
    echo "<3>A16DBG: henry-7AW apex-prof missing art=$(/boot/bin/busybox readlink /apex/com.android.art 2>/dev/null)" > /dev/kmsg
fi
if [ -x /data/system_bin/getprop ]; then
    echo "<0>A16DBG: henry-7AW getprop odsign.success=$(/data/system_bin/getprop odsign.verification.success 2>/dev/null) boot-image=$(/data/system_bin/getprop dalvik.vm.boot-image 2>/dev/null)" > /dev/kmsg
fi
_apexdc=/data/misc/apexdata/com.android.art/dalvik-cache/x86_64
# Henry 7BE: readback boot image chain (mainline extensions on U+)
_zbe_ml=0
for _f in "$_apexdc"/boot-framework-*.art "$_apexdc"/boot-framework-*.oat "$_apexdc"/boot-framework-*.vdex; do
    [ -f "$_f" ] || continue
    _zbe_ml=$((_zbe_ml + 1))
    echo "<0>A16DBG: henry-7BE apexdc $(/boot/bin/busybox basename "$_f") bytes=$(/boot/bin/busybox wc -c < "$_f" 2>/dev/null)" > /dev/kmsg
done
if [ "$_zbe_ml" -eq 0 ]; then
    for _f in boot-framework.art boot-framework.oat boot-framework.vdex; do
        echo "<3>A16DBG: henry-7BE apexdc $_f missing (U+ legacy)" > /dev/kmsg
    done
fi
echo "<0>A16DBG: henry-7CF zygote-be ml-artifacts=$_zbe_ml" > /dev/kmsg
echo "<0>A16DBG: henry-7AT apexdc boot.art=$(/boot/bin/busybox wc -c < $_apexdc/boot.art 2>/dev/null)B fw_boot=$(/boot/bin/busybox wc -c < $_fw/boot.art 2>/dev/null)B odsign.success=$(/data/system_bin/getprop odsign.verification.success 2>/dev/null)" > /dev/kmsg
for _f in boot.art boot.oat boot.vdex; do
    _p="$_db/$_f"
    if [ -f "$_p" ]; then
        _h=$(/boot/bin/busybox hexdump -n 8 -e '8/1 "%02x"' "$_p" 2>/dev/null)
        echo "<0>A16DBG: henry-7AQ $_f magic=$_h bytes=$(/boot/bin/busybox wc -c < "$_p" 2>/dev/null)" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7AQ $_f missing" > /dev/kmsg
    fi
done
if [ -x /system/bin/getprop ]; then
    _GP=/system/bin/getprop
elif [ -x /data/system_bin/getprop ]; then
    _GP=/data/system_bin/getprop
else
    _GP=
fi
if [ -n "$_GP" ]; then
    # R154: restore cache-info before zygote ART init (odsign wipes it)
    _ci=/data/misc/apexdata/com.android.art/dalvik-cache/cache-info.xml
    /boot/bin/busybox rm -f "$_ci"   # R169: no force_disable_uffd (conflicts with CC libart)
    _uffd=$("$_GP" ro.dalvik.vm.enable_uffd_gc 2>/dev/null)
    _fd=$("$_GP" persist.device_config.runtime_native_boot.force_disable_uffd_gc 2>/dev/null)
    _ci=/data/misc/apexdata/com.android.art/dalvik-cache/cache-info.xml
    _ci_st=missing
    [ -f "$_ci" ] && _ci_st=bytes:$(/boot/bin/busybox wc -c < "$_ci" 2>/dev/null)
    echo "<0>A16DBG: henry-7BC zygote uffd_gc=$_uffd force_disable=$_fd cache_info=$_ci_st getprop=$_GP" > /dev/kmsg
fi
# R161 henry-7AJ: libc execs /apex/com.android.runtime/bin/crash_dump64 — re-bind after apexd
_rt_mp=""
for _d in /apex/com.android.runtime@*; do
    [ -d "$_d" ] && _rt_mp="$_d" && break
done
[ -z "$_rt_mp" ] && [ -d /apex/com.android.runtime ] && _rt_mp=/apex/com.android.runtime
if [ -n "$_rt_mp" ] && [ ! -d "$_rt_mp/bin" ]; then
    _rtapex=/system/apex/com.android.runtime.apex
    /boot/bin/busybox umount "$_rt_mp" 2>/dev/null
    /boot/bin/busybox mkdir -p "$_rt_mp"
    _rtmrc=1
    if [ -f "$_rtapex" ] && /boot/bin/busybox mount -t erofs -o ro "$_rtapex" "$_rt_mp" 2>/dev/null; then
        _rtmrc=0
    else
        _tlp=""; _n=10
        while [ $_n -lt 64 ]; do
            if [ ! -f "/sys/block/loop$_n/loop/backing_file" ]; then _tlp=/dev/loop$_n; break; fi
            _n=$((_n + 1))
        done
        if [ -n "$_tlp" ] && [ -f "$_rtapex" ] &&
           /boot/bin/busybox losetup -o 4096 "$_tlp" "$_rtapex" 2>/dev/null &&
           /boot/bin/busybox mount -t erofs -o ro "$_tlp" "$_rt_mp" 2>/dev/null; then
            _rtmrc=0
        fi
    fi
    echo "<0>A16DBG: henry-7AJ zygote runtime-remount mrc=$_rtmrc bin=$([ -d "$_rt_mp/bin" ] && echo ok || echo missing)" > /dev/kmsg
fi
if [ -n "$_rt_mp" ] && [ -d "$_rt_mp/bin" ] && [ -f /boot/bin/crash_dump64 ]; then
    /boot/bin/busybox ln -sfn "$_rt_mp" /apex/com.android.runtime
    _rt_ov=/data/runtime-bin-ov
    /boot/bin/busybox rm -rf "$_rt_ov"
    /boot/bin/busybox mkdir -p "$_rt_ov"
    for _bf in "$_rt_mp/bin"/*; do
        [ -f "$_bf" ] || continue
        _bn=$(/boot/bin/busybox basename "$_bf")
        /boot/bin/busybox cat "$_bf" > "$_rt_ov/$_bn" 2>/dev/null
        /boot/bin/busybox chmod 755 "$_rt_ov/$_bn" 2>/dev/null
    done
    /boot/bin/busybox cat /boot/bin/crash_dump64 > "$_rt_ov/crash_dump64"
    /boot/bin/busybox chmod 755 "$_rt_ov/crash_dump64"
    /boot/bin/busybox umount "$_rt_mp/bin" 2>/dev/null
    if /boot/bin/busybox mount --bind "$_rt_ov" "$_rt_mp/bin" 2>/dev/null; then
        echo "<0>A16DBG: henry-7AJ zygote apex-bin bind ok crash_dump=$(/boot/bin/busybox wc -c < /apex/com.android.runtime/bin/crash_dump64 2>/dev/null)B" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7AJ zygote apex-bin bind fail mp=$_rt_mp" > /dev/kmsg
    fi
else
    echo "<3>A16DBG: henry-7AJ zygote apex-crash_dump skip mp=$_rt_mp bin=$([ -d "$_rt_mp/bin" ] && echo ok || echo missing)" > /dev/kmsg
fi
"$LINKER" "$AP" -Xzygote /system/bin --zygote --start-system-server --socket-name=zygote "$@" 2>"$LOG"
rc=$?
if [ -s "$LOG" ]; then
    /boot/bin/busybox head -300 "$LOG" | while IFS= read -r line; do
        echo "<0>A16DBG: zygote: $line" > /dev/kmsg
    done
fi
# Henry 7AI: post-mortem logcat + tombstone oracle (SIGABRT assert text)
_dump_lines() {
    _pfx="$1"
    _file="$2"
    _n="${3:-30}"
    [ -s "$_file" ] || return 0
    /boot/bin/busybox head -"$_n" "$_file" | while IFS= read -r line; do
        echo "<0>A16DBG: henry-7AI ${_pfx}: $line" > /dev/kmsg
    done
}
_run_logcat_dump() {
    _tag="$1"
    shift
    _out=/data/zygote-logcat.tmp
    _err=/data/zygote-logcat.stderr
    /boot/bin/busybox rm -f "$_out" "$_err"
    /boot/bin/busybox sleep 1
    "$LINKER_LOG" "$LCAT" -d "$@" >"$_out" 2>"$_err" || true
    _n=$(/boot/bin/busybox wc -l < "$_out" 2>/dev/null)
    echo "<0>A16DBG: henry-7AN ${_tag} lines=${_n:-0} lcat=$LCAT linker=$LINKER_LOG" > /dev/kmsg
    [ -s "$_err" ] && _dump_lines logcat-err "$_err" 8
    [ -s "$_out" ] && _dump_lines "${_tag}" "$_out" 60
}
LCAT=/boot/bin/logcat
[ -x "$LCAT" ] || LCAT=/data/system_bin/logcat
[ -x "$LCAT" ] || LCAT=/system/bin/logcat
LINKER_LOG=/system/bin/bootstrap/linker64
[ -x "$LINKER_LOG" ] || LINKER_LOG=/apex/com.android.runtime/bin/linker64
[ -x "$LINKER_LOG" ] || LINKER_LOG=/boot/bin/linker64
if [ -x "$LCAT" ] && [ -x "$LINKER_LOG" ]; then
    export LD_LIBRARY_PATH=/apex/com.android.runtime/lib64/bionic:/data/system_lib64:/system/lib64
    _run_logcat_dump dump -b all -t 100
else
    echo "<3>A16DBG: henry-7AI skip logcat lcat=$LCAT linker=$LINKER_LOG" > /dev/kmsg
fi
# Henry 7AO: tombstone + crash_dump oracle
_ts=$(/boot/bin/busybox ls -t /data/tombstones/tombstone_* /data/tombstones/*/* 2>/dev/null | /boot/bin/busybox head -1)
if [ -n "$_ts" ] && [ -f "$_ts" ]; then
    echo "<0>A16DBG: henry-7AO tombstone=$_ts bytes=$(/boot/bin/busybox wc -c < "$_ts" 2>/dev/null)" > /dev/kmsg
    _dump_lines tombstone "$_ts" 120
    /boot/bin/busybox grep -E 'backtrace:|#[0-9]+ pc|signal [0-9]+|fault addr|Abort message' "$_ts" 2>/dev/null | while read -r line; do
        echo "<0>A16DBG: henry-7AO bt: $line" > /dev/kmsg
    done
else
    echo "<3>A16DBG: henry-7AO no-tombstone" > /dev/kmsg
fi
CDMP=/apex/com.android.runtime/bin/crash_dump64
[ -x "$CDMP" ] || CDMP=/data/system_bin/crash_dump64
[ -x "$CDMP" ] || CDMP=/system/bin/crash_dump64
echo "<0>A16DBG: henry-7AJ crash_dump path=$CDMP bytes=$(/boot/bin/busybox wc -c < $CDMP 2>/dev/null)B x=$( [ -x "$CDMP" ] && echo ok || echo missing)" > /dev/kmsg
if [ -x "$CDMP" ] && [ -x "$LINKER" ]; then
    CDLOG=/data/crash_dump_probe.stderr
    /boot/bin/busybox rm -f "$CDLOG"
    "$LINKER" "$CDMP" --help >"$CDLOG" 2>&1 || true
    if [ -s "$CDLOG" ]; then
        _dump_lines crash_dump "$CDLOG" 15
    else
        echo "<3>A16DBG: henry-7AO crash_dump probe empty" > /dev/kmsg
    fi
fi
_anr=$(/boot/bin/busybox ls -t /data/anr/traces.txt 2>/dev/null | /boot/bin/busybox head -1)
[ -n "$_anr" ] && _dump_lines anr "$_anr" 20
for _pf in /sys/fs/pstore/console-ramoops-0 /proc/last_kmsg; do
    [ -r "$_pf" ] && _dump_lines pstore "$_pf" 15 && break
done
echo "<0>A16DBG: zygote-wrapper exit rc=$rc" > /dev/kmsg
exit $rc
ZYGEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-zygote.sh
FSTAB_BODY='/dev/block/sda1 /metadata ext4 noatime,nosuid,nodev wait,formattable'
# /data on ext4 when sdb1 mounted; omit sdb1 from fstab so vold does not remount ro
for hw in ranchu goldfish baklava64 emu64x tiramisu64 unknown; do
    echo "$FSTAB_BODY" > /vendor/etc/fstab.$hw
done
# ro.hardware is often "unknown" on BS cmdline; import /vendor/etc/init/hw/init.${ro.hardware}.rc
BS_INIT_RC='# BS bringup: patched sm/hwsm from initrd (bind on /system often fails on erofs)
on early-init
    export ANDROID_BOOTLOGO 1
    export ANDROID_ROOT /system
    export ANDROID_ASSETS /system/app
    export ANDROID_DATA /data
    export ANDROID_STORAGE /storage
    export ANDROID_ART_ROOT /apex/com.android.art
    export ANDROID_I18N_ROOT /apex/com.android.i18n
    export ANDROID_TZDATA_ROOT /apex/com.android.tzdata
    export EXTERNAL_STORAGE /sdcard
    export ASEC_MOUNTPOINT /mnt/asec
    setprop keystore.module_hash.sent true
    # R121: removed keystore.boot_level=1e9 — stock init.rc progresses keystore.boot_level (30) then earlyBootEnded (henry §7R)
    setprop persist.sys.usb.config adb
    setprop sys.usb.config adb
    setprop service.adb.tcp.port 5555
    setprop ro.adb.secure 0
    # R169: removed Henry 7BA force_disable_uffd setprops — they conflict with the R168
    # consistent-CC libart (force boot.oat non-read-barrier vs CC runtime read-barrier=true).

service apexd-bootstrap /boot/bin/apexd --bootstrap
    override
    user root
    group system
    oneshot
    disabled
    capabilities SYS_ADMIN

service apexd /boot/bin/apexd
    override
    class core
    user root
    group system
    disabled
    interface aidl apexservice
    capabilities SYS_ADMIN CHOWN DAC_OVERRIDE DAC_READ_SEARCH FOWNER

service bs_apex_symlinks /vendor/bin/bs-apex-symlinks.sh
    class core
    user root
    group root
    oneshot
    disabled

service servicemanager /boot/bin/servicemanager
    override
    class core animation
    user system
    group system readproc
    critical
    file /dev/kmsg w
    onrestart setprop servicemanager.ready false
    onrestart restart --only-if-running apexd
    onrestart restart audioserver
    onrestart restart gatekeeperd
    onrestart class_restart --only-enabled main
    onrestart class_restart --only-enabled hal
    onrestart class_restart --only-enabled early_hal
    task_profiles ProcessCapacityHigh
    shutdown critical

service hwservicemanager /boot/bin/hwservicemanager
    override
    user system
    group system readproc
    critical
    onrestart setprop hwservicemanager.ready false
    onrestart class_restart --only-enabled main
    onrestart class_restart --only-enabled hal
    onrestart class_restart --only-enabled early_hal
    task_profiles ServiceCapacityLow HighPerformance
    class animation
    shutdown critical

service vendor.keymint-default /boot/bin/sh /vendor/bin/bs-keymint.sh
    override
    class early_hal
    user root
    group root

service keystore2 /vendor/bin/bs-keystore2.sh /data/misc/keystore
    override
    class early_hal
    user root
    group root readproc log
    task_profiles ProcessCapacityHigh
    rlimit memlock unlimited unlimited

service odsign /boot/bin/sh /vendor/bin/bs-odsign.sh
    override
    class core
    user root
    group root

service netd /boot/bin/sh /vendor/bin/bs-netd.sh
    override
    class main
    user root
    group root net_admin
    socket dnsproxyd stream 0660 root inet
    socket mdns stream 0660 root system
    socket fwmarkd stream 0660 root inet

service surfaceflinger /boot/bin/sh /vendor/bin/bs-surfaceflinger.sh
    override
    class core animation
    user root
    group root

service audioserver /boot/bin/sh /vendor/bin/bs-audioserver.sh
    override
    class core
    user root
    group root

service logd /boot/bin/sh /vendor/bin/bs-logd.sh
    override
    class core
    user root
    group root
    socket logd stream 0666 logd logd
    socket logdr seqpacket 0666 logd logd
    socket logdw dgram 0222 logd logd
    capabilities SYSLOG AUDIT_CONTROL

service logd-reinit /boot/bin/sh /vendor/bin/bs-logd.sh -L
    override
    class core
    user root
    group root
    oneshot

service art_boot /system/bin/true
    override
    disabled
    oneshot
    class core
    user root
    group root

service zygote /boot/bin/sh /vendor/bin/bs-zygote.sh
    override
    class main
    priority -20
    user root
    group root readproc reserved_disk
    socket zygote stream 660 root system
    socket usap_pool_primary stream 660 root system
    onrestart exec_background - system system -- /system/bin/vdc volume abort_fuse
    onrestart write /sys/power/state on
    onrestart write /sys/power/wake_lock zygote_kwl
    onrestart restart audioserver
    onrestart restart cameraserver
    onrestart restart media
    onrestart restart wificond
    task_profiles ProcessCapacityHigh MaxPerformance

service bs_bootlog /boot/bin/sh /boot/bin/bs_bootlog.sh
    user root
    group system
    disabled
    seclabel u:r:su:s0

on post-fs-data
    setprop keystore.module_hash.sent true
    # R121: removed keystore.boot_level=1e9 — stock init.rc progresses keystore.boot_level (30) then earlyBootEnded (henry §7R)
    setprop vold.post_fs_data_done 1
    setprop service.adb.tcp.port 5555
    start bs_bootlog
    start vendor.keymint-default
    start keystore2
    exec_start bs_apex_symlinks
    # R122: retrying earlyBootEnded. The stock init.rc `exec vdc keymaster earlyBootEnded`
    # runs ~0.1s after keystore2 starts — before keystore2 registers android.security.maintenance
    # (slow wrapper init) → "service specific error: 4" → boot level keys never established →
    # odsign BOOT_LEVEL_EXCEEDED. bs-earlyboot retries until maintenance is ready (blocking this
    # post-fs-data action, so class_start core / odsign wait for keys). henry §7R.
    exec - root root -- /boot/bin/sh /vendor/bin/bs-earlyboot.sh
    exec_background u:r:adbd:s0 root root -- /data/local/tmp/adbd

# R121 (henry §7R): stock init.rc runs `vdc keymaster earlyBootEnded` (un-blocked via the
# passthrough vdc wrapper) which establishes boot level keys. bs-earlyboot (above) retries it
# to handle the keystore2 maintenance registration timing.

on boot
    setprop service.adb.tcp.port 5555
    exec_start bs_apex_symlinks
    exec_background u:r:adbd:s0 root root -- /data/local/tmp/adbd

on property:apexd.status=activated
    exec_start bs_apex_symlinks'
/boot/bin/busybox mkdir -p /vendor/bin
cat > /vendor/bin/bs-apex-symlinks.sh <<'APEXEOF'
#!/boot/bin/sh
MARKER=/data/.bs_apex_symlinks_v11_done
needs_symlinks=0
for base in com.android.i18n com.android.tzdata com.android.conscrypt com.android.art com.android.runtime; do
    if [ ! -e "/apex/$base" ]; then
        needs_symlinks=1
    fi
done
if [ -f "$MARKER" ] && [ "$needs_symlinks" -eq 0 ]; then exit 0; fi
echo "<0>A16DBG: bs-apex-symlinks start (needs=$needs_symlinks)" > /dev/kmsg
if [ -d /boot/linkerconfig ]; then
    /boot/bin/busybox rm -rf /tmp/linkerconfig_bind
    /boot/bin/busybox mkdir -p /tmp/linkerconfig_bind/bootstrap /tmp/linkerconfig_bind/default \
        /tmp/linkerconfig_bind/com.android.runtime /tmp/linkerconfig_bind/com.android.art
    /boot/bin/busybox cp /boot/linkerconfig/ld.config.txt /tmp/linkerconfig_bind/ld.config.txt 2>/dev/null
    /boot/bin/busybox cp /boot/linkerconfig/ld.config.txt /tmp/linkerconfig_bind/bootstrap/ld.config.txt 2>/dev/null
    /boot/bin/busybox cp /boot/linkerconfig/ld.config.txt /tmp/linkerconfig_bind/default/ld.config.txt 2>/dev/null
    /boot/bin/busybox cp /boot/linkerconfig/com.android.runtime/ld.config.txt /tmp/linkerconfig_bind/com.android.runtime/ 2>/dev/null
    /boot/bin/busybox cp /boot/linkerconfig/com.android.art/ld.config.txt /tmp/linkerconfig_bind/com.android.art/ 2>/dev/null
    /boot/bin/busybox umount /linkerconfig 2>/dev/null || true
    /boot/bin/busybox mount --bind /tmp/linkerconfig_bind /linkerconfig 2>/dev/null && \
        echo "<0>A16DBG: linkerconfig rebound in bs-apex" > /dev/kmsg
fi
echo "<0>A16DBG: /apex=$(/boot/bin/busybox ls /apex 2>&1 | /boot/bin/busybox tr '\n' ' ')" > /dev/kmsg
find_free_loop() {
    n=10
    while [ $n -lt 64 ]; do
        if [ ! -f "/sys/block/loop$n/loop/backing_file" ]; then
            echo /dev/loop$n
            return 0
        fi
        n=$((n + 1))
    done
    /boot/bin/busybox losetup -f 2>/dev/null
}
mount_system_apex() {
    name="$1"
    ver="$2"
    mp="/apex/${name}@${ver}"
    if [ -d "$mp/bin" ] || [ -d "$mp/lib" ] || [ -d "$mp/etc" ]; then
        /boot/bin/busybox ln -sfn "$mp" "/apex/$name"
        return 0
    fi
    apexfile="/system/apex/${name}.apex"
    if [ ! -f "$apexfile" ]; then
        return 1
    fi
    /boot/bin/busybox mkdir -p "$mp"
    loopdev=$(find_free_loop)
    [ -n "$loopdev" ] || return 1
    if /boot/bin/busybox losetup -o 4096 "$loopdev" "$apexfile" 2>/dev/null &&
       /boot/bin/busybox mount -t erofs -o ro "$loopdev" "$mp" 2>/dev/null; then
        /boot/bin/busybox ln -sfn "$mp" "/apex/$name"
        echo "<0>A16DBG: remounted $name on $loopdev -> $mp" > /dev/kmsg
        return 0
    fi
    echo "<3>A16DBG: remount $name failed (loop=$loopdev)" > /dev/kmsg
    return 1
}
mount_system_apex com.android.i18n 1
mount_system_apex com.android.tzdata 370499999
mount_system_apex com.android.os.statsd 361090000
if [ ! -d /apex/com.android.runtime/bin ] && [ -f /system/apex/com.android.runtime.apex ]; then
    /boot/bin/busybox mkdir -p /apex/com.android.runtime
    loopdev=$(find_free_loop)
    if [ -n "$loopdev" ] && /boot/bin/busybox losetup -o 4096 "$loopdev" /system/apex/com.android.runtime.apex 2>/dev/null &&
       /boot/bin/busybox mount -t erofs -o ro "$loopdev" /apex/com.android.runtime 2>/dev/null; then
        echo "<0>A16DBG: remounted runtime on $loopdev" > /dev/kmsg
    fi
fi
ART_MP=/apex/com.android.art@990091000
if [ ! -f "${ART_MP}/lib64/libart.so" ] && [ -f /boot/art-payload.img ]; then
    /boot/bin/busybox mkdir -p "$ART_MP"
    loopdev=$(find_free_loop)
    if [ -n "$loopdev" ] && /boot/bin/busybox losetup "$loopdev" /boot/art-payload.img 2>/dev/null &&
       /boot/bin/busybox mount -t erofs -o ro "$loopdev" "$ART_MP" 2>/dev/null; then
        echo "<0>A16DBG: art payload remounted on $loopdev" > /dev/kmsg
    else
        echo "<3>A16DBG: art payload remount failed (loop=$loopdev)" > /dev/kmsg
    fi
fi
ART_DEC=/data/apex/decompressed/com.android.art@990091000.decompressed.apex
if [ ! -f "${ART_MP}/lib64/libart.so" ] && [ -f "$ART_DEC" ]; then
    /boot/bin/busybox mkdir -p "$ART_MP"
    mounted=0
    loopdev=""
    n=10
    while [ $n -lt 64 ]; do
        if [ ! -f "/sys/block/loop$n/loop/backing_file" ]; then
            loopdev=/dev/loop$n
            if /boot/bin/busybox losetup "$loopdev" "$ART_DEC" 2>/dev/null; then
                break
            fi
            loopdev=""
        fi
        n=$((n + 1))
    done
    if [ -z "$loopdev" ]; then
        loopdev=$(/boot/bin/busybox losetup -f 2>/dev/null)
        [ -n "$loopdev" ] && /boot/bin/busybox losetup "$loopdev" "$ART_DEC" 2>/dev/null || loopdev=""
    fi
    if [ -n "$loopdev" ] && /boot/bin/busybox mount -t erofs -o ro "$loopdev" "$ART_MP" 2>/dev/null; then
        echo "<0>A16DBG: art erofs mounted on $loopdev" > /dev/kmsg
        mounted=1
    fi
    if [ "$mounted" -eq 0 ] && /boot/bin/busybox mount -t erofs -o ro "$ART_DEC" "$ART_MP" 2>/dev/null; then
        echo "<0>A16DBG: art erofs direct mounted" > /dev/kmsg
        mounted=1
    fi
    if [ "$mounted" -eq 0 ]; then
        echo "<3>A16DBG: art erofs mount failed for $ART_DEC (loop=$loopdev)" > /dev/kmsg
    fi
fi
for d in /apex/com.android.art@* /apex/com.android.art.debug@*; do
    if [ -d "$d" ]; then
        /boot/bin/busybox ln -sfn "$d" /apex/com.android.art
        /boot/bin/busybox ln -sfn "$d" /apex/com.android.art.debug
        echo "<0>A16DBG: apex symlink art -> $d" > /dev/kmsg
        break
    fi
done
for d in /apex/com.android.conscrypt@*; do
    if [ -d "$d" ]; then
        /boot/bin/busybox ln -sfn "$d" /apex/com.android.conscrypt
        echo "<0>A16DBG: apex symlink conscrypt -> $d" > /dev/kmsg
        break
    fi
done
for d in /apex/com.android.runtime@*; do
    if [ -d "$d" ]; then
        /boot/bin/busybox ln -sfn "$d" /apex/com.android.runtime
        echo "<0>A16DBG: apex symlink runtime -> $d" > /dev/kmsg
        break
    fi
done
for d in /apex/com.android.i18n@*; do
    if [ -d "$d" ]; then
        /boot/bin/busybox ln -sfn "$d" /apex/com.android.i18n
        echo "<0>A16DBG: apex symlink i18n -> $d" > /dev/kmsg
        break
    fi
done
for d in /apex/com.android.tzdata@*; do
    if [ -d "$d" ]; then
        /boot/bin/busybox ln -sfn "$d" /apex/com.android.tzdata
        echo "<0>A16DBG: apex symlink tzdata -> $d" > /dev/kmsg
        break
    fi
done
if [ -f /apex/com.android.art/bin/app_process64 ]; then
    /boot/bin/busybox cat /apex/com.android.art/bin/app_process64 > /data/system_bin/app_process64
    /boot/bin/busybox chmod 755 /data/system_bin/app_process64
    echo "<0>A16DBG: app_process64 copied from art apex ($(/boot/bin/busybox wc -c < /data/system_bin/app_process64) bytes)" > /dev/kmsg
elif [ -f /boot/bin/app_process64 ]; then
    /boot/bin/busybox cat /boot/bin/app_process64 > /data/system_bin/app_process64
    /boot/bin/busybox chmod 755 /data/system_bin/app_process64
    echo "<0>A16DBG: app_process64 refreshed from initrd" > /dev/kmsg
elif [ -L /data/system_bin/app_process64 ]; then
    tgt=$(/boot/bin/busybox readlink /data/system_bin/app_process64)
    echo "<3>A16DBG: app_process64 still symlink $tgt" > /dev/kmsg
else
    echo "<3>A16DBG: art apex bin missing; app_process64=$(/boot/bin/busybox ls -l /data/system_bin/app_process64 2>&1)" > /dev/kmsg
fi
if [ -f /apex/com.android.art/bin/linker64 ]; then
    /boot/bin/busybox cat /apex/com.android.art/bin/linker64 > /data/system_bin/linker64
    /boot/bin/busybox chmod 755 /data/system_bin/linker64
    echo "<0>A16DBG: linker64 copied from art apex" > /dev/kmsg
elif [ -f /boot/bin/linker64 ]; then
    /boot/bin/busybox cat /boot/bin/linker64 > /data/system_bin/linker64
    /boot/bin/busybox chmod 755 /data/system_bin/linker64
    echo "<0>A16DBG: linker64 refreshed from initrd" > /dev/kmsg
fi
# Henry 7O: ART libs live in com.android.art APEX; symlink into staged /system/lib64
STAGE_LIB=/data/system_lib64
ART_LIBDIR=""
for _d in /apex/com.android.art@*/lib64 /apex/com.android.art/lib64; do
    [ -d "$_d" ] && ART_LIBDIR="$_d" && break
done
if [ -z "$ART_LIBDIR" ] && [ -L /apex/com.android.art ]; then
    _art=$(/boot/bin/busybox readlink /apex/com.android.art)
    case "$_art" in /*) ;; *) _art="/apex/$_art";; esac
    [ -d "$_art/lib64" ] && ART_LIBDIR="$_art/lib64"
fi
if [ -n "$ART_LIBDIR" ] && [ -d "$STAGE_LIB" ]; then
    art_lib_new=0
    for lib in "$ART_LIBDIR"/*.so; do
        [ -f "$lib" ] || continue
        name=$(/boot/bin/busybox basename "$lib")
        if [ ! -e "$STAGE_LIB/$name" ]; then
            /boot/bin/busybox ln -sf "$ART_LIBDIR/$name" "$STAGE_LIB/$name"
            art_lib_new=$((art_lib_new + 1))
        fi
    done
    echo "<0>A16DBG: henry-7O art lib symlinks: $art_lib_new new in $STAGE_LIB (from $ART_LIBDIR)" > /dev/kmsg
    echo "<0>A16DBG: henry-7O libnativeloader=$(/boot/bin/busybox ls -l $STAGE_LIB/libnativeloader.so 2>&1)" > /dev/kmsg
    echo "<0>A16DBG: henry-7O libart=$(/boot/bin/busybox ls -l $STAGE_LIB/libart.so 2>&1)" > /dev/kmsg
else
    echo "<3>A16DBG: henry-7O skip: ART_LIBDIR=[$ART_LIBDIR] STAGE_LIB=[$STAGE_LIB]" > /dev/kmsg
    if [ -d /boot/art-libs ] && [ -d "$STAGE_LIB" ]; then
        _art_dir=/data/art-libs
        /boot/bin/busybox mkdir -p "$_art_dir"
        art_lib_new=0
        for _af in /boot/art-libs/*.so; do
            [ -f "$_af" ] || continue
            _an=$(/boot/bin/busybox basename "$_af")
            _src=$(/boot/bin/busybox wc -c < "$_af")
            _cur=0
            [ -f "$_art_dir/$_an" ] && _cur=$(/boot/bin/busybox wc -c < "$_art_dir/$_an")
            if [ "$_cur" -ne "$_src" ]; then
                /boot/bin/busybox cat "$_af" > "$_art_dir/$_an"
                /boot/bin/busybox chmod 755 "$_art_dir/$_an"
                art_lib_new=$((art_lib_new + 1))
            fi
        done
        for _af in /boot/art-libs/*.so; do
            [ -f "$_af" ] || continue
            _an=$(/boot/bin/busybox basename "$_af")
            [ -L "$STAGE_LIB/$_an" ] && /boot/bin/busybox rm -f "$STAGE_LIB/$_an"
        done
        echo "<0>A16DBG: henry-7Z bs-apex art-libs dir=$_art_dir n=$art_lib_new nativeloader=$(/boot/bin/busybox wc -c < $_art_dir/libnativeloader.so 2>/dev/null)B" > /dev/kmsg
    fi
fi
# Henry 7O-statsd: rm stale cat copies; rely on apex LD path
if [ -d "$STAGE_LIB" ]; then
    /boot/bin/busybox rm -f "$STAGE_LIB/libstatspull.so" "$STAGE_LIB/libstatssocket.so"
fi
for d in /apex/com.android.os.statsd@*; do
    [ -d "$d/lib64" ] && /boot/bin/busybox ln -sfn "$d" /apex/com.android.os.statsd && break
done
if [ -f /apex/com.android.os.statsd/lib64/libstatspull.so ]; then
    echo "<0>A16DBG: henry-7O-statsd apex ok in bs-apex" > /dev/kmsg
else
    echo "<3>A16DBG: henry-7O-statsd apex missing in bs-apex" > /dev/kmsg
fi
# Henry 7AB: bind staged libs onto APEX lib64 for dlopen(libart.so)
_art_mp=/apex/com.android.art@990091000
for _d in /apex/com.android.art@*; do
    [ -d "$_d" ] && _art_mp="$_d" && break
done
if [ -d /data/art-libs ] && [ -f /data/art-libs/libart.so ]; then
    for _lib in libstatspull.so libstatssocket.so; do
        [ -f /data/art-libs/$_lib ] && continue
        for _src in /data/statsd-libs/$_lib /boot/statsd-libs/$_lib; do
            [ -f "$_src" ] && /boot/bin/busybox cat "$_src" > "/data/art-libs/$_lib" && break
        done
    done
    for _lib in libbase.so libc++.so libexpat.so liblz4.so liblzma.so libunwindstack.so libdl_android.so heapprofd_client_api.so; do
        [ -f /data/art-libs/$_lib ] && continue
        for _src in /system/lib64/$_lib /data/system_lib64/$_lib; do
            [ -f "$_src" ] && /boot/bin/busybox cat "$_src" > "/data/art-libs/$_lib" && break
        done
    done
    echo "<0>A16DBG: henry-7AE bs-apex statspull=$(/boot/bin/busybox wc -c < /data/art-libs/libstatspull.so 2>/dev/null)B total=$(/boot/bin/busybox ls /data/art-libs/*.so 2>/dev/null | /boot/bin/busybox wc -l)" > /dev/kmsg
    /boot/bin/busybox mkdir -p "$_art_mp/lib64"
    /boot/bin/busybox umount "$_art_mp/lib64" 2>/dev/null || true
    /boot/bin/busybox mount --bind /data/art-libs "$_art_mp/lib64" 2>/dev/null && \
        echo "<0>A16DBG: henry-7AB bs-apex art bind ok" > /dev/kmsg || \
        echo "<3>A16DBG: henry-7AB bs-apex art bind failed" > /dev/kmsg
    /boot/bin/busybox ln -sfn "$_art_mp" /apex/com.android.art
fi
# Henry 7AV: apex art shim — /apex/com.android.art/etc/boot-image.prof (lib64 bind hides native etc @ R92)
_art_mp=/apex/com.android.art@990091000
for _d in /apex/com.android.art@*; do
    [ -d "$_d" ] && _art_mp="$_d" && break
done
_prof_src=""
for _p in /data/boot-profiles/boot-image.prof /boot/profiles/boot-image.prof; do
    [ -f "$_p" ] && _prof_src="$_p" && break
done
_etc_ok=0
if [ -f "$_art_mp/etc/boot-image.prof" ]; then
    _etc_ok=1
    echo "<0>A16DBG: henry-7AV art-etc native prof=$(/boot/bin/busybox wc -c < $_art_mp/etc/boot-image.prof 2>/dev/null)B" > /dev/kmsg
elif [ -f /apex/com.android.art/etc/boot-image.prof ]; then
    _etc_ok=1
    echo "<0>A16DBG: henry-7AV art-etc link prof=$(/boot/bin/busybox wc -c < /apex/com.android.art/etc/boot-image.prof 2>/dev/null)B" > /dev/kmsg
fi
if [ "$_etc_ok" -eq 0 ] && [ -n "$_prof_src" ] && [ -d "$_art_mp" ]; then
    _shim=/data/apex-art-shim
    /boot/bin/busybox rm -rf "$_shim"
    /boot/bin/busybox mkdir -p "$_shim/etc"
    if [ -d "$_art_mp/etc" ]; then
        for _ef in "$_art_mp/etc"/*; do
            [ -f "$_ef" ] || continue
            _en=$(/boot/bin/busybox basename "$_ef")
            /boot/bin/busybox cat "$_ef" > "$_shim/etc/$_en"
        done
    fi
    if [ ! -f "$_shim/etc/boot-image.prof" ]; then
        /boot/bin/busybox cat "$_prof_src" > "$_shim/etc/boot-image.prof"
    fi
    /boot/bin/busybox chmod 644 "$_shim/etc/boot-image.prof"
    for _sub in bin lib lib64; do
        [ -d "$_art_mp/$_sub" ] && /boot/bin/busybox ln -sf "$_art_mp/$_sub" "$_shim/$_sub"
    done
    /boot/bin/busybox mkdir -p "$_shim/javalib"
    _mp_oj=$(/boot/bin/busybox wc -c < "$_art_mp/javalib/core-oj.jar" 2>/dev/null)
    echo "<0>A16DBG: henry-7AY art_mp core-oj=${_mp_oj:-0}B" > /dev/kmsg
    _jav_src=""
    if [ -n "$_mp_oj" ] && [ "$_mp_oj" -gt 0 ] 2>/dev/null; then
        _jav_src="$_art_mp/javalib"
    elif [ -f /boot/art-javalib/core-oj.jar ]; then
        _jav_src=/boot/art-javalib
    fi
    if [ -n "$_jav_src" ]; then
        for _j in core-oj.jar core-libart.jar okhttp.jar bouncycastle.jar apache-xml.jar service-art.jar; do
            [ -f "$_jav_src/$_j" ] && /boot/bin/busybox cat "$_jav_src/$_j" > "$_shim/javalib/$_j"
        done
        echo "<0>A16DBG: henry-7AY bs-apex staged src=$_jav_src core-oj=$(/boot/bin/busybox wc -c < $_shim/javalib/core-oj.jar 2>/dev/null)B" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7AY bs-apex javalib stage failed mp=$_art_mp" > /dev/kmsg
    fi
    /boot/bin/busybox ln -sfn "$_shim" /apex/com.android.art
    echo "<0>A16DBG: henry-7AV art-shim ok prof=$(/boot/bin/busybox wc -c < $_shim/etc/boot-image.prof 2>/dev/null)B core-oj=$(/boot/bin/busybox wc -c < $_shim/javalib/core-oj.jar 2>/dev/null)B art_mp=$_art_mp" > /dev/kmsg
elif [ "$_etc_ok" -eq 0 ]; then
    echo "<3>A16DBG: henry-7AV art-shim skip prof_src=[$_prof_src] art_mp=[$_art_mp] etc=$(/boot/bin/busybox ls $_art_mp/etc 2>&1 | /boot/bin/busybox head -1)" > /dev/kmsg
fi
_i18n_mp=/apex/com.android.i18n@1
for _d in /apex/com.android.i18n@*; do
    [ -d "$_d" ] && _i18n_mp="$_d" && break
done
if [ -d /data/i18n-libs ] && [ -f /data/i18n-libs/libicu.so ]; then
    /boot/bin/busybox mkdir -p "$_i18n_mp/lib64"
    /boot/bin/busybox umount "$_i18n_mp/lib64" 2>/dev/null || true
    /boot/bin/busybox mount --bind /data/i18n-libs "$_i18n_mp/lib64" 2>/dev/null && \
        echo "<0>A16DBG: henry-7AB bs-apex i18n bind ok" > /dev/kmsg || \
        echo "<3>A16DBG: henry-7AB bs-apex i18n bind failed" > /dev/kmsg
    /boot/bin/busybox ln -sfn "$_i18n_mp" /apex/com.android.i18n
fi
all_ok=1
for base in com.android.i18n com.android.tzdata com.android.art com.android.runtime; do
    if [ ! -e "/apex/$base" ]; then
        all_ok=0
    fi
done
if [ -x /data/system_bin/getprop ]; then
    echo "<0>A16DBG: prop-readback ro.apex.updatable=$(/data/system_bin/getprop ro.apex.updatable 2>&1)" > /dev/kmsg
    echo "<0>A16DBG: prop-readback ro.vndk.version=$(/data/system_bin/getprop ro.vndk.version 2>&1)" > /dev/kmsg
fi
echo "<0>A16DBG: bs-apex-symlinks done; all_ok=$all_ok i18n=$(/boot/bin/busybox ls -ld /apex/com.android.i18n 2>&1); art=$(/boot/bin/busybox ls -ld /apex/com.android.art 2>&1)" > /dev/kmsg
[ "$all_ok" -eq 1 ] && /boot/bin/busybox touch "$MARKER"
if [ -x /data/system_bin/setprop ] && [ "$all_ok" -eq 1 ]; then
    /data/system_bin/setprop sys.bs_apex_symlinks.done 1
fi
APEXEOF
/boot/bin/busybox chmod 755 /vendor/bin/bs-apex-symlinks.sh
for hw in ranchu goldfish baklava64 emu64x tiramisu64 unknown; do
    echo "$BS_INIT_RC" > /vendor/etc/init/hw/init.$hw.rc
done
# libfstab needs androidboot.hardware in cmdline/bootconfig; stage2 injects via DT if present
if [ -d /proc/device-tree/firmware/android ]; then
    echo -n ranchu > /proc/device-tree/firmware/android/hardware 2>/dev/null || true
fi
cat > /vendor/build.prop <<'EOF'
ro.zygote=zygote64
ro.hardware=ranchu
ro.boot.hardware=ranchu
ro.product.cpu.abilist=x86_64,x86
ro.product.cpu.abilist32=x86
ro.product.cpu.abilist64=x86_64
ro.debuggable=1
ro.secure=0
ro.adb.secure=0
ro.apex.updatable=true
persist.sys.usb.config=adb
service.adb.tcp.port=5555
init.svc_debug.no_fatal.keystore2=true
EOF
# /init.environ.rc missing on BS bringup rootfs; init.rc imports it at boot
if [ -f /boot/init.environ.rc ]; then
    /boot/bin/busybox cp /boot/init.environ.rc /tmp/init.environ.rc
    /boot/bin/busybox mount --bind /tmp/init.environ.rc /init.environ.rc 2>/dev/null && \
        echo "<0>A16DBG: init.environ.rc bind ok" > /dev/kmsg || \
        echo "<3>A16DBG: init.environ.rc bind failed (vendor export fallback)" > /dev/kmsg
fi
# Pre-install linkerconfig before init runs linkerconfig (fallback copies from here)
if [ -d /boot/linkerconfig ]; then
    /boot/bin/busybox mkdir -p /linkerconfig/bootstrap /linkerconfig/default \
        /linkerconfig/com.android.runtime /linkerconfig/com.android.art
    for f in ld.config.txt; do
        [ -f "/boot/linkerconfig/$f" ] && /boot/bin/busybox cp "/boot/linkerconfig/$f" "/linkerconfig/bootstrap/$f"
        [ -f "/boot/linkerconfig/$f" ] && /boot/bin/busybox cp "/boot/linkerconfig/$f" "/linkerconfig/default/$f"
        [ -f "/boot/linkerconfig/$f" ] && /boot/bin/busybox cp "/boot/linkerconfig/$f" "/linkerconfig/$f"
    done
    for apex in com.android.runtime com.android.art; do
        [ -f "/boot/linkerconfig/$apex/ld.config.txt" ] && \
            /boot/bin/busybox cp "/boot/linkerconfig/$apex/ld.config.txt" "/linkerconfig/$apex/ld.config.txt"
    done
    /boot/bin/busybox rm -rf /tmp/linkerconfig_bind
    /boot/bin/busybox mkdir -p /tmp/linkerconfig_bind
    /boot/bin/busybox cp -a /linkerconfig/. /tmp/linkerconfig_bind/
    if /boot/bin/busybox mount --bind /tmp/linkerconfig_bind /linkerconfig 2>/dev/null; then
        echo "<0>A16DBG: linkerconfig bind ok (protect from regen)" > /dev/kmsg
    else
        echo "<3>A16DBG: linkerconfig bind failed" > /dev/kmsg
    fi
    _lc_art=$(/boot/bin/busybox grep -c '/data/art-libs' /linkerconfig/ld.config.txt 2>/dev/null || echo 0)
    _lc_i18n=$(/boot/bin/busybox grep -c '/data/i18n-libs' /linkerconfig/ld.config.txt 2>/dev/null || echo 0)
    _lc_bionic=$(/boot/bin/busybox grep -c 'runtime/\${LIB}/bionic' /linkerconfig/ld.config.txt 2>/dev/null || echo 0)
    _lc_sysb=$(/boot/bin/busybox grep -c 'system.search.paths += /apex/com.android.runtime' /linkerconfig/ld.config.txt 2>/dev/null || echo 0)
    echo "<0>A16DBG: henry-7AA ld.config art=$_lc_art i18n=$_lc_i18n bionic=$_lc_bionic sysbionic=$_lc_sysb" > /dev/kmsg
    echo "<0>A16DBG: linkerconfig preinstalled from initrd" > /dev/kmsg
fi
# loop-control only — pre-creating loop0..N blocks apexd LOOP_CONFIGURE (EBUSY)
/boot/bin/busybox mkdir -p /dev
[ -e /dev/loop-control ] || /boot/bin/busybox mknod /dev/loop-control c 10 237
# bootstrap linker64 on read-only /system (rm/ln fails on erofs/loop mount)
# R174: henry approach - ensure /system/bin/bootstrap/linker64 exists (initrd provides if system lacks)
if [ ! -d /system/bin/bootstrap ]; then
    /boot/bin/busybox mkdir -p /system/bin/bootstrap
fi
if [ ! -x /system/bin/bootstrap/linker64 ] && [ -f /boot/bin/linker64 ]; then
    /boot/bin/busybox cat /boot/bin/linker64 > /system/bin/bootstrap/linker64
    /boot/bin/busybox chmod 755 /system/bin/bootstrap/linker64
    echo "<0>A16DBG: R174 bootstrap linker64 staged from initrd" > /dev/kmsg
fi
if [ -x /system/bin/bootstrap/linker64 ]; then
  /boot/bin/busybox cp /system/bin/bootstrap/linker64 /tmp/linker64
  /boot/bin/busybox chmod 755 /tmp/linker64
  if /boot/bin/busybox mount --bind /tmp/linker64 /system/bin/linker64 2>/dev/null; then
    echo "<0>A16DBG: linker64 bind bootstrap" > /dev/kmsg
  elif /boot/bin/busybox cat /tmp/linker64 > /system/bin/linker64 2>/dev/null; then
    /boot/bin/busybox chmod 755 /system/bin/linker64
    echo "<0>A16DBG: linker64 cp bootstrap (bind failed, copy over)" > /dev/kmsg
  elif [ -x /apex/com.android.runtime/bin/linker64 ]; then
    echo "<0>A16DBG: linker64 uses runtime apex" > /dev/kmsg
  else
    echo "<3>A16DBG: linker64 bootstrap bind failed" > /dev/kmsg
  fi
fi
if [ -f /boot/etc/cgroups.json ]; then
    /boot/bin/busybox mkdir -p /etc
    /boot/bin/busybox cp /boot/etc/cgroups.json /etc/cgroups.json
fi
if [ -f /boot/etc/task_profiles.json ]; then
    /boot/bin/busybox mkdir -p /etc
    /boot/bin/busybox cp /boot/etc/task_profiles.json /etc/task_profiles.json
fi
# Vendor VINTF manifest (keymint HAL — required for keystore2 binder lookup)
/boot/bin/busybox mkdir -p /vendor/etc
cat > /vendor/etc/manifest.xml <<'EOF'
<manifest version="1.0" type="device">
    <hal format="aidl">
        <name>android.hardware.security.keymint</name>
        <version>4</version>
        <fqname>IKeyMintDevice/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.security.keymint</name>
        <version>3</version>
        <fqname>IRemotelyProvisionedComponent/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.security.sharedsecret</name>
        <fqname>ISharedSecret/default</fqname>
    </hal>
    <hal format="aidl">
        <name>android.hardware.security.secureclock</name>
        <fqname>ISecureClock/default</fqname>
    </hal>
</manifest>
EOF
/boot/bin/busybox ln -sf /vendor/etc/manifest.xml /vendor/manifest.xml 2>/dev/null || \
    /boot/bin/busybox cp /vendor/etc/manifest.xml /vendor/manifest.xml
echo "<0>A16DBG: vendor manifest.xml with keymint HAL" > /dev/kmsg
# vdc wrapper/real pair is installed earlier; do not overwrite it here.
if [ -x /data/system_bin/vdc.real ]; then
    echo "<0>A16DBG: henry-7BJ keep vdc wrapper real=$(/boot/bin/busybox wc -c < /data/system_bin/vdc.real 2>/dev/null)B" > /dev/kmsg
elif [ -f /system/bin/vdc ]; then
    /boot/bin/busybox cp /system/bin/vdc /data/system_bin/vdc 2>/dev/null && \
        /boot/bin/busybox chmod 755 /data/system_bin/vdc && \
        echo "<0>A16DBG: vdc staged to /data/system_bin/vdc" > /dev/kmsg
fi
# Patched init (second stage uses /tmp/init path in first_stage_init.cpp)
/boot/bin/busybox mount -t tmpfs tmpfs /tmp -o size=64m 2>/dev/null
/boot/bin/busybox cp /boot/init-patched /tmp/init
/boot/bin/busybox chmod 755 /tmp/init
if [ -f /boot/bin/apexd ]; then
    /boot/bin/busybox cp /boot/bin/apexd /tmp/apexd
    /boot/bin/busybox chmod 755 /tmp/apexd
    if /boot/bin/busybox mount --bind /tmp/apexd /system/bin/apexd 2>/dev/null; then
        echo "<0>A16DBG: apexd bind ok" > /dev/kmsg
    else
        echo "<3>A16DBG: apexd bind failed" > /dev/kmsg
    fi
fi
if [ -f /boot/bin/servicemanager ]; then
    /boot/bin/busybox cp /boot/bin/servicemanager /tmp/servicemanager
    /boot/bin/busybox chmod 755 /tmp/servicemanager
    if /boot/bin/busybox mount --bind /tmp/servicemanager /system/bin/servicemanager 2>/dev/null; then
        echo "<0>A16DBG: sm bind ok /system/bin/servicemanager" > /dev/kmsg
    else
        echo "<3>A16DBG: sm bind failed; using /boot/bin via vendor init override" > /dev/kmsg
    fi
fi
if [ -f /boot/bin/hwservicemanager ]; then
    /boot/bin/busybox cp /boot/bin/hwservicemanager /tmp/hwservicemanager
    /boot/bin/busybox chmod 755 /tmp/hwservicemanager
    if /boot/bin/busybox mount --bind /tmp/hwservicemanager /system/system_ext/bin/hwservicemanager 2>/dev/null; then
        echo "<0>A16DBG: hwsm bind ok" > /dev/kmsg
    else
        echo "<3>A16DBG: hwsm bind failed; using /boot/bin via vendor init override" > /dev/kmsg
    fi
fi
# Re-assert writable tmpfs only where needed — never stomp ext4 /data
for mp in /cache /metadata; do
    mount_tmpfs_mp "$mp"
done
if mountpoint -q /data; then
    /boot/bin/busybox mount -o remount,rw /data 2>/dev/null || true
    echo "<0>A16DBG: /data kept block-backed rw before init" > /dev/kmsg
elif ! mountpoint -q /data; then
    mount_tmpfs_mp /data
    echo "<3>A16DBG: /data tmpfs before init (no block dev)" > /dev/kmsg
fi
# apexd LOOP_CONFIGURE needs /dev/loopN nodes (ueventd not running yet)
n=3
while [ $n -lt 64 ]; do
    if [ ! -e /dev/loop$n ]; then
        /boot/bin/busybox mknod /dev/loop$n b 7 $n 2>/dev/null || true
    fi
    n=`expr $n + 1`
done
/boot/bin/busybox mdev -s 2>/dev/null || true
/boot/bin/busybox mkdir -p /data/misc/adb /data/misc/keystore /data/system 2>/dev/null
if [ -f /boot/adbkey.pub ]; then
    /boot/bin/busybox cp /boot/adbkey.pub /data/misc/adb/adb_keys
    /boot/bin/busybox chmod 640 /data/misc/adb/adb_keys
    echo "<0>A16DBG: adb_keys ready before init" > /dev/kmsg
fi
STAGE_BIN=/data/local/tmp
/boot/bin/busybox mkdir -p "$STAGE_BIN" 2>/dev/null
if [ -f /boot/bin/adbd ]; then
    /boot/bin/busybox cp /boot/bin/adbd "$STAGE_BIN/adbd"
    /boot/bin/busybox chmod 755 "$STAGE_BIN/adbd"
    echo "<0>A16DBG: adbd staged to $STAGE_BIN/adbd" > /dev/kmsg
fi
if [ -f /boot/bin/logcat ]; then
    /boot/bin/busybox cp /boot/bin/logcat "$STAGE_BIN/logcat"
    /boot/bin/busybox chmod 755 "$STAGE_BIN/logcat"
fi
if [ -f /boot/bin/bs_bootlog.sh ]; then
    /boot/bin/busybox cp /boot/bin/bs_bootlog.sh "$STAGE_BIN/bs_bootlog.sh"
    /boot/bin/busybox chmod 755 "$STAGE_BIN/bs_bootlog.sh"
fi
if [ -x "$STAGE_BIN/adbd" ]; then
    echo "<0>A16DBG: adbd rooted ready at $STAGE_BIN/adbd" > /dev/kmsg
else
    echo "<3>A16DBG: adbd missing" > /dev/kmsg
fi
echo "<0>A16DBG: loop devices ready" > /dev/kmsg
if [ -x /data/system_bin/getprop ]; then
    echo "<0>A16DBG: prop-readback early ro.apex.updatable=$(/data/system_bin/getprop ro.apex.updatable 2>&1)" > /dev/kmsg
    echo "<0>A16DBG: prop-readback early ro.vndk.version=$(/data/system_bin/getprop ro.vndk.version 2>&1)" > /dev/kmsg
fi
# R121 (henry §7R): stock /system/etc/init/hw/init.rc runs
#   `exec - system system -- /system/bin/vdc keymaster earlyBootEnded` (after setprop
#   keystore.boot_level 30). This ESTABLISHES MAX_BOOT_LEVEL keys via set_up_boot_level_cache,
#   which odsign needs to generate boot.art. Do NOT no-op it (earlier 7BL round did, wrongly).
echo "<0>A16DBG: henry-7BL stock init.rc earlyBootEnded left intact (R121)" > /dev/kmsg
# R173e: ensure /etc -> /system/etc so logd/other services find /etc/cgroups.json + task_profiles.json
/boot/bin/busybox ln -sf /system/etc /etc 2>/dev/null
echo "<0>A16DBG: R173e /etc -> /system/etc symlink" > /dev/kmsg
# R173j: Round30 Root.vhd lacks /system/etc/cgroups.json + task_profiles.json -> SetupCgroups fails ->
# ueventd createProcessGroup fails. Bind the fresh-system copies (from initrd) over them.
for _cfg in cgroups.json task_profiles.json; do
    if [ -f /boot/$_cfg ]; then
        /boot/bin/busybox mount --bind /boot/$_cfg /system/etc/$_cfg 2>/dev/null && \
            echo "<0>A16DBG: R173j bind /system/etc/$_cfg ($(wc -c < /boot/$_cfg)B)" > /dev/kmsg
    fi
done
# R173j: Round30 Root.vhd lacks /system/etc/cgroups.json + task_profiles.json -> SetupCgroups fails ->
# ueventd createProcessGroup fails. Bind the fresh-system copies (from initrd) over them.
for _cfg in cgroups.json task_profiles.json; do
    if [ -f /boot/$_cfg ]; then
        /boot/bin/busybox mount --bind /boot/$_cfg /system/etc/$_cfg 2>/dev/null && \
            echo "<0>A16DBG: R173j bind /system/etc/$_cfg ($(wc -c < /boot/$_cfg)B)" > /dev/kmsg
    fi
done
echo "<0>A16DBG: exec /tmp/init-patched" > /dev/kmsg
exec /tmp/init
