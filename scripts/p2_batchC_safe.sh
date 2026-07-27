#!/bin/bash
# P2 Batch C: safe additive frameworks-base ports (no BstUtils rewrite, no pagefusion, no GRM)
set -euo pipefail
LOG=~/p2_batchC_safe.log
OUT=~/bst-aosp/patches/android-16/patches/p2-batchC
mkdir -p "$OUT"
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:batchC start $(date -Is)"

A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base

# 1) Features.java (additive, tiny)
mkdir -p "$A16/core/java/android/util"
cp -a "$A13/core/java/android/util/Features.java" "$A16/core/java/android/util/Features.java"
echo "COPIED Features.java"

# 2) Sdk23.java (additive) + allowlist
mkdir -p "$A16/core/java/com/bluestacks/internal"
cp -a "$A13/core/java/com/bluestacks/internal/Sdk23.java" "$A16/core/java/com/bluestacks/internal/Sdk23.java"
echo "COPIED Sdk23.java"
ALLOW=~/aosp16/build/soong/scripts/check_boot_jars/package_allowed_list.txt
if ! grep -q 'com\\.bluestacks\\.internal' "$ALLOW"; then
  python3 - <<'PY'
from pathlib import Path
p = Path.home()/"aosp16/build/soong/scripts/check_boot_jars/package_allowed_list.txt"
t = p.read_text()
needle = "com\\.bluestacks\\.os\\..*\n"
insert = needle + "com\\.bluestacks\\.internal\ncom\\.bluestacks\\.internal\\..*\n"
if needle not in t:
    raise SystemExit("allowlist needle missing")
p.write_text(t.replace(needle, insert, 1))
print("allowlist: inserted com.bluestacks.internal")
PY
else
  echo "allowlist already has internal"
fi

# 3) WMS: extend bstNotify + add sendOrientationToHostAsync (fail-open)
python3 - <<'PY'
from pathlib import Path
WMS = Path.home()/"aosp16/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java"
w = WMS.read_text()
if "setAppConfigDbParams(packageName" in w:
    print("WMS setAppConfig already present")
else:
    old = '''            int rval = hostCall.onActivityDisplayed(packageName, activityName, callingPackage);
            if (rval != 0) {
                Slog.w(TAG, "R259 onActivityDisplayed rval=" + rval);
            }
        } catch (Exception ex) {
            Slog.w(TAG, "R259 bstNotifyActivityDisplayed failed: " + ex);
        }
    }'''
    new = '''            int rval = hostCall.onActivityDisplayed(packageName, activityName, callingPackage);
            if (rval != 0) {
                Slog.w(TAG, "R259 onActivityDisplayed rval=" + rval);
            }

            // P2 BatchC: app-config + mouse (fail-open)
            try {
                if (mBstFilterApps != null) {
                    boolean macrosDisabled = mBstFilterApps.isMacrosDisabledApp(packageName);
                    boolean showFeedbackPopup = mBstFilterApps.showFeedbackPopup(packageName);
                    String mouseCursorStyle = mBstFilterApps.getMouseCursorStyle(packageName);
                    boolean nativeGamepad = mBstFilterApps.isEnableNativeGamePad(packageName);
                    int cfg = hostCall.setAppConfigDbParams(packageName, macrosDisabled,
                            showFeedbackPopup, mouseCursorStyle, nativeGamepad);
                    if (cfg != 0) {
                        Slog.w(TAG, "P2 setAppConfigDbParams rval=" + cfg);
                    }
                    String mouseAction = mBstFilterApps.getMouseAction(packageName, activityName);
                    String lastSentMouseAction =
                            SystemProperties.get("bst.config.last_mouse_action", "");
                    if (!mouseAction.isEmpty() || !lastSentMouseAction.isEmpty()) {
                        int mr = hostCall.onSetMouseAction(packageName, activityName, mouseAction);
                        SystemProperties.set("bst.config.last_mouse_action", mouseAction);
                        if (mr != 0) {
                            Slog.w(TAG, "P2 onSetMouseAction rval=" + mr);
                        }
                    }
                }
            } catch (Exception cfgEx) {
                Slog.w(TAG, "P2 appconfig/mouse after ActivityDisplayed: " + cfgEx);
            }
        } catch (Exception ex) {
            Slog.w(TAG, "R259 bstNotifyActivityDisplayed failed: " + ex);
        }
    }'''
    if old not in w:
        raise SystemExit("WMS bstNotify anchor missing")
    w = w.replace(old, new, 1)
    print("WMS extended bstNotifyActivityDisplayed")

if "sendOrientationToHostAsync" not in w:
    method = '''
    /**
     * Send orientation update to HOST (P2 BatchC). Fail-open.
     * @hide
     */
    public void sendOrientationToHostAsync(final int rotation) {
        try {
            BstHostCallManager hostCall = mBstHostCallManagerService;
            if (hostCall == null) {
                hostCall = (BstHostCallManager) mContext.getSystemService(Context.BST_HOST_CALL);
            }
            if (hostCall == null) {
                return;
            }
            final BstHostCallManager hc = hostCall;
            mH.post(() -> {
                try {
                    int rval = hc.onOrientationChange(rotation);
                    if (rval != 0) {
                        Slog.w(TAG, "P2 onOrientationChange rval=" + rval);
                    }
                } catch (Exception e) {
                    Slog.w(TAG, "P2 onOrientationChange failed: " + e);
                }
            });
        } catch (Exception e) {
            Slog.w(TAG, "P2 sendOrientationToHostAsync: " + e);
        }
    }
'''
    anchor = "    void bstNotifyActivityDisplayed(ActivityRecord activityRecord) {"
    if anchor not in w:
        raise SystemExit("cannot find bstNotify for method insert")
    w = w.replace(anchor, method + "\n" + anchor, 1)
    print("WMS added sendOrientationToHostAsync")

    # Call site: after default display rotation notify if a G5 hook exists
    rot_anchor = None
    for cand in [
        "        mDisplayManagerInternal.performTraversal(t);",
        "        updateRotationUnchecked(false, false);",
    ]:
        if cand in w:
            rot_anchor = cand
            break
    if rot_anchor and "sendOrientationToHostAsync(" not in w.split(rot_anchor)[0][-500:]:
        # Prefer injecting near bstNotifyActivityDisplayed callers only — safer:
        # call from bstNotify path is wrong; leave method for DisplayContent/DisplayRotation later.
        print("WMS orientation call site: method only (wire in DisplayRotation later)")
    else:
        print("WMS orientation call site: deferred")
else:
    print("WMS sendOrientation already present")

WMS.write_text(w)
print("WMS written")
PY

# 4) Verify BstHostCallManager has setAppConfigDbParams / onSetMouseAction / sendOrientation
rg -n "setAppConfigDbParams|onSetMouseAction|sendOrientation" \
  "$A16/core/java/com/bluestacks/os/BstHostCallManager.java" | head -20

# 5) Verify mBstFilterApps field exists on WMS
rg -n "mBstFilterApps|BstFilterAppsManager" \
  "$A16/services/core/java/com/android/server/wm/WindowManagerService.java" | head -15

echo "A16DBG:P2:batchC DONE $(date -Is)"
git -C "$A16" status --short | head -30
