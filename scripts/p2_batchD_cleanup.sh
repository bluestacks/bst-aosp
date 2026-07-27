#!/bin/bash
# Abort all conflicted 3way applies; keep only clean BatchC + BstUtils + pagefusion + clean OK files
set -euo pipefail
echo "A16DBG:P2:batchD cleanup start $(date -Is)"
A16=~/aosp16/frameworks/base
cd "$A16"

# List unmerged / conflicted
git status --short | head -80

# Restore ALL conflicted (U) and any with conflict markers back to HEAD,
# then re-apply ONLY known-good pieces.
# First: save BstUtils and pagefusion and BatchC WMS / Features / Sdk23
cp -a core/java/android/util/BstUtils.java /tmp/BstUtils.java.bak 2>/dev/null || true
cp -a core/java/android/util/Features.java /tmp/Features.java.bak 2>/dev/null || true
cp -a core/java/com/bluestacks/internal/Sdk23.java /tmp/Sdk23.java.bak 2>/dev/null || true
cp -a services/core/java/com/android/server/wm/WindowManagerService.java /tmp/WMS.java.bak
rm -rf /tmp/pagefusion.bak
cp -a cmds/pagefusion /tmp/pagefusion.bak 2>/dev/null || true

# Hard reset tracked files to HEAD (clears conflicts), keep untracked later
git restore --source=HEAD --staged --worktree .
git clean -fd -- core/java/android/app core/java/android/content core/java/android/os \
  core/java/android/view core/java/android/widget core/java/android/hardware \
  core/java/android/inputmethodservice core/java/android/permission \
  core/java/android/text core/java/com/android core/res data libs 2>/dev/null || true

# Also clean unmerged index
git reset --hard HEAD

# Restore good pieces
cp -a /tmp/BstUtils.java.bak core/java/android/util/BstUtils.java
cp -a /tmp/Features.java.bak core/java/android/util/Features.java
mkdir -p core/java/com/bluestacks/internal
cp -a /tmp/Sdk23.java.bak core/java/com/bluestacks/internal/Sdk23.java
cp -a /tmp/WMS.java.bak services/core/java/com/android/server/wm/WindowManagerService.java
rm -rf cmds/pagefusion
cp -a /tmp/pagefusion.bak cmds/pagefusion

# Re-apply ONLY files that applied cleanly in batchD (from log OK_ lines) — selective list
A13=~/app-player/android-13/frameworks/base
for f in \
  cmds/app_process/app_main.cpp \
  cmds/bootanimation/BootAnimationUtil.cpp \
  core/java/Android.bp \
  core/java/android/app/IActivityTaskManager.aidl \
  core/java/android/app/SystemServiceRegistry.java \
  core/java/android/content/Intent.java \
  core/java/android/content/pm/PackageParser.java \
  core/java/android/content/res/AssetManager.java \
  core/java/android/hardware/Sensor.java \
  core/java/android/hardware/input/IInputManager.aidl \
  core/java/android/permission/ILegacyPermissionManager.aidl \
  core/java/android/permission/LegacyPermissionManager.java \
  core/res/res/values/dimens.xml \
  core/res/res/values/symbols.xml \
  core/res/res/xml/config_webview_packages.xml \
  data/etc/hiddenapi-package-whitelist.xml \
  data/keyboards/Generic.kl \
  data/keyboards/Virtual.kcm \
  libs/hwui/HardwareBitmapUploader.h \
  libs/hwui/jni/android_graphics_HardwareRenderer.cpp \
  libs/hwui/renderthread/RenderThread.cpp \
  libs/hwui/renderthread/RenderThread.h
 do
  (cd "$A13" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/fw_one.patch
  if [ ! -s /tmp/fw_one.patch ]; then echo EMPTY_$f; continue; fi
  if (cd "$A16" && git apply --check /tmp/fw_one.patch 2>/tmp/e.err); then
    (cd "$A16" && git apply /tmp/fw_one.patch && echo OK_$f)
  else
    echo SKIP_$f
  fi
 done

# ensure allowlist still has internal
ALLOW=~/aosp16/build/soong/scripts/check_boot_jars/package_allowed_list.txt
grep -q 'com\\.bluestacks\\.internal' "$ALLOW" || {
  python3 - <<'PY'
from pathlib import Path
p = Path.home()/"aosp16/build/soong/scripts/check_boot_jars/package_allowed_list.txt"
t = p.read_text()
needle = "com\\.bluestacks\\.os\\..*\n"
insert = needle + "com\\.bluestacks\\.internal\ncom\\.bluestacks\\.internal\\..*\n"
p.write_text(t.replace(needle, insert, 1))
print("allowlist fixed")
PY
}

echo "=== final status ==="
git -C "$A16" status --short | head -50
# no conflict markers
if rg -l '<<<<<<<' --glob '*.java' --glob '*.xml' --glob '*.bp' --glob '*.aidl' --glob '*.cpp' --glob '*.h' . 2>/dev/null | head; then
  echo "ERROR: conflict markers remain"
  exit 1
fi
echo "NO_CONFLICT_MARKERS"
echo "A16DBG:P2:batchD cleanup DONE $(date -Is)"
