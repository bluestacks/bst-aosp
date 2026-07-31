#!/bin/bash
# Launcher: start g1_pack_root in background (remote). Avoids PowerShell heredoc issues.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/g1_pack_root.sh" --check

INIT="$HOME/releases/Baklava64/system/vendor/etc/init"
BK="$HOME/releases/Baklava64/system/vendor/etc/init.disabled_by_g8"
if [ -f "$BK/android.hardware.security.keymint-service.rc" ]; then
  mv "$BK/android.hardware.security.keymint-service.rc" "$INIT/"
  echo "keymint_restored"
fi

rm -f ~/g1_pack_root.log
nohup bash "$SCRIPT_DIR/g1_pack_root.sh" </dev/null >/dev/null 2>&1 &
echo "PACK_PID=$!"
sleep 4
pgrep -af 'g1_pack_root|g1_stage_system' | head -8 || true
echo "===LOG==="
head -25 ~/g1_pack_root.log || echo "NO_LOG_YET"
