#!/bin/bash
set +u
echo "=== ckati cpu ==="
ps -o pid,etime,pcpu,pmem,rss,cmd -p 2422156 2>/dev/null || ps -o pid,etime,pcpu,pmem,cmd -C ckati | head -5
echo "=== installs size ==="
ls -lh ~/aosp16/out_nxt_Baklava64/soong/installs-bst_x86_64.mk 2>/dev/null
wc -l ~/aosp16/out_nxt_Baklava64/soong/installs-bst_x86_64.mk 2>/dev/null
echo "=== log mtime/size ==="
stat -c '%y %s' ~/p2_cont21d_mdroid.log
tail -3 ~/p2_cont21d_mdroid.log
echo "=== load ==="
uptime
echo "=== strace peek (2s) ==="
timeout 2 strace -p 2422156 -e trace=openat,read,write 2>&1 | tail -20 || true
