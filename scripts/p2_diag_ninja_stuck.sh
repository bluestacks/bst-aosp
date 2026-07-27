#!/bin/bash
set +u
N=$(pgrep -u markxu -f 'ninja .*out_nxt_Baklava64/.ninja_fifo' | head -1)
echo "ninja_pid=$N"
if [ -z "$N" ]; then echo NO_NINJA; pgrep -u markxu -af ninja | head -10; exit 0; fi
ps -o pid,etime,pcpu,pmem,stat,wchan,cmd -p $N
echo "=== children ==="
pgrep -P $N -a | head -20 || echo none
echo "=== strace 3s ==="
timeout 3 strace -p $N -e trace=read,write,futex,wait4,openat 2>&1 | tail -25
echo "=== fifo ==="
ls -la ~/aosp16/out_nxt_Baklava64/.ninja_fifo 2>/dev/null
echo "=== soong_ui ==="
ps -o pid,etime,stat,wchan,pcpu -p 2832841 2>/dev/null
echo "=== verbose ninja status file ==="
# soong sometimes writes to verbose log
ls -lt ~/aosp16/out_nxt_Baklava64/verbose*log ~/aosp16/out_nxt_Baklava64/soong/*.log 2>/dev/null | head -10
# check if ninja is waiting on lock
lsof -p $N 2>/dev/null | rg 'lock|fifo|ninja' | head -20
