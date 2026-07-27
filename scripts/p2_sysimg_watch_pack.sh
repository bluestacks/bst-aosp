#!/bin/bash
# Watch systemimage log; when done, stage+pack (Batch A/B) then optionally apply remaining
set -uo pipefail
LOG=~/p2_sysimg_watch.log
exec > >(tee -a "$LOG") 2>&1
echo "A16DBG:P2:watch start $(date -Is)"
while true; do
  if rg -q "A16DBG:P2:systemimage BatchA/B rc=" ~/p2_systemimage_batchAB.log 2>/dev/null; then
    break
  fi
  if ! pgrep -f "out_nxt_Baklava64/soong_ui --build-mode.*systemimage" >/dev/null; then
    # process died without rc line
    echo "soong gone without rc line $(date -Is)"
    tail -30 ~/p2_systemimage_batchAB.log
    break
  fi
  sleep 60
done
rc_line=$(rg -n "A16DBG:P2:systemimage BatchA/B rc=" ~/p2_systemimage_batchAB.log | tail -1 || true)
echo "DONE_LINE=$rc_line"
if echo "$rc_line" | rg -q "rc=0"; then
  echo "systemimage OK — staging"
  bash ~/bst-aosp/scripts/g1_stage_system.sh
  # re-copy launcher/gralloc safety via g1_copy if present
  if [ -f ~/bst-aosp/scripts/g1_copy_bst_apks.sh ]; then
    bash ~/bst-aosp/scripts/g1_copy_bst_apks.sh || true
  fi
  bash ~/bst-aosp/scripts/p2_pack_once.sh
  echo "A16DBG:P2:watch pack done $(date -Is)"
  md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
else
  echo "systemimage FAILED or unknown — not packing"
  exit 1
fi
