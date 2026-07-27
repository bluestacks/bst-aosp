#!/bin/bash
set +u
sed -i 's/\r$//' ~/bst-aosp/scripts/g1_build_stable.sh ~/bst-aosp/scripts/p2_await_stable.sh
chmod +x ~/bst-aosp/scripts/g1_build_stable.sh ~/bst-aosp/scripts/p2_await_stable.sh
pkill -f 'p2_await_stable' || true
pkill -f 'scripts/g1_build_stable.sh' || true
sleep 2
: > ~/p2_cont21d_mdroid.log
: > ~/p2_cont21d_await.log
nohup bash ~/bst-aosp/scripts/g1_build_stable.sh </dev/null >~/p2_cont21d_mdroid.log 2>&1 &
echo "BUILD_PID=$!"
sleep 12
nohup bash ~/bst-aosp/scripts/p2_await_stable.sh </dev/null >/dev/null 2>&1 &
echo "AWAIT_PID=$!"
sleep 2
pgrep -af 'g1_build_stable|p2_await_stable|bin/m |soong_ui' | head -15 || true
echo '--- mdroid head ---'
head -30 ~/p2_cont21d_mdroid.log
echo '--- await ---'
cat ~/p2_cont21d_await.log
