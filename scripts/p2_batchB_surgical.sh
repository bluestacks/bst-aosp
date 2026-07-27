#!/bin/bash
# Surgical Batch B/C hostcall WM hooks — no wholesale a13 overlay
set -euo pipefail
LOG=~/p2_batchB_surgical.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:batchB_surgical start $(date -Is)"
python3 << 'PY'
from pathlib import Path
import re

WMS = Path.home()/"aosp16/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java"
DC = Path.home()/"aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java"
AS = Path.home()/"aosp16/frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java"
A13_DC = Path.home()/"app-player/android-13/frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java"
A13_AS = Path.home()/"app-player/android-13/frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java"

# --- 1) Extend bstNotifyActivityDisplayed ---
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

            // P2 BatchB/C: also push app-config + mouse action (a13 bstSendTopDisplayedOnFocusChange)
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
        raise SystemExit("WMS anchor for bstNotify extend missing")
    w = w.replace(old, new, 1)
    print("WMS extended bstNotifyActivityDisplayed")

if "sendOrientationToHostAsync" not in w:
    method = '''
    /**
     * Send Orientation update to HOST (P2 BatchB/C from a13).
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
            int rval = hostCall.onOrientationChange(rotation);
            if (rval != 0) {
                Slog.i(TAG, "Failed to send Host Orientation request: " + rval);
            }
        } catch (Exception exc) {
            Slog.e(TAG, "Cannot send orientation to host: " + exc);
        }
    }
'''
    # insert before bstNotifyActivityDisplayed
    anchor = "    void bstNotifyActivityDisplayed(ActivityRecord activityRecord) {"
    if anchor not in w:
        raise SystemExit("insert anchor missing")
    w = w.replace(anchor, method + "\n" + anchor, 1)
    print("WMS added sendOrientationToHostAsync")
else:
    print("WMS sendOrientation already present")

WMS.write_text(w)

# --- 2) DisplayContent call site ---
dc = DC.read_text()
if "sendOrientationToHostAsync" in dc:
    print("DisplayContent already wired")
else:
    # find a13 context
    a13 = A13_DC.read_text()
    # look for nearby unique string
    idx = a13.find("sendOrientationToHostAsync")
    print("a13 DC context:\n", a13[idx-300:idx+200])
    # Heuristic: wire after rotation update completes — search a16 for similar spot
    # Common a13 pattern near configure / updateOrientation
    candidates = [
        "updateOrientation(",
        "onConfigurationChanged(",
        "setRotation(",
    ]
    # Safer: add at end of updateOrientation method if we find it returning
    m = re.search(r"(boolean updateOrientation\([^\)]*\)\s*\{)", dc)
    if not m:
        # try overload
        print("WARN: could not find updateOrientation; skip DC wire — escalate")
    else:
        # Find matching close of first updateOrientation method is hard; instead insert after
        # getDisplayRotation().updateOrientation(...) success paths used in a13.
        # Read a13 lines around call:
        lines=a13.splitlines()
        for i,l in enumerate(lines):
            if "sendOrientationToHostAsync" in l:
                block="\n".join(lines[max(0,i-12):i+3])
                print("A13_BLOCK:\n", block)
        # Minimal: append a package-private helper call in DisplayContent where rotation applied.
        # Search a16 for "mDisplayRotation.updateRotationUnchecked" or similar
        if "mWmService.sendOrientationToHostAsync" not in dc:
            # Insert near end of class before last closing — too risky.
            # Instead find "void updateRotationUnchecked" or rotation callback.
            needle = None
            for pat in [
                "void sendNewConfiguration()",
                "boolean updateOrientation()",
                "void onDesiredDisplayChanged()",
            ]:
                if pat.replace("()","") in dc and "sendOrientation" not in dc:
                    pass
            # Practical approach used by G5 style: after successful orientation change in
            # updateOrientation(Configuration, boolean) return path — use a13 line context string.
            # Find in a16: "return mDisplayRotation.updateOrientation("
            if "mDisplayRotation.updateOrientation" in dc and "P2:sendOrientation" not in dc:
                # Add after each? too many. Add dedicated call in sendNewConfiguration if exists.
                pass
            # Fallback: inject into WindowManagerService.updateRotationUnchecked instead
            print("DC wire deferred to WMS.updateRotationUnchecked")

# Wire via WMS.updateRotationUnchecked if present
w = WMS.read_text()
if "P2:sendOrientation after updateRotation" not in w:
    # find updateRotationUnchecked method
    m = re.search(r"void updateRotationUnchecked\(boolean alwaysSendConfiguration,\s*boolean forceRelayout\)\s*\{", w)
    if m:
        # insert call at start of method body
        insert_at = m.end()
        snippet = '\n        // P2:sendOrientation after updateRotation — notify host of current rotation\n        try {\n            sendOrientationToHostAsync(getDefaultDisplayRotation());\n        } catch (Exception e) {\n            Slog.w(TAG, "P2 sendOrientationToHostAsync: " + e);\n        }\n'
        w = w[:insert_at] + snippet + w[insert_at:]
        WMS.write_text(w)
        print("WMS updateRotationUnchecked wired")
    else:
        print("WARN: updateRotationUnchecked not found; orientation call site escalate")

# --- 3) ActivityStarter GRM ---
ast = AS.read_text()
if "isAppLaunchAllowed" in ast:
    print("ActivityStarter GRM already present")
else:
    # ensure imports / field
    if "import com.bluestacks.os.BstHostCallManager;" not in ast:
        ast = ast.replace(
            "import android.content.Context;",
            "import android.content.Context;\nimport com.bluestacks.os.BstHostCallManager;",
            1,
        )
        if "import com.bluestacks.os.BstHostCallManager;" not in ast:
            # try after package imports
            ast = re.sub(r"(package com\.android\.server\.wm;\n)",
                         r"\1\nimport com.bluestacks.os.BstHostCallManager;\n",
                         ast, count=1)
    if "mBstHostCallManagerService" not in ast:
        # add field near other private fields
        ast = re.sub(
            r"(class ActivityStarter \{)",
            r"\1\n    private BstHostCallManager mBstHostCallManagerService;",
            ast,
            count=1,
        )
    # Find launch success path similar to a13
    # Look for getPackageInfo(launchPkg
    if "getPackageInfo(launchPkg" in ast or "intent.getComponent()" in ast:
        # Insert after aInfo/userId block — find unique a16 anchor near startActivityUnchecked entry checks
        # Use a13-relative: after START_SUCCESS and intent.getComponent() != null
        anchor = None
        patterns = [
            r"if \(err == ActivityManager\.START_SUCCESS\) \{\s*\n\s*if \(intent\.getComponent\(\) != null\) \{",
            r"if \(err == ActivityManager\.START_SUCCESS && intent\.getComponent\(\) != null\) \{",
        ]
        # Simpler text search
        marker = "if (err == ActivityManager.START_SUCCESS)"
        if marker not in ast:
            print("WARN: ActivityStarter START_SUCCESS anchor missing — escalate GRM")
        else:
            # find the nested getComponent check after first START_SUCCESS
            idx = ast.find(marker)
            window = ast[idx:idx+800]
            print("AS window:\n", window[:500])
            # If a16 structure differs, insert a standalone check before executeRequest returns
            grimm = '''
                // P2 BatchB/C: GRM / isAppLaunchAllowed (from a13 ActivityStarter)
                try {
                    final String launchPkg = intent.getComponent() != null
                            ? intent.getComponent().getPackageName() : null;
                    if (launchPkg != null) {
                        boolean bstCheckGrm = (aInfo != null) ? !aInfo.applicationInfo.isSystemApp() : true;
                        if (bstCheckGrm && callingPackage != null
                                && !callingPackage.equals("com.bluestacks.BstCommandProcessor")
                                && !callingPackage.equals(launchPkg)) {
                            if (mBstHostCallManagerService == null) {
                                mBstHostCallManagerService = (BstHostCallManager)
                                        mService.mContext.getSystemService(Context.BST_HOST_CALL);
                            }
                            if (mBstHostCallManagerService != null
                                    && !mBstHostCallManagerService.isAppLaunchAllowed(launchPkg, false)) {
                                Slog.i(TAG, "P2 Show grm for pkg = " + launchPkg);
                                return err;
                            }
                        }
                    }
                } catch (Exception e) {
                    Slog.w(TAG, "P2 isAppLaunchAllowed check failed: " + e);
                }
'''
            # Insert right after START_SUCCESS opening brace
            insert_pos = ast.find(marker) + len(marker)
            # skip whitespace and {
            while insert_pos < len(ast) and ast[insert_pos] in " \t\r\n":
                insert_pos += 1
            if insert_pos < len(ast) and ast[insert_pos] == "{":
                insert_pos += 1
                ast = ast[:insert_pos] + grimm + ast[insert_pos:]
                AS.write_text(ast)
                print("ActivityStarter GRM inserted")
            else:
                print("WARN: could not insert GRM")
    else:
        print("WARN: ActivityStarter structure unexpected")

print("DONE surgical")
PY

# Layer1: compile services
set +u
cd ~/aosp16
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
echo "A16DBG:P2:batchB_surgical m services start $(date -Is)"
m services -j24
rc=$?
echo "A16DBG:P2:batchB_surgical m services rc=$rc $(date -Is)"
exit $rc
