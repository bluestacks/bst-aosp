#!/usr/bin/env python3
"""Move hwservicemanager from generic.mk PRODUCT_PACKAGES to system_image_defaults (Henry/BlueStacks)."""
import os
import re
import sys

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
os.chdir(AOSP)

mk = "device/generic/goldfish/product/generic.mk"
packages_mk = "device/generic/common/packages.mk"
base_system_ext = "build/make/target/product/base_system_ext.mk"
telephony_system_ext = "build/make/target/product/telephony_system_ext.mk"
bp = "build/make/target/product/generic/Android.bp"

mk_text = open(mk).read()
open(mk + ".bak", "w").write(mk_text)
def remove_hwsm_product_packages(text: str) -> str:
    lines = text.splitlines(keepends=True)
    out = []
    i = 0
    while i < len(lines):
        if (
            lines[i].strip() == "PRODUCT_PACKAGES += \\"
            and i + 2 < len(lines)
            and "hwservicemanager" in lines[i + 1]
            and "android.hidl.allocator@1.0-service" in lines[i + 2]
        ):
            i += 3
            while i < len(lines) and lines[i].strip() == "":
                i += 1
            continue
        out.append(lines[i])
        i += 1
    return "".join(out)


def remove_hwsm_shipping_api34(text: str) -> str:
    """Comment hwservicemanager lines in PRODUCT_PACKAGES_SHIPPING_API_LEVEL_34 blocks."""
    out = []
    added_note = False
    for line in text.splitlines(keepends=True):
        stripped = line.lstrip()
        if "hwservicemanager" in stripped and not stripped.startswith("#"):
            indent = line[: len(line) - len(stripped)]
            if not added_note:
                out.append(f"{indent}# BlueStacks: on /system via system_image_defaults\n")
                added_note = True
            out.append(f"{indent}# {stripped}")
        else:
            out.append(line)
    return "".join(out)


def fix_orphan_packages_tail(text: str) -> str:
    """Remove broken orphan lines left after hwservicemanager block removal."""
    needle = (
        "# BlueStacks bringup: also listed in generic/Android.bp system image deps.\n"
        "    android.hidl.memory@1.0-impl \\\n"
    )
    if needle in text:
        return text.replace(needle, "")
    return text


mk_new = remove_hwsm_product_packages(mk_text)
if mk_new == mk_text:
    print("generic.mk: no PRODUCT_PACKAGES hwservicemanager block to remove")
else:
    open(mk, "w").write(mk_new)
    print("generic.mk: removed hwservicemanager from PRODUCT_PACKAGES")

if os.path.isfile(packages_mk):
    pkg_text = open(packages_mk).read()
    open(packages_mk + ".bak", "w").write(pkg_text)
    pkg_new = remove_hwsm_product_packages(pkg_text)
    if pkg_new == pkg_text:
        print("packages.mk: no PRODUCT_PACKAGES hwservicemanager block to remove")
    else:
        open(packages_mk, "w").write(pkg_new)
        print("packages.mk: removed hwservicemanager from PRODUCT_PACKAGES")

for path, label in (
    (base_system_ext, "base_system_ext.mk"),
    (telephony_system_ext, "telephony_system_ext.mk"),
):
    if not os.path.isfile(path):
        continue
    ext_text = open(path).read()
    open(path + ".bak", "w").write(ext_text)
    ext_new = remove_hwsm_shipping_api34(ext_text)
    if ext_new == ext_text:
        print(f"{label}: no SHIPPING_API_LEVEL_34 hwservicemanager block to comment")
    else:
        open(path, "w").write(ext_new)
        print(f"{label}: commented hwservicemanager from SHIPPING_API_LEVEL_34")

if os.path.isfile(packages_mk):
    pkg_text = open(packages_mk).read()
    pkg_fixed = fix_orphan_packages_tail(pkg_text)
    if pkg_fixed != pkg_text:
        open(packages_mk, "w").write(pkg_fixed)
        print("packages.mk: removed orphan android.hidl.memory line")

bp_text = open(bp).read()
open(bp + ".bak", "w").write(bp_text)
needle = '"init_system", // base_system'
insert = needle + '\n                "hwservicemanager", // BlueStacks on /system'
if '"hwservicemanager", // BlueStacks on /system' in bp_text:
    print("Android.bp: hwservicemanager dep already present")
elif needle not in bp_text:
    print("Android.bp: init_system needle not found", file=sys.stderr)
    sys.exit(1)
else:
    open(bp, "w").write(bp_text.replace(needle, insert, 1))
    print("Android.bp: added hwservicemanager to system_image_defaults")
