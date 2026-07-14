#!/usr/bin/env python3
"""Parse MINIDUMP_EXCEPTION_STREAM from a Windows minidump (basic, no deps)."""
import struct
import sys
from pathlib import Path

EXCEPTION_NAMES = {
    0xC0000005: "ACCESS_VIOLATION",
    0xC000001D: "ILLEGAL_INSTRUCTION",
    0xC0000094: "INTEGER_DIVIDE_BY_ZERO",
    0xC00000FD: "STACK_OVERFLOW",
    0xE06D7363: "CPP_EH_EXCEPTION",
}


def read_u64(data: bytes, off: int) -> int:
    return struct.unpack_from("<Q", data, off)[0]


def read_u32(data: bytes, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def read_minidump_string(data: bytes, rva: int) -> str:
    if rva == 0 or rva + 4 > len(data):
        return ""
    length = read_u32(data, rva)
    if length == 0 or rva + 4 + length > len(data):
        return ""
    return data[rva + 4 : rva + 4 + length].decode("utf-16le", errors="replace")


def find_module(modules, addr: int):
    for name, base, size in modules:
        if base <= addr < base + size:
            return name, base, addr - base
    return None, 0, 0


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: parse-minidump-exception.py <file.dmp>", file=sys.stderr)
        return 1
    path = Path(sys.argv[1])
    data = path.read_bytes()
    if data[:4] != b"MDMP":
        print(f"not a minidump: {path}")
        return 1
    num_streams = read_u32(data, 8)
    stream_dir = 32
    exc = None
    modules = []
    for i in range(num_streams):
        base = stream_dir + i * 12
        stype = read_u32(data, base)
        dsize = read_u32(data, base + 4)
        rva = read_u32(data, base + 8)
        if stype == 4:  # ModuleListStream
            nmods = read_u32(data, rva)
            mod_off = rva + 4
            # MINIDUMP_MODULE is 108 bytes on x64
            for j in range(nmods):
                mbase = mod_off + j * 108
                mod_base = read_u64(data, mbase + 0)
                mod_size = read_u32(data, mbase + 8)
                name_rva = read_u32(data, mbase + 20)  # ModuleNameRva
                name = read_minidump_string(data, name_rva)
                modules.append((name, mod_base, mod_size))
        if stype == 6:  # ExceptionStream
            thread_id = read_u32(data, rva)
            # MINIDUMP_EXCEPTION_STREAM: ThreadId, __alignment, MINIDUMP_EXCEPTION
            exc_off = rva + 8
            code = struct.unpack_from("<I", data, exc_off)[0]
            flags = struct.unpack_from("<I", data, exc_off + 4)[0]
            record = struct.unpack_from("<Q", data, exc_off + 8)[0]
            addr = struct.unpack_from("<Q", data, exc_off + 16)[0]
            num_params = struct.unpack_from("<I", data, exc_off + 24)[0]
            params = struct.unpack_from("<" + "Q" * 15, data, exc_off + 32)
            exc = (thread_id, code, flags, record, addr, num_params, params)
            break
    if not exc:
        print("no exception stream found")
        return 1
    tid, code, flags, record, addr, nparams, params = exc
    name = EXCEPTION_NAMES.get(code, "UNKNOWN")
    print(f"file: {path}")
    print(f"thread_id: {tid}")
    print(f"exception_code: 0x{code:08X} ({name})")
    print(f"exception_flags: 0x{flags:08X}")
    print(f"exception_record: 0x{record:016X}")
    print(f"exception_address: 0x{addr:016X}")
    if code == 0xC0000005 and nparams >= 2:
        op = params[0]
        addr_fault = params[1]
        ops = {0: "read", 1: "write", 8: "DEP"}
        print(f"access: {ops.get(op, op)}")
        print(f"fault_address: 0x{addr_fault:016X}")
    mod, base, off = find_module(modules, addr)
    if mod:
        mod_ascii = mod.encode("ascii", errors="backslashreplace").decode("ascii")
        print(f"module: {mod_ascii}")
        print(f"module_base: 0x{base:016X}")
        print(f"module_offset: 0x{off:X}")
    elif modules:
        print("module: (unresolved)")
        print("loaded_modules:")
        for name, mbase, msize in modules[:30]:
            n = name.encode("ascii", errors="backslashreplace").decode("ascii")
            print(f"  0x{mbase:016X} size=0x{msize:X} {n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
