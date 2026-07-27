#!/bin/bash
# Replace cont22 await: wait for m droid DONE then full pack (not stale pack_fast-only).
set +u
exec >>~/p2_cont22_await.log 2>&1
echo "await_v2_start $(date -Is)"
# kill older await loops that call pack_fast only (same script name patterns)
# (this process replaces them; caller should pkill old awaits first)
while pgrep -f 'scripts/g1_build_stable.sh' >/dev/null 2>&1; do
  sleep 60
done
sleep 5
line=$(rg "A16DBG:G1: DONE rc=" ~/p2_cont22_mdroid.log | tail -1 || true)
echo "seen: $line"
rc=$(echo "$line" | sed -n 's/.*DONE rc=\([0-9]*\).*/\1/p')
if [ "$rc" = "0" ]; then
  bash ~/bst-aosp/scripts/p2_cont22_pack.sh
  echo "await_v2_pack_done $(date -Is)"
  exit 0
fi
echo "await_v2_skip rc=${rc:-missing}"
exit 1
