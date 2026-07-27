#!/bin/bash
set +u
echo "=== m tree ==="
pstree -ap 2832834 2>/dev/null | head -40
echo "=== soong_ui ==="
pgrep -u markxu -af 'soong_ui' | head -10
echo "=== lock ==="
lsof ~/aosp16/out/.lock 2>/dev/null | head -5 || echo lock_free
ls -la ~/aosp16/out/.lock 2>/dev/null
echo "=== log mtime/size ==="
stat -c '%y %s' ~/p2_cont22_mdroid.log
echo "=== OPENGL env of m ==="
MP=$(pgrep -u markxu -f 'bin/m droid' | head -1)
tr '\0' '\n' < /proc/$MP/environ 2>/dev/null | grep -E 'OPENGL|OUT_DIR' || true
echo "=== wchan ==="
ps -o pid,etime,stat,wchan,pcpu,cmd -p $MP 2>/dev/null
pgrep -u markxu -P $MP -a | head -10
# children of soong
SU=$(pgrep -u markxu -f 'soong_ui --build-mode' | head -1)
echo "soong=$SU"
if [ -n "$SU" ]; then
  ps -o pid,etime,stat,wchan,pcpu -p $SU
  pstree -ap $SU 2>/dev/null | head -25
fi
