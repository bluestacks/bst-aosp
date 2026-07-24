#!/usr/bin/env python3
# P2-MECH-7: Connectivity EthernetConfigStore — BST static IP config (anti-detection, a13->a16).
# bstLoadStaticConfig: create static IpConfiguration from BST properties (ip_guest_addr, gateway, DNS).
# Gated by bst.config.modify_network. Boot-safe (property gate). Robust exact-string replace.
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

patch("packages/modules/Connectivity/service-t/src/com/android/server/ethernet/EthernetConfigStore.java", [
    # imports
    ("import android.net.IpConfiguration;\n",
     "import android.net.IpConfiguration;\n"
     "import android.net.IpConfiguration.IpAssignment;\n"
     "import android.net.IpConfiguration.ProxySettings;\n"
     "import android.net.LinkAddress;\nimport android.net.NetworkUtils;\n"
     "import android.net.StaticIpConfiguration;\nimport android.os.SystemProperties;\n"),
    # gate at read() method start
    ("    void read(final String newFilePath, final String oldFilePath, final String filename) {\n",
     "    void read(final String newFilePath, final String oldFilePath, final String filename) {\n"
     "        // A16DBG:P2:MECH BST static network config (a13; gated)\n"
     "        if (SystemProperties.getInt(\"bst.config.modify_network\", 1) > 0) {\n"
     "            bstLoadStaticConfig();\n"
     "            return;\n"
     "        }\n"),
    # bstLoadStaticConfig method (before the class closing or after read)
    ("    public void read() {\n",
     "    // A16DBG:P2:MECH BST: load static IP from properties (anti-detection, a13)\n"
     "    private void bstLoadStaticConfig() {\n"
     "        StaticIpConfiguration staticIp = new StaticIpConfiguration();\n"
     "        staticIp.ipAddress = new LinkAddress(\n"
     "                NetworkUtils.numericToInetAddress(\n"
     "                        SystemProperties.get(\"bst.status.ip_guest_addr\", \"10.0.2.15\")),\n"
     "                SystemProperties.getInt(\"bst.status.ip_addr_prefix_len\", 24));\n"
     "        staticIp.gateway = NetworkUtils.numericToInetAddress(\n"
     "                SystemProperties.get(\"bst.status.ip_gateway_addr\", \"10.0.2.2\"));\n"
     "        staticIp.dnsServers.add(NetworkUtils.numericToInetAddress(\n"
     "                SystemProperties.get(\"bst.dns_server\", \"8.8.8.8\")));\n"
     "        staticIp.dnsServers.add(NetworkUtils.numericToInetAddress(\n"
     "                SystemProperties.get(\"bst.dns_server2\", \"10.0.2.3\")));\n"
     "        mIpConfigurations.put(\"0\", new IpConfiguration(\n"
     "                IpAssignment.STATIC, ProxySettings.NONE, staticIp, null));\n"
     "    }\n\n"
     "    public void read() {\n"),
], "Connectivity EthernetConfigStore BST static IP")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
