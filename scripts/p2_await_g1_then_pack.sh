#!/bin/bash
# Wait for g1_build.sh to finish, then run full pack on rc=0.
set -uo pipefail
LOG=~/p2_watch_droid_pack.log
exec >>"$LOG" 2>&1
echo "A16DBG:P2:await_g1 start $(date -Is)"

# Wait until g1_build.sh is running (brief), then until it exits.
for i in $(seq 1 60); do
  if pgrep -f "bash .*/g1_build.sh" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

while pgrep -f "bash .*/g1_build.sh" >/dev/null 2>&1; do
  sleep 20
done
sleep 5

# Prefer newest DONE across common log sinks (g1_build.sh may be redirected).
line=$(rg "A16DBG:G1: DONE rc=" ~/p2_cont20_mdroid.log ~/g1_build_droid.log ~/p2_mdroid.log 2>/dev/null | tail -1 || true)
echo "seen: $line"
rc=$(echo "$line" | sed -n 's/.*DONE rc=\([0-9]*\).*/\1/p')
if [ "$rc" = "0" ]; then
  bash ~/bst-aosp/scripts/p2_full_pack_after_droid.sh
  echo "A16DBG:P2:pack_done $(date -Is)"
  exit 0
fi
echo "A16DBG:P2:skip pack rc=${rc:-missing}"
exit 1
