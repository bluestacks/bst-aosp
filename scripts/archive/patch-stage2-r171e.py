#!/usr/bin/env python3
"""Patch stage2.sh for R171e: odsign runs earlyBootEnded inline.

Root cause: vendor init.rc bs-earlyboot trigger never executes (R117/7BL issue).
Fix: bs-odsign runs earlyBootEnded directly (no sleep, no wait loop).
     If earlyBootEnded fails, proceed anyway (R126 keystore2 bypass handles perm).
"""

STAGE2 = "/home/clouddev/bst/workspace/markxu/app-player/hd/guest/BootImage/stage2.sh"

with open(STAGE2, "r") as f:
    content = f.read()

# Replace the skip-exit block in bs-odsign with inline earlyBootEnded
old_skip = '''# R171d: no wait loop (sleep hangs on VBox). bs-earlyboot triggers odsign directly after setting flag.
if [ ! -f /data/bs-earlyboot.done ]; then
    echo "<0>A16DBG: henry-7BD odsign skip: earlyboot.done flag not set (bs-earlyboot will trigger)" > /dev/kmsg
    exit 0
fi
echo "<0>A16DBG: henry-7BD odsign earlyboot flag found, proceeding" > /dev/kmsg'''

new_inline = '''# R171e: run earlyBootEnded inline (vendor init.rc 7BL never executes).
# No sleep/wait loops - all syscalls that sleep hang on VBox.
if [ ! -f /data/bs-earlyboot.done ]; then
    echo "<0>A16DBG: henry-7R inline earlyBootEnded running" > /dev/kmsg
    _VDC=/data/system_bin/vdc
    [ -x "$_VDC" ] || _VDC=/system/bin/vdc
    _LNK=/system/bin/bootstrap/linker64
    if [ -x "$_LNK" ] && [ -x "$_VDC" ]; then
        "$_LNK" "$_VDC" keymaster earlyBootEnded 2>/tmp/eb_inline.err
        _rc=$?
        echo "<0>A16DBG: henry-7R inline earlyBootEnded rc=$_rc" > /dev/kmsg
    else
        echo "<3>A16DBG: henry-7R inline earlyBootEnded SKIP: vdc=$([ -x $_VDC ] && echo ok || echo missing) linker=$([ -x $_LNK ] && echo ok || echo missing)" > /dev/kmsg
    fi
    touch /data/bs-earlyboot.done
fi
echo "<0>A16DBG: henry-7BD odsign proceeding to odsign binary" > /dev/kmsg'''

assert old_skip in content, "old skip block not found!"
content = content.replace(old_skip, new_inline)

with open(STAGE2, "w") as f:
    f.write(content)

print("R171e patched successfully")

# Verify
with open(STAGE2, "r") as f:
    verify = f.read()
assert "inline earlyBootEnded" in verify
assert "odsign proceeding" in verify
print("Verification passed")
