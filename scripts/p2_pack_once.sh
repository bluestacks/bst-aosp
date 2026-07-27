#!/bin/bash
# Disconnect all nbd then single pack
for n in /dev/nbd0 /dev/nbd1 /dev/nbd2 /dev/nbd3 /dev/nbd4 /dev/nbd5 /dev/nbd6 /dev/nbd7 /dev/nbd8 /dev/nbd9 /dev/nbd10 /dev/nbd11 /dev/nbd12 /dev/nbd13 /dev/nbd14 /dev/nbd15; do
  sudo qemu-nbd -d "$n" 2>/dev/null || true
done
sleep 3
exec bash ~/bst-aosp/scripts/p2_formal_diag_pack.sh
