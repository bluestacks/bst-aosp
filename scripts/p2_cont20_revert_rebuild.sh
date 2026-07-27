#!/bin/bash
# Revert cont.20 "clean applies" that broke javac; keep BstUtils + Batch C/D priors.
set -euo pipefail
LOG=~/p2_cont20_revert.log
exec > >(tee "$LOG") 2>&1
cd ~/aosp16/frameworks/base

# Cont20 newly applied — revert to HEAD (Batch D priors that were already committed in tree
# before cont20 are listed separately; LegacyPermissionManager was Batch D + double-apply).
REVERT=(
  core/jni/AndroidRuntime.cpp
  core/jni/android_os_storage_StorageManager.cpp
  core/res/AndroidManifest.xml
  media/java/android/media/AudioSystem.java
  media/java/android/media/MediaCodecInfo.java
  packages/SystemUI/res/layout/qs_panel.xml
  packages/SystemUI/res/layout/status_bar_notification_section_header.xml
  services/core/java/com/android/server/am/BatteryStatsService.java
  services/core/java/com/android/server/location/injector/SystemAppOpsHelper.java
  services/core/java/com/android/server/net/NetworkPolicyManagerService.java
  services/core/java/com/android/server/pm/Settings.java
  services/core/java/com/android/server/power/ShutdownThread.java
  services/core/java/com/android/server/wm/ActivityClientController.java
  services/core/java/com/android/server/wm/ActivityStartController.java
  services/core/java/com/android/server/wm/ActivityTaskManagerDebugConfig.java
  services/core/java/com/android/server/wm/DisplayWindowSettings.java
  services/core/java/com/android/server/wm/WindowManagerDebugConfig.java
  telephony/common/com/android/internal/telephony/TelephonyPermissions.java
  telephony/java/android/telephony/ServiceState.java
)
for f in "${REVERT[@]}"; do
  git checkout HEAD -- "$f"
  echo "reverted $f"
done

# Fix LegacyPermissionManager duplicate: keep first assignPermissionsToBstApps only
python3 - <<'PY'
from pathlib import Path
p = Path("core/java/android/permission/LegacyPermissionManager.java")
text = p.read_text()
# Count occurrences
n = text.count("assignPermissionsToBstApps")
print("assignPermissionsToBstApps count before:", n)
# Remove trailing duplicate method block (second public void assignPermissionsToBstApps)
import re
parts = list(re.finditer(
    r"\n    /\*\*[^*]*\* @hide\n     \*/\n    public void assignPermissionsToBstApps\(@NonNull String filepath\) \{.*?\n    \}\n",
    text,
    flags=re.S,
))
print("matched blocks:", len(parts))
if len(parts) >= 2:
    # remove last match
    m = parts[-1]
    text = text[:m.start()] + text[m.end():]
    p.write_text(text)
    print("removed duplicate block")
elif "assignPermissionsToBstApps" in text:
    # fallback: if two method defs without matching regex, strip from second def to end-before-last-brace
    idxs = [m.start() for m in re.finditer(r"public void assignPermissionsToBstApps", text)]
    print("def idxs", idxs)
    if len(idxs) >= 2:
        # find start of javadoc above second
        second = idxs[1]
        start = text.rfind("\n    /**", 0, second)
        if start < 0:
            start = second
        # end of method: first "\n    }\n}" after second or "\n    }\n\n"
        end = text.find("\n    }\n}", second)
        if end < 0:
            end = text.find("\n    }\n", second)
            end = end + len("\n    }\n")
        else:
            # keep final class closing
            end = end + len("\n    }\n")
        text2 = text[:start] + "\n" + text[end:]
        # ensure class still closes
        if not text2.rstrip().endswith("}"):
            text2 = text2.rstrip() + "\n}\n"
        p.write_text(text2)
        print("fallback removed second def")
print("count after:", p.read_text().count("assignPermissionsToBstApps"))
PY

echo "=== BstUtils kept ==="
wc -l core/java/android/util/BstUtils.java
head -45 core/java/android/util/BstUtils.java | tail -15

echo "=== device bst_arm64 ==="
ls ~/aosp16/device/bst/qvirt/

# Rebuild framework only
cd ~/aosp16
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:P2:cont20b m framework $(date -Is)"
m framework -j24
rc=$?
echo "A16DBG:P2:cont20b framework rc=$rc $(date -Is)"
exit $rc
