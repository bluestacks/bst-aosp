#!/bin/bash
set +u
PID=$(pgrep -f 'ckati --ninja --ninja_dir=out_nxt_Baklava64' | head -1)
echo "ckati_pid=$PID"
if [ -z "$PID" ]; then echo no_ckati; exit 0; fi
ps -o pid,etime,pcpu,pmem,rss,vsz,stat -p "$PID"
echo "=== status ==="
rg -n 'State:|VmRSS:|voluntary_ctxt|nonvoluntary' /proc/$PID/status
echo "=== wchan ==="
cat /proc/$PID/wchan; echo
echo "=== open ninja/mk ==="
ls -l /proc/$PID/fd 2>/dev/null | rg 'ninja|installs|dtimage|\.mk|\.environment' | head -20
echo "=== ninja out sizes ==="
ls -lh ~/aosp16/out_nxt_Baklava64/build-*.ninja ~/aosp16/out_nxt_Baklava64/*.ninja 2>/dev/null | head -20
stat -c '%y %s %n' ~/aosp16/out_nxt_Baklava64/build-bst_x86_64.ninja 2>/dev/null
stat -c '%y %s %n' ~/aosp16/out_nxt_Baklava64/build-bst_x86_64-package.ninja 2>/dev/null
echo "=== mem ==="
free -h | head -3
echo "=== top cpu markxu ==="
ps -u markxu -o pid,pcpu,pmem,rss,etime,comm --sort=-pcpu | head -12
echo "=== strace 3s ==="
timeout 3 strace -p "$PID" -e trace=write,read,openat,mmap,munmap,brk 2>&1 | tail -40
