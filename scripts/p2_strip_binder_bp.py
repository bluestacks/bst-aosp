#!/usr/bin/env python3
from pathlib import Path
import re
p = Path.home() / "aosp16/frameworks/native/libs/binder/Android.bp"
t = p.read_text()
t2 = t
for name in (
    "BstFilterAppsManager.cpp",
    "BstUtilsManager.cpp",
    "IBstFilterAppsService.cpp",
    "IBstUtilsService.cpp",
):
    t2 = re.sub(r'\n\s*"' + re.escape(name) + r'",', "", t2)
p.write_text(t2)
print("bp changed", t != t2)
print("bst left", "BstFilter" in t2 or "IBst" in t2)
