#!/bin/bash
set +u
echo "=== poll tail ==="
tail -40 ~/p2_cont21d_poll.log
echo "=== await ==="
cat ~/p2_cont21d_await.log
echo "=== done ==="
rg 'A16DBG:G1: DONE rc=|FAILED:|ninja: build stopped|build completed successfully' ~/p2_cont21d_mdroid.log | tail -15
echo "=== procs ==="
pgrep -af 'g1_build_stable|bin/m droid|ckati --ninja|ninja -j|p2_await|p2_cont21_pack|mmm' | grep -v henry | head -20
echo "=== img ==="
ls -la ~/aosp16/out_nxt_Baklava64/target/product/qvirt/system.img
echo "=== ninja progress peek ==="
# last percentage-like lines without huge warnings
rg -N '^\[' ~/p2_cont21d_mdroid.log | tail -8
echo "=== root size/mtime (no md5) ==="
ls -la ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
