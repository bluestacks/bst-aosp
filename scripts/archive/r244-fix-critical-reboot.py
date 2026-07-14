#!/usr/bin/env python3
from pathlib import Path
import re

p = Path.home() / "aosp16/system/core/init/service.cpp"
t = p.read_text()
pat = re.compile(
    r"SetFatalRebootTarget\(fatal_reboot_target_\);\n"
    r"\s*// BS bringup R173h:.*?\n"
    r"\s*// Skip LOG\(FATAL\).*?\n"
    r"\s*LOG\(WARNING\) << \"BS bringup R173h skip critical reboot.*?\n"
    r"\s*\(void\)exit_reason;",
    re.S,
)
new = (
    "SetFatalRebootTarget(fatal_reboot_target_);\n"
    '                            LOG(FATAL) << "critical process \'" << name_ << "\' exited 4 times "\n'
    "                                       << exit_reason;"
)
m = pat.search(t)
if not m:
    for i, ln in enumerate(t.splitlines(), 1):
        if 388 <= i <= 400:
            print(i, repr(ln))
    raise SystemExit("pattern not found")
t2, n = pat.subn(new, t, count=1)
print("replaced", n)
p.write_text(t2)
assert "R173h" not in p.read_text()
print("OK")
