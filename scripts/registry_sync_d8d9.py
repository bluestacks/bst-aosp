#!/usr/bin/env python3
# Sync patches/registry.json for D8/D9/D3/pagefusion (cont.101-102).
# - Update win-frameworks-native: D9 binder C++ now real impl (was fail-open stub).
# - Add D8 (subscription, ported), pagefusion (ported), D3 (screenshot, deferred).
import json, datetime, os
P = os.path.join(os.path.dirname(__file__), "..", "patches", "registry.json")
P = os.path.abspath(P)
d = json.load(open(P, encoding="utf-8"))

# 1. Update win-frameworks-native (D9 real impl now landed)
for e in d["patches"]:
    if e.get("id") == "win-frameworks-native":
        e["port_status"] = "ported"
        e["source_commit"] = "c581b1bae8"
        e["checkpoint_ref"] = "patches/android-16/patches/aosp16__frameworks_native_libs_binder.patch"
        e["verification"] = (
            "Root a878d3c8 Layer2 7/7 @161s. D9 binder C++ REAL impl now ported (was fail-open stub): "
            "3670 lines BstUtilsManager/BstFilterAppsManager/IBstUtilsService/IBstFilterAppsService in libbinder, "
            "6 a13->a16 fixes (VNDK guard+String16, allowlist b/64223827, exit-time-dtor, LIBBINDER_EXPORTED visibility, "
            "vendor PermissionController guard, (void)uid). commit c581b1bae8. "
            "Prior: installd globals/utils, ServiceManager.cpp, EventHub.cpp (Root 00c31065)."
        )
        e["host_compat"] = "ok"
        break

# 2. Helper to build a full-schema entry
def entry(**kw):
    base = {
        "id": None, "platform": "both", "project_path": None, "area": "frameworks",
        "unify_group": "bst-framework", "related_group": "P2-DEF", "phase": "P2",
        "temp_debt": False, "base_tag": "android-13.0.0_r49", "since_count": None,
        "bst_count": None, "has_bst": True, "confidence": "high", "purpose": None,
        "quality": None, "impact": None, "port_status": "ported", "host_compat": "ok",
        "verification": None, "checkpoint_ref": None, "boot_artifact": None,
        "source_commit": None, "owner": "agent", "notes": "",
    }
    base.update(kw)
    return base

existing = {e["id"] for e in d["patches"]}
new_entries = [
    entry(
        id="p2-d8-telephony-subscription",
        platform="both",
        project_path="frameworks/base",
        purpose="D8 fake-SIM subscription count anti-detection: SubscriptionManager.getActiveSubscriptionInfoCount() returns 1 when bst.config.enable_telephony=true. Sidesteps a13 blocker (getActiveSubscriptionInfoList @RequiresPermission drop fails check_current_api).",
        quality="clean; property-gated; no aidl change",
        impact="anti-detection (7th telephony layer); boot-safe",
        port_status="ported",
        source_commit="00274255beb7",
        verification="Layer2 7/7 @161s system.img a878d3c8; commit 00274255beb7 frameworks/base",
        checkpoint_ref="patches/android-16/patches/aosp16__frameworks_base__d8-subscription.patch",
        notes="D8 deferred item PORTED cont.101",
    ),
    entry(
        id="win-frameworks-base-pagefusion",
        platform="win",
        project_path="frameworks/base",
        unify_group="bst-framework",
        purpose="BST vbox page-fusion module (cmds/pagefusion). a16 fix: local #define PAGE_SIZE 4096 + PAGE_MASK (bionic -D__BIONIC_NO_PAGE_SIZE_MACRO disables the macro globally).",
        quality="clean; mechanical a16 bionic gap",
        impact="runtime page-fusion (vbox); boot-safe",
        port_status="ported",
        source_commit="2cf8a0cf64c5",
        verification="Layer2 7/7 @161s system.img a878d3c8; commit 2cf8a0cf64c5",
        checkpoint_ref="patches/android-16/patches/aosp16__frameworks_base__pagefusion.patch",
        notes="bonus latent gap exposed by .intermediates rebuild; PORTED cont.100-101",
    ),
    entry(
        id="p2-d3-screenshot-shared-folder",
        platform="both",
        project_path="frameworks/base",
        purpose="D3 screenshot -> /mnt/windows/BstSharedFolder + onScreenshotSaved hostcall. a14-a16 SystemUI screenshot pipeline rewritten (SaveImageInBackgroundTask gone; ScreenshotController+coroutine).",
        quality="DESIGN ONLY - not implemented",
        impact="convenience feature; blocked on /mnt/windows mount (host virt side)",
        port_status="deferred",
        host_compat="pending",
        verification="DESIGN: progress/d3-redesign.md (inject ScreenshotController.kt:508; 3-block A/B/C). DEFERRED to virt-port phase per user decision 2026-07-26 (block C /mnt/windows mount needs vbox/qvm port, out of Phase 2 scope).",
        checkpoint_ref="progress/d3-redesign.md",
        notes="D3 deferred item; user deferred cont.102",
    ),
]
for ne in new_entries:
    if ne["id"] not in existing:
        d["patches"].append(ne)
        print("added", ne["id"])
    else:
        print("exists, skipped", ne["id"])

d["generated_at"] = "2026-07-26"
with open(P, "w", encoding="utf-8") as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
    f.write("\n")
print("OK registry.json synced; patches now", len(d["patches"]))
