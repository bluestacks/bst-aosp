#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/selinux.cpp"
t = p.read_text()

needle = (
    '    if (policy.empty()) {\n'
    '        LOG(WARNING) << "Skipping SELinux policy load (BS bringup)";\n'
    '        return;\n'
    '    }'
)
repl = (
    '    if (policy.empty()) {\n'
    '        LOG(WARNING) << "Skipping SELinux policy load (BS bringup)";\n'
    '        if (security_setenforce(0) != 0) {\n'
    '            PLOG(WARNING) << "security_setenforce(0) failed (no policy)";\n'
    '        }\n'
    '        return;\n'
    '    }'
)
if needle in t:
    t = t.replace(needle, repl)
    p.write_text(t)
    print("selinux setenforce on skip OK")
else:
    print("pattern not found (maybe already patched)")
