#!/bin/bash
set +u
echo "=== build procs ==="
pgrep -af 'soong_ui|ninja|g1_build_stable|p2_cont22' 2>/dev/null | grep -v pgrep | head -40
echo "=== mdroid log tail ==="
tail -30 ~/p2_cont22_mdroid.log 2>/dev/null || echo NO_LOG
echo "=== error.log ==="
wc -c ~/aosp16/out_nxt_Baklava64/error.log 2>/dev/null
tail -40 ~/aosp16/out_nxt_Baklava64/error.log 2>/dev/null
echo "=== ninja status ==="
N=$(pgrep -u markxu -f 'ninja -d keepdepfile.*combined-bst_x86_64' | head -1)
echo "N=$N"
if [ -n "$N" ]; then
  # status fields are one per line; avoid awk on multi-match lines
  grep -E '^(Name|State|VmRSS|voluntary_ctxt_switches|nonvoluntary_ctxt_switches|Threads):' /proc/$N/status
  echo "children=$(pgrep -P $N 2>/dev/null | wc -l)"
  echo "tasks=$(ls /proc/$N/task 2>/dev/null | wc -l)"
  ps -o pid,etime,pcpu,rss,stat -p $N
fi
echo "=== DONE markers ==="
rg 'DONE rc=|FAILED:|ninja: build stopped|build completed|error:' ~/p2_cont22_mdroid.log 2>/dev/null | tail -20 || echo none
echo "=== await ==="
tail -20 ~/p2_cont22_await.log 2>/dev/null || true
ls -lt ~/p2_cont22*.log 2>/dev/null | head -10
echo "=== product packages power ==="
rg -n 'power-service.example|performance_hint' ~/aosp16/device/bst/qvirt/*.mk 2>/dev/null | head -10
echo "=== Transitions ==="
rg -n 'ENABLE_SHELL_TRANSITIONS' ~/aosp16/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java | head -5
