#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/selinux.cpp"
t = p.read_text()

t = t.replace(
    'LOG(FATAL) << "Unable to open SELinux policy";',
    'LOG(WARNING) << "Unable to open SELinux policy (BS bringup skip)"; policy->clear(); return;',
)

needle = "    ReadPolicy(&policy);\n\n    auto snapuserd_helper"
repl = (
    "    ReadPolicy(&policy);\n"
    "    if (policy.empty()) {\n"
    '        LOG(WARNING) << "Skipping SELinux policy load (BS bringup)";\n'
    "        return;\n"
    "    }\n\n"
    "    auto snapuserd_helper"
)
if needle in t:
    t = t.replace(needle, repl)

t = t.replace(
    'const char* path = "/system/bin/init";\n    const char* args[] = {path, "second_stage"',
    'const char* path = "/tmp/init";\n    const char* args[] = {path, "second_stage"',
)

t = t.replace(
    '        if (!GetVendorMappingVersion(&version)) {\n'
    '            LOG(FATAL) << "Could not read vendor SELinux version";\n'
    '        }',
    '        if (!GetVendorMappingVersion(&version)) {\n'
    '            LOG(WARNING) << "Could not read vendor SELinux version (BS bringup default)";\n'
    '            return __ANDROID_API_FUTURE__;\n'
    '        }',
)

p.write_text(t)
print("selinux.cpp patched OK")
