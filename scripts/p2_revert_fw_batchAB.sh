#!/bin/bash
# Revert P2 Batch A/B frameworks-base changes that crash system_server.
# Keep: VINTF allocator-only + bootclasspath allowlist (build/soong) elsewhere.
set -euo pipefail
LOG=~/p2_revert_fw_batchAB.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:revert fw BatchA/B start $(date -Is)"
FB=~/aosp16/frameworks/base
cd "$FB"
# restore tracked modifications
git checkout -- \
  core/java/android/util/BstUtils.java \
  core/java/com/bluestacks/os/BstFilterAppsManager.java \
  core/java/com/bluestacks/os/BstHostCallCcCodes.java \
  core/java/com/bluestacks/os/BstHostCallManager.java \
  core/java/com/bluestacks/os/BstUtilsManager.java \
  services/core/java/com/android/server/wm/ActivityStarter.java \
  services/core/java/com/android/server/wm/WindowManagerService.java
# remove Batch A untracked additions
rm -rf cmds/pagefusion
rm -f core/java/android/util/Features.java
rm -rf core/java/com/bluestacks/internal
# drop allowlist entries for internal if Sdk23 gone (keep os)
ALLOW=~/aosp16/build/soong/scripts/check_boot_jars/package_allowed_list.txt
sed -i '/com\\.bluestacks\\.internal/d' "$ALLOW" || true
echo "=== status ==="
git status --short | head -30
rg -n 'bluestacks' "$ALLOW" || true
echo "A16DBG:P2:revert fw BatchA/B DONE $(date -Is)"
