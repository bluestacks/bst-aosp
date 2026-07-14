#!/usr/bin/env python3
"""BS bringup patches: cgroup tolerance, skip reboot_on_failure, createProcessGroup."""
from pathlib import Path

# 1. SetupCgroupsAction: warn and continue
p = Path.home() / "aosp16/system/core/init/init.cpp"
t = p.read_text()
old = (
    "    if (!CgroupSetup()) {\n"
    "        return ErrnoError() << \"Failed to setup cgroups\";\n"
    "    }"
)
new = (
    "    if (!CgroupSetup()) {\n"
    "        LOG(WARNING) << \"Failed to setup cgroups (BS bringup continue)\";\n"
    "        return {};\n"
    "    }"
)
if old in t:
    t = t.replace(old, new)
    p.write_text(t)
    print("init.cpp cgroup OK")
else:
    print("init.cpp cgroup already patched")

# 2. createProcessGroup failure -> warn continue
p = Path.home() / "aosp16/system/core/init/service.cpp"
t = p.read_text()
old = (
    "        if (errno != 0) {\n"
    "            Result<void> result = cgroups_activated.Write(kActivatingCgroupsFailed);\n"
    "            if (!result.ok()) {\n"
    "                return Error() << \"Sending notification failed: \" << result.error();\n"
    "            }\n"
    "            return Error() << \"createProcessGroup(\" << uid() << \", \" << pid_ << \", \" << use_memcg\n"
    "                           << \") failed for service '\" << name_ << \"': \" << strerror(errno);\n"
    "        }\n"
    "\n"
    "        // When the blkio controller"
)
new = (
    "        if (errno != 0) {\n"
    "            LOG(WARNING) << \"createProcessGroup failed for '\" << name_\n"
    "                       << \"' (BS bringup continue): \" << strerror(errno);\n"
    "        }\n"
    "\n"
    "        // When the blkio controller"
)

if old in t:
    t = t.replace(old, new)
    p.write_text(t)
    print("service.cpp cgroup OK")
else:
    print("service.cpp cgroup pattern not found")

p = Path.home() / "aosp16/system/core/init/service.cpp"
t = p.read_text()
old = (
    "    if ((siginfo.si_code != CLD_EXITED || siginfo.si_status != 0) && on_failure_reboot_target_) {\n"
    "        LOG(ERROR) << \"Service \" << name_\n"
    "                   << \" has 'reboot_on_failure' option and failed, shutting down system.\";\n"
    "        trigger_shutdown(*on_failure_reboot_target_);\n"
    "    }"
)
new = (
    "    if ((siginfo.si_code != CLD_EXITED || siginfo.si_status != 0) && on_failure_reboot_target_) {\n"
    "        LOG(WARNING) << \"Service \" << name_\n"
    "                   << \" reboot_on_failure ignored (BS bringup)\";\n"
    "    }"
)
if old in t:
    t = t.replace(old, new)
    p.write_text(t)
    print("service.cpp reboot_on_failure OK")
else:
    print("service.cpp reboot_on_failure already patched")

# 4. ExecStart reboot_on_failure guard
old2 = (
    "    auto reboot_on_failure = make_scope_guard([this] {\n"
    "        if (on_failure_reboot_target_) {\n"
    "            trigger_shutdown(*on_failure_reboot_target_);\n"
    "        }\n"
    "    });"
)
new2 = (
    "    auto reboot_on_failure = make_scope_guard([this] {\n"
    "        if (on_failure_reboot_target_) {\n"
    "            LOG(WARNING) << \"ExecStart reboot_on_failure ignored for \" << name_ << \" (BS bringup)\";\n"
    "        }\n"
    "    });"
)
t = p.read_text()
if old2 in t:
    t = t.replace(old2, new2)
    p.write_text(t)
    print("service.cpp ExecStart guard OK")
