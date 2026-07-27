#!/bin/bash
set -euo pipefail
echo "A16DBG:P2:fix libc.map start $(date -Is)"
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/bionic/libc/libc.map.txt"
t = p.read_text().splitlines(True)
out = [l for l in t if "iopl;" not in l and "ioperm;" not in l]
p.write_text("".join(out))
print("removed", len(t) - len(out), "lines")
PY
FN=~/aosp16/frameworks/native
git -C "$FN" restore --source=HEAD --staged --worktree \
  cmds/dumpstate/DumpstateUtil.cpp cmds/dumpstate/dumpstate.h \
  cmds/installd/globals.cpp cmds/installd/globals.h cmds/installd/utils.cpp \
  cmds/servicemanager/ServiceManager.cpp || true
git -C "$FN" status --short | head || true
git -C ~/aosp16/bionic status --short | head
echo DONE
