#!/usr/bin/env python3
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
wrong = """
\tmkdir -p initrd/boot/dalvik-cache/x86_64
\t@test -f dalvik-cache/x86_64/boot.art && cp -a dalvik-cache/x86_64/. initrd/boot/dalvik-cache/x86_64/ || (echo "missing dalvik-cache/x86_64/boot.art" && exit 1)"""
text = text.replace(wrong, "", 1)
dalvik_block = """
\tmkdir -p initrd/boot/dalvik-cache/x86_64
\t@test -f dalvik-cache/x86_64/boot.art && cp -a dalvik-cache/x86_64/. initrd/boot/dalvik-cache/x86_64/ || (echo "missing dalvik-cache/x86_64/boot.art" && exit 1)"""
if "initrd/boot/dalvik-cache" not in text:
    anchor = "\tcp art-payload.img initrd/boot/art-payload.img"
    if anchor not in text:
        raise SystemExit("anchor not found")
    text = text.replace(anchor, anchor + dalvik_block, 1)
    print("fixed: dalvik in initrd.img recipe")
else:
    print("dalvik already in initrd.img recipe")
mk.write_text(text)
