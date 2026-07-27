#!/bin/bash
set +u
echo "=== log tail ==="
tail -50 ~/p2_cont21d_mdroid.log
echo "=== regenerating count ==="
rg -c 'regenerating' ~/p2_cont21d_mdroid.log || true
echo "=== pstree m ==="
MP=$(pgrep -f 'bin/m droid' | head -1)
echo "m_pid=$MP"
if [ -n "$MP" ]; then
  pstree -ap "$MP" 2>/dev/null | head -40 || ps --forest -g "$(ps -o sid= -p $MP | tr -d ' ')" 2>/dev/null | head -40
  echo "=== environ OPENGL ==="
  tr '\0' '\n' < /proc/$MP/environ 2>/dev/null | rg 'OPENGL|OUT_DIR|OEM' || echo none
fi
echo "=== make_vars OPENGL ==="
rg -n 'OPENGL' ~/aosp16/out_nxt_Baklava64/soong/make_vars-bst_x86_64.mk 2>/dev/null | head -10 || echo no_make_vars
echo "=== soong.environment.used ==="
rg -n 'BUILD_EMULATOR_OPENGL' ~/aosp16/out_nxt_Baklava64/soong/soong.*environment* 2>/dev/null | head -10
ls ~/aosp16/out_nxt_Baklava64/soong/*environ* 2>/dev/null | head -10
echo "=== other markxu builds ==="
pgrep -af 'out_nxt_Baklava64|goldfish|mmm' | grep markxu | head -20
