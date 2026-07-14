#!/bin/bash
# R246: mount writable tmpfs on /metadata before exec /init (no BS metadata partition).
set -euo pipefail
STAGE2="${1:-$HOME/app-player/hd/guest/BootImage/stage2.sh}"
MARK='R246 metadata tmpfs rw mounted'
if grep -q "$MARK" "$STAGE2" 2>/dev/null; then
  echo "already patched: $STAGE2"
  exit 0
fi
python3 - <<'PY' "$STAGE2"
import sys
from pathlib import Path
p = Path(sys.argv[1])
text = p.read_text()
needle = 'echo "<0>A16DBG: stage2 about to exec /init'
block = r'''# R246: writable /metadata (stock post-fs mkdirs fail on ro root without metadata partition)
/boot/bin/busybox mkdir -p /metadata 2>/dev/null
if ! /boot/bin/busybox mountpoint -q /metadata 2>/dev/null; then
    /boot/bin/busybox mount -t tmpfs tmpfs /metadata -o mode=0711,size=256m 2>/dev/null || true
elif ! /boot/bin/busybox touch /metadata/.rwtest 2>/dev/null; then
    /boot/bin/busybox umount /metadata 2>/dev/null || true
    /boot/bin/busybox mount -t tmpfs tmpfs /metadata -o mode=0711,size=256m 2>/dev/null || true
fi
/boot/bin/busybox rm -f /metadata/.rwtest 2>/dev/null
/boot/bin/busybox mkdir -p /metadata/aconfig/maps /metadata/apex 2>/dev/null
echo "<0>A16DBG: R246 metadata tmpfs rw mounted" > /dev/kmsg

'''
if needle not in text:
    raise SystemExit(f"anchor not found in {p}")
p.write_text(text.replace(needle, block + needle, 1))
print(f"patched {p}")
PY
grep -n 'R246 metadata' "$STAGE2"
