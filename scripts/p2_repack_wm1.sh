#!/bin/bash
# Re-pack current tree (expect WM-1 present, AM/WM-2 absent) to restore green Root.
set +u
LOG=~/p2_repack_wm1.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:repack_wm1 start $(date -Is)"
# Sanity: WM-1 yes, WM-2/AM no
rg -n 'A16DBG:P2:FW-WM ActivityStarter|A16DBG:P2:FW-WM ATM' \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/wm/ActivityTaskManagerService.java | head -5
if rg -q 'A16DBG:P2:FW-WM-2|A16DBG:P2:FW-AM' \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/am/ActiveServices.java 2>/dev/null; then
  echo "FATAL: WM-2 or AM markers still present"
  exit 3
fi
echo "markers OK"
bash ~/bst-aosp/scripts/p2_cont22_pack.sh
echo "A16DBG:P2:repack_wm1 DONE $(date -Is)"
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
# confirm services has WM-1 strings
strings ~/releases/Baklava64/system/framework/services.jar 2>/dev/null | rg 'A16DBG:P2:FW-WM' | head -5 || echo 'strings skip'
