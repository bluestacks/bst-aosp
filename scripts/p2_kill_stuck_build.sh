#!/bin/bash
set -uo pipefail
echo "cleanup_start $(date -Is)"
pkill -f '/markxu/bst-aosp/scripts/g1_build.sh' || true
pkill -f '/markxu/bst-aosp/scripts/p2_cont21d_await' || true
pkill -f '/markxu/bst-aosp/scripts/g1_build_stable' || true
pkill -f '/markxu/aosp16/out_nxt_Baklava64/soong_ui' || true
pkill -f 'ninja_dir=out_nxt_Baklava64' || true
sleep 2
# force-kill known stuck PIDs if still around
kill -9 2134504 2134505 2358493 2358494 2305623 2297712 2306978 2079491 2079477 2>/dev/null || true
sleep 2
pgrep -af 'out_nxt_Baklava64|g1_build' | head -15 || echo none
lsof /home/clouddev/bst/workspace/markxu/aosp16/out/.lock 2>/dev/null | head -3 || echo lock_free
echo cleanup_done
