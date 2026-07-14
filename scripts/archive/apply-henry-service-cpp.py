#!/usr/bin/env python3
"""Align service.cpp with henry reference (10-aosp-repo-diff.patch)."""
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/service.cpp"
t = p.read_text()

# henry: domain transition failure -> skip on __ANDROID__
old = (
    "    if (rc == 0 && computed_context == mycon.get()) {\n"
    "        return Error() << \"File \" << service_path << \"(labeled \\\"\" << filecon.get()\n"
    "                       << \"\\\") has incorrect label or no domain transition from \" << mycon.get()\n"
    "                       << \" to another SELinux domain defined. Have you configured your \"\n"
    "                          \"service correctly? https://source.android.com/security/selinux/\"\n"
    "                          \"device-policy#label_new_services_and_address_denials. Note: this \"\n"
    "                          \"error shows up even in permissive mode in order to make auditing \"\n"
    "                          \"denials possible.\";\n"
    "    }"
)
new = (
    "    if (rc == 0 && computed_context == mycon.get()) {\n"
    "#if defined(__ANDROID__)\n"
    "        LOG(WARNING) << \"File \" << service_path << \"(labeled \\\"\" << filecon.get()\n"
    "                     << \"\\\") has incorrect label or no domain transition from \" << mycon.get()\n"
    "                     << \" to another SELinux domain defined.\";\n"
    "        return \"skip\";\n"
    "#else\n"
    "        return Error() << \"File \" << service_path << \"(labeled \\\"\" << filecon.get()\n"
    "                       << \"\\\") has incorrect label or no domain transition from \" << mycon.get()\n"
    "                       << \" to another SELinux domain defined. Have you configured your \"\n"
    "                          \"service correctly? https://source.android.com/security/selinux/\"\n"
    "                          \"device-policy#label_new_services_and_address_denials. Note: this \"\n"
    "                          \"error shows up even in permissive mode in order to make auditing \"\n"
    "                          \"denials possible.\";\n"
    "#endif\n"
    "    }"
)
if old in t:
    t = t.replace(old, new)
    p.write_text(t)
    print("henry domain-transition skip applied")
else:
    print("domain-transition block already patched or not found")
