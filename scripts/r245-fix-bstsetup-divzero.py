#!/usr/bin/env python3
"""R245: Guard bstsetup.env random propfile selection against totalfiles=0 (divide by zero)."""
from pathlib import Path
import re

paths = [
    Path.home() / "app-player/hd/guest/BootImage/bstsetup.env",
    Path.home() / "app-player/hd/guest/BootImage/initrd/boot/bstsetup.env",
]

# Replace: y=$(($x%$totalfiles+1))  with safe form that uses 1 when empty
# and ensure callers still fall through when totalfiles=0 via existing empty propfile checks.
# Safer: if totalfiles is 0, set y=1 but ls|sed will yield empty -> existing fallbacks.
# Best: wrap the arithmetic:
#   if [ "$totalfiles" -eq 0 ]; then y=0; else y=$(($x%$totalfiles+1)); fi

pat = re.compile(
    r"(totalfiles=`[^`]+`\n"
    r"\s*RANDOM=`date '\+%s'`\n"
    r"\s*x=\$RANDOM\n)"
    r"\s*y=\$\(\(\$x%\$totalfiles\+1\)\)\n",
    re.M,
)

repl = (
    r"\1"
    r"            if [ \"$totalfiles\" -eq 0 ]; then\n"
    r"                y=0\n"
    r"            else\n"
    r"                y=$(($x%$totalfiles+1))\n"
    r"            fi\n"
)

for p in paths:
    if not p.exists():
        print(f"SKIP missing {p}")
        continue
    t = p.read_text()
    t2, n = pat.subn(repl, t)
    if n == 0:
        # try already-patched
        if 'if [ "$totalfiles" -eq 0 ]' in t:
            print(f"ALREADY {p}")
            continue
        print(f"NO_MATCH {p}")
        # show nearby
        for i, ln in enumerate(t.splitlines(), 1):
            if "totalfiles=" in ln and "wc -l" in ln:
                print(i, ln)
        continue
    bak = p.with_suffix(p.suffix + ".bak-r245")
    bak.write_text(t)
    p.write_text(t2)
    print(f"PATCHED {p} n={n}")

print("DONE")
