#!/usr/bin/env python3
"""Remove duplicate hidl.manager/token from framework manifest.

Stock A16 already provides them via system/hwservicemanager/hwservicemanager.xml
(assembled into system_ext @ manager 1.2 + token 1.0). Keeping both triggers
vintffm conflict when PRODUCT_ENFORCE_VINTF_MANIFEST=true.
Keep android.hidl.allocator in framework (not in hwservicemanager.xml).
"""
from pathlib import Path
import re

p = Path.home() / "aosp16/system/libhidl/vintfdata/manifest.xml"
t = p.read_text()


def rm_hal(text: str, name: str) -> str:
    # Use [^"]* for max-level to avoid backref issues with digit after \
    pat = re.compile(
        r"\n    <hal format=\"hidl\" max-level=\"[^\"]+\">\n"
        r"        <name>" + re.escape(name) + r"</name>\n"
        r"        <transport>hwbinder</transport>\n"
        r"        <version>[^<]+</version>\n"
        r"        <interface>\n"
        r"            <name>[^<]+</name>\n"
        r"            <instance>default</instance>\n"
        r"        </interface>\n"
        r"    </hal>"
    )
    t2, n = pat.subn("", text, count=1)
    print(f"remove {name}: n={n}")
    if n != 1:
        raise SystemExit(f"failed to remove {name}")
    return t2


t = rm_hal(t, "android.hidl.manager")
t = rm_hal(t, "android.hidl.token")
p.write_text(t)
print("remaining android.hidl.*:")
for m in re.finditer(r"<name>android\.hidl\.[^<]+</name>", p.read_text()):
    print(" ", m.group(0))
