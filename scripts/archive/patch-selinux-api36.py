#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/selinux.cpp"
t = p.read_text()

t = t.replace(
    'LOG(WARNING) << "Could not read vendor SELinux version (BS bringup default)";\n'
    '            return __ANDROID_API_FUTURE__;',
    'LOG(WARNING) << "Could not read vendor SELinux version (BS bringup default)";\n'
    '            return 36;  // Android 16 API level',
)

p.write_text(t)
print("vendor API level -> 36 OK")
