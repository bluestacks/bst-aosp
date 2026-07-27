#!/bin/bash
set -uo pipefail
exec >>~/p2_cont21d_await.log 2>&1
echo "await_stable_start $(date -Is)"
# Wait until g1_build_stable is gone AND a DONE line exists (avoid race on startup)
for i in $(seq 1 720); do
  if ! pgrep -f 'scripts/g1_build_stable.sh' >/dev/null 2>&1; then
    line=$(rg "A16DBG:G1: DONE rc=" ~/p2_cont21d_mdroid.log | tail -1 || true)
    if [ -n "$line" ]; then
      echo "seen: $line"
      break
    fi
  fi
  sleep 30
done
line=$(rg "A16DBG:G1: DONE rc=" ~/p2_cont21d_mdroid.log | tail -1 || true)
echo "final: $line"
rc=$(echo "$line" | sed -n 's/.*DONE rc=\([0-9]*\).*/\1/p')
if [ "$rc" = "0" ]; then
  bash ~/bst-aosp/scripts/p2_cont21_pack_fast.sh
  echo "await_pack_done $(date -Is)"
  md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
  exit 0
fi
echo "await_skip rc=${rc:-missing}"
exit 1
