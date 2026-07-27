#!/usr/bin/env python3
"""Build metalava-clean android.util.BstUtils from a13 source.

Conservative transforms only:
  - class-level @hide
  - @hide on every public static method missing it
  - GetCustomDpi -> getCustomDpi
  - public HashMap params -> Map (ConcreteCollection)
  - add Map + annotation imports
"""
from pathlib import Path
import re

a13 = Path.home() / "app-player/android-13/frameworks/base/core/java/android/util/BstUtils.java"
out = Path.home() / "aosp16/frameworks/base/core/java/android/util/BstUtils.java"
src = a13.read_text()

# Imports
if "import android.annotation.Nullable;" not in src:
    src = src.replace(
        "package android.util;\n",
        "package android.util;\n\n"
        "import android.annotation.NonNull;\n"
        "import android.annotation.Nullable;\n",
        1,
    )
if "import java.util.Map;" not in src:
    src = src.replace("import java.util.List;", "import java.util.List;\nimport java.util.Map;", 1)

# Class @hide
src = re.sub(
    r"\npublic final class BstUtils \{",
    "\n/**\n * BlueStacks helper utilities.\n * @hide\n */\npublic final class BstUtils {",
    src,
    count=1,
)

# Rename GetCustomDpi
src = src.replace("GetCustomDpi", "getCustomDpi")

# ConcreteCollection: only the known public signature
src = src.replace(
    "HashMap<String, String> mBstReferralInstallTimeList, HashMap<String, ArrayList<Long>> mBstInstallTimeList",
    "Map<String, String> mBstReferralInstallTimeList, Map<String, ArrayList<Long>> mBstInstallTimeList",
)

# Insert /** @hide */ before public static if not already present above
lines = src.splitlines(True)
out_lines = []
for i, line in enumerate(lines):
    if re.match(r"\s*public static ", line):
        window = "".join(out_lines[-20:])
        if "@hide" not in window:
            indent = re.match(r"(\s*)", line).group(1)
            out_lines.append(f"{indent}/** @hide */\n")
    out_lines.append(line)
src = "".join(out_lines)

# Light nullability on return types for common reference returns (metalava MissingNullability)
def annot_ret(m):
    ret, rest = m.group(1), m.group(2)
    r = ret.strip()
    if r.startswith("@") or r in ("void", "boolean", "int", "long", "float", "double"):
        return m.group(0)
    if r.startswith("String") or r.startswith("Object") or r.startswith("List") or r.startswith("Map"):
        return f"public static @Nullable {ret}{rest}"
    return m.group(0)

src = re.sub(r"public static ([^=(]+?)(\w+\()", annot_ret, src)

out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(src)
text = out.read_text()
assert "GetCustomDpi" not in text
assert "getCustomDpi" in text
assert text.count("@hide") >= 10
print(f"wrote {out} lines={len(text.splitlines())} hide_count={text.count('@hide')}")
