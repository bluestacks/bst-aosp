#!/usr/bin/env python3
import sys

target = sys.argv[1] if len(sys.argv) > 1 else "init/selinux.cpp"

with open(target, "r") as f:
    content = f.read()

# Add SetupSelinux skip - early return
old = 'int SetupSelinux(char** argv) {\n    SetStdioToDevNull(argv);'
new = '''int SetupSelinux(char** argv) {
    // BlueStacks: skip SELinux entirely (no policy)
    LOG(WARNING) << "SetupSelinux skipped (BlueStacks permissive mode)";
    setenv(kEnvSelinuxStartedAt, std::to_string(
        std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count()).c_str(), 1);
    return 0;

    SetStdioToDevNull(argv);'''
content = content.replace(old, new)

# Fix indentation of IsEnforcing return false (if it's on same line)
content = content.replace(
    'bool IsEnforcing() {\nreturn false;',
    'bool IsEnforcing() {\n    return false;')

with open(target, "w") as f:
    f.write(content)
print("SELINUX_SKIP_FIXED")
