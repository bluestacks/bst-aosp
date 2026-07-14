#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/frameworks/native/cmds/servicemanager/ServiceManager.cpp"
text = p.read_text()
old = """#ifndef VENDORSERVICEMANAGER
    if (!meetsDeclarationRequirements(ctx, binder, name)) {
        // already logged
        return Status::fromExceptionCode(Status::EX_ILLEGAL_ARGUMENT, "VINTF declaration error.");
    }
#endif  // !VENDORSERVICEMANAGER"""
new = """#ifndef VENDORSERVICEMANAGER
    if (!meetsDeclarationRequirements(ctx, binder, name)) {
        LOG(WARNING) << "VINTF declaration missing for " << name << " (BS bringup continue)";
    }
#endif  // !VENDORSERVICEMANAGER"""
if "BS bringup continue" not in text:
    if old not in text:
        raise SystemExit("ServiceManager.cpp pattern not found")
    p.write_text(text.replace(old, new, 1))
    print("patched ServiceManager.cpp")
else:
    print("already patched")
