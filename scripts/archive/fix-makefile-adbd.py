#!/usr/bin/env python3
from pathlib import Path

mk = Path.home() / "app-player/buildscripts/Makefile"
text = mk.read_text()
bad = """$(call copy,$(ANDROIDOUT)/system,$(OUTPUTDIR)/)
ifeq ($(ANDROID_VERSION),baklava)
\t$(call copy,$(BSTTOOLS)/tiramisu/adbd_rooted_tiramisu,$(OUTPUTDIR)/system/bin/adbd)
endif
[ -d $(ANDROIDOUT)/installer ]"""
good = """$(call copy,$(ANDROIDOUT)/system,$(OUTPUTDIR)/)
[ -d $(ANDROIDOUT)/installer ]"""
if bad in text:
    text = text.replace(bad, good, 1)
    print("removed bad ifeq from define")
anchor = "\t$(call  copy_android_files_to_outputdir)\nifeq ($(ANDROID_VERSION),nougat)"
insert = """\t$(call  copy_android_files_to_outputdir)
ifeq ($(ANDROID_VERSION),baklava)
\t$(call copy,$(BSTTOOLS)/tiramisu/adbd_rooted_tiramisu,$(OUTPUTDIR)/system/bin/adbd)
endif
ifeq ($(ANDROID_VERSION),nougat)"""
if "adbd_rooted_tiramisu" not in text:
    if anchor not in text:
        raise SystemExit("Root.vdi anchor missing")
    text = text.replace(anchor, insert, 1)
    print("added adbd to Root.vdi recipe")
else:
    print("adbd patch already present")
mk.write_text(text)
