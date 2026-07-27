#!/bin/bash
set +u
echo "=== who owns out_nxt builds ==="
ps -eo pid,ppid,user,etime,cmd | rg 'out_nxt_Baklava64' | rg -v 'rg out_nxt' | head -30
echo "=== ninja parents ==="
for p in $(pgrep -f 'combined-android_x86_64.ninja|combined-bst_x86_64.ninja' || true); do
  echo "PID $p:"
  ps -o pid,ppid,user,etime,cmd -p $p
  ps -o pid,ppid,user,etime,cmd -p $(ps -o ppid= -p $p | tr -d ' ')
done
echo "=== our build log ==="
wc -l ~/p2_cont21d_mdroid.log
cat ~/p2_cont21d_mdroid.log | head -40
echo "=== DONE? ==="
rg 'DONE rc=|regenerating|No need to regenerate|build completed' ~/p2_cont21d_mdroid.log | tail -10
echo "=== lock ==="
lsof ~/aosp16/out/.lock 2>/dev/null | head -5 || echo lock_free
echo "=== markxu soong/m ==="
pgrep -af 'g1_build_stable|bin/m |soong_ui --build' | head -10
