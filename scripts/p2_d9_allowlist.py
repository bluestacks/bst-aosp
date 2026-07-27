#!/usr/bin/env python3
# P2-D9 fix #2: a16 libbinder forbids manually-written binder interfaces unless allowlisted (b/64223827).
# IBstUtilsService.cpp / IBstFilterAppsService.cpp use IMPLEMENT_META_INTERFACE (manual) -> static_assert fires.
# Fix: add the two BST interface FQNs to kDownstreamManualInterfaces in IInterface.h
# (the sanctioned list — comment literally says "Add downstream interfaces here"; not a hack).
# This is the canonical mechanism for downstream manual interfaces; no device-layer alternative exists
# for a static_assert in a core header.
import os, sys
A16 = os.path.expanduser("~/aosp16")
F = "frameworks/native/libs/binder/include/binder/IInterface.h"
full = os.path.join(A16, F)
with open(full) as f: src = f.read()

old = (
    'constexpr const char* const kDownstreamManualInterfaces[] = {\n'
    '  // Add downstream interfaces here.\n'
    '  nullptr,\n'
    '};\n'
)
new = (
    'constexpr const char* const kDownstreamManualInterfaces[] = {\n'
    '  // Add downstream interfaces here.\n'
    '  // A16DBG:P2:D9 BlueStacks manual binder interfaces (a13 port; allowlist per b/64223827)\n'
    '  "com.bluestacks.os.IBstUtilsService",\n'
    '  "com.bluestacks.os.IBstFilterAppsService",\n'
    '  nullptr,\n'
    '};\n'
)
if old not in src:
    print("ERROR: anchor not found"); sys.exit(1)
if src.count(old) > 1:
    print("ERROR: anchor not unique"); sys.exit(1)
with open(full, "w") as f: f.write(src.replace(old, new, 1))
print("OK   IInterface.h kDownstreamManualInterfaces += IBstUtilsService, IBstFilterAppsService")
