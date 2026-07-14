#!/usr/bin/env python3
"""Fix xpl std::format ambiguity with clang-r563880 libc++ (A16 libs build)."""
from pathlib import Path

xerr = Path.home() / "app-player/hd/Source/xpl/include/Xerr.h"
xfmt = Path.home() / "app-player/hd/Source/xpl/include/Xfmt.h"

# Xerr.h: avoid std::format<int, string> in error_code helper
xerr_text = xerr.read_text()
old_err = '    return xfmtFormat("{{{}, {}}}", a.value(), a.message());'
new_err = '    return string("{") + std::to_string(a.value()) + ", " + a.message() + "}";'
if old_err in xerr_text:
    xerr.write_text(xerr_text.replace(old_err, new_err, 1))
    print("patched Xerr.h")
elif new_err in xerr_text:
    print("Xerr.h already patched")
else:
    raise SystemExit("Xerr.h anchor not found")

# Xfmt.h: int32_t formatter must not call std::format<int> (recursive ambiguity)
xfmt_text = xfmt.read_text()
old_fmt = """XFMT_SPECIALIZE_FOR_REF(int32_t, [](int32_t arg) { return std::format("{}", static_cast<int>(arg)); });
XFMT_SPECIALIZE_FOR_REF(volatile int32_t, [](int32_t arg) { return std::format("{}", static_cast<int>(arg)); });"""
new_fmt = """XFMT_SPECIALIZE_FOR_REF(int32_t, [](int32_t arg) { return std::to_string(static_cast<int>(arg)); });
XFMT_SPECIALIZE_FOR_REF(volatile int32_t, [](int32_t arg) { return std::to_string(static_cast<int>(arg)); });"""
if old_fmt in xfmt_text:
    xfmt.write_text(xfmt_text.replace(old_fmt, new_fmt, 1))
    print("patched Xfmt.h int32_t formatters")
elif new_fmt in xfmt_text:
    print("Xfmt.h already patched")
else:
    raise SystemExit("Xfmt.h anchor not found")
