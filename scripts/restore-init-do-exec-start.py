#!/usr/bin/env python3
"""Restore upstream do_exec_start in init builtins.cpp (FindService, not MakeTemporaryOneshotService)."""
import os
import re
import sys

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
F = os.path.join(AOSP, "system/core/init/builtins.cpp")
text = open(F).read()

UPSTREAM = """static Result<void> do_exec_start(const BuiltinArguments& args) {
    Service* service = ServiceList::GetInstance().FindService(args[1]);
    if (!service) {
        return Error() << "Service not found";
    }

    if (auto result = service->ExecStart(); !result.ok()) {
        return Error() << "Could not start exec service: " << result.error();
    }

    return {};
}"""

if "FindService(args[1])" in text and "skip ALL exec_start" not in text:
    print("do_exec_start already upstream")
    sys.exit(0)

patched, n = re.subn(
    r"static Result<void> do_exec_start\(const BuiltinArguments& args\) \{.*?\n\}",
    UPSTREAM,
    text,
    count=1,
    flags=re.DOTALL,
)

if n != 1:
    print("ERROR: do_exec_start block not found", file=sys.stderr)
    sys.exit(1)

open(F + ".bak_restore_exec", "w").write(text)
open(F, "w").write(patched)
print("Restored upstream do_exec_start (FindService)")
