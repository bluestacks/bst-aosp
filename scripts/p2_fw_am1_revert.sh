#!/bin/bash
# Revert FW-AM-1 surgical patches from tree.
set +u
python3 - <<'PY'
from pathlib import Path
import subprocess, os
base = Path.home()/'aosp16/frameworks/base'
files = [
  'services/core/java/com/android/server/am/ActivityManagerService.java',
  'services/core/java/com/android/server/am/ActiveServices.java',
]
os.chdir(base)
for f in files:
    r = subprocess.run(['git','checkout','HEAD','--',f], capture_output=True, text=True)
    print(f, 'checkout', r.returncode, r.stderr.strip() or r.stdout.strip() or 'ok')
# But HEAD may include our patches if committed? Usually uncommitted — checkout HEAD restores last commit
# Verify no FW-AM markers; keep WM-1 markers in ActivityStarter/ATM
for f in files:
    t=(base/f).read_text()
    print(f, 'FW-AM markers', 'A16DBG:P2:FW-AM' in t)
# Ensure WM-1 still present
for f in [
  'services/core/java/com/android/server/wm/ActivityStarter.java',
  'services/core/java/com/android/server/wm/ActivityTaskManagerService.java',
]:
    t=(base/f).read_text()
    print(f, 'FW-WM markers', 'A16DBG:P2:FW-WM' in t)
PY
