#!/bin/bash
# R250: Henry 7AA-1 chmod 644 llndk.libraries.txt + pack Root
set -eo pipefail
OD=~/releases/Baklava64
LOG=~/r250-pack-root.log
exec > >(tee "$LOG") 2>&1
echo "=== R250 llndk chmod $(date) ==="
f="$OD/system/etc/llndk.libraries.txt"
ls -la "$f"
chmod 644 "$f"
chown "$(id -u):$(id -g)" "$f" 2>/dev/null || true
ls -la "$f"
# Also ensure libgcall presence check
find "$OD/system" -name 'libgcall*' 2>/dev/null | head -10 || echo 'NO_LIBGCALL'
bash ~/bst-aosp/scripts/r247-pack-root.sh
echo R250_DONE
