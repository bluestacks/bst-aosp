#!/bin/bash
# Install Batch A+B artifacts into staged system without full systemimage restage
set -euo pipefail
LOG=~/p2_batchAB_stage_pack.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:batchAB stage-pack start $(date -Is)"
OUT=~/aosp16/out_nxt_Baklava64/target/product/qvirt
STAGE=~/releases/Baklava64/system

install_one() {
  local rel="$1"
  local src="$OUT/$rel"
  local dst="$STAGE/$rel"
  test -f "$src" || { echo "MISSING $src"; return 1; }
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  echo "INSTALLED $rel $(md5sum "$dst" | awk '{print $1}')"
}

install_one system/framework/services.jar
install_one system/framework/framework.jar
install_one system/bin/pagefusion || echo "pagefusion optional skip"
# baked props already present
grep -E 'ro.hardware.(gralloc|egl)' "$STAGE/build.prop" | sort -u

# Save surgical diff
mkdir -p ~/bst-aosp/patches/android-16/patches/p2-framework-rest
cd ~/aosp16/frameworks/base
git diff -- services/core/java/com/android/server/wm/WindowManagerService.java \
  services/core/java/com/android/server/wm/ActivityStarter.java \
  > ~/bst-aosp/patches/android-16/patches/p2-framework-rest/aosp16__frameworks_base__P2-batchB-surgical.diff || true
wc -l ~/bst-aosp/patches/android-16/patches/p2-framework-rest/aosp16__frameworks_base__P2-batchB-surgical.diff

bash ~/bst-aosp/scripts/p2_pack_once.sh
echo "A16DBG:P2:batchAB stage-pack DONE $(date -Is)"
