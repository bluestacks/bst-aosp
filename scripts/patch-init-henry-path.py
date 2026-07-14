#!/usr/bin/env python3
"""Revert bringup /tmp/init hacks; align with Henry 10-aosp-repo-diff (exec /system/bin/init)."""
from pathlib import Path

aosp = Path.home() / "aosp16"
fsi = aosp / "system/core/init/first_stage_init.cpp"
sel = aosp / "system/core/init/selinux.cpp"

# first_stage_init: selinux_setup via /system/bin/init (not /tmp/init)
fsi_text = fsi.read_text()
old_fsi = """    const char* path = "/tmp/init";
    const char* args[] = {path, "selinux_setup", nullptr};"""
new_fsi = """    const char* path = "/system/bin/init";
    const char* args[] = {path, "selinux_setup", nullptr};"""
if old_fsi in fsi_text:
    fsi.write_text(fsi_text.replace(old_fsi, new_fsi, 1))
    print("patched first_stage_init.cpp -> /system/bin/init selinux_setup")
elif new_fsi in fsi_text:
    print("first_stage_init.cpp already Henry path")
else:
    raise SystemExit("first_stage_init.cpp anchor not found")

# selinux.cpp: remove early /tmp/init bypass; restore normal SetupSelinux tail
sel_text = sel.read_text()
old_head = """int SetupSelinux(char** argv) {
    LOG(WARNING) << "SetupSelinux skipped (BS permissive)";
    setenv(kEnvSelinuxStartedAt, std::to_string(std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now().time_since_epoch()).count()).c_str(), 1);
    // BS bringup: skip SELinux policy load, go directly to second_stage
    const char* path = "/tmp/init";
    const char* args[] = {path, "second_stage", nullptr};
    execv(path, const_cast<char**>(args));
    PLOG(FATAL) << "execv() to second_stage failed";
    return 1;

    SetStdioToDevNull(argv);"""

new_head = """int SetupSelinux(char** argv) {
    SetStdioToDevNull(argv);"""

old_tail = """    // SetupOverlays does not return if overlays exist, instead it execs overlay_remounter
    // which then execs second stage init
// BS: moved to top of function

//     const char* path = "/system/bin/init";
//     const char* args[] = {path, "second_stage", nullptr};
//     execv(path, const_cast<char**>(args));

    // execv() only returns if an error happened, in which case we
    // panic and never return from this function.
//     PLOG(FATAL) << "execv(\"" << path << "\") failed";

//     return 1;
}"""

new_tail = """    // SetupOverlays does not return if overlays exist, instead it execs overlay_remounter
    // which then execs second stage init
    if (use_overlays) SetupOverlays();

    const char* path = "/system/bin/init";
    const char* args[] = {path, "second_stage", nullptr};
    execv(path, const_cast<char**>(args));

    // execv() only returns if an error happened, in which case we
    // panic and never return from this function.
    PLOG(FATAL) << "execv(\"" << path << "\") failed";

    return 1;
}"""

if old_head in sel_text:
    sel_text = sel_text.replace(old_head, new_head, 1)
    print("removed SetupSelinux /tmp/init early bypass")
elif "execv() to second_stage failed" not in sel_text:
    print("SetupSelinux head already Henry path")
else:
    raise SystemExit("selinux.cpp SetupSelinux head anchor not found")

if old_tail in sel_text:
    sel_text = sel_text.replace(old_tail, new_tail, 1)
    sel.write_text(sel_text)
    print("restored SetupSelinux /system/bin/init second_stage exec")
elif 'const char* path = "/system/bin/init"' in sel_text and "second_stage" in sel_text:
    sel.write_text(sel_text)
    print("SetupSelinux tail already Henry path")
else:
    raise SystemExit("selinux.cpp SetupSelinux tail anchor not found")

# Henry restorecon message (non-fatal)
sel_text = sel.read_text()
old_rc = 'PLOG(ERROR) << "restorecon of /system/bin/init failed (BlueStacks)";'
henry_rc = 'PLOG(ERROR) << "restorecon of /system/bin/init failed (ignored for BlueStacks ro /system)";'
if old_rc in sel_text:
    sel.write_text(sel_text.replace(old_rc, henry_rc, 1))
    print("updated restorecon log message to Henry wording")
