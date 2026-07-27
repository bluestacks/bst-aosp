#!/usr/bin/env python3
# P2-FW-SERVICES-1b: LocationManagerService GMS network popup suppress (isolated).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
MARKER = "A16DBG:P2:FW-SERVICES-1b"
ERRS = []


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
    if MARKER in src:
        print(f"SKIP {label} (already patched)")
        return
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:80]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:80]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


LOCATION = "services/core/java/com/android/server/location/LocationManagerService.java"

patch(
    LOCATION,
    [
        (
            "import android.util.ArrayMap;\n",
            "import android.util.ArrayMap;\nimport android.util.BstUtils;\n",
        ),
        (
            "        public boolean isProviderEnabledForUser(@NonNull String provider, int userId) {\n"
            "            userId = ActivityManager.handleIncomingUser(Binder.getCallingPid(),\n"
            "                    Binder.getCallingUid(), userId, false, false, "
            "\"isProviderEnabledForUser\", null);\n",
            "        public boolean isProviderEnabledForUser(@NonNull String provider, int userId) {\n"
            "            // A16DBG:P2:FW-SERVICES-1b Location — suppress GMS network accuracy popup (a13)\n"
            "            if (\"network\".equals(provider)) {\n"
            "                int pid = Binder.getCallingPid();\n"
            "                String packageName = BstUtils.getAppNameFromPid(pid);\n"
            "                if (D) {\n"
            "                    Log.d(TAG, \"A16DBG:P2:FW-SERVICES-1b isProviderEnabled pid=\"\n"
            "                            + pid + \" pkg=\" + packageName);\n"
            "                }\n"
            "                if (packageName != null\n"
            "                        && packageName.startsWith(\"com.google.android.gms\")) {\n"
            "                    LocationProviderManager networkManager = getLocationProviderManager(\n"
            "                            provider);\n"
            "                    if (networkManager == null || !networkManager.isEnabled(userId)) {\n"
            "                        if (D) {\n"
            "                            Log.d(TAG, \"A16DBG:P2:FW-SERVICES-1b network disabled for gms\");\n"
            "                        }\n"
            "                        return false;\n"
            "                    }\n"
            "                }\n"
            "            }\n\n"
            "            userId = ActivityManager.handleIncomingUser(Binder.getCallingPid(),\n"
            "                    Binder.getCallingUid(), userId, false, false, "
            "\"isProviderEnabledForUser\", null);\n",
        ),
    ],
    "LocationManagerService",
)

if ERRS:
    for e in ERRS:
        print(f"ERROR {e}", file=sys.stderr)
    sys.exit(1)

print(f"VERIFY {MARKER} present:", MARKER in open(os.path.join(A16, LOCATION)).read())
