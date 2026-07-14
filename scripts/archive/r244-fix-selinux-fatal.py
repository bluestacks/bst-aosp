#!/usr/bin/env python3
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/selinux.cpp"
t = p.read_text()
old = 'LOG(ERROR) << "Unable to open SELinux policy (BS bringup skip)";'
new = 'LOG(FATAL) << "Unable to open SELinux policy";'
if old not in t:
    for i, ln in enumerate(t.splitlines(), 1):
        if "SELinux policy" in ln:
            print(i, repr(ln))
    raise SystemExit("pattern missing")
p.write_text(t.replace(old, new, 1))
assert "(BS bringup skip)" not in p.read_text()
print("selinux RESTORED to Henry FATAL")
