#!/bin/bash
set +u
echo "restart_start $(date -Is)"
# stop cont21d build stack
pkill -f 'scripts/p2_poll_cont21d.sh' || true
pkill -f 'scripts/p2_await_stable.sh' || true
pkill -f 'scripts/g1_build_stable.sh' || true
# kill markxu soong/ckati for this OUT only
pkill -f 'out_nxt_Baklava64/soong_ui' || true
pkill -f 'ninja_dir=out_nxt_Baklava64' || true
pkill -f 'bin/m droid' || true
# kill find children left under our tree
pkill -f "find frameworks/base/core/res/res" || true
sleep 3
# leftover lock
lsof /home/clouddev/bst/workspace/markxu/aosp16/out/.lock 2>/dev/null | head -5 || echo lock_free
: > ~/p2_cont21d_mdroid.log
: > ~/p2_cont21d_await.log
nohup bash ~/bst-aosp/scripts/g1_build_stable.sh </dev/null >~/p2_cont21d_mdroid.log 2>&1 &
echo "BUILD_PID=$!"
sleep 15
nohup bash ~/bst-aosp/scripts/p2_await_stable.sh </dev/null >/dev/null 2>&1 &
echo "AWAIT_PID=$!"
nohup bash ~/bst-aosp/scripts/p2_poll_cont21d.sh </dev/null >/dev/null 2>&1 &
sleep 5
pgrep -af 'g1_build_stable|p2_await_stable|bin/m droid|ckati --ninja' | grep -v henry | head -12
echo '--- log ---'
head -40 ~/p2_cont21d_mdroid.log
echo "restart_done $(date -Is)"
