#!/bin/bash
# cont.22: prep perfhint + enable transitions, then full m droid (OPENGL stable true).
set +u
exec > >(tee -a ~/p2_cont22.log) 2>&1
echo "cont22_start $(date -Is)"
bash ~/bst-aosp/scripts/p2_cont22_perfhint_prep.sh --enable-transitions
# ensure no stale markxu soong lock
if [ -e ~/aosp16/out/.lock ] && ! lsof ~/aosp16/out/.lock >/dev/null 2>&1; then
  rm -f ~/aosp16/out/.lock
fi
nohup bash ~/bst-aosp/scripts/g1_build_stable.sh </dev/null >~/p2_cont22_mdroid.log 2>&1 &
echo "BUILD_PID=$!"
# await pack on success
nohup bash -c '
  exec >>~/p2_cont22_await.log 2>&1
  echo await_start $(date -Is)
  while pgrep -f scripts/g1_build_stable.sh >/dev/null; do sleep 60; done
  sleep 5
  line=$(rg "A16DBG:G1: DONE rc=" ~/p2_cont22_mdroid.log | tail -1 || true)
  echo seen:$line
  rc=$(echo "$line" | sed -n "s/.*DONE rc=\([0-9]*\).*/\1/p")
  if [ "$rc" = "0" ]; then
    bash ~/bst-aosp/scripts/p2_cont21_pack_fast.sh
    echo await_pack_done $(date -Is)
    ls -la ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
  else
    echo await_skip rc=${rc:-missing}
    exit 1
  fi
' </dev/null >/dev/null 2>&1 &
echo "AWAIT_PID=$!"
sleep 8
head -40 ~/p2_cont22_mdroid.log
grep -n 'ENABLE_SHELL_TRANSITIONS\|power-service.example' ~/aosp16/device/bst/qvirt/bst_x86_64.mk ~/aosp16/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java | head -15
echo cont22_launched
