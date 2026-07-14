#!/usr/bin/env python3
"""Root.fs: Baklava64 uses android/system.sfs (henry) instead of android/system/ tree."""
from pathlib import Path

mk = Path.home() / "app-player/buildscripts/Makefile"
text = mk.read_text()
anchor = "$(call copy,$(OUTPUTDIR)/$(3),$(OUTPUTDIR)/$(2)/android/system)"
if "make-baklava-system-sfs.sh" in text:
    print("Makefile system.sfs patch already present")
    raise SystemExit(0)
if anchor not in text:
    raise SystemExit("create_rootfs system copy anchor not found")
replacement = """if [ \"$(IMAGE)\" = \"Baklava64\" ]; then \\
\tbash -x $(BUILD_SCRIPT_PATH)/make-baklava-system-sfs.sh $(OUTPUTDIR) || exit 1; \\
\t$(call copy,$(OUTPUTDIR)/system.sfs,$(OUTPUTDIR)/$(2)/android/); \\
else \\
\t$(call copy,$(OUTPUTDIR)/$(3),$(OUTPUTDIR)/$(2)/android/system); \\
fi
$(call copy,$(OUTPUTDIR)/$(4),$(OUTPUTDIR)/$(2)/)
if [ \"$(IMAGE)\" != \"Baklava64\" ]; then \\
\tsudo chown 0:0 $(OUTPUTDIR)/$(2)/android/system/xbin/bstk/su || exit 1; \\
\tsudo chmod 06755 $(OUTPUTDIR)/$(2)/android/system/xbin/bstk/su || exit 1; \\
\tsudo chmod 0111 $(OUTPUTDIR)/$(2)/android/system/xbin/bstk/ || exit 1; \\
fi"""
text = text.replace(anchor, replacement, 1)
mk.write_text(text)
print("Makefile: Baklava64 -> system.sfs in create_rootfs")
