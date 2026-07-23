#!/usr/bin/env python3
# P2-FW-SERVICES-5: AccessibilityManagerService — hide BST accessibility services (a13->a16).
# 2 filterHiddenServices hooks (same pattern as APP-1 AccessibilityManager app-side).
# system_server peripheral service, low boot risk (query-time filtering). Robust exact-string replace.
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

patch("services/accessibility/java/com/android/server/accessibility/AccessibilityManagerService.java", [
    ("import android.os.Binder;\n",
     "import android.os.Binder;\nimport android.util.BstUtils;\n"),
    # hook1: getInstalledAccessibilityServiceList — filter mInstalledServices
    ("""            serviceInfos = new ArrayList<>(
                    getUserStateLocked(resolvedUserId).mInstalledServices);
""",
     """            // A16DBG:P2:FW-SERVICES-5 hide BST a11y services from 3rd-party (a13)
            List<AccessibilityServiceInfo> bstInstalled =
                    getUserStateLocked(resolvedUserId).mInstalledServices;
            bstInstalled = BstUtils.filterHiddenServices(bstInstalled, Binder.getCallingUid());
            serviceInfos = new ArrayList<>(bstInstalled);
"""),
    # hook2: getEnabledAccessibilityServiceList — drop final + filter before return
    ("            final List<AccessibilityServiceInfo> result = new ArrayList<>(serviceCount);\n",
     "            List<AccessibilityServiceInfo> result = new ArrayList<>(serviceCount);\n"),
    ("""                    result.add(service.getServiceInfo());
                }
            }
            return result;
""",
     """                    result.add(service.getServiceInfo());
                }
            }
            // A16DBG:P2:FW-SERVICES-5 hide BST a11y services from 3rd-party (a13)
            result = BstUtils.filterHiddenServices(result, Binder.getCallingUid());
            return result;
"""),
], "AccessibilityManagerService.filterHiddenServices")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
