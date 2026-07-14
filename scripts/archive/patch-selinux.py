#!/usr/bin/env python3
import os

os.chdir(os.path.expanduser("~/aosp16/system/core"))

with open("init/selinux.cpp", "r") as f:
    content = f.read()

# Fix 1: ReadPolicy - change LOG(FATAL) to LOG(ERROR) + return empty
old = 'void ReadPolicy(std::string* policy) {\n    const char* path = "/system/etc/selinux/plat_sepolicy.cil";\n    if (!android::base::ReadFileToString(path, policy)) {\n        LOG(FATAL) << "Unable to open SELinux policy";'
new = 'void ReadPolicy(std::string* policy) {\n    const char* path = "/system/etc/selinux/plat_sepolicy.cil";\n    if (!android::base::ReadFileToString(path, policy)) {\n        LOG(ERROR) << "Unable to open SELinux policy (BS: non-fatal)";\n        *policy = "";\n        return;'
content = content.replace(old, new)

# Fix 2: LoadSelinuxPolicyAndroid - skip if policy empty
old2 = '    ReadPolicy(&policy);\n    LoadSelinuxPolicy(policy);'
new2 = '    ReadPolicy(&policy);\n    if (policy.empty()) {\n        LOG(WARNING) << "SELinux policy empty, skipping (BS permissive)";\n        return;\n    }\n    LoadSelinuxPolicy(policy);'
content = content.replace(old2, new2)

with open("init/selinux.cpp", "w") as f:
    f.write(content)
print("SELINUX_PATCHED")
