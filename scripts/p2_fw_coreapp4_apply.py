#!/usr/bin/env python3
# P2-FW-CORE-APP-4: ViewRootImpl FreeFireMax key fix (ROB-16938) +
# InputDevice anti-emulator name hiding (a13->a16). App-process hooks only.
import os, sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


VRI_KEY_HOOK = """
            // A16DBG:P2:FW-CORE-APP-4 ROB-16938 FreeFireMax Space/C key release (a13)
            int keyCode = event.getKeyCode();
            int repeatCount = event.getRepeatCount();
            int keyAction = event.getAction();
            if ((keyCode == KeyEvent.KEYCODE_C || keyCode == KeyEvent.KEYCODE_SPACE)
                    && keyAction == KeyEvent.ACTION_DOWN) {
                int uid = Binder.getCallingUid();
                if (uid >= 10000) {
                    String packageName = BstUtils.getAppNameFromPid(Binder.getCallingPid());
                    if (packageName != null && packageName.equals("com.dts.freefiremax")) {
                        if (repeatCount == 0) {
                            mView.postDelayed(() -> {
                                KeyEvent eventUp = KeyEvent.changeAction(event, KeyEvent.ACTION_UP);
                                eventUp = KeyEvent.changeTimeRepeat(
                                        eventUp, eventUp.getEventTime() + 60, eventUp.getRepeatCount());
                                enqueueInputEvent(eventUp);
                            }, 60);
                        } else {
                            return FINISH_HANDLED;
                        }
                    }
                }
            }

"""

patch(
    "core/java/android/view/ViewRootImpl.java",
    [
        (
            "import android.util.AndroidRuntimeException;\n",
            "import android.util.AndroidRuntimeException;\nimport android.util.BstUtils;\n",
        ),
        (
            """        private int processKeyEvent(QueuedInputEvent q) {
            final KeyEvent event = (KeyEvent)q.mEvent;
            if (mView.dispatchKeyEventPreIme(event)) {
""",
            """        private int processKeyEvent(QueuedInputEvent q) {
            final KeyEvent event = (KeyEvent)q.mEvent;
"""
            + VRI_KEY_HOOK
            + """            if (mView.dispatchKeyEventPreIme(event)) {
""",
        ),
    ],
    "ViewRootImpl.FreeFireMax key fix",
)

INPUT_GETNAME = """
        // A16DBG:P2:FW-CORE-APP-4 hide BST/VirtualBox input device names from apps (a13)
        int pid = Binder.getCallingPid();
        String callingApp = BstUtils.getAppNameFromPid(pid);
        String modifiedDeviceName = "Synaptics";
        boolean exposeInputDevices = false;
        IBstFilterAppsService mBstFilter = IBstFilterAppsService.Stub.asInterface(
                ServiceManager.getService(Context.BST_FILTER_APPS));
        try {
            if (callingApp != null) {
                exposeInputDevices = mBstFilter.areInputDevicesExposed(callingApp);
            }
        } catch (Exception ex) {
            Slog.d(TAG, ex.getMessage());
        }
        if ((mName.toLowerCase().startsWith("bluestacks")
                || mName.toLowerCase().startsWith("virtualbox")
                || mName.toLowerCase().contains("keyboard")
                || mName.toLowerCase().contains("mouse"))
                && (Binder.getCallingUid() != Process.SYSTEM_UID)
                && (Binder.getCallingUid() >= 10000)
                && callingApp != null
                && !callingApp.startsWith("com.bluestacks")
                && !callingApp.startsWith("com.uncube")) {
            if (exposeInputDevices) {
                if (mName.startsWith("BlueStacks") || mName.startsWith("VirtualBox")) {
                    if (mName.toLowerCase().contains("keyboard")) {
                        return modifiedDeviceName + " keyboard";
                    } else if (mName.toLowerCase().contains("mouse")) {
                        return modifiedDeviceName + " mouse";
                    } else {
                        return modifiedDeviceName + "-" + mId;
                    }
                }
            } else {
                return modifiedDeviceName + "-" + mId;
            }
        }

"""

patch(
    "core/java/android/view/InputDevice.java",
    [
        (
            "import android.os.Build;\n",
            "import android.os.Binder;\nimport android.os.Build;\nimport android.os.Process;\n"
            "import android.os.ServiceManager;\n",
        ),
        (
            "import android.text.TextUtils;\n",
            "import android.text.TextUtils;\nimport android.util.BstUtils;\nimport android.util.Slog;\n\n"
            "import com.bluestacks.os.IBstFilterAppsService;\n",
        ),
        (
            "public final class InputDevice implements Parcelable {\n",
            "public final class InputDevice implements Parcelable {\n"
            "    private static final String TAG = \"InputDevice\";\n",
        ),
        (
            "    public String getName() {\n        return mName;\n    }\n",
            "    public String getName() {\n" + INPUT_GETNAME + "        return mName;\n    }\n",
        ),
        (
            'description.append("Input Device ").append(mId).append(": ").append(mName).append("\\n");\n',
            'description.append("Input Device ").append(mId).append(": ").append(getName()).append("\\n");\n',
        ),
    ],
    "InputDevice.getName anti-detection",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
