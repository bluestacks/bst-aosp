#!/bin/bash
set +u
echo "hard_kill $(date -Is)"
# nuke markxu build stack for out_nxt_Baklava64
for pat in \
  'scripts/p2_poll_cont21d' \
  'scripts/p2_await_stable' \
  'scripts/g1_build_stable' \
  'out_nxt_Baklava64/soong_ui' \
  'ninja_dir=out_nxt_Baklava64' \
  'build/soong/bin/m droid' \
  'find frameworks/base/core/res/res'
 do
  pkill -9 -f "$pat" 2>/dev/null || true
done
# explicit PIDs if lingering
kill -9 2421169 2422155 2422156 2421162 2420448 2420733 2494493 2494509 2494872 2>/dev/null || true
sleep 5
echo "=== remaining ==="
pgrep -af 'out_nxt_Baklava64|g1_build_stable|p2_await_stable|bin/m droid' | grep -v henry | head -20 || echo none
echo "=== lock ==="
lsof /home/clouddev/bst/workspace/markxu/aosp16/out/.lock 2>/dev/null | head -5 || echo lock_free
# if lock file exists and no holder, remove stale lock
if [ -e /home/clouddev/bst/workspace/markxu/aosp16/out/.lock ]; then
  if ! lsof /home/clouddev/bst/workspace/markxu/aosp16/out/.lock >/dev/null 2>&1; then
    rm -f /home/clouddev/bst/workspace/markxu/aosp16/out/.lock
    echo removed_stale_lock
  fi
fi
sleep 2
: > ~/p2_cont21d_mdroid.log
: > ~/p2_cont21d_await.log
: > ~/p2_cont21d_poll.log
nohup bash ~/bst-aosp/scripts/g1_build_stable.sh </dev/null >~/p2_cont21d_mdroid.log 2>&1 &
echo "BUILD_PID=$!"
sleep 20
# verify new log has our start marker
if ! rg -q 'OPENGL=true stable' ~/p2_cont21d_mdroid.log; then
  echo "WARN: start marker missing; log head:"
  head -30 ~/p2_cont21d_mdroid.log
fi
nohup bash ~/bst-aosp/scripts/p2_await_stable.sh </dev/null >/dev/null 2>&1 &
echo "AWAIT_PID=$!"
nohup bash ~/bst-aosp/scripts/p2_poll_cont21d.sh </dev/null >/dev/null 2>&1 &
sleep 3
pgrep -af 'g1_build_stable|p2_await|bin/m |soong_ui' | grep markxu | head -15
echo '--- log head ---'
head -35 ~/p2_cont21d_mdroid.log
echo "hard_done $(date -Is)"
