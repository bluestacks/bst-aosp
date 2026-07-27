#!/bin/bash
set +u
# Kill ONLY active md5sum of Baklava Root (not unrelated)
ps -eo pid,etime,cmd | rg 'md5sum .*Baklava64.*Root\.vhd' || true
ps -eo pid,etime,cmd | rg 'md5sum .*Baklava64.*Root\.vhd' | awk '{print $1}' | xargs -r kill -9
sleep 1
ps -eo pid,etime,cmd | rg 'md5sum .*Baklava64' || echo 'no baklava md5'
echo "=== find child ==="
pgrep -af 'find frameworks/base/core/res' | head -5
ps -o pid,etime,pcpu,state,cmd -C find 2>/dev/null | head -10
echo "=== ckati ==="
ps -o pid,etime,pcpu,state,rss -p 2422156 2>/dev/null
echo "=== swap ==="
free -h | head -3
