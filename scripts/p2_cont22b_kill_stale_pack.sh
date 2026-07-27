#!/bin/bash
set +u
# Kill ONLY real pack/libs scripts (not waiters that mention them in argv).
for pat in 'bash .*/p2_cont22_pack\.sh' 'bash .*/p2_cont22b_rebuild_pack\.sh' 'bash .*/g1_build_libs\.sh' 'bash .*/g1_stage_system\.sh' 'bash .*/make-baklava-system-sfs'; do
  pids=$(pgrep -u markxu -f "$pat" 2>/dev/null || true)
  for p in $pids; do
    args=$(ps -o args= -p "$p" 2>/dev/null || true)
    case "$args" in
      *'bash -c'*) continue ;;
      *while*) continue ;;
    esac
    echo "kill $p $args"
    kill "$p" 2>/dev/null || true
  done
done
sleep 2
# SIGKILL leftovers
for pat in 'bash .*/p2_cont22_pack\.sh' 'bash .*/g1_build_libs\.sh'; do
  for p in $(pgrep -u markxu -f "$pat" 2>/dev/null); do
    args=$(ps -o args= -p "$p" 2>/dev/null || true)
    case "$args" in *'bash -c'*|*while*) continue ;; esac
    echo "SIGKILL $p"; kill -9 "$p" 2>/dev/null || true
  done
done
sleep 1
echo 'remaining:'
pgrep -u markxu -af 'p2_cont22_pack|g1_build_libs|p2_cont22b' | head -15 || echo none
