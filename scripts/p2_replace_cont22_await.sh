#!/bin/bash
set +u
sed -i 's/\r$//' ~/bst-aosp/scripts/p2_cont22_pack.sh ~/bst-aosp/scripts/p2_cont22_await_v2.sh
chmod +x ~/bst-aosp/scripts/p2_cont22_pack.sh ~/bst-aosp/scripts/p2_cont22_await_v2.sh
# stop old await that only runs pack_fast
pkill -f 'p2_cont22_await.log' 2>/dev/null || true
pkill -f 'p2_cont21_pack_fast.sh' 2>/dev/null || true
# don't kill build
sleep 1
nohup bash ~/bst-aosp/scripts/p2_cont22_await_v2.sh </dev/null >/dev/null 2>&1 &
echo AWAIT_V2_PID=$!
sleep 1
pgrep -af 'p2_cont22_await_v2|g1_build_stable|bin/m droid' | head -10
tail -3 ~/p2_cont22_mdroid.log
