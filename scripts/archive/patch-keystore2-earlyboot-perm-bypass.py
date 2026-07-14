#!/usr/bin/env python3
"""R126: bypass check_keystore_permission(EarlyBootEnded) in keystore2 maintenance.rs.

Root cause (R125): maintenance.earlyBootEnded calls check_keystore_permission first; in the
bst-aosp minimal-SELinux environment the binder caller has no SELinux context (calling_sid is
None) -> Error::sys -> ResponseCode::SYSTEM_ERROR(4) -> set_up_boot_level_cache never runs ->
no boot level key -> odsign BOOT_LEVEL_EXCEEDED(-84) -> no boot.art.

Fix (bringup): make the EarlyBootEnded permission check non-fatal so set_up_boot_level_cache
runs. TODO(restore): re-enable when SELinux contexts are properly set up.

Apply on the remote aosp16 tree:
  M=~/aosp16/system/security/keystore2/src/maintenance.rs
then `m keystore2` (OUT_DIR=out_nxt_Baklava64, lunch aosp_x86_64) and repackage initrd/fastboot
(BootImage Makefile copies out/.../system/bin/keystore2 -> initrd/boot/bin/keystore2).
"""
import pathlib, sys

M = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(
    "~/aosp16/system/security/keystore2/src/maintenance.rs").expanduser()
old = (
    "    fn early_boot_ended() -> Result<()> {\n"
    "        check_keystore_permission(KeystorePerm::EarlyBootEnded)\n"
    '            .context(ks_err!("Checking permission"))?;\n'
)
new = (
    "    fn early_boot_ended() -> Result<()> {\n"
    "        // BS-A16 bringup (R126): calling_sid is None in minimal-SELinux env, so\n"
    "        // check_keystore_permission returns SYSTEM_ERROR and blocks set_up_boot_level_cache\n"
    "        // (-> no boot level key -> odsign BOOT_LEVEL_EXCEEDED -> no boot.art). Make the\n"
    "        // EarlyBootEnded permission check non-fatal for bringup. TODO(restore): re-enable when\n"
    "        // SELinux contexts are properly set up.\n"
    "        let _ = check_keystore_permission(KeystorePerm::EarlyBootEnded);\n"
)
t = M.read_text()
if new.splitlines()[-1] in t and "BS-A16 bringup (R126)" in t:
    print("already patched"); sys.exit(0)
if old not in t:
    print("ANCHOR_NOT_FOUND"); sys.exit(1)
M.write_text(t.replace(old, new, 1))
print("patched", M)
