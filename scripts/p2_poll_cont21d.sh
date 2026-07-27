#!/bin/bash
# Poll until DONE or failure; print compact status periodically.
set +u
exec >>~/p2_cont21d_poll.log 2>&1
echo "poll_start $(date -Is)"
for i in $(seq 1 120); do
  if rg -q 'A16DBG:G1: DONE rc=' ~/p2_cont21d_mdroid.log; then
    echo "poll_seen_done $(date -Is)"
    rg 'A16DBG:G1: DONE rc=' ~/p2_cont21d_mdroid.log | tail -1
    break
  fi
  if ! pgrep -f 'scripts/g1_build_stable.sh' >/dev/null 2>&1 && ! pgrep -f 'bin/m droid' >/dev/null 2>&1; then
    echo "poll_build_gone $(date -Is)"
    tail -30 ~/p2_cont21d_mdroid.log
    break
  fi
  if (( i % 6 == 0 )); then
    echo "poll_tick $(date -Is)"
    tail -2 ~/p2_cont21d_mdroid.log | tr '\n' ' ' | cut -c1-200
    echo
    ps -o etime,pcpu,pmem,rss -C ckati 2>/dev/null | head -3
    pgrep -c 'ninja' || true
    ls -la ~/aosp16/out_nxt_Baklava64/target/product/qvirt/system.img 2>/dev/null | awk '{print $5,$6,$7,$8}'
  fi
  sleep 60
done
echo "poll_end $(date -Is)"
# If await already packing, note it
tail -5 ~/p2_cont21d_await.log
