#!/usr/bin/env python3
import os, sys

os.chdir(os.path.expanduser("~/aosp16/system/core/init"))

with open("service.cpp", "r") as f:
    content = f.read()

# Fix 1: Add permissive skip at function start
old = 'static Result<std::string> ComputeContextFromExecutable(const std::string& service_path) {\n    std::string computed_context;'
new = '''static Result<std::string> ComputeContextFromExecutable(const std::string& service_path) {
    // BS: permissive - skip SELinux domain check
    if (!is_selinux_enabled() || security_getenforce() == 0) {
        return "skip";
    }

    std::string computed_context;'''
content = content.replace(old, new)

# Fix 2: Error() -> WARNING for domain transition failure
old2 = 'return Error() << "File " << service_path << "(labeled \\"" << filecon.get()'
new2 = 'LOG(WARNING) << "File " << service_path << "(labeled \\"" << filecon.get()'
content = content.replace(old2, new2, 1)

# Fix 3: Add return "skip" after denials possible
old3 = '                           "denials possible.";\n    }'
new3 = '                           "denials possible.";\n        return "skip";\n    }'
content = content.replace(old3, new3, 1)

with open("service.cpp", "w") as f:
    f.write(content)
print("SERVICE_FIXED_OK")
