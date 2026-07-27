#!/bin/bash
# cont.21: DisplayRotation hand-port + safe tiny cleans + selinux enabled.c
set -euo pipefail
LOG=~/p2_cont21.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:cont21 start $(date -Is)"

A13=~/app-player/android-13
A16=~/aosp16

# --- 1) selinux enabled.c (a13 parity: is_selinux_enabled=0) ---
EN_A16=$A16/external/selinux/libselinux/src/enabled.c
if ! grep -q 'return 0;' "$EN_A16" || ! grep -A2 'is_selinux_enabled' "$EN_A16" | head -5 | grep -q 'return 0'; then
  python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/external/selinux/libselinux/src/enabled.c"
t = p.read_text()
if "return 0;\n\n\t/* init_selinuxmnt" in t or "is_selinux_enabled" in t and "return 0;" in t.split("is_selinux_enabled")[1][:80]:
    print("enabled.c already patched?")
else:
    old = """int is_selinux_enabled(void)
{
\t/* init_selinuxmnt() gets called before this function. We
 \t * will assume that if a selinux file system is mounted, then
 \t * selinux is enabled. */
#ifdef ANDROID
\treturn (selinux_mnt ? 1 : 0);
#else
\treturn (selinux_mnt && has_selinux_config);
#endif
}"""
    new = """int is_selinux_enabled(void)
{
    return 0;

\t/* init_selinuxmnt() gets called before this function. We
 \t * will assume that if a selinux file system is mounted, then
 \t * selinux is enabled. */
/*
#ifdef ANDROID
\treturn (selinux_mnt ? 1 : 0);
#else
\treturn (selinux_mnt && has_selinux_config);
#endif
*/
}"""
    if old not in t:
        # try looser match
        import re
        t2, n = re.subn(
            r"int is_selinux_enabled\(void\)\s*\{.*?^\}",
            new,
            t,
            count=1,
            flags=re.S|re.M,
        )
        if n != 1:
            raise SystemExit(f"enabled.c patch failed n={n}")
        p.write_text(t2)
    else:
        p.write_text(t.replace(old, new))
    print("patched enabled.c")
print(Path.home().joinpath("aosp16/external/selinux/libselinux/src/enabled.c").read_text().split("is_selinux_enabled")[1][:200])
PY
else
  echo "enabled.c already has early return 0"
fi

# --- 2) Safe tiny clean applies (debug/config only; skip known bad) ---
SAFE=(
  services/core/java/com/android/server/wm/ActivityTaskManagerDebugConfig.java
  services/core/java/com/android/server/wm/WindowManagerDebugConfig.java
  services/core/java/com/android/server/wm/DisplayWindowSettings.java
  services/core/java/com/android/server/wm/ActivityClientController.java
  services/core/java/com/android/server/power/ShutdownThread.java
  services/core/java/com/android/server/am/BatteryStatsService.java
)
for f in "${SAFE[@]}"; do
  (cd "$A13/frameworks/base" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/safe.patch
  if [ ! -s /tmp/safe.patch ]; then echo "empty $f"; continue; fi
  if (cd "$A16/frameworks/base" && git apply --check /tmp/safe.patch 2>/dev/null); then
    (cd "$A16/frameworks/base" && git apply /tmp/safe.patch) && echo "OK $f" || echo "FAIL apply $f"
  else
    echo "SKIP conflict $f"
  fi
done

# --- 3) DisplayRotation: try 3way then fix markers ---
DR=services/core/java/com/android/server/wm/DisplayRotation.java
cp -a "$A16/frameworks/base/$DR" /tmp/DisplayRotation.java.bak
(cd "$A13/frameworks/base" && git diff android-13.0.0_r49..HEAD -- "$DR") > /tmp/dr.patch
set +e
(cd "$A16/frameworks/base" && git apply --3way /tmp/dr.patch)
rc=$?
set -e
echo "DisplayRotation apply rc=$rc"
if grep -q '<<<<<<' "$A16/frameworks/base/$DR" 2>/dev/null; then
  echo "CONFLICT markers — attempting mechanical resolve favoring BST orientation policy"
  python3 - <<'PY'
from pathlib import Path
p = Path.home()/"aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayRotation.java"
t = p.read_text()
# Resolve conflict markers: prefer "ours" (a16) for structure, but keep BST hunks from theirs when clearly BST
# Simpler: if conflicted, restore bak and apply surgical BST edits via python from a13 diff intent
print("has markers", "<<<<<<" in t)
p.write_text(Path("/tmp/DisplayRotation.java.bak").read_text())
print("restored bak; will surgical-edit")
PY
  python3 - <<'PY'
"""Surgical DisplayRotation BST port on a16 tree."""
from pathlib import Path
import re
p = Path.home()/"aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayRotation.java"
t = p.read_text()
changed = []

def ensure_import(src, imp):
    if imp in src:
        return src
    # after other android.util imports
    m = re.search(r"(import android\.util\.[^\n]+\n)", src)
    if m:
        return src[:m.end()] + imp + "\n" + src[m.end():]
    return src

if "import android.util.Log;" not in t:
    t = ensure_import(t, "import android.util.Log;")
    changed.append("import Log")

if "BST_DEBUG_ORIENTATION" not in t:
    t = t.replace(
        'private static final String TAG = TAG_WITH_CLASS_NAME ? "DisplayRotation" : TAG_WM;',
        'private static final String TAG = TAG_WITH_CLASS_NAME ? "DisplayRotation" : TAG_WM;\n'
        '    private static final boolean BST_DEBUG_ORIENTATION = SystemProperties.getInt("bst.debug.orientation", 0) > 0 ? true : false;',
        1,
    )
    changed.append("BST_DEBUG_ORIENTATION")

# FIXED_TO_USER_ROTATION_DISABLED
t2 = t.replace(
    "private int mFixedToUserRotation = IWindowManager.FIXED_TO_USER_ROTATION_DEFAULT;",
    "private int mFixedToUserRotation = IWindowManager.FIXED_TO_USER_ROTATION_DISABLED;",
    1,
)
if t2 != t:
    changed.append("FIXED_TO_USER_ROTATION_DISABLED")
    t = t2

# setUserRotation: make public if still package/VisibleForTesting
t2 = re.sub(
    r"@VisibleForTesting\s+void setUserRotation\(",
    "public void setUserRotation(",
    t,
    count=1,
)
if t2 != t:
    changed.append("setUserRotation public")
    t = t2
t2 = re.sub(r"\n    void setUserRotation\(", "\n    public void setUserRotation(", t, count=1)
if t2 != t:
    changed.append("setUserRotation public2")
    t = t2

# sensorRotation = lastRotation (BST: ignore accelerometer)
old_sensor = re.search(
    r"int sensorRotation = mOrientationListener != null\s*\n\s*\? mOrientationListener\.getProposedRotation\(\).*?\n\s*if \(sensorRotation < 0\) \{\s*\n\s*sensorRotation = lastRotation;\s*\n\s*\}",
    t,
    flags=re.S,
)
if old_sensor:
    repl = (
        "// BST: Not using sensorRotation (no accelerometer); use lastRotation.\n"
        "        int sensorRotation = lastRotation;\n"
        "        if (BST_DEBUG_ORIENTATION)\n"
        "            Log.d(TAG, \"rotationForOrientation: mUserRotationMode  \" + mUserRotationMode + \" sensorRotation \"  + sensorRotation );"
    )
    t = t[:old_sensor.start()] + repl + t[old_sensor.end():]
    changed.append("sensorRotation=lastRotation")
else:
    print("WARN: sensorRotation pattern not found — check manually")

# configure() reverseDefaultRotation bypass — only if still has reverseDefaultRotation block
if "BST Changes: We just consider two values" not in t and "config_reverseDefaultRotation" in t:
    # Replace configure orientation assignment block carefully
    # Pattern: if (width > height) { ... reverseDefault ... } else { ... }
    pat = re.compile(
        r"(void configure\(int width, int height\) \{\n"
        r"        final Resources res = mContext\.getResources\(\);\n)"
        r"(        if \(width > height\) \{.*?\n        \} else \{.*?\n        \}\n)",
        re.S,
    )
    m = pat.search(t)
    if m:
        new_block = m.group(1) + """        // BST: only treat rotation 0/1 paths; pin portrait/landscape pairs.
        if (width > height) {
            mLandscapeRotation = Surface.ROTATION_0;
            mSeascapeRotation = Surface.ROTATION_180;
            mPortraitRotation = Surface.ROTATION_90;
            mUpsideDownRotation = Surface.ROTATION_270;
        } else {
            mPortraitRotation = Surface.ROTATION_0;
            mUpsideDownRotation = Surface.ROTATION_180;
            mLandscapeRotation = Surface.ROTATION_90;
            mSeascapeRotation = Surface.ROTATION_270;
        }
"""
        t = t[:m.start()] + new_block + t[m.end():]
        changed.append("configure pin rotations")
    else:
        print("WARN: configure block not matched")

p.write_text(t)
print("DisplayRotation surgical changes:", changed)
# ensure SystemProperties import
if "SystemProperties" in t and "import android.os.SystemProperties" not in t:
    # may use android.os.SystemProperties fully qualified — check
    if "android.os.SystemProperties" not in t and "import android.os.SystemProperties" not in Path(p).read_text():
        tt = Path(p).read_text()
        if "import android.os.UserHandle;" in tt:
            tt = tt.replace("import android.os.UserHandle;", "import android.os.UserHandle;\nimport android.os.SystemProperties;")
            Path(p).write_text(tt)
            print("added SystemProperties import")
PY
else
  echo "DisplayRotation applied without markers"
fi

# --- 4) Inventory Bst* services ---
echo "=== Bst services in a16 ==="
ls "$A16/frameworks/base/services/java/com/bluestacks/server/" 2>/dev/null | head -30 || echo "no bluestacks/server dir"
rg -n "class BstHostCallService|class BstFilterAppsService" "$A16/frameworks/base" -g "*.java" 2>/dev/null | head -10

# --- 5) FSTAB debt check: is /vdc skip present? ---
if rg -n "contains\(\"/vdc\"\)|skip.*vdc|vdc.*skip" "$A16/system/core/init/builtins.cpp" >/dev/null; then
  echo "FSTAB: vdc skip STILL PRESENT (temp_debt)"
else
  echo "FSTAB: no /vdc do_exec skip in builtins.cpp — debt may be obsolete if boot green"
fi

# --- 6) Build services + framework ---
cd "$A16"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:P2:cont21 m services framework $(date -Is)"
m services framework -j24
rc=$?
echo "A16DBG:P2:cont21 build rc=$rc $(date -Is)"
exit $rc
