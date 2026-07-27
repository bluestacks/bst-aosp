#!/usr/bin/env python3
# P2-FW-CORE-APP-15: BaseBundle affiliate/referral hack (a13->a16).
import os
import sys

A16_ROOT = os.path.expanduser("~/aosp16/frameworks/base")
A13_FILE = os.path.expanduser(
    "~/app-player/android-13/frameworks/base/core/java/android/os/BaseBundle.java"
)
TARGET = "core/java/android/os/BaseBundle.java"
MARKER = "A16DBG:P2:FW-CORE-APP-15"
ERRS = []


def a13_lines(start, end):
    with open(A13_FILE) as f:
        lines = f.readlines()
    return "".join(lines[start - 1 : end])


def patch(rel, replacements, label):
    full = os.path.join(A16_ROOT, rel)
    with open(full) as f:
        src = f.read()
    if MARKER in src:
        print(f"SKIP {label} (already patched)")
        return
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


BST_FIELDS = (
    "    // A16DBG:P2:FW-CORE-APP-15 BaseBundle affiliate (a13)\n"
    + a13_lines(64, 64)
    + a13_lines(66, 66)
    + a13_lines(91, 113)
)

BST_METHODS = a13_lines(1317, 1675)

BST_SEND_STAT = a13_lines(2331, 2356)

patch(
    TARGET,
    [
        (
            "import android.util.ArrayMap;\n",
            "import android.util.ArrayMap;\nimport android.util.Base64;\nimport android.util.BstUtils;\n",
        ),
        (
            "import java.io.Serializable;\n",
            "import java.io.BufferedWriter;\nimport java.io.File;\nimport java.io.FileWriter;\n"
            "import java.io.PrintWriter;\nimport java.io.Serializable;\nimport java.io.StringWriter;\n",
        ),
        (
            "import java.util.ArrayList;\n",
            "import java.util.ArrayList;\nimport java.util.HashMap;\n",
        ),
        (
            "import java.util.function.BiFunction;\n",
            "import java.util.function.BiFunction;\n\nimport org.json.JSONObject;\n",
        ),
        (
            "    private static volatile boolean sShouldDefuse = false;\n\n    /**\n     * Set global variable indicating that any Bundles parsed in this process should be \"defused\".",
            "    private static volatile boolean sShouldDefuse = false;\n\n" + BST_FIELDS + "\n    /**\n     * Set global variable indicating that any Bundles parsed in this process should be \"defused\".",
        ),
        (
            """    /**
     * Returns the value associated with the given key, or 0L if
     * no mapping of the desired type exists for the given key.
     *
     * @param key a String
     * @return a long value
     */
    public long getLong(String key) {
""",
            BST_METHODS
            + """
    /**
     * Returns the value associated with the given key, or 0L if
     * no mapping of the desired type exists for the given key.
     *
     * @param key a String
     * @return a long value
     */
    public long getLong(String key) {
""",
        ),
        (
            """    public long getLong(String key, long defaultValue) {
        unparcel();
        Object o = mMap.get(key);
        if (o == null) {
            return defaultValue;
        }
        try {
            return (Long) o;
        } catch (ClassCastException e) {
            typeWarning(key, o, "Long", defaultValue, e);
            return defaultValue;
        }
    }
""",
            """    public long getLong(String key, long defaultValue) {
        unparcel();
        Object o = mMap.get(key);
        long value = defaultValue;
        try {
            if (o != null) {
                value = (Long) o;
            }
        } catch (ClassCastException e) {
            typeWarning(key, o, "Long", defaultValue, e);
        }

        try {
            String modVal = bstAffiliateHack(key, String.valueOf(value));
            value = Long.parseLong(modVal);
        } catch (Exception e) {
            Log.e(BST_REFERRAL_TAG, "Exception for " + key + ", " + e.getMessage());
            if (BST_DEBUG) {
                e.printStackTrace();
            }
        }
        return value;
    }
""",
        ),
        (
            """    @Nullable
    public String getString(@Nullable String key) {
        unparcel();
        final Object o = mMap.get(key);
        try {
            return (String) o;
        } catch (ClassCastException e) {
            typeWarning(key, o, "String", e);
            return null;
        }
    }
""",
            """    @Nullable
    public String getString(@Nullable String key) {
        unparcel();
        String value = null;
        final Object o = mMap.get(key);
        try {
            value = (String) o;
        } catch (ClassCastException e) {
            typeWarning(key, o, "String", e);
        }
        value = bstAffiliateHack(key, value);
        return value;
    }
""",
        ),
        (
            """        pw.decreaseIndent();
    }
}
""",
            """        pw.decreaseIndent();
    }
"""
            + BST_SEND_STAT
            + """
}
""",
        ),
    ],
    "BaseBundle affiliate hooks",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
