#!/bin/bash
set -uo pipefail
exec >>~/p2_cont21d_await.log 2>&1
echo "await_start $(date -Is)"
while pgrep -f 'bash .*/g1_build.sh' >/dev/null 2>&1; do
  sleep 30
done
sleep 5
line=$(rg "A16DBG:G1: DONE rc=" ~/p2_cont21d_mdroid.log | tail -1 || true)
echo "seen: $line"
rc=$(echo "$line" | sed -n 's/.*DONE rc=\([0-9]*\).*/\1/p')
if [ "$rc" = "0" ]; then
  bash ~/bst-aosp/scripts/p2_cont21_pack_fast.sh
  echo "await_pack_done $(date -Is)"
  md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
  exit 0
fi
echo "await_skip rc=${rc:-missing}"
exit 1
