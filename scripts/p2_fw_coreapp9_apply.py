#!/usr/bin/env python3
# P2-FW-CORE-APP-9: InputManagerGlobal ROB-18338 nativeMouse filter (a13->a16).
# Defer bstReloadPointerIcon until IInputManager IMS hook exists on a16.
import os
import sys

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


patch(
    "core/java/android/hardware/input/InputManagerGlobal.java",
    [
        (
            "import android.util.IntArray;\n",
            "import android.util.BstUtils;\nimport android.util.IntArray;\n",
        ),
        (
            """    public int[] getInputDeviceIds() {
        synchronized (mInputDeviceListeners) {
            populateInputDevicesLocked();

            final int count = mInputDevices.size();
            final int[] ids = new int[count];
            for (int i = 0; i < count; i++) {
                ids[i] = mInputDevices.keyAt(i);
            }
            return ids;
        }
    }
""",
            """    public int[] getInputDeviceIds() {
        synchronized (mInputDeviceListeners) {
            populateInputDevicesLocked();

            // A16DBG:P2:FW-CORE-APP-9 ROB-18338 filter nativeMouse for one package (a13)
            int uid = Binder.getCallingUid();
            String packageName = "";
            if (uid >= Process.FIRST_APPLICATION_UID) {
                packageName = BstUtils.getAppNameFromPid(Binder.getCallingPid());
            }
            if (!"com.netease.yyslshmt".equals(packageName)) {
                final int count = mInputDevices.size();
                final int[] ids = new int[count];
                for (int i = 0; i < count; i++) {
                    ids[i] = mInputDevices.keyAt(i);
                }
                return ids;
            }

            List<Integer> idList = new ArrayList<>();
            for (int i = 0; i < mInputDevices.size(); i++) {
                InputDevice device = mInputDevices.valueAt(i);
                if (device == null) {
                    int id = mInputDevices.keyAt(i);
                    try {
                        device = mIm.getInputDevice(id);
                    } catch (RemoteException ex) {
                        throw ex.rethrowFromSystemServer();
                    }
                }
                if (device == null) {
                    continue;
                }
                if (device.getVendorId() == 0x1234 && device.getProductId() == 0x5678) {
                    if (debug()) {
                        Log.d(TAG, "A16DBG:P2:FW-CORE-APP-9 filter device: " + device.getName()
                                + " (Vendor: 0x" + Integer.toHexString(device.getVendorId())
                                + ", Product: 0x" + Integer.toHexString(device.getProductId())
                                + ")");
                    }
                    continue;
                }
                idList.add(device.getId());
            }

            int[] ids = new int[idList.size()];
            for (int i = 0; i < idList.size(); i++) {
                ids[i] = idList.get(i);
            }
            return ids;
        }
    }
""",
        ),
    ],
    "InputManagerGlobal ROB-18338 filter",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
