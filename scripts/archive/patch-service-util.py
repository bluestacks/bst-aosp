#!/usr/bin/env python3
# Apply documented service.cpp and util.cpp fixes for A16 boot
import sys, os

base = os.path.expanduser("~/aosp16/system/core/init")

# === Fix service.cpp: permissive skip ===
with open(os.path.join(base, "service.cpp"), "r") as f:
    content = f.read()

# Add permissive check at start of ComputeContextFromExecutable
old = 'static Result<std::string> ComputeContextFromExecutable(const std::string& service_path) {\n    std::string computed_context;'
new = '''static Result<std::string> ComputeContextFromExecutable(const std::string& service_path) {
    // BlueStacks: permissive - skip SELinux domain check
    if (!is_selinux_enabled() || security_getenforce() == 0) {
        return "skip";
    }

    std::string computed_context;'''
content = content.replace(old, new)

# Change Error() to WARNING + return "skip" for domain transition failure
old2 = 'return Error() << "File " << service_path << "(labeled \\"" << filecon.get()'
new2 = 'LOG(WARNING) << "File " << service_path << "(labeled \\"" << filecon.get()'
content = content.replace(old2, new2, 1)

old3 = '                           "denials possible.";\n    }'
new3 = '                           "denials possible.";\n        return "skip";\n    }'
content = content.replace(old3, new3, 1)

with open(os.path.join(base, "service.cpp"), "w") as f:
    f.write(content)
print("SERVICE_PATCHED")

# === Fix util.cpp: socket context + insecure file ===
with open(os.path.join(base, "util.cpp"), "r") as f:
    content = f.read()

# Socket context: disable via if(false)
content = content.replace(
    "if (!socketcon.empty()) {",
    "if (false && !socketcon.empty()) { // BS: disabled")
content = content.replace(
    "if (!socketcon.empty()) setsockcreatecon(nullptr)",
    "if (false && !socketcon.empty()) setsockcreatecon(nullptr) // BS: disabled")

# Insecure file: just change the condition
content = content.replace(
    "if ((sb.st_mode & (S_IWGRP | S_IWOTH)) != 0) {",
    "if (false) { // BS: insecure file check disabled\n    if (false && (sb.st_mode & (S_IWGRP | S_IWOTH)) != 0) {")

with open(os.path.join(base, "util.cpp"), "w") as f:
    f.write(content)
print("UTIL_PATCHED")
