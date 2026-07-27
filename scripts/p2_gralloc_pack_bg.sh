#!/bin/bash
# Pack current staged system (gralloc already baked in OUT + staged build.prop)
exec > >(tee ~/p2_gralloc_pack.log) 2>&1
bash ~/bst-aosp/scripts/p2_formal_diag_pack.sh
echo "A16DBG:P2:gralloc_pack wrapper exit=$?"
