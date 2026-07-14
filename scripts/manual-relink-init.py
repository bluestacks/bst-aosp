#!/usr/bin/env python3
"""Manual rebuild init_second_stage: recompile builtins.cpp into libinit.a and relink (no soong regen)."""
import os
import re
import subprocess
import sys

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
OUT = "out"
OUT_NXT = "out_nxt_Baklava64"
INSTALL_OUT = os.environ.get("INSTALL_OUT", OUT_NXT)

os.chdir(AOSP)

NINJA_MAIN = f"{OUT}/soong/build.aosp_x86_64.ninja"
NINJA_INC = f"{OUT}/soong/build.aosp_x86_64.incremental.ninja"
CFLAG_KEY = "m.libinit_android_x86_64_static.cFlags1"

BUILTINS_SRC = "system/core/init/builtins.cpp"
BUILTINS_OBJ = (
    f"{OUT}/soong/.intermediates/system/core/init/libinit/android_x86_64_static/"
    "obj/system/core/init/builtins.o"
)
LIBINIT_A = (
    f"{OUT}/soong/.intermediates/system/core/init/libinit/android_x86_64_static/libinit.a"
)
# Henry pack / install paths use out_nxt tree
LIBINIT_A_NXT = (
    f"{OUT_NXT}/soong/.intermediates/system/core/init/libinit/android_x86_64_static/libinit.a"
)
INIT_UNSTRIPPED = (
    f"{OUT_NXT}/soong/.intermediates/system/core/init/init_second_stage/"
    "android_x86_64/unstripped/init"
)
INIT_RSP = f"{INIT_UNSTRIPPED}.rsp"
INIT_OUT = (
    f"{OUT_NXT}/soong/.intermediates/system/core/init/init_second_stage/android_x86_64/init"
)
NINJA_MAIN_NXT = f"{OUT_NXT}/soong/build.android_x86_64.ninja"
NINJA_INC_NXT = f"{OUT_NXT}/soong/build.android_x86_64.incremental.ninja"
INIT_UNSTRIPPED_TARGET = (
    f"{OUT_NXT}/soong/.intermediates/system/core/init/init_second_stage/"
    "android_x86_64/unstripped/init"
)
INIT_INSTALL = f"{OUT_NXT}/target/product/x86_64/system/bin/init"
REL_INIT = os.path.expanduser("~/releases/Baklava64/system/bin/init")

CLANG_BIN = os.path.join(AOSP, "prebuilts/clang/host/linux-x86/clang-r563880c/bin/clang++")
LLVM_AR = os.path.join(AOSP, "prebuilts/clang/host/linux-x86/clang-r563880/bin/llvm-ar")


def load_vars(path: str) -> dict[str, str]:
    vars_: dict[str, str] = {}
    with open(path, "r", errors="replace") as f:
        for line in f:
            if " = " not in line or line.startswith(" "):
                continue
            k, _, v = line.partition(" = ")
            k = k.strip()
            if re.match(r"^[gm]\.", k):
                vars_[k] = v.rstrip("\n")
    return vars_


def expand(s: str, vars_: dict[str, str], depth: int = 0) -> str:
    if depth > 20:
        raise RuntimeError("variable expansion too deep")
    prev = None
    while prev != s:
        prev = s
        for m in re.finditer(r"\$\{([^}]+)\}", s):
            key = m.group(1)
            if key not in vars_:
                raise KeyError(f"undefined ninja var: {key}")
            s = s.replace("${" + key + "}", vars_[key])
    return s


def extract_cflags() -> str:
    vars_ = load_vars(NINJA_MAIN)
    with open(NINJA_INC, "r", errors="replace") as f:
        for line in f:
            if line.startswith(f"{CFLAG_KEY} ="):
                raw = line.split("=", 1)[1].strip()
                return expand(raw, vars_)
    raise RuntimeError(f"{CFLAG_KEY} not found in {NINJA_INC}")


def extract_link_args() -> tuple[list[str], str, str]:
    vars_ = load_vars(NINJA_MAIN_NXT)
    with open(NINJA_INC_NXT, "r", errors="replace") as f:
        content = f.read()
    marker = INIT_UNSTRIPPED_TARGET
    idx = content.find(marker)
    if idx < 0:
        raise RuntimeError(f"{marker} not found in incremental ninja")
    block = content[idx : idx + 12000]
    ldflags = crt_begin = crt_end = None
    for line in block.splitlines():
        s = line.strip()
        if s.startswith("ldFlags ="):
            ldflags = s.split("=", 1)[1].strip()
        elif s.startswith("crtBegin ="):
            crt_begin = s.split("=", 1)[1].strip()
        elif s.startswith("crtEnd ="):
            crt_end = s.split("=", 1)[1].strip()
        elif s.startswith("build ") and ldflags:
            break
    if not all((ldflags, crt_begin, crt_end)):
        raise RuntimeError("init_second_stage link args not found in incremental ninja")

    def resolve(p: str) -> str:
        return p if os.path.isabs(p) else os.path.join(AOSP, p)

    flags: list[str] = []
    parts = expand(ldflags, vars_).split()
    i = 0
    while i < len(parts):
        p = parts[i]
        if p in ("-target", "-B") and i + 1 < len(parts):
            flags.extend([p, parts[i + 1]])
            i += 2
            continue
        if p.startswith("-"):
            flags.append(p)
        elif "/" in p or p.endswith((".o", ".a", ".so")):
            flags.append(resolve(p))
        else:
            flags.append(p)
        i += 1
    return flags, resolve(crt_begin), resolve(crt_end)


def run(cmd: list[str], **kw):
    print("+", " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True, **kw)


def main() -> int:
    src = open("system/core/init/builtins.cpp").read()
    if "skip ALL exec_start" in src:
        print("ERROR: builtins.cpp still has exec_start skip", file=sys.stderr)
        return 1
    if "Could not create exec service" in src and "FindService(args[1])" not in src:
        print("ERROR: builtins.cpp has wrong do_exec_start (MakeTemporaryOneshotService)", file=sys.stderr)
        return 1
    if "FindService(args[1])" not in src:
        print("ERROR: builtins.cpp missing upstream do_exec_start", file=sys.stderr)
        return 1

    cflags = extract_cflags().split()
    # Replace out/soong with actual OUT path for includes
    cflags = [c.replace("out/soong", f"{OUT}/soong") for c in cflags]

    os.makedirs(os.path.dirname(BUILTINS_OBJ), exist_ok=True)
    run([CLANG_BIN, "-c", os.path.abspath(BUILTINS_SRC), "-o", os.path.abspath(BUILTINS_OBJ)] + cflags)

    import shutil
    import tempfile

    for liba in (LIBINIT_A, LIBINIT_A_NXT):
        if not os.path.isfile(liba):
            print(f"skip missing {liba}")
            continue
        with tempfile.TemporaryDirectory() as td:
            run([LLVM_AR, "x", os.path.abspath(liba)], cwd=td)
            shutil.copy2(os.path.abspath(BUILTINS_OBJ), os.path.join(td, "builtins.o"))
            objs = sorted(f for f in os.listdir(td) if f.endswith(".o"))
            tmp_ar = os.path.join(td, "libinit.a.new")
            run([LLVM_AR, "rcs", tmp_ar] + objs, cwd=td)
            shutil.copy2(tmp_ar, os.path.abspath(liba))
        print(f"updated {liba}")

    os.makedirs(os.path.dirname(INIT_UNSTRIPPED), exist_ok=True)
    ldflags, crt_begin, crt_end = extract_link_args()
    rsp_path = os.path.abspath(INIT_RSP)
    run([
        CLANG_BIN,
        crt_begin,
        f"@{rsp_path}",
        crt_end,
        "-o", os.path.abspath(INIT_UNSTRIPPED),
    ] + ldflags)

    os.makedirs(os.path.dirname(INIT_OUT), exist_ok=True)
    strip_sh = os.path.join(AOSP, "build/soong/scripts/strip.sh")
    strip_env = os.environ.copy()
    strip_env["CLANG_BIN"] = os.path.dirname(CLANG_BIN)
    strip_env["XZ"] = os.path.join(AOSP, "prebuilts/build-tools/linux-x86/bin/xz")
    strip_env["CREATE_MINIDEBUGINFO"] = os.path.join(
        AOSP, "prebuilts/build-tools/linux-x86/bin/create_minidebuginfo"
    )
    run([
        strip_sh,
        "--keep-mini-debug-info",
        "-i", os.path.abspath(INIT_UNSTRIPPED),
        "-o", os.path.abspath(INIT_OUT),
        "-d", os.path.abspath(INIT_OUT + ".d"),
    ], env=strip_env)

    os.makedirs(os.path.dirname(INIT_INSTALL), exist_ok=True)
    import shutil

    shutil.copy2(INIT_OUT, INIT_INSTALL)
    if os.path.isdir(os.path.dirname(REL_INIT)):
        shutil.copy2(INIT_OUT, REL_INIT)

    out = subprocess.check_output(["md5sum", INIT_INSTALL], text=True).split()[0]
    print("init md5:", out)
    strings = subprocess.check_output(["strings", INIT_INSTALL], text=True)
    for bad in ("skip ALL exec_start", "R174 skip wait_for_prop apexd"):
        if bad in strings:
            print(f"ERROR: still contains: {bad}", file=sys.stderr)
            return 1
    print("MANUAL_RELINK_INIT_DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
