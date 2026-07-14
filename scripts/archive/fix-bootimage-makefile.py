#!/usr/bin/env python3
from pathlib import Path

mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
text = text.replace("tcp bs_bootlog.sh", "\tcp bs_bootlog.sh")
anchor = "\tcp stage2.sh initrd/boot/stage2.sh\n"
ins = anchor + "\tcp bs_bootlog.sh initrd/boot/bin/bs_bootlog.sh\n\tchmod 755 initrd/boot/bin/bs_bootlog.sh\n"
if "bs_bootlog.sh initrd" not in text:
    text = text.replace(anchor, ins, 1)
mk.write_text(text)
print("Makefile fixed")
