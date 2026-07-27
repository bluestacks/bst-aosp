#!/bin/bash
set +u
echo "stop_full $(date -Is)"
pkill -9 -f 'scripts/p2_poll_cont21d' || true
pkill -9 -f 'scripts/p2_await_stable' || true
pkill -9 -f 'scripts/g1_build_stable' || true
pkill -9 -f 'scripts/p2_check_artifacts' || true
# only markxu soong for our aosp16 path
pkill -9 -u markxu -f '/markxu/aosp16/out_nxt_Baklava64/soong_ui' || true
pkill -9 -u markxu -f 'ninja_dir=out_nxt_Baklava64' || true
pkill -9 -u markxu -f '/markxu/aosp16/build/soong/bin/m ' || true
sleep 3
pgrep -u markxu -af 'soong_ui|bin/m |g1_build|ckati --ninja' | head -10 || echo markxu_build_clear
lsof /home/clouddev/bst/workspace/markxu/aosp16/out/.lock 2>/dev/null | head -3 || echo lock_free
if [ -e /home/clouddev/bst/workspace/markxu/aosp16/out/.lock ] && ! lsof /home/clouddev/bst/workspace/markxu/aosp16/out/.lock >/dev/null 2>&1; then
  rm -f /home/clouddev/bst/workspace/markxu/aosp16/out/.lock
  echo removed_stale_lock
fi
uptime
echo stop_done
