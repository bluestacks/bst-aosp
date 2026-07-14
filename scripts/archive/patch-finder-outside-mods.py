#!/usr/bin/env python3
"""Align finder.go outsideModList with Henry 10-aosp-repo-diff.patch."""
from pathlib import Path

finder = Path.home() / "aosp16/build/soong/ui/build/finder.go"
text = finder.read_text()

henry_list = """\t// BlueStacks: out-of-tree Android.mk paths (same as android-13 app-player).
\toutsideModList := []string{
\t\t"../hd/Source/vmsg/guest/Android.mk",
\t\t"../hd/Source/xpl/Android.mk",
\t\t"../hd/Source/tools/bstconf/Android.mk",
\t\t"../hd/Source/tools/bstchkdata/Android.mk",
\t\t"../hd/Source/hcall/guest/Android.mk",
\t\t"../hd/Source/gcall/guest/Android.mk",
\t\t"../ggl/goldfish-opengl-pie/Android.mk",
\t}
\tfor _, outsideMod := range outsideModList {
\t\tandroidMks = append(androidMks, outsideMod)
\t}"""

# Replace any existing outsideModList block
import re
pat = re.compile(
    r"\t// BlueStacks: out-of-tree Android\.mk paths.*?\n\tfor _, outsideMod := range outsideModList \{\n\t\tandroidMks = append\(androidMks, outsideMod\)\n\t\}",
    re.DOTALL,
)
if pat.search(text):
    text = pat.sub(henry_list, text, count=1)
    finder.write_text(text)
    print("patched finder.go outsideModList (Henry full list)")
elif "../hd/Source/tools/bstconf/Android.mk" in text:
    print("finder.go already has Henry outsideModList")
else:
    raise SystemExit("outsideModList anchor not found in finder.go")

mk = Path.home() / "app-player/buildscripts/Makefile"
mtext = mk.read_text()
old_opt = """\tif [ -f $(ANDROIDOUT)/system/out_bstconf/bstconf ]; then \\
\t\tcp $(ANDROIDOUT)/system/out_bstconf/bstconf $(BASEPATH)/hd/guest/BootImage/; \\
\telse \\
\t\techo "bstconf not in ANDROIDOUT, using existing BootImage/bstconf"; \\
\tfi
\tif [ -f $(ANDROIDOUT)/system/out_bstchkdata/bstchkdata ]; then \\
\t\tcp $(ANDROIDOUT)/system/out_bstchkdata/bstchkdata $(BASEPATH)/hd/guest/BootImage/; \\
\telse \\
\t\techo "bstchkdata not in ANDROIDOUT, using existing BootImage/bstchkdata"; \\
\tfi"""
henry_cp = """\tcp $(ANDROIDOUT)/system/out_bstconf/bstconf $(BASEPATH)/hd/guest/BootImage/ || exit 1
\tcp $(ANDROIDOUT)/system/out_bstchkdata/bstchkdata $(BASEPATH)/hd/guest/BootImage/ || exit 1"""
if old_opt in mtext:
    mk.write_text(mtext.replace(old_opt, henry_cp, 1))
    print("restored Henry hard cp for bstconf/bstchkdata")
elif henry_cp.split("\n")[0] in mtext:
    print("Makefile bstconf cp already Henry style")
else:
    raise SystemExit("bstconf Makefile anchor not found")
