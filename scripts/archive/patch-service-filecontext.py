#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/service.cpp"
t = p.read_text()

old = (
    '    if (getfilecon(service_path.c_str(), &raw_filecon) == -1) {\n'
    '        return Error() << "Could not get file context";\n'
    '    }'
)
new = (
    '    if (getfilecon(service_path.c_str(), &raw_filecon) == -1) {\n'
    '        LOG(WARNING) << "Could not get file context for " << service_path\n'
    '                   << " (BS bringup skip)";\n'
    '        return "skip";\n'
    '    }'
)
if old in t:
    p.write_text(t.replace(old, new))
    print("service.cpp file context skip OK")
else:
    print("pattern not found")
