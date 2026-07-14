#!/usr/bin/env python3
"""R254: Treat Baklava64 like Tiramisu64 for gcall BUILD_T.

GcallDec.cpp gates gcallCreatorsStudioEffectControlClbk behind
  #if !defined(BUILD_PIE) && !defined(BUILD_RVC) && !defined(BUILD_T)
JNI never implements that Clbk (Henry Tiramisu uses -DBUILD_T).
Without it, libgcall_jni link fails with undefined symbol.
"""
from pathlib import Path
import sys

MK = Path.home() / "app-player/hd/Source/gcall/guest/Android.mk"
if len(sys.argv) > 1:
    MK = Path(sys.argv[1])

text = MK.read_text()
marker = "R254 / Henry 7h Baklava64 BUILD_T"
if marker in text:
    print(f"already patched: {MK}")
    sys.exit(0)

needle = """ifeq ($(IMAGE), Tiramisu64)
	LOCAL_CFLAGS += -DBUILD_T
endif
"""
insert = """ifeq ($(IMAGE), Tiramisu64)
	LOCAL_CFLAGS += -DBUILD_T
endif

# R254 / Henry 7h Baklava64 BUILD_T — same CreatorsStudio gate as Tiramisu
ifeq ($(IMAGE), Baklava64)
	LOCAL_CFLAGS += -DBUILD_T
endif
"""
if needle not in text:
    print("needle not found", file=sys.stderr)
    sys.exit(1)

MK.write_text(text.replace(needle, insert, 1))
print(f"patched {MK}")
