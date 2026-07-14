#!/usr/bin/env python3
"""R244: finish restoring Henry stock reboot_on_failure in service.cpp"""
from pathlib import Path

sp = Path.home() / "aosp16/system/core/init/service.cpp"
st = sp.read_text()

# Any remaining BS bringup skip blocks -> trigger_shutdown
patterns = [
    (
        '            // BS bringup: skip shutdown for failed services\n'
        '        LOG(WARNING) << "BS bringup: skipping reboot_on_failure for " << name_;',
        '            trigger_shutdown(*on_failure_reboot_target_);',
    ),
    (
        '        // BS bringup: skip shutdown for failed services\n'
        '        LOG(WARNING) << "BS bringup: skipping reboot_on_failure for " << name_;',
        '        trigger_shutdown(*on_failure_reboot_target_);',
    ),
]

total = 0
for old, new in patterns:
    c = st.count(old)
    if c:
        st = st.replace(old, new)
        total += c
        print(f"replaced block count={c}")

# Line-based fallback
if "BS bringup: skipping reboot_on_failure" in st or "BS bringup: skip shutdown" in st:
    out = []
    i = 0
    lines = st.splitlines(True)
    while i < len(lines):
        ln = lines[i]
        if "BS bringup: skip shutdown" in ln:
            # skip this comment line; next LOG line also skip and insert trigger
            i += 1
            if i < len(lines) and "skipping reboot_on_failure" in lines[i]:
                # preserve indent of the LOG line's sibling - use 8 or 12 spaces based on context
                indent = "            " if lines[i].startswith("        LOG") else "        "
                out.append(f"{indent}trigger_shutdown(*on_failure_reboot_target_);\n")
                i += 1
                total += 1
                continue
            continue
        if "BS bringup: skipping reboot_on_failure" in ln:
            indent = "            " if ln.lstrip().startswith("LOG") else "        "
            out.append(f"{indent}trigger_shutdown(*on_failure_reboot_target_);\n")
            i += 1
            total += 1
            continue
        out.append(ln)
        i += 1
    st = "".join(out)
    print(f"line-filter total ops, cumulative={total}")

if "BS bringup: skipping reboot_on_failure" in st:
    for i, ln in enumerate(st.splitlines(), 1):
        if "BS bringup" in ln:
            print(f"REMAINING {i}: {ln}")
    raise SystemExit("FAIL: BS bringup still present")

sp.write_text(st)
print("service.cpp OK")
print("trigger_shutdown count:", st.count("trigger_shutdown(*on_failure_reboot_target_)"))
