#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/selinux.cpp"
t = p.read_text()

old = (
    '        if (!GetVendorMappingVersion(&version)) {\n'
    '            LOG(FATAL) << "Could not read vendor SELinux version";\n'
    '        }'
)
new = (
    '        if (!GetVendorMappingVersion(&version)) {\n'
    '            LOG(WARNING) << "Could not read vendor SELinux version (BS bringup default)";\n'
    '            return __ANDROID_API_FUTURE__;\n'
    '        }'
)
if old in t:
    p.write_text(t.replace(old, new))
    print("vendor version patched OK")
else:
    print("already patched or pattern not found")
