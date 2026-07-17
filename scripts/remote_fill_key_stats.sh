#!/bin/bash
# Kill accidental full triage if started
pkill -f 'triage_focused.sh' 2>/dev/null || true
sleep 1
for proj in frameworks/base frameworks/native system/core system/sepolicy hardware/interfaces packages/apps/Launcher3 kernel device/bst/qvirt device/generic/common; do
  dir=~/app-player/android-13/$proj
  if [ ! -d "$dir" ]; then echo "WIN_MISSING $proj"; continue; fi
  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then echo "WIN_NOGIT $proj"; continue; fi
  tag=$(git -C "$dir" tag -l 'android-13.0.0_r*' 2>/dev/null | sort -t_ -k2 -V | tail -1)
  since=$(timeout 60 git -C "$dir" rev-list --count "${tag}..HEAD" 2>/dev/null || echo timeout)
  bst=$(timeout 60 git -C "$dir" rev-list --count "${tag}..HEAD" --author=bluestacks --author=BlueStacks 2>/dev/null || echo 0)
  echo "WIN $proj tag=$tag since=$since bst=$bst"
done
echo '---'
for proj in device/bst/qvirt frameworks/base frameworks/native system/core kernel; do
  dir=~/app-player-mac/android-mac/$proj
  if [ ! -d "$dir" ]; then echo "MAC_MISSING $proj"; continue; fi
  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then echo "MAC_NOGIT $proj"; continue; fi
  tag=$(git -C "$dir" tag -l 'android-13.0.0_r*' 2>/dev/null | sort -t_ -k2 -V | tail -1)
  since=$(timeout 60 git -C "$dir" rev-list --count "${tag}..HEAD" 2>/dev/null || echo timeout)
  bst=$(timeout 60 git -C "$dir" rev-list --count "${tag}..HEAD" --author=bluestacks --author=BlueStacks 2>/dev/null || echo 0)
  echo "MAC $proj tag=$tag since=$since bst=$bst"
done
# mac qvirt may not be a submodule but plain dir
if [ -d ~/app-player-mac/android-mac/device/bst/qvirt ]; then
  echo "MAC_QVIRT_DIR_EXISTS"
  find ~/app-player-mac/android-mac/device/bst/qvirt -maxdepth 1 -type f | head
fi
# win kernel location
ls -d ~/app-player/android-13/kernel ~/kernel-common-a13 ~/aosp16/kernel-a16 2>/dev/null
