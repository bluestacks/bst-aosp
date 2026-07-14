#!/usr/bin/env python3
"""Set ro.zygote=zygote64 when vendor build.prop missing (BS bringup)."""
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/init.cpp"
t = p.read_text()

needle = "    PropertyInit();\n"
repl = (
    "    PropertyInit();\n"
    "    if (GetProperty(\"ro.zygote\", \"\").empty()) {\n"
    "        LOG(WARNING) << \"ro.zygote missing, defaulting to zygote64 (BS bringup)\";\n"
        "        InitPropertySet(\"ro.zygote\", \"zygote64\");\n"
    "    }\n"
)
if "ro.zygote missing" not in t:
    if needle in t:
        t = t.replace(needle, repl, 1)
        p.write_text(t)
        print("init.cpp ro.zygote default OK")
    else:
        print("PropertyInit() not found")
        raise SystemExit(1)
else:
    print("init.cpp already patched")
