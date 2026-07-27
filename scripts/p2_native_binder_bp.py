#!/usr/bin/env python3
"""Add BST binder sources to a16 libbinder Android.bp if missing."""
from pathlib import Path

p = Path.home() / "aosp16/frameworks/native/libs/binder/Android.bp"
t = p.read_text()
needle = '        "BpBinder.cpp",\n'
insert = (
    '        "BpBinder.cpp",\n'
    '        "BstFilterAppsManager.cpp",\n'
    '        "BstUtilsManager.cpp",\n'
    '        "IBstFilterAppsService.cpp",\n'
    '        "IBstUtilsService.cpp",\n'
)
if "BstFilterAppsManager.cpp" in t:
    print("Android.bp already has BST binder srcs")
else:
    if needle not in t:
        raise SystemExit("BpBinder.cpp anchor missing")
    # Only replace first occurrence in main libbinder srcs
    p.write_text(t.replace(needle, insert, 1))
    print("Android.bp: inserted BST binder srcs after BpBinder.cpp")

# verify files exist
base = Path.home() / "aosp16/frameworks/native/libs/binder"
for f in [
    "BstFilterAppsManager.cpp",
    "BstUtilsManager.cpp",
    "IBstFilterAppsService.cpp",
    "IBstUtilsService.cpp",
    "include/binder/BstFilterAppsManager.h",
    "include/binder/BstUtilsManager.h",
    "include/binder/IBstFilterAppsService.h",
    "include/binder/IBstUtilsService.h",
]:
    ok = (base / f).exists()
    print(("OK" if ok else "MISS"), f)
