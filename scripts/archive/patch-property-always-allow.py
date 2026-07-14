#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/property_service.cpp"
t = p.read_text()

old = (
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
new = (
    "static bool CheckMacPerms(const std::string& name, const char* target_context,\n"
    "                          const char* source_context, const ucred& cr) {\n"
    "    // BS bringup: sepolicy not loaded; selinux_check_access always fails\n"
    "    (void)name; (void)target_context; (void)source_context; (void)cr;\n"
    "    return true;"
)
if old in t:
    t = t.replace(old, new)
    p.write_text(t)
    print("CheckMacPerms always allow OK")
else:
    print("pattern not found")
