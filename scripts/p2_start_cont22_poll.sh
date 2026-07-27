#!/bin/bash
set +u
sed -i 's/\r$//' ~/bst-aosp/scripts/p2_cont22_poll.sh
pkill -f 'scripts/p2_cont22_poll.sh' 2>/dev/null || true
sleep 1
: > ~/p2_cont22_poll.log
nohup bash ~/bst-aosp/scripts/p2_cont22_poll.sh </dev/null >/dev/null 2>&1 &
echo POLL_PID=$!
sleep 2
head -3 ~/p2_cont22_poll.log
pgrep -af 'p2_cont22_poll|g1_build_stable|bin/m droid' | head -8
