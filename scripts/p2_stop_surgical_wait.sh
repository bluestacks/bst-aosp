#!/bin/bash
# Stop load-wait surgical (human: build-machine contention is not a problem).
set +u
pkill -9 -f 'scripts/p2_cont21d_surgical' || true
echo "stopped_surgical $(date -Is)"
pgrep -u markxu -af 'p2_cont21d_surgical|wait_load' | head -5 || echo none
uptime
