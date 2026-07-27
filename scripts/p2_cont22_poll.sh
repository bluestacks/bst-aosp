#!/bin/bash
set +u
exec >>~/p2_cont22_poll.log 2>&1
echo "poll_start $(date -Is)"
for i in $(seq 1 180); do
  if rg -q 'A16DBG:G1: DONE rc=' ~/p2_cont22_mdroid.log 2>/dev/null; then
    echo "poll_done $(date -Is)"
    rg 'A16DBG:G1: DONE rc=' ~/p2_cont22_mdroid.log | tail -1
    tail -5 ~/p2_cont22_await.log
    ls -la ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
    exit 0
  fi
  if ! pgrep -f 'scripts/g1_build_stable.sh' >/dev/null && ! pgrep -f 'bin/m droid' >/dev/null; then
    echo "poll_build_gone $(date -Is)"
    tail -40 ~/p2_cont22_mdroid.log
    exit 1
  fi
  if (( i % 5 == 0 )); then
    echo "tick $(date -Is) $(tail -1 ~/p2_cont22_mdroid.log | cut -c1-120)"
    pgrep -c soong_build || true
    ls -la ~/aosp16/out_nxt_Baklava64/target/product/qvirt/system.img | awk '{print $5,$6,$7,$8}'
  fi
  sleep 60
done
echo poll_timeout
exit 1
