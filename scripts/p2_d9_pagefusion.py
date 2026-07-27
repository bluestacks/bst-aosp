#!/usr/bin/env python3
# P2 pagefusion fix: a16 bionic compiles ALL modules with -D__BIONIC_NO_PAGE_SIZE_MACRO,
# which intentionally disables the PAGE_SIZE macro (it's not a true compile-time constant).
# So #include <bits/page_size.h> is useless — the macro is suppressed. pagefusion uses PAGE_SIZE
# as a compile-time const (x86_64 guest = 4KB pages, same as a13). Fix: define locally.
# (Replaces the prior useless <bits/page_size.h> include added in the first attempt.)
import os, sys
A16 = os.path.expanduser("~/aosp16")
F = "frameworks/base/cmds/pagefusion/PageFusion.cpp"
full = os.path.join(A16, F)
with open(full) as f: src = f.read()

old_include = "#include <bits/page_size.h>  // A16DBG:P2 a16 bionic: PAGE_SIZE/PAGE_MASK moved out of transitive includes\n"
defines = (
    "// A16DBG:P2 a16 bionic: -D__BIONIC_NO_PAGE_SIZE_MACRO disables the PAGE_SIZE macro globally;\n"
    "// pagefusion uses it as a compile-time const (x86_64 guest = 4KB pages, same as a13).\n"
    "#ifndef PAGE_SIZE\n#define PAGE_SIZE 4096\n#endif\n"
    "#ifndef PAGE_MASK\n#define PAGE_MASK (~(PAGE_SIZE - 1))\n#endif\n"
)

if old_include in src:
    src = src.replace(old_include, defines, 1)
    how = "replaced prior <bits/page_size.h> include"
elif "bits/page_size.h" in src:
    print("ERROR: bits/page_size.h present but anchor mismatch"); sys.exit(1)
elif "#define PAGE_SIZE 4096" in src:
    print("already fixed (PAGE_SIZE defined locally)"); sys.exit(0)
else:
    # fresh: insert after #include <unistd.h>
    anchor = "#include <unistd.h>\n"
    if anchor not in src:
        print("ERROR: no <unistd.h> anchor"); sys.exit(1)
    src = src.replace(anchor, anchor + defines, 1)
    how = "inserted after <unistd.h>"

with open(full, "w") as f: f.write(src)
print(f"OK PageFusion.cpp: local PAGE_SIZE/PAGE_MASK defines ({how})")
