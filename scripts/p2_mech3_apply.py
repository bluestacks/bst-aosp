#!/usr/bin/env python3
# P2-MECH-3: getprop BST property filter (anti-detection, a13->a16).
# Hide BST-specific properties (bst.* prefix + 12-name list) from `getprop` output unless
# bst.debug.show_prop=1. a16 PrintProperty is the insertion point (a13 filtered in iteration loop).
# system/core/toolbox, low boot risk (toolbox command). Robust exact-string replace.
import os, sys
A16 = os.path.expanduser("~/aosp16")
ERRS = []
def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src: ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1: ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig: ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

GLOBALS = '''// A16DBG:P2:MECH BST getprop property filter (anti-detection, a13)
static bool show_bst_props = false;
static const std::vector<std::string> bst_prop_list = {
    "init.svc.bst", "init.svc.imeservice", "init.svc.appstatsd",
    "init.svc.enable_arm_bin", "init.svc.postupgrade", "gsm.sim.bstserial",
    "persist.sys.pcode", "persist.sys.devId", "persist.sys.abivalue",
    "persist.sys.user.email", "ro.csc.sales_code", "ro.product.store",
};
static bool FindBstProp(const char* name) {
    std::string s(name);
    for (const auto& v : bst_prop_list) {
        if (s == v) return true;
    }
    return false;
}

'''

patch("system/core/toolbox/getprop.cpp", [
    # globals + FindBstProp before PrintProperty
    ("void PrintProperty(const char* name, const char* default_value, ResultType result_type) {\n",
     GLOBALS + "void PrintProperty(const char* name, const char* default_value, ResultType result_type) {\n"),
    # filter at PrintProperty start
    ("    switch (result_type) {\n        case ResultType::Value:\n",
     "    // A16DBG:P2:MECH BST: skip BST-specific props unless bst.debug.show_prop=1 (a13)\n"
     "    if (!show_bst_props && (strncmp(name, \"bst\", 3) == 0 || FindBstProp(name))) {\n"
     "        return;\n"
     "    }\n"
     "    switch (result_type) {\n        case ResultType::Value:\n"),
    # init show_bst_props in getprop_main
    ("    auto result_type = ResultType::Value;\n",
     "    auto result_type = ResultType::Value;\n"
     "    // A16DBG:P2:MECH BST: init show_bst_props from bst.debug.show_prop (a13)\n"
     "    char _bst_dbg[92] = {0};\n"
     "    if (__system_property_get(\"bst.debug.show_prop\", _bst_dbg) > 0) {\n"
     "        show_bst_props = (strcmp(_bst_dbg, \"1\") == 0);\n"
     "    }\n"),
], "getprop BST prop filter")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
