#!/usr/bin/env python3
"""BS bringup: skip SELinux property checks when policy not loaded."""
from pathlib import Path

# property_service.cpp
p = Path.home() / "aosp16/system/core/init/property_service.cpp"
t = p.read_text()
old = (
    "static bool CheckMacPerms(const std::string& name, const char* target_context,\n"
    "                          const char* source_context, const ucred& cr) {\n"
    "    if (!target_context || !source_context) {\n"
    "        return false;\n"
    "    }"
)
new = (
    "static bool CheckMacPerms(const std::string& name, const char* target_context,\n"
    "                          const char* source_context, const ucred& cr) {\n"
    "    // BS bringup: no loaded sepolicy -> selinux_check_access always fails\n"
    "    if (!is_selinux_enabled() || security_getenforce() == 0) {\n"
    "        return true;\n"
    "    }\n"
    "    if (!target_context || !source_context) {\n"
    "        return true;\n"
    "    }"
)
if old in t:
    t = t.replace(old, new)
    p.write_text(t)
    print("property_service.cpp CheckMacPerms OK")
else:
    print("property_service.cpp already patched")

# init.cpp UpdateApexLinkerConfig
p = Path.home() / "aosp16/system/core/init/init.cpp"
t = p.read_text()
needle = (
    "    const char* linkerconfig_binary = \"/apex/com.android.runtime/bin/linkerconfig\";\n"
    "    const char* linkerconfig_target = \"/linkerconfig\";\n"
    "    const char* arguments[] = {linkerconfig_binary, \"--target\", linkerconfig_target, \"--apex\",\n"
    "                               apex_name.c_str(),   \"--strict\"};\n"
    "\n"
    "    if (logwrap_fork_execvp"
)
repl = (
    "    const char* linkerconfig_binary = \"/apex/com.android.runtime/bin/linkerconfig\";\n"
    "    if (access(linkerconfig_binary, X_OK) != 0) {\n"
    "        LOG(WARNING) << \"linkerconfig missing, skip apex \" << apex_name;\n"
    "        return {};\n"
    "    }\n"
    "    const char* linkerconfig_target = \"/linkerconfig\";\n"
    "    const char* arguments[] = {linkerconfig_binary, \"--target\", linkerconfig_target, \"--apex\",\n"
    "                               apex_name.c_str(),   \"--strict\"};\n"
    "\n"
    "    if (logwrap_fork_execvp"
)
if needle in t and "linkerconfig missing" not in t:
    t = t.replace(needle, repl)
    p.write_text(t)
    print("init.cpp UpdateApexLinkerConfig OK")

# builtins.cpp GenerateLinkerConfiguration
p = Path.home() / "aosp16/system/core/init/builtins.cpp"
t = p.read_text()
old2 = (
    "static Result<void> GenerateLinkerConfiguration() {\n"
    "    const char* linkerconfig_binary = \"/apex/com.android.runtime/bin/linkerconfig\";\n"
    "    const char* linkerconfig_target = \"/linkerconfig\";\n"
    "    const char* arguments[] = {linkerconfig_binary, \"--target\", linkerconfig_target};\n"
    "\n"
    "    if (logwrap_fork_execvp"
)
new2 = (
    "static Result<void> GenerateLinkerConfiguration() {\n"
    "    const char* linkerconfig_binary = \"/apex/com.android.runtime/bin/linkerconfig\";\n"
    "    if (access(linkerconfig_binary, X_OK) != 0) {\n"
    "        LOG(WARNING) << \"linkerconfig missing, using bootstrap linker config\";\n"
    "        return {};\n"
    "    }\n"
    "    const char* linkerconfig_target = \"/linkerconfig\";\n"
    "    const char* arguments[] = {linkerconfig_binary, \"--target\", linkerconfig_target};\n"
    "\n"
    "    if (logwrap_fork_execvp"
)
if old2 in t and "using bootstrap linker config" not in t:
    t = t.replace(old2, new2)
    p.write_text(t)
    print("builtins.cpp GenerateLinkerConfiguration OK")
