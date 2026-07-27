#!/bin/bash
set +u
echo "=== procs ==="
pgrep -u markxu -af 'g1_build_stable|soong_ui|ninja -d keepdepfile' 2>/dev/null | head -15
echo "=== mdroid tail ==="
tail -15 ~/p2_cont22_mdroid.log 2>/dev/null || echo NO_LOG
echo "=== DONE ==="
rg 'DONE rc=|FAILED:|ninja: build stopped|build completed' ~/p2_cont22_mdroid.log 2>/dev/null | tail -5 || echo none
echo "=== error.log bytes ==="
wc -c ~/aosp16/out_nxt_Baklava64/error.log 2>/dev/null
N=$(pgrep -u markxu -f 'ninja -d keepdepfile.*combined-bst_x86_64' | head -1)
echo "ninja=$N"
if [ -n "$N" ]; then
  awk '/^voluntary_ctxt_switches:/{print "ctxt="$2} /^VmRSS:/{print "rss_kb="$2} /^State:/{print}' /proc/$N/status
  ps -o etime=,pcpu=,rss= -p "$N"
  echo "children=$(pgrep -P $N 2>/dev/null | wc -l)"
fi
