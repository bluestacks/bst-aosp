#!/usr/bin/env python3
# P2-MECH-5: build/make product config tweaks (a13->a16).
# runtime_libart.mk: PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false (slim image).
# telephony_system_ext.mk: remove EmergencyInfo package.
# handheld_system.mk: remove 5 unused apps (BasicDreams/BluetoothMidiService/BuiltInPrintService/ManagedProvisioning/MmsService).
# Mechanical PRODUCT_PACKAGES config. Low risk (image content tweaks).
import os, sys
A16 = os.path.expanduser("~/aosp16")
ERRS = []
def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src: ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1: ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig: ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

# runtime_libart.mk: add PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false before usage
patch("build/make/target/product/runtime_libart.mk", [
    ("art_target_include_debug_build := $(PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD)\n",
     "# A16DBG:P2:MECH BST: disable ART debug build (slim image, a13)\n"
     "PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false\n"
     "art_target_include_debug_build := $(PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD)\n"),
], "runtime_libart DEBUG_BUILD=false")

# telephony_system_ext.mk: remove EmergencyInfo
patch("build/make/target/product/telephony_system_ext.mk", [
    ("    EmergencyInfo \\\n", ""),
], "telephony_system_ext remove EmergencyInfo")

# handheld_system.mk: remove 5 unused apps (each is a line in PRODUCT_PACKAGES list)
for app in ["BasicDreams", "BluetoothMidiService", "BuiltInPrintService", "ManagedProvisioning", "MmsService"]:
    patch("build/make/target/product/handheld_system.mk", [
        (f"    {app} \\\n", f"    # A16DBG:P2:MECH BST removed {app} (a13)\n"),
    ], f"handheld_system remove {app}")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
