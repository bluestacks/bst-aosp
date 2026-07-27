#!/bin/bash
# Wait only — no kill, no surgical. When g1_build_stable exits, pack if DONE rc=0.
set +u
exec >>~/p2_cont22_await.log 2>&1
echo "await_wait_only_start $(date -Is)"
while pgrep -u markxu -f 'scripts/g1_build_stable.sh' >/dev/null 2>&1; do
  N=$(pgrep -u markxu -f 'ninja -d keepdepfile.*combined-bst_x86_64' | head -1)
  if [ -n "$N" ]; then
    rss=$(awk '/^VmRSS:/{print $2}' /proc/$N/status)
    ctxt=$(awk '/^voluntary_ctxt_switches:/{print $2}' /proc/$N/status)
    ch=$(pgrep -P "$N" 2>/dev/null | wc -l)
    echo "poll $(date -Is) ninja=$N rss=$rss ctxt=$ctxt children=$ch"
  else
    echo "poll $(date -Is) ninja=gone build_stable=alive"
  fi
  sleep 120
done
echo "g1_build_stable exited $(date -Is)"
sleep 3
line=$(rg "A16DBG:G1: DONE rc=" ~/p2_cont22_mdroid.log | tail -1 || true)
echo "seen: $line"
rc=$(echo "$line" | sed -n 's/.*DONE rc=\([0-9]*\).*/\1/p')
if [ "$rc" = "0" ]; then
  bash ~/bst-aosp/scripts/p2_cont22_pack.sh
  echo "await_wait_only_pack_done $(date -Is)"
  exit 0
fi
echo "await_wait_only_skip rc=${rc:-missing}"
tail -40 ~/p2_cont22_mdroid.log
exit 1
