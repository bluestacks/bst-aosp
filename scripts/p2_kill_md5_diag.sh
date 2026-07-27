#!/bin/bash
set +u
echo "=== kill orphan md5sum on Root ==="
pgrep -af 'md5sum.*Root' || true
pkill -f 'md5sum.*Root\.vhd' || true
pkill -f 'md5sum /home/clouddev/bst/workspace/markxu/releases' || true
sleep 1
pgrep -af md5sum | head -5 || echo no_md5
echo "=== ckati fds ==="
PID=2422156
if [ -d /proc/$PID ]; then
  ls -l /proc/$PID/fd 2>/dev/null | head -40
  echo "=== fd3 detail ==="
  ls -l /proc/$PID/fd/3 2>/dev/null
  echo "=== children of soong_ui/m ==="
  pstree -ap 2421162 2>/dev/null | head -50
  echo "=== swap ==="
  free -h | head -3
fi
