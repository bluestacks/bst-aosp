#!/bin/bash
set +u
echo "=== procs detail ==="
pstree -ap 2832834 2>/dev/null | head -30 || echo no_m
pgrep -u markxu -af 'ninja -j|ckati|soong_ui --build' | head -10
echo "=== last progress lines ==="
rg -N '^\[' ~/p2_cont22_mdroid.log | tail -15
echo "=== real errors (not C_INCLUDES warn) ==="
rg -n 'FAILED:|ninja: build stopped|error:|Error |fatal error|assemble_vintf|VINTF|duplicate|conflict' ~/p2_cont22_mdroid.log | rg -v 'C_INCLUDES|warning:' | tail -40
echo "=== log mtime ==="
stat -c '%y %s' ~/p2_cont22_mdroid.log
echo "=== Transitions + power pkg ==="
grep -n 'ENABLE_SHELL_TRANSITIONS' ~/aosp16/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java | head -5
grep -n 'power-service.example' ~/aosp16/device/bst/qvirt/bst_x86_64.mk
echo "=== soong env OPENGL ==="
# from m process
MP=$(pgrep -u markxu -f 'bin/m droid' | head -1)
echo mpid=$MP
ps -o etime,pcpu,stat -p $MP 2>/dev/null
