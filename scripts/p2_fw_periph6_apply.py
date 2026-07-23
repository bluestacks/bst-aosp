#!/usr/bin/env python3
# P2-FW-PERIPH-6: SettingsProvider — hide BST a11y services from ENABLED_ACCESSIBILITY_SERVICES setting.
# Complementary to AccessibilityManagerService (SERVICES-5): filters the setting string for 3rd-party
# callers. Adapted from a13: a16 getSettingLocked gained deviceId param; Setting ctor @1769 arg order
# (name,value,defaultValue,packageName,tag,fromSystem,id) differs from a13 (reordered). system_server
# content provider, query-time filter. Robust exact-string replace.
import os, sys
A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []

def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1:
            ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

patch("packages/SettingsProvider/src/com/android/providers/settings/SettingsProvider.java", [
    # imports BstUtils + Slog
    ("import android.os.UserHandle;\n",
     "import android.os.UserHandle;\n"
     "import android.util.BstUtils;\nimport android.util.Slog;\n"),
    # capture setting + filter ENABLED_ACCESSIBILITY_SERVICES for 3rd-party, reconstruct Setting (a16 @1769 ctor order)
    ("""        synchronized (mLock) {
            return mSettingsRegistry.getSettingLocked(SETTINGS_TYPE_SECURE,
                    owningUserId, deviceId, name);
        }
""",
     """        synchronized (mLock) {
            Setting setting = mSettingsRegistry.getSettingLocked(SETTINGS_TYPE_SECURE,
                    owningUserId, deviceId, name);
            // A16DBG:P2:FW-PERIPH-6 BST hide a11y services from setting for 3rd-party (a13)
            if (Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES.equals(name) && setting != null
                    && setting.getValue() != null) {
                int callingUid = Binder.getCallingUid();
                final String filteredServices =
                        BstUtils.filterHiddenServices(setting.getValue(), callingUid);
                final SettingsState settingsState = mSettingsRegistry.getSettingsLocked(
                        SETTINGS_TYPE_SECURE, owningUserId, deviceId);
                if (settingsState == null) {
                    Slog.e(LOG_TAG, "A16DBG:P2:FW-PERIPH-6 Failed to obtain SettingsState");
                    return setting;
                }
                setting = settingsState.new Setting(
                        setting.getName(), filteredServices, setting.getDefaultValue(),
                        setting.getPackageName(), setting.getTag(), setting.isDefaultFromSystem(),
                        setting.getId());
            }
            return setting;
        }
"""),
], "SettingsProvider a11y setting filter")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
