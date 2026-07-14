#!/usr/bin/env python3
"""Patch stage2.sh for R171d: fix odsign wait loop hang on VBox.

Root cause: busybox sleep + getprop hang the VM on VirtualBox.
Fix: use file flag instead of getprop, remove sleep loop, have bs-earlyboot
      directly trigger odsign after setting the flag.
"""

STAGE2 = "/home/clouddev/bst/workspace/markxu/app-player/hd/guest/BootImage/stage2.sh"

with open(STAGE2, "r") as f:
    content = f.read()

# Fix 1: Replace setprop with touch flag in bs-earlyboot
old_setprop = '[ -x "$SETPROP" ] && "$SETPROP" sys.bs.earlyboot.done 1'
new_setprop = 'touch /data/bs-earlyboot.done && echo "<0>A16DBG: henry-7R-bs-earlyboot.done flag set" > /dev/kmsg'
assert old_setprop in content, "Fix 1: setprop line not found!"
content = content.replace(old_setprop, new_setprop)

# Fix 2: Add odsign trigger after flag set in bs-earlyboot (before exit $rc)
old_exit_line = 'touch /data/bs-earlyboot.done && echo "<0>A16DBG: henry-7R-bs-earlyboot.done flag set" > /dev/kmsg\nexit $rc'
new_exit_line = 'touch /data/bs-earlyboot.done && echo "<0>A16DBG: henry-7R-bs-earlyboot.done flag set" > /dev/kmsg\n# R171d: trigger odsign directly after earlyboot flag set (avoid sleep hangs on VBox)\necho "<0>A16DBG: henry-7R triggering odsign after earlyboot" > /dev/kmsg\nif [ -x /vendor/bin/bs-odsign.sh ]; then /vendor/bin/bs-odsign.sh & fi\nexit $rc'
assert old_exit_line in content, "Fix 2: exit line not found!"
content = content.replace(old_exit_line, new_exit_line)

# Fix 3: Replace getprop wait loop with simple flag check
old_loop_start = 'GETPROP=/data/system_bin/getprop'
old_loop_end_marker = 'echo "<0>A16DBG: henry-7BD odsign post-earlyboot wait=${_w}s done=$("$GETPROP" sys.bs.earlyboot.done 2>/dev/null)" > /dev/kmsg'
assert old_loop_start in content, "Fix 3: wait loop start not found!"
assert old_loop_end_marker in content, "Fix 3: wait loop end not found!"

new_check = '# R171d: no wait loop (sleep hangs on VBox). bs-earlyboot triggers odsign directly after setting flag.\nif [ ! -f /data/bs-earlyboot.done ]; then\n    echo "<0>A16DBG: henry-7BD odsign skip: earlyboot.done flag not set (bs-earlyboot will trigger)" > /dev/kmsg\n    exit 0\nfi\necho "<0>A16DBG: henry-7BD odsign earlyboot flag found, proceeding" > /dev/kmsg'

idx_start = content.find(old_loop_start)
idx_end = content.find(old_loop_end_marker) + len(old_loop_end_marker)
content = content[:idx_start] + new_check + content[idx_end:]

with open(STAGE2, "w") as f:
    f.write(content)

print("Patched successfully")

# Verify
with open(STAGE2, "r") as f:
    verify = f.read()
checks = [
    "bs-earlyboot.done flag set",
    "triggering odsign after earlyboot",
    "odsign skip: earlyboot.done flag not set",
]
for c in checks:
    assert c in verify, f"VERIFY FAILED: {c}"
print("All checks passed")
