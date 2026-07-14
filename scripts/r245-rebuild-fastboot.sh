#!/bin/bash
# R245: rebuild initrd/fastboot with patched bstsetup; videobuf optional
set -eo pipefail
cd ~/app-player/hd/guest/BootImage
LOG=~/r245-rebuild-fastboot.log
exec > >(tee "$LOG") 2>&1
echo "=== R245 rebuild $(date) ==="

# Make videobuf copy non-fatal if missing (camera optional for boot.art path)
if [ -f Makefile ] && grep -q 'videobuf-core.ko' Makefile; then
  cp -a Makefile Makefile.bak-r245
  # comment out hard fail lines for videobuf if file missing
  python3 - <<'PY'
from pathlib import Path
p = Path("Makefile")
lines = p.read_text().splitlines(True)
out = []
for ln in lines:
    if "videobuf-core.ko" in ln and ln.strip().startswith("cp "):
        out.append("\t-[ -f /drivers/media/v4l2-core/videobuf-core.ko ] && " + ln.lstrip()[0:].replace("\tcp ", "cp ", 1) if False else "")
        # simpler: prefix with - to ignore errors in make
        if ln.startswith("\tcp "):
            out.append(ln.replace("\tcp ", "\t-cp ", 1))
        else:
            out.append(ln)
    else:
        out.append(ln)
p.write_text("".join(out))
print("Makefile videobuf made optional")
PY
fi

# ensure bstsetup quotes fixed
python3 ~/r245-fix-bstsetup-quotes.py

make initrd.img
echo INITRD_OK
ls -la initrd.img initrd/boot/bstsetup.env
rg -n 'totalfiles.*eq 0' initrd/boot/bstsetup.env | head

# build fastboot
make build_fastboot
echo FASTBOOT_OK
find . -name 'fastboot.vdi' -o -name 'fastboot.vhd' | head
# deploy to releases
OUT=~/releases/Baklava64/bst-v5.22.210_Baklava64-local
if [ -f fastboot/fastboot.vdi ]; then
  cp -a fastboot/fastboot.vdi "$OUT/fastboot.vdi"
elif [ -f fastboot.vdi ]; then
  cp -a fastboot.vdi "$OUT/fastboot.vdi"
fi
md5sum "$OUT/fastboot.vdi"
ls -la "$OUT/fastboot.vdi"
echo REBUILD_DONE
