#!/bin/bash
set +u
bash ~/bst-aosp/scripts/p2_cont22_health.sh
sleep 90
echo "=== +90s ==="
N=$(pgrep -u markxu -f 'ninja -d keepdepfile.*combined-bst_x86_64' | head -1)
echo ninja=$N
ps -o etime,pcpu,rss,stat -p "$N" 2>/dev/null
echo children=$(pgrep -P "$N" 2>/dev/null | wc -l)
# sample child cmds
pgrep -P "$N" -a 2>/dev/null | head -8
rg -N '^\[' ~/p2_cont22_mdroid.log | tail -8
stat -c 'log_bytes=%s mtime=%y' ~/p2_cont22_mdroid.log
