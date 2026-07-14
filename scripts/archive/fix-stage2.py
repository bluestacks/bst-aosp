#!/usr/bin/env python3
import sys, os

target = sys.argv[1] if len(sys.argv) > 1 else "/tmp/initrd_test/boot/stage2.sh"

with open(target, "r") as f:
    content = f.read()

block = ("# bringup: force tmpfs for data/cache\n"
         "mkdir -p /data /cache /metadata\n"
         "mount -t tmpfs tmpfs /data\n"
         "mount -t tmpfs tmpfs /cache 2>/dev/null\n"
         "mount -t tmpfs tmpfs /metadata 2>/dev/null\n"
         "# bringup: non-fatal die_if_error\n"
         'die_if_error() { if [ $? -ne 0 ]; then echo "<3>WARNING(NON-FATAL): $@" > /dev/kmsg; fi; }\n')

content = content.replace("source /boot/bstsetup.env", block + "source /boot/bstsetup.env")

with open(target, "w") as f:
    f.write(content)
print("STAGE2_FIXED")
