#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/selinux.cpp"
t = p.read_text()
old = """    // SetupOverlays does not return if overlays exist, instead it execs overlay_remounter
    // which then execs second stage init
// BS: moved to top of function

//     const char* path = "/system/bin/init";
//     const char* args[] = {path, "second_stage", nullptr};
//     execv(path, const_cast<char**>(args));

    // execv() only returns if an error happened, in which case we
    // panic and never return from this function.
//     PLOG(FATAL) << "execv(\\"" << path << "\\") failed";

//     return 1;
}"""
new = """    // SetupOverlays does not return if overlays exist, instead it execs overlay_remounter
    // which then execs second stage init
    if (use_overlays) SetupOverlays();

    const char* path = "/system/bin/init";
    const char* args[] = {path, "second_stage", nullptr};
    execv(path, const_cast<char**>(args));

    // execv() only returns if an error happened, in which case we
    // panic and never return from this function.
    PLOG(FATAL) << "execv(\\"" << path << "\\") failed";

    return 1;
}"""
if old not in t:
    if 'if (use_overlays) SetupOverlays();' in t and 'second_stage' in t.split('SetupSelinux')[-1]:
        print("tail already fixed")
    else:
        raise SystemExit("tail anchor missing")
else:
    p.write_text(t.replace(old, new, 1))
    print("fixed SetupSelinux tail")
